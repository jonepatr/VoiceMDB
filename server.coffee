express = require("express")
app = express()
fs = require("fs")
exec = require('child_process').exec
request = require('request')
watch = require('watch')
port = process.env.PORT or 1235
dir = "/Applications/Voxeo/Prophecy/webapps/www/MRCP/Utterances/"

app.configure ->
  app.use express.bodyParser()
  app.use app.router

app.listen port
app.all "/voice", ((req, res, next) ->  
  files = fs.readdirSync(dir).map((v) ->
    name: v
    time: fs.statSync(dir + v).mtime.getTime()
  ).sort((a, b) ->
    b.time - a.time
  ).filter((v) ->
    v.name if v.name[-3...] is "wav"
  )
  console.log(files[0].name)
  exec 'rm ./tmp/flac.flac; touch ./tmp/flac.flac; flac --best -f --sample-rate=8000 --keep-foreign-metadata --output-name=./tmp/flac.flac ' + dir + files[0].name, () ->
    file = fs.readFileSync("./tmp/flac.flac")
    options =
      url: 'http://www.google.com/speech-api/v1/recognize?client=chromium&lang=en-US&maxresults=1'
      body: file
      headers: 
        'Content-Type': 'audio/x-flac; rate=8000'
    request.post options, (error, response, body) ->           
      body = body.split("\n")[0]
      console.log(body) 
      req._voicemdb = JSON.parse(body)["hypotheses"][0].utterance
      next()
#      , 1
), (req, res, next) ->
  try
    res.send req._voicemdb
    

app.all "/search", ((req, res, next) ->  
  
  params = get_params(req.url[7...]);
  console.log(params)
  if params.type is "movie"
    type = "tt"
  else
    type = "nm"
  options =
    dataType: "json"
    #url: 'http://www.imdb.com/xml/find?json=1&q=' + params.what + '&' + type  + '=true'
    url: 'http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=bkmrmkfhr3fpdwn3tqn59k4b&q=' + params.what + '&page_limit=1'
  request.get options, (error, response, body) ->
    #if params.type is "movie"
    console.log(JSON.parse(body))
    req._voicemdb = JSON.parse(body)
    # regex = /(<([^>]+)>)/g
#     result = JSON.parse(body)["title_popular"][0]["description"].replace(regex, "")
#     newRes = result.split(",")
#     req._voicemdb = "Found " + JSON.parse(body)["title_popular"][0]["title"] + " from " + newRes[0] + " by " + newRes[1].trim()
# else
 #      t = JSON.parse(body)["name_popular"][0]["description"].split(",")
 #      req._voicemdb = JSON.parse(body)["name_popular"][0]["name"] + " is an " + t[0]
    next()
#      , 1
), (req, res, next) ->
  try
    res.send req._voicemdb    
    
    
get_params = (search_string) ->
  parse = (params, pairs) ->
    pair = pairs[0]
    parts = pair.split("=")
    key = decodeURIComponent(parts[0])
    value = decodeURIComponent(parts.slice(1).join(""))
    
    # Handle multiple parameters of the same name
    if typeof params[key] is "undefined"
      params[key] = value
    else
      params[key] = [].concat(params[key], value)
    (if pairs.length is 1 then params else parse(params, pairs.slice(1)))

  
  # Get rid of leading ?
  (if search_string.length is 0 then {} else parse({}, search_string.substr(1).split("&")))
    
    
    