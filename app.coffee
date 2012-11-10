path = require 'path'
connect_assets = require 'connect-assets'
express = require 'express'
socket_io = require('socket.io')

app = express()
server = require('http').createServer(app)
io = socket_io.listen server

app_root = __dirname
static_dir = 'static'
static_path = path.join app_root, static_dir

app.set 'view engine', 'jade'

app
    .use(express.logger())
    .use(express.bodyParser())
    .use(express.methodOverride())
    .use(app.router)
    .use(express.static static_path)
    .use(connect_assets src: static_dir)

global.js.root = 'javascripts'
global.css.root = 'stylesheets'

app.get '/', (req, res) ->
    res.render 'index'

clients = {}
current_drawer = null
#round_data = { messages: [] }
round_in_progress = false
round_lines = {}
round_chat_messages = []

rand_id = ->
    ids = [key for key of clients when clients.hasOwnProperty(key)]
    ids[Math.floor(Math.random() * ids.length)]

io.sockets.on 'connection', (socket) ->
    socket_id = socket.id
    clients[socket_id] = socket
    
    personal_chat_msg = null
    need_to_start_round = false
    if clients.length == 1
        personal_chat_msg = 'You are the first player. Please wait at least one more player to begin.'
    # need to start round when more than one client connected and round is not started yet
    else if clients.length > 1 && !round_in_progress
        current_drawer = rand_id()
        round_in_progress = true
        need_to_start_round = true
        personal_chat_msg = 'Second player connected. Crocs time!!!'
    else
        personal_chat_msg = 'The game is in progress. You can type in your guess.'

    socket.emit 'login info', { id: socket_id, round_lines: round_lines, round_chat_messages: round_chat_messages }
    socket.emit 'chat msg', message: personal_chat_msg

    if need_to_start_round
        socket_broadcast_msg 'round start', { drawer_id: current_drawer }, true

    socket.on 'line create', (data) ->
        socket_broadcast_line socket, 'line create', data
    socket.on 'line update', (data) ->
        socket_broadcast_line socket, 'line update', data
    socket.on 'line end', (data) ->
        socket_broadcast_line socket, 'line end', data
    socket.on 'chat msg', (data) ->
        socket_broadcast_msg socket, 'chat msg', data
    socket.on 'disconnect', ->
        delete clients[socket_id]
        if current_drawer == socket_id
            # todo: restart round
            current_drawer = rand_id()

port = process.env.PORT or 5000

server.listen port


socket_broadcast_line = (socket, command, data) ->
    if data.points
        round_lines[data.id] = data
    socket.broadcast.emit command, data

socket_broadcast_msg = (socket, command, data, dont_record_chat_data) ->
    if !dont_record_chat_data then round_chat_messages.push message: data
    socket.broadcast.emit command, message: data
    socket.emit command, message: data

record_chat_msg = (msg) ->
    round_chat_messages.push message: msg
