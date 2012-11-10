path = require 'path'
fs = require 'fs'
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
clients_count = 0
current_drawer = null
current_word = null
round_in_progress = false
round_lines = {}
round_chat_messages = []
words = fs.readFileSync path.join(app_root, 'words.txt'), 'ascii'
words = words.split '\n'
end_round_timeout = null

rand_id = ->
    ids = [key for key of clients when clients.hasOwnProperty(key)]
    ids[Math.floor(Math.random() * ids.length)]

io.sockets.on 'connection', (socket) ->
    socket_id = socket.id
    clients[socket_id] = socket
    clients_count++
    console.log clients_count
    
    personal_chat_msg = null
    need_to_start_round = false
    if clients_count == 1
        personal_chat_msg = 'You are the first player. Please wait at least one more player to begin.'
    # need to start round when more than one client connected and round is not started yet
    else if clients_count > 1 && !round_in_progress
        need_to_start_round = true
        personal_chat_msg = 'Second player connected. Crocs time!!!'
    else
        personal_chat_msg = 'The game is in progress. You can type in your guess.'

    socket.emit 'login info', { id: socket_id, round_lines: round_lines, round_chat_messages: round_chat_messages }
    socket.emit 'chat msg', message: personal_chat_msg

    if need_to_start_round
        start_round()

    socket.on 'line create', (data) ->
        socket_broadcast_line socket, 'line create', data
    socket.on 'line update', (data) ->
        socket_broadcast_line socket, 'line update', data
    socket.on 'line end', (data) ->
        socket_broadcast_line socket, 'line end', data
    socket.on 'chat msg', (data) ->
        clear = data.message.replace /[^0-9a-zA-Zа-яА-ЯёЁ]+/, ' '
        guess = clear.split(' ').indexOf(current_word) != -1
        socket_broadcast_msg socket, 'chat msg', data
        if guess
            socket_broadcast_msg socket, 'chat msg', message: 'CORRECT!!! Game round is over. Next game begins!!'
    socket.on 'disconnect', ->
        delete clients[socket_id]
        clients_count--
        if current_drawer == socket_id
            end_round()

port = process.env.PORT or 5000

server.listen port

start_round = () ->
    current_word = words[Math.floor(Math.random() * words.length)]
    current_drawer = rand_id()
    round_in_progress = true
    drawer_socket = clients[current_drawer]
    console.log 'SOKEEEEEEEEEEEEEEEETTTT' + current_drawer
    #drawer_socket.broadcast.emit 'round start', { drawer_id: current_drawer }
    #drawer_socket.emit 'round start', { drawer_id: current_drawer, word: current_word }
    #end_round_timeout = setTimeout end_round, 2*60*1000

end_round = () ->
    if end_round_timeout
        clearTimeout end_round_timeout
        end_round_timeout = null
    start_round()

socket_broadcast_line = (socket, command, data) ->
    if data.points
        round_lines[data.id] = data
    socket.broadcast.emit command, data

socket_broadcast_msg = (socket, command, data, dont_record_chat_data) ->
    if !dont_record_chat_data then round_chat_messages.push message: data
    socket.broadcast.emit command, message: data
    socket.emit command, data

record_chat_msg = (msg) ->
    round_chat_messages.push message: msg
