$(function() {
    var socket = io.connect(document.location.host),
        stage = new Kinetic.Stage({
            container: "drawing-stage",
            width: 700,
            height: 400,
            listening: true
        }),
        layer = new Kinetic.Layer(),
        drawing = false,
        client_id,
        my_line_id = 0,
        current_line_id,
        lines = {};

    stage.add(layer);

    function create_line(data) {
        var id = data.id, points = data.points,
            res;
        if (id in lines) {
            return;
        }
        res = lines[id] = {
            line: null,
            points: points
        };
        draw_line(res);
        return res;
    }

    function draw_line(line_data) {
        if (line_data.line) {
            line_data.line.remove();
        }
        line_data.line = new Kinetic.Line({
            points: line_data.points,
            stroke: "red",
            strokeWidth: 15,
            lineCap: "round",
            lineJoin: "round"
        });
        layer.add(line_data.line);
        layer.draw();
    }

    function update_line(data) {
        var id = data.id, points = data.points,
            line_data = lines[id];
        if (!line_data) {
            line_data = create_line(id, points);
        }
        line_data.points = points;
        draw_line(line_data);
    }

    function end_line(data) {
        var id = data.id;
        delete lines[id];
    }

    $('#drawing-stage .kineticjs-content').on({
        'mousedown touchstart': function (evt) {
            drawing = true;
            my_line_id += 1;
            current_line_id = client_id + ':' + my_line_id;
            var coords = stage.getUserPosition(evt),
                points = [coords.x, coords.y],
                data = {id: current_line_id, points: points};
            create_line(data);
            socket.emit('line create', data);
        },
        'mousemove touchmove': function (evt) {
            if (!drawing) {
                return;
            }
            var coords = stage.getUserPosition(evt),
                points = lines[current_line_id].points,
                data;
            points.push(coords.x);
            points.push(coords.y);
            data = { id: current_line_id, points: points };
            update_line(data);
            socket.emit('line update', data);
        },
        'mouseup touchend mouseout': function () {
            var data = { id: current_line_id };
            drawing = false;
            end_line(data);
            socket.emit('line end', data);
            current_line_id = null;
        }
    });

    socket.on('login info', function(data) {
       client_id = data.id;
    });

    socket.on('line create', function(data) {
        create_line(data);
    });
    socket.on('line update', function(data) {
        update_line(data);
    });
    socket.on('line end', function(data) {
        end_line(data);
    });

});