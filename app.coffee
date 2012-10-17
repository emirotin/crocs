path = require 'path'

express = require 'express'
socket_io = require('socket.io')

app = express()
server = require('http').createServer(app)
io = socket_io.listen server

app_root = __dirname
static_path = path.join app_root, 'static'

app.set 'view engine', 'jade'

app
    .use(express.logger())
    .use(express.bodyParser())
    .use(express.methodOverride())
    .use(app.router)
    .use(express.static static_path)

app.get '/', (req, res) ->
    res.render 'index'

clients = {}
client_id = 0

io.sockets.on 'connection', (socket) ->
    client_id += 1
    clients[client_id] = socket
    socket.emit 'login info', { id: client_id }
    socket.on 'line create', (data) ->
        console.log data
        socket.broadcast.emit 'line create', data
    socket.on 'line update', (data) ->
        socket.broadcast.emit 'line update', data
    socket.on 'line end', (data) ->
        socket.broadcast.emit 'line end', data

port = process.env.PORT or 5000

server.listen port