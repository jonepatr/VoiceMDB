express = require("express")
app = express()
fs = require("fs")
exec = require('child_process').exec
request = require('request')
watch = require('watch')
port = process.env.PORT or 1235
dir = "/Applications/Voxeo/Prophecy/webapps/www/MRCP/Utterances/"
tomatoes = require('tomatoes')
movies = tomatoes('bkmrmkfhr3fpdwn3tqn59k4b')

app.configure ->
  app.use express.bodyParser()
  app.use app.router


String::replaceAll = (sfind, sreplace) ->
  str = this
  str = str.replace(sfind, sreplace)  while str.indexOf(sfind) > -1
  str
  

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
  if params.type is "movie"
    movies.search params.what.replaceAll("+", " "), (err, results) ->
      console.log(err, results[0])
      #" by " + results[0].abridged_directors
      req._voicemdb = results[0].title + " from " + results[0].year + " with a rating of " + results[0]["ratings"].critics_score
      next()
  else
    
  
    
    # regex = /(<([^>]+)>)/g
#     result = JSON.parse(body)["title_popular"][0]["description"].replace(regex, "")
#     newRes = result.split(",")
#     req._voicemdb = "Found " + JSON.parse(body)["title_popular"][0]["title"] + " from " + newRes[0] + " by " + newRes[1].trim()
# else
 #      t = JSON.parse(body)["name_popular"][0]["description"].split(",")
 #      req._voicemdb = JSON.parse(body)["name_popular"][0]["name"] + " is an " + t[0]
    
#      , 1
), (req, res, next) ->
  try
    res.send req._voicemdb    
    


app.all "/current", ((req, res, next) ->  
  movies.getList 'movies', 'in_theaters', (err, result) ->
    console.log(result)
    req._voicemdb = result.movies.sort((a, b) -> parseInt(b["ratings"].critics_score) - parseInt(a["ratings"].critics_score) )[0..5].map((a) -> a.title + " from " + a.year + " with a rating of " + a["ratings"].critics_score)
    next()
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
    

    
    