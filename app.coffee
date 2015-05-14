express = require 'express'

app = express()

allowCrossDomain = (req, res, next) ->
  res.header "Access-Control-Allow-Origin", '*' 
  res.header "Access-Control-Allow-Methods", "GET,PUT,POST,DELETE"
  res.header "Access-Control-Allow-Headers", "Content-Type"
  next()

app.use allowCrossDomain
app.use express.static __dirname + '/public'

app.listen 8080
