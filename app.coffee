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
users = {}
socket_to_user = {}
clients_count = 0
current_drawer = null
current_word = null
round_in_progress = false
round_lines = {}
round_chat_messages = []
words = fs.readFileSync path.join(app_root, 'words.txt'), 'ascii'
words = words.split '\n'
end_round_timeout = null

active_users = -> (key for key of users when users.hasOwnProperty(key) and users[key])

rand_user = ->
    ids = active_users()
    ids[Math.floor(Math.random() * ids.length)]

io.sockets.on 'connection', (socket) ->
    socket_id = socket.id
    users_count = active_users().length
    personal_chat_msg = null
    if users_count == 1
        personal_chat_msg = 'You are the first player. Please wait at least one more player to begin.'
    # need to start round when more than one client connected and round is not started yet
    else if users_count > 1 && !round_in_progress
        personal_chat_msg = 'Second player connected. Crocs time!!!'
    else
        personal_chat_msg = 'The game is in progress. You can type in your guess.'

    socket.emit 'connect info', { round_lines: round_lines, round_chat_messages: round_chat_messages }
    socket.emit 'chat msg', message: personal_chat_msg

    socket.on 'login', (data) ->
        users[data.fb_id] =
          socket: socket
          name: data.name
        socket_to_user[socket_id] = data.fb_id
        if active_users().length > 1 && !round_in_progress
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
            socket_broadcast_msg socket, 'guess', ok: true
    socket.on 'disconnect', ->
        delete users[socket_to_user[socket_id]]
        delete socket_to_user[socket_id]


start_round = () ->
    current_word = words[Math.floor(Math.random() * words.length)]
    current_drawer = rand_user()
    drawer_socket = users[current_drawer].socket
    round_in_progress = true
    drawer_socket.broadcast.emit 'round start', { drawer_id: current_drawer }
    drawer_socket.emit 'round start', { drawer_id: current_drawer, word: current_word }
    end_round_timeout = setTimeout end_round, 2*60*1000

end_round = () ->
    round_in_progress = false
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


port = process.env.PORT or 5000
server.listen port
