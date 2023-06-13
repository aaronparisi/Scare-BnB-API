const { Pool } = require('pg')
const crypto = require('crypto')
const fs = require('fs')
const path = require('path')
const { S3Client, PutObjectCommand, DeleteObjectsCommand, ListObjectsV2Command } = require("@aws-sdk/client-s3")
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner")
const { faker } = require('@faker-js/faker')

const dotEnv = fs.readFileSync(path.join(__dirname, '.env'), 'utf8')
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

const pgPool = new Pool({
  user: 'aaronparisi',
  host: 'localhost',
  database: `scare-bnb-${process.env.ENV}`,
  password: process.env.PG_PW,
  port: 5432,
})
const s3 = new S3Client({
  region: 'us-west-2',
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

const sanitizeFakerName = fakerName => {
  return fakerName.replace(/[^a-zA-Z0-9._%+-]/g, '')
}
const generateRandomPathname = (l = 20) => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < l; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
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
  debugger
  return {
    title: faker.lorem.words(3),
    description: faker.lorem.lines(3),
    beds: faker.datatype.number({ min: 0, max: 10 }),
    baths: faker.datatype.number({ min: 0, max: 5 }),
    square_feet: faker.datatype.number({ min: 100, max: 1000000 }),
    nightly_rate: faker.commerce.price(0, 10000000, 2),
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
  if (bookingOverlaps) return generateValidBooking(guestId, propertyId)
  else return Promise.resolve(booking)
}

const hashAndSaltPassword = pw => {
  const salt = crypto.randomBytes(16).toString('hex')
  const hash = crypto
    .pbkdf2Sync(pw, salt, 1000, 64, 'sha512')
    .toString('hex')
  return {hash, salt}
}
const isBookingOverlapping = async booking => {
  const { property_id, start_date, end_date } = booking
  const pgClient = await pgPool.connect()

  try {
    const overlaps = await pgClient.query(`
      SELECT COUNT(*) AS count
      FROM bookings
      WHERE property_id = $1
        AND start_date < $2
        AND end_date > $3
    `, [property_id, end_date, start_date])

    return overlaps.rows[0].count > 0
  } catch (err) {
    throw err
  } finally {
    console.log('finished booking overlap check; releasing pgClient')
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
  const pgClient = await pgPool.connect()
  console.log('pgPool connection established')

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
    console.log('finished deleting tabbles; releasing pgClient')
    pgClient.release()
  }
}
const buildTables = async () => {
  console.log('inside buildTables')
  const pgClient = await pgPool.connect()
  console.log('pgPool connection established')

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
        image_pathname VARCHAR(255) UNIQUE,
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
          RAISE EXCEPTION 'Existing booking for property "%" conflicts with start_date: %, end_date: %',
            (SELECT title FROM properties WHERE id = NEW.property_id),
            NEW.start_date,
            NEW.end_date;
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
        image_pathname VARCHAR(255) UNIQUE,
        property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
      );
    `)

    await pgClient.query('COMMIT')
    console.log('table creation COMMIT successful')
  } catch (err) {
    await pgClient.query('ROLLBACK')
    console.log('rolling back due to error in buildTables: ', err)
    throw err
  } finally {
    console.log('table creation completed; releasing client')
    pgClient.release();
  }
}
const seedTables = async () => {
  console.log('seeding tables')
  const pgClient = await pgPool.connect()

  try {
    console.log('attempting to seed users')
    const userPromises = []
    const propertyPromises = []
    const bookingPromises = []
    const userImagePromises = []
    const propertyImagePromises = []
    for (let i = 0; i < 5; i++) {
      const user = generateUser()
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
    }

    Promise.all(userPromises)
      .then(userIds => {
        console.log('attempting to seed properties')
        userIds.slice(0, 3).forEach(userId => {
          for (let j = 0; j < 1; j++) {  // loop is silly now but potenaial to have multiple props per user
            const prop = generateProperty()
            console.log('seeding property: ', prop.title)
            const prom = pgClient.query(
              `INSERT INTO properties (id, title, description, beds, baths, square_feet, nightly_rate, smoking, pets, manager_id) VALUES (DEFAULT, $1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id;`,
              [
                prop.title,
                prop.description,
                prop.beds,
                prop.baths,
                prop.square_feet,
                prop.nightly_rate,
                prop.smoking,
                prop.pets,
                userId
              ]
            )
              .then(row => row.rows[0].id)
            propertyPromises.push(prom)

            prom.then(propId => {
              const addr = prop.address
              console.log('seeding address: ', addr.line_1)
              if (addr) {
                pgClient.query(
                  `INSERT INTO addresses (id, line_1, line_2, city, state, zip_code, property_id) VALUES (DEFAULT, $1, $2, $3, $4, $5, $6);`,
                  [
                    addr.line_1,
                    addr.line_2,
                    addr.city,
                    addr.state,
                    addr.zip_code,
                    propId
                  ]
                )
              }
            })
          }
        })

        return Promise.all([
          Promise.resolve(userIds),
          Promise.all(propertyPromises)
        ])
      })
      .then(([userIds, propertyIds]) => {
        console.log('attempting to seed bookings')
        userIds.slice(3, 5).forEach(userId => {
          for (let j = 0; j < 2; j++ ) {  // 2 bookings per guest
            const propId = propertyIds[Math.floor(Math.random() * propertyIds.length)]
            const prom = generateValidBooking(userId, propId)
              .then(booking => {
                pgClient.query(
                  `INSERT INTO bookings (id, start_date, end_date, guest_id, property_id) VALUES (DEFAULT, $1, $2, $3, $4);`,
                  [
                    booking.start_date,
                    booking.end_date,
                    userId,
                    propId
                  ]
                )
              })
            bookingPromises.push(prom)
          }
        })

        return Promise.all([
          Promise.resolve(userIds),
          Promise.resolve(propertyIds),
          Promise.all(bookingPromises)
        ])
      })
      .then(([userIds, propertyIds, _]) => {
        console.log('finished seeding bookings')

        const userImagePaths = fs.readdirSync(path.join(__dirname, 'images', 'users'), 'utf8')
          .filter(f => fs.statSync(path.join(__dirname, 'images', 'users', f)).isFile() && !f.startsWith('.'))
        const propertyImagePaths = fs.readdirSync(path.join(__dirname, 'images', 'properties'), 'utf8')
          .filter(f => fs.statSync(path.join(__dirname, 'images', 'properties', f)).isFile() && !f.startsWith('.'))
        if (userIds.length > userImagePaths.length) throw new Error(`Too few user images.  users: ${userIds.length}; user images: ${userImagePaths.length}`)
        if (propertyIds.length > propertyImagePaths.length) throw new Error(`Too few property images.  properties: ${propertyIds.length}; property images: ${propertyImagePaths.length}`)

        console.log('seeding user image ids in users table')
        userIds.forEach((userId, idx) => {
          const imagePath = userImagePaths[idx]
          const imageData = fs.readFileSync(path.join(__dirname, 'images', 'users', imagePath))
          const awsImagePath = new Date().toISOString() + '_' + generateRandomPathname() + path.extname(imagePath)
          const prom = pgClient.query(
            `UPDATE users SET image_pathname = $1 WHERE id = $2;`,
            [
              awsImagePath,
              userId
            ]
          )
            .then(() => {
              return {
                imageData,
                awsImagePath
              }
            })
          userImagePromises.push(prom)
        })

        console.log('seeding property images table')
        propertyIds.forEach((propertyId, idx) => {
          for (let i = 0; i < 3; i++) {
            const imagePath = propertyImagePaths[idx]
            const imageData = fs.readFileSync(path.join(__dirname, 'images', 'properties', imagePath))
            const awsImagePath = new Date().toISOString() + '_' + generateRandomPathname() + path.extname(imagePath)
            console.log(imagePath)
            console.log(path.extname(imagePath))
            console.log(awsImagePath)
            const prom = pgClient.query(
              `INSERT INTO "property-images" (id, image_pathname, property_id) VALUES (DEFAULT, $1, $2);`,
              [
                awsImagePath,
                propertyId
              ]
            )
              .then(() => {
                return {
                  imageData,
                  awsImagePath
                }
              })
            propertyImagePromises.push(prom)
          }
        })

        return Promise.all([
          Promise.all(userImagePromises),
          Promise.all(propertyImagePromises)
        ])
      })
      .then(async ([userImageInfos, propertyImageInfos]) => {
        const objs = await s3.send(new ListObjectsV2Command({ Bucket: BUCKET }))
        await s3.send(new DeleteObjectsCommand({
          Bucket: BUCKET,
          Delete: {
            Objects: objs.Contents.map(o => ({ Key: o.Key }))
          }
        }))

        userImageInfos.forEach(i => {
          console.log('putting user image object to aws bucket: ', i.awsImagePath)
          s3.send(new PutObjectCommand({
            Bucket: BUCKET,
            Key: i.awsImagePath,
            Body: i.imageData
          }))
        })
        propertyImageInfos.forEach(i => {
          console.log('putting property image object to aws bucket: ', i.awsImagePath)
          s3.send(new PutObjectCommand({
            Bucket: BUCKET,
            Key: i.awsImagePath,
            Body: i.imageData
          }))
        })
      })
  } catch (err) {
    await pgClient.query('ROLLBACK')
    console.log('rolling back due to error seeding tables: ', err)
    throw err
  } finally {
    console.log('finished seeding users, properties, addresses, and bookings; releasing client')
    pgClient.release()
  }
}
const resetTables = async () => {
  await deleteTables()
  await buildTables()
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
