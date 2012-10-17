express = require 'express'

path = require 'path'
app = express()

app_root = __dirname
static_path = path.join app_root, 'static'

app.set 'view engine', 'jade'

app
    .use(express.logger())
    .use(express.bodyParser())
    .use(express.methodOverride())
    .use(app.router)
    .use(express.static static_path)
    #.use(connect_assets(src: 'static'))

app.get '/', (req, res) ->
    res.render 'index'

app.listen process.env.PORT or 5000