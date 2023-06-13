const http = require('http')
const fs = require('fs')
const path = require('path')
const { S3Client, PutObjectCommand, DeleteObjectsCommand, ListObjectsV2Command } = require("@aws-sdk/client-s3")
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner")
const { Pool } = require('pg')

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
  !process.env.SEED_USER_PASSWORD ||
  !process.env.HOST ||
  !process.env.PORT
) {
  console.error('Please provide all required environment variables.')
  return
}

const CONTENT_TYPES = {
  json: 'application/json'
}
const CONTROLLER = {

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

const log = (msg, sub1, level = "INFO") => {
  const toLog = `[ ${new Date().toISOString()} | ${level} ] ${msg}`
  if (level === "ERROR") console.error(`\x1b[31m ${toLog} \x1b[0m`, sub1)
  else console.log(toLog, sub1 ? sub1 : "")
}

const getUserById = id => {
  let pgClient
  return pgPool.connect()
    .then(ret => {
      pgClient = ret
      return pgClient.query(`SELECT id, username, email FROM users WHERE id = $1`, [id])
    })
    .then(res => {
      pgClient.release()
      return res.rows[0] ?? null
    })
    .catch(err => {
      log('error getting user by id: ', err, 'ERROR')
      throw err
    })
}

const respond = (res, statusCode, data) => {
  res.writeHead(statusCode, { 'Content-Type': CONTENT_TYPES.json })
  res.end(JSON.stringify(data))
}
const handleUsersRequest = (req, res) => {
  switch (req.method) {
    case 'GET':
      const userId = req.parsedUrl.searchParams.get('id')
      if (!userId) respond(res, 404, { error: 'Malformed url for /users request' })

      getUserById(userId)
        .then(user => {
          if (user) respond(res, 200, user)
          else respond(res, 404, { error: `No user with id [${userId}] found` })
        })
        .catch(err => {
          respond(res, 500, { error: err.message })
        })
      break
    case 'POST':
      // TODO add user to database
      // respond with user id?
      debugger
      break
  }
}
const handleNotFoundRequest = (req, res) => {
  res.writeHead(404, { 'Content-Type': CONTENT_TYPES.json })
  res.end(JSON.stringify({ error: 'Not found.' }))
}
const handleRequest = (req, res) => {
  req.parsedUrl = new URL(req.url, `http://${req.headers.host}`)
  log("New Request: ", req.parsedUrl.pathname)

  switch(req.parsedUrl.pathname.split("/")[1]) {
    case 'users':
      handleUsersRequest(req, res)
      break
    default:
      handleNotFoundRequest(req, res)
  }
}

const main = () => {
  log(`Starting scare-bnb api server`)

  const exit = signal => {
    server.close(() => process.exit())
    log('Server is closed.')
  }

  const server = http.createServer(handleRequest)
  server.listen(process.env.PORT, process.env.HOST, e => {
    if (e) {
      log(`server.listen() returned error: `, e, process.env.PORT)
      return
    }
    log(`Server is listening on ${process.env.HOST}:${process.env.PORT}`)
  })

  process.on('SIGINT', exit)
  process.on('SIGTERM', exit)
  process.on('uncaughtException', (err, origin) => {
    log(`Process caught unhandled exception: ${err} ${origin}`, 'ERROR')
  })
}

main()
