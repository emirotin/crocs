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

BOT_ID = 'guardante'
BOT_NAME = 'Crockets'

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
    res.render 'index', { online_users: users }

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

    socket.emit 'connect info', { round_lines: round_lines, round_chat_messages: round_chat_messages }

    socket.on 'login', (data) ->
        users[data.fb_id] =
          socket: socket
          name: data.name
          fb_id: data.fb_id
        socket_to_user[socket_id] = data.fb_id
        if data.fb_id == current_drawer
            socket.emit 'is drawer', word: current_word
        io.sockets.emit 'online', data

    socket.on 'line create', (data) ->
        socket_broadcast_line socket, 'line create', data
    socket.on 'line update', (data) ->
        socket_broadcast_line socket, 'line update', data
    socket.on 'line end', (data) ->
        socket_broadcast_line socket, 'line end', data
    socket.on 'chat msg', (data) ->
        clear = data.message.replace /[^0-9a-zA-Zа-яА-ЯёЁ]+/, ' '
        guess = clear.toLowerCase().split(' ').indexOf(current_word) != -1
        socket_id = socket.id
        fb_id = socket_to_user[socket_id]
        data.fb_id = fb_id
        user = users[fb_id]
        data.name = user.name
        socket_broadcast_msg socket, 'chat msg', data
        if guess
            end_round(true, user.name)
    socket.on 'disconnect', ->
        fb_id = socket_to_user[socket_id]
        delete users[fb_id]
        delete socket_to_user[socket_id]
        io.sockets.emit 'offline', fb_id: fb_id


start_round = () ->
    if (active_users().length < 2)
      setTimeout start_round, 1000
      return
    current_word = words[Math.floor(Math.random() * words.length)]
    current_drawer = rand_user()
    drawer_socket = users[current_drawer].socket
    round_in_progress = true
    drawer_socket.broadcast.emit 'round start', { drawer_id: current_drawer }
    drawer_socket.emit 'round start', { drawer_id: current_drawer, word: current_word }
    end_round_timeout = setTimeout end_round, 3*60*1000

end_round = (is_guessed, winner_name) ->
    round_in_progress = false
    round_lines = {}
    round_chat_messages = []
    if end_round_timeout
        clearTimeout end_round_timeout
        end_round_timeout = null
    if is_guessed
        io.sockets.emit 'guess ok', { drawer_id: current_drawer, word: current_word, winner: winner_name }
    setTimeout start_round, 1000

socket_broadcast_line = (socket, command, data) ->
    if data.points
        round_lines[data.id] = data
    socket.broadcast.emit command, data

socket_broadcast_msg = (socket, command, data, dont_record_chat_data) ->
    if !dont_record_chat_data then round_chat_messages.push data
    socket.broadcast.emit command, data
    socket.emit command, data

record_chat_msg = (msg) ->
    round_chat_messages.push message: msg


port = process.env.PORT or 5000
server.listen port

start_round()
