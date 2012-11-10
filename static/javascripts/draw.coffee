#global Kinetic
$cr = window.$cr = window.$cr or {}
socket = $cr.socket

stage = new Kinetic.Stage
    container: "drawing-stage"
    width: 643
    height: 500
    listening: true

layer = new Kinetic.Layer()
drawing = false
client_id = null
my_line_id = 0
current_line_id = null
lines = {}
stage.add(layer)

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


add_chat_msg = (data) ->
  $(".chat-log").append("<div>" + data.message + "</div>")


$('#drawing-stage .kineticjs-content').on
    'mousedown touchstart': (evt) ->
        drawing = true
        my_line_id += 1
        current_line_id = client_id + ':' + my_line_id
        coords = stage.getUserPosition(evt)
        points = [coords.x, coords.y]
        data = {id: current_line_id, points: points}
        create_line(data)
        socket.emit('line create', data)
    'mousemove touchmove': (evt) ->
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
        data = { id: current_line_id }
        drawing = false
        end_line(data)
        socket.emit('line end', data)
        current_line_id = null

socket.on 'login info', (data) ->
  client_id = data.id
  for id of data.round_lines
      draw_line data.round_lines[id]
  if data.round_chat_messages.length
      for msg in data.round_chat_messages
          add_chat_msg msg

socket.on 'line create', (data) ->
  create_line(data)

socket.on 'line update', (data) ->
  update_line(data)

socket.on 'line end', (data) ->
  end_line(data)

socket.on 'chat msg', (data) ->
  add_chat_msg(data)

$('#chat_input').on 'keydown', (evt) ->
  if evt.which == 13
      input = $('#chat_input')
      evt.preventDefault()
      socket.emit('chat msg', input.val())
      input.val('')
