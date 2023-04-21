const { Pool } = require('pg')
const crypto = require('crypto')
const fs = require('fs')
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3")
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner")
const { faker } = require('@faker-js/faker')

const dotEnv = fs.readFileSync('.env', 'utf8')
dotEnv.split('\n').forEach(line => {
  const [ key, val ] = line.split('=')
  process.env[key] = val
})

if (
  !process.env.PG_PW ||
  !process.env.AWS_ACCESS || 
  !process.env.AWS_SECRET ||
  !process.env.ENV ||
  !process.env.SEED_USER_PASSWORD
) {
  console.error('Please provide all required environment variables.')
  return
}

const pool = new Pool({
  user: 'aaronparisi',
  host: 'localhost',
  database: `scare-bnb-${process.env.ENV}`,
  password: process.env.PG_PW,
  port: 5432,
})
const s3 = new S3Client({
  region: 'us-west-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS,
    secretAccessKey: process.env.AWS_SECRET,
  }
})

let SEEDS = {
  users: [],
  bookings: []
}
const BUCKET = `scare-bnb-${process.env.ENV}`
const CONTENT_TYPES = {
  allImages: ["image/png", "image/jpeg", "image/webp"]
}

const fetchSignedUrl = async (command, exp = 60 * 2) => {
  presignedUrl = await getSignedUrl(
    s3,
    command,
    { expiresIn: exp }
  )
  console.log(presignedUrl)
  return presignedUrl
}

const sanitizeFilename = filename => {
  const extIdx = filename.lastIndexOf('.')
  const ext = filename.slice(extensionIndex)
  const sanitizedFilename = filename
    .slice(0, extensionIndex)
    .replace(/[^a-zA-Z0-9]/g, '_')

  return `${sanitizedFilename}${ext}`
}
const sanitizeFakerName = fakerName => {
  return fakerName.replace(/[^a-zA-Z0-9._%+-]/g, '')
}

const generateUser = () => {
  console.log('generating user')
  const fname = sanitizeFakerName(faker.name.firstName())
  const lname = sanitizeFakerName(faker.name.lastName())
  return {
    username: `${fname}_${lname}_${faker.datatype.number(1000)}`,
    email: `${lname}_${fname}@screamail.com`,
    password: process.env.SEED_USER_PASSWORD,
    properties: []
  }
}
const generateProperty = () => {
  console.log('generating property')
  return {
    title: faker.lorem.words(3),
    description: faker.lorem.lines(3),
    beds: faker.datatype.number({ min: 0, max: 10 }),
    baths: faker.datatype.number({ min: 0, max: 5 }),
    square_feet: faker.datatype.number({ min: 100, max: 1000000 }),
    nightly_rate: faker.commerce.price({ min: 0, max: 1000000000, dec: 2 }),
    smoking: faker.datatype.boolean(),
    pets: faker.datatype.boolean(),
    address: generateAddress()
  }
}
const generateAddress = () => {
  console.log('generating address')
  return {
    line_1: faker.address.streetAddress(),
    city: faker.address.city(),
    state: faker.address.stateAbbr(),
    zip_code: faker.address.zipCode(),
  }
}
const generateValidBooking = async (guestId, propertyId) => {
  console.log('generating booking')
  const startDate = faker.date.soon(200)
  const booking = {
    start_date: faker.date.soon(200),
    end_date: new Date(startDate.getTime() + (5 * 86400)),
    guest_id: guestId,
    property_id: propertyId
  }

  const bookingOverlaps = await isBookingOverlapping(booking)
  if (bookingOverlaps) return generateBooking(guestId, propertyId)
  else return Promise.resolve(booking)
}

const hashAndSaltPassword = pw => {
  const salt = crypto.randomBytes(16).toString('hex')
  const hash = crypto
    .pbkdf2Sync(pw, salt, 1000, 64, 'sha512')
    .toString('hex')
  return {hash, salt}
}
const buildStoredFilename = filename => {
  return `${new Date()}_${sanitizeFilename(filename)}`
}
const isBookingOverlapping = async booking => {
  const { property_id, start_date, end_date } = booking
  const pgClient = await pool.connect()

  try {
    const overlaps = await pgClient.query(`
      SELECT COUNT(*) AS count
      FROM bookings
      WHERE property_id = $1
        AND start_date < $2
        AND end_date > $3
    `, [property_id, end_date, start_date])

    console.log(overlaps.rows)
    console.log(`booking for prop ${property_id} is overlapping: ${overlaps.rows[0].count > 0}`)
    return overlaps.rows[0].count > 0
  } catch (err) {
    debugger
    throw err
  } finally {
    console.log('releasing pgClient')
    pgClient.release();
  }
}
const shuffleArray = array => {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]]
  }

  return array
}

const deleteTables = async () => {
  console.log('inside deleteTables')
  const pgClient = await pool.connect()
  console.log('pool connection established')

  try {
    await pgClient.query('BEGIN')

    console.log('obtaining table names for deletion')
    const tnQuery = await pgClient.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE';
    `)

    console.log('beginning table deletion')
    const drops = tnQuery.rows
      .map(row => {
        return pgClient.query(`
          DROP TABLE IF EXISTS "${row.table_name}" CASCADE;
        `)
      })
    await Promise.all(drops)
    console.log('finished deleting all tables')
  } catch (err) {
    await pgClient.query('ROLLBACK')
    console.log('rolling back due to error in deleteTables: ', err)
    throw err
  } finally {
    console.log('releasing pgClient')
    pgClient.release()
  }
}
const buildTables = async () => {
  console.log('inside buildTables')
  const pgClient = await pool.connect()
  console.log('pool connection established')

  try {
    await pgClient.query('BEGIN')

    console.log('attempting to CREATE users table')
    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) UNIQUE NOT NULL CHECK (username NOT LIKE '% %'),
        email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        avatar_id VARCHAR(255) UNIQUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
      );
    `)

    console.log('attempting to CREATE properties table')
    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS properties (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        beds INTEGER NOT NULL CHECK (beds >= 0 AND beds <= 50),
        baths INTEGER NOT NULL CHECK (baths >= 0 AND baths <= 50),
        square_feet INTEGER NOT NULL CHECK (square_feet >= 0),
        nightly_rate NUMERIC(10, 2) NOT NULL,
        smoking BOOLEAN NOT NULL,
        pets BOOLEAN NOT NULL,
        manager_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
      );
    `)

    console.log('attempting to CREATE addresses table')
    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS addresses (
        id SERIAL PRIMARY KEY,
        line_1 VARCHAR(255) NOT NULL,
        line_2 VARCHAR(255),
        city VARCHAR(255) NOT NULL,
        state VARCHAR(255) NOT NULL,
        zip_code VARCHAR(10) NOT NULL CHECK (zip_code ~ '^[0-9]{5}(?:-[0-9]{4})?$'),
        property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
      );
    `)

    console.log('attempting to CREATE bookings table')
    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS bookings (
        id SERIAL PRIMARY KEY,
        start_date TIMESTAMP WITH TIME ZONE NOT NULL,
        end_date TIMESTAMP WITH TIME ZONE NOT NULL,
        guest_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
      );
    `)

    console.log('creating overlap-check function')
    await pgClient.query(`
      CREATE OR REPLACE FUNCTION bookings_overlap_check()
      RETURNS TRIGGER AS $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM bookings
          WHERE guest_id = NEW.guest_id
          AND property_id = NEW.property_id
          AND start_date <= NEW.end_date
          AND end_date >= NEW.start_date
          AND id != NEW.id
        ) THEN
          RAISE EXCEPTION 'Booking overlaps with existing booking';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `)
    console.log('attaching overlap-check to bookings table')
    await pgClient.query(`
      CREATE TRIGGER bookings_overlap_trigger
      BEFORE INSERT OR UPDATE ON bookings
      FOR EACH ROW
      EXECUTE FUNCTION bookings_overlap_check();
    `)
    console.log('overlap-check attached to bookings table')

    console.log('attempting to CREATE property-images table')
    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS "property-images" (
        id SERIAL PRIMARY KEY,
        image_id VARCHAR(255) UNIQUE,
        property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
      );
    `)

    console.log('attempting COMMIT')
    await pgClient.query('COMMIT')
    console.log('COMMIT successful')
  } catch (err) {
    await pgClient.query('ROLLBACK')
    console.log('rolling back due to error in buildTables: ', err)
    throw err
  } finally {
    console.log('releasing pgClient')
    pgClient.release();
  }
}
const seedSeeds = (numUsers, numPropsPerUser) => {
  console.log(`seeding seeds: ${numUsers} users, each with ${numPropsPerUser} properties`)
  for (let i = 0; i < numUsers; i++) {
    const user = generateUser()
    for (let j = 0; j < numPropsPerUser; j++) {
      user.properties.push(generateProperty())
    }
    SEEDS.users.push(user)
  }
}
const seedBucket = () => {
  // query for all users usernames
  // for each username, find the file in /seed_images/users/<username>/ directory
  // upload to aws with key `${new Date()}_${username}_avatar.${ext}`
  // save same path to database for that user

  // query for all properties
  // for each property title, find directory /seed_images/properties/<propTitle>/
  // for each file in that directory:
    // upload to aws with key `${new Date()}_${property_title}_${i}.${ext}`
    // loop via index, sanitize property title
}
const seedTables = async () => {
  console.log('seeding tables')
  const pgClient = await pool.connect()
  let shouldSeedBucket = true

  try {
    console.log('attempting to seed users and properties')
    const userPromises = []
    const propertyPromises = []
    SEEDS.users.forEach(user => {
      console.log('seeding user: ', user.username)
      const { hash, salt } = hashAndSaltPassword(user.password)
      const prom = pgClient.query(`
        INSERT INTO users (id, username, email, password_hash, password_salt) VALUES (DEFAULT, $1, $2, $3, $4) RETURNING id;
      `, [
        user.username,
        user.email,
        hash,
        salt
      ])
        .then(row => row.rows[0].id)
      userPromises.push(prom)
    })

    Promise.all(userPromises)
      .then(userIds => {
        userIds.forEach((userId, idx) => {
          SEEDS.users[idx].properties.forEach(prop => {
            console.log('seeding property: ', prop.title)
            const prom = pgClient.query(`
              INSERT INTO properties (id, title, description, beds, baths, square_feet, nightly_rate, smoking, pets, manager_id) VALUES (DEFAULT, $1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id;
            `, [
              prop.title,
              prop.description,
              prop.beds,
              prop.baths,
              prop.square_feet,
              prop.nightly_rate,
              prop.smoking,
              prop.pets,
              userId
            ])
              .then(row => row.rows[0].id)
            propertyPromises.push(prom)

            prom.then(propId => {
              const addr = prop.address
              console.log('seeding address: ', addr.line_1)
              if (addr) {
                pgClient.query(`
                  INSERT INTO addresses (id, line_1, line_2, city, state, zip_code, property_id) VALUES (DEFAULT, $1, $2, $3, $4, $5, $6);
                  `, [
                    addr.line_1,
                    addr.line_2,
                    addr.city,
                    addr.state,
                    addr.zip_code,
                    propId
                  ])}
            })
          })
        })

        return Promise.all([
          Promise.all(userPromises),
          Promise.all(propertyPromises)
        ])
      })
      .then(([userIds, propertyIds]) => {
        console.log('attempting to seed bookings')
        userIds.forEach(async userId => {
          for (let i = 0; i < 2; i ++ ) {
            const propId = propertyIds[Math.floor(Math.random() * propertyIds.length)]
            let booking = await generateValidBooking(userId, propId)
            console.log(booking.property_id, booking.start_date, booking.end_date)
            pgClient.query(`
              INSERT INTO bookings (id, start_date, end_date, guest_id, property_id) VALUES (DEFAULT, $1, $2, $3, $4);
            `, [
              booking.start_date,
              booking.end_date,
              userId,
              propId
            ])
          }
        })
        console.log('finished seeding users, properties, addresses, and bookings')
      })
  } catch (err) {
    await pgClient.query('ROLLBACK')
    shouldSeedBucket = false
    console.log('rolling back due to error seeding users: ', err)
    throw err
  } finally {
    console.log('releasing pgClient')
    pgClient.release()
  }

  if (shouldSeedBucket) {
    // TODO
  }
}
const resetTables = async () => {
  await deleteTables()
  await buildTables()
  await seedSeeds(20, 1)
  await seedTables()
}

resetTables()
// fetchSignedUrl(
//   new PutObjectCommand({
//     Bucket: BUCKET,
//     Key: "fake.txt",
//     ContentType: CONTENT_TYPES.allImages
//   }),
// )
