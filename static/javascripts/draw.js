$(function() {
    var stage = new Kinetic.Stage({
            container: "drawing-stage",
            width: 700,
            height: 400,
            listening: true
        }),
        layer = new Kinetic.Layer(),
        currentLinePoints,
        currentLine,
        drawing = false;
    stage.add(layer);

    $('#drawing-stage .kineticjs-content').on({
        'mousedown touchstart': function (evt) {
            drawing = true;
            var coords = stage.getUserPosition(evt);
            currentLinePoints = [coords.x, coords.y];
        },
        'mousemove touchmove': function (evt) {
            if (!drawing) {
                return;
            }
            var coords = stage.getUserPosition(evt);
            currentLinePoints.push(coords.x, coords.y);
            if (currentLine) {
                currentLine.remove();
            }
            currentLine = new Kinetic.Line({
                points: currentLinePoints,
                stroke: "red",
                strokeWidth: 15,
                lineCap: "round",
                lineJoin: "round"
            });
            layer.add(currentLine);
            layer.draw();
        },
        'mouseup touchend mouseout': function () {
            drawing = false;
            currentLine = null;
            currentLinePoints = null;
        }
    });
});