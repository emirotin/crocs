#global Kinetic
$cr = window.$cr = window.$cr or {}
socket = $cr.socket

$message = $('.notification-area .alert')
message = (html) ->
  $message.html html

stage = new Kinetic.Stage
    container: "drawing-stage"
    width: 643
    height: 500
    listening: true

layer = new Kinetic.Layer()
drawing = false
is_drawer = false
current_word = null
my_line_id = 0
current_line_id = null
lines = {}

create_layer = ->
  if layer
    layer.remove()
  layer = new Kinetic.Layer()
  stage.add(layer)

create_layer()

create_line = (data) ->
    id = data.id
    points = data.points
    if id in lines
        return
    res = lines[id] =
        line: null
        points: points
    draw_line(res)
    return res

draw_line = (line_data) ->
    if line_data.line
        line_data.line.remove()

    if line_data.points.length > 2
        line_data.line = new Kinetic.Line
            points: line_data.points
            stroke: "red"
            strokeWidth: 15
            lineCap: "round"
            lineJoin: "round"
    else
        line_data.line = new Kinetic.Circle
            x: line_data.points[0]
            y: line_data.points[1]
            radius: 15 / 2
            fill: "red"
            strokeWidth: 0
    layer.add(line_data.line)
    layer.draw()

update_line = (data) ->
    id = data.id
    points = data.points
    line_data = lines[id]
    if not line_data
        line_data = create_line(id, points)
    line_data.points = points
    draw_line(line_data)

end_line = (data) ->
    id = data.id
    delete lines[id]


BOT_ID = 'guardante'
BOT_NAME = 'Crockets'

add_chat_msg = (data) ->
  $(".chat-log").append($cr.tmpl('chat', data))


$('#drawing-stage .kineticjs-content').on
    'mousedown touchstart': (evt) ->
        if not is_drawer then return
        drawing = true
        my_line_id += 1
        current_line_id = $cr.user_id + ':' + my_line_id
        coords = stage.getUserPosition(evt)
        points = [coords.x, coords.y]
        data = {id: current_line_id, points: points}
        create_line(data)
        socket.emit('line create', data)
    'mousemove touchmove': (evt) ->
        if not is_drawer then return
        if not drawing
            return
        coords = stage.getUserPosition(evt)
        points = lines[current_line_id].points
        points.push(coords.x)
        points.push(coords.y)
        data = { id: current_line_id, points: points }
        update_line(data)
        socket.emit('line update', data)
    'mouseup touchend mouseout': () ->
        if not is_drawer then return
        data = { id: current_line_id }
        drawing = false
        end_line(data)
        socket.emit('line end', data)
        current_line_id = null

socket.on 'connect info', (data) ->
    for id of data.round_lines
        draw_line data.round_lines[id]
    if data.round_chat_messages.length
        for msg in data.round_chat_messages
            add_chat_msg msg


alert_is_drawer = (word) -> message "You should draw: <strong class='the-word'>#{word}</strong>"

socket.on 'is drawer', (data) ->
    is_drawer = true
    current_word = if is_drawer then data.word else null
    alert_is_drawer current_word

socket.on 'line create', (data) ->
    create_line(data)

socket.on 'line update', (data) ->
    update_line(data)

socket.on 'line end', (data) ->
    end_line(data)

socket.on 'chat msg', (data) ->
    add_chat_msg(data)

socket.on 'round start', (data) ->
    is_drawer = $cr.user_id == data.drawer_id
    current_word = if is_drawer then data.word else null
    create_layer()
    lines = {}
    if is_drawer
      alert_is_drawer current_word
    else
      message "The new round starts!"

$('#chat_input').on 'keydown', (evt) ->
  if evt.which == 13
      evt.preventDefault()
      input = $('#chat_input')
      val = input.val()
      if not val
          return
      socket.emit('chat msg', {message: val})
      input.val('')

socket.on 'guess ok', (data) ->
  message "The word was #{data.word}. Good guess, #{data.winner}!"

socket.on 'online', (data) ->
    if $('.onliners').find("onliner-#{data.fb_id}").length
        $('.onliners').append($cr.tmpl('onliner', data))

socket.on 'offline', (data) ->
    $('.onliners').find("onliner-#{data.fb_id}").fadeOut()