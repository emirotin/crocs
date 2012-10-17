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
current_drawer = null

rand_id = ->
    ids = [key for key of clients when clients.hasOwnProperty(key)]
    ids[Math.floor(Math.random() * ids.length)]

io.sockets.on 'connection', (socket) ->
    socket_id = socket.id
    clients[socket_id] = socket
    if current_drawer == null
        current_drawer = socket_id
    socket.emit 'login info', { id: socket_id, is_drawer: current_drawer == socket_id }
    socket.on 'line create', (data) ->
        socket.broadcast.emit 'line create', data
    socket.on 'line update', (data) ->
        socket.broadcast.emit 'line update', data
    socket.on 'line end', (data) ->
        socket.broadcast.emit 'line end', data
    socket.on 'disconnect', ->
        delete clients[socket_id]
        if current_drawer == socket_id
            current_drawer = rand_id()


port = process.env.PORT or 5000

server.listen port