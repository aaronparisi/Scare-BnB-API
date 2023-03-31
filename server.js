const { Pool } = require('pg')

const pool = new Pool({
  user: 'aaronparisi',
  host: 'localhost',
  database: 'springfield-bnb',
  password: process.env.PG_PW,
  port: 5432,
})

const buildTables = async () => {
  console.log('---- inside buildTables')
  const client = await pool.connect()
  console.log('---- pool connection established')

  try {
    await client.query('BEGIN')
    console.log('attempting to CREATE users table')
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL
      );
    `)
    await client.query(`
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
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        beds INTEGER NOT NULL
      );
    `)
    console.log('attempting COMMIT')
    await client.query('COMMIT')
    console.log('COMMIT successful')
  } catch (err) {
    await client.query('ROLLBACK')
    console.log('error in buildTables: ', err)
    throw err
  } finally {
    console.log('releasing client')
    client.release();
  }
}

buildTables()
