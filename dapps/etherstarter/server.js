// use: web3.setProvider(new web3.providers.HttpSyncProvider('http://localhost:8888/client'));
// eth has to run on 8090:
// eth -j -m 10 -n off --json-rpc-port 8090
// static server based on: https://gist.github.com/ryanflorence/701407

var http = require("http"),
    url = require("url"),
    path = require("path"),
    fs = require("fs"),
    _request = require("request"),
    port = process.argv[2] || 3000

http.createServer(function(request, response) {

  var uri = url.parse(request.url).pathname
    , filename = path.join(process.cwd(), uri)

  if(uri.match(/^\/client/)) {
    var body = '';
    request.on('data', function (data) {
      body += data;
    });
    request.on('end', function () {
      console.log("RPC REQUEST:");
      console.log(body);
      _request( {uri: 'http://localhost:8090', method: "POST", body: body }, function(error, res, body) {
        response.writeHead(200, {"Content-Type": "text/plain"})
        console.log("\nRPC RESPONSE:");
        if(body) {
          console.log(body)
          response.write(body)
        } else {
          console.log("ERROR: is eth running?")
        }
        response.end()
      });
    });

  } else {

    fs.exists(filename, function(exists) {
      if(!exists) {
        response.writeHead(404, {"Content-Type": "text/plain"})
        response.write("404 Not Found\n")
        response.end()
        return
      }

      if (fs.statSync(filename).isDirectory()) filename += '/etherstarter.html'

      fs.readFile(filename, "binary", function(err, file) {
        if(err) {
          response.writeHead(500, {"Content-Type": "text/plain"})
          response.write(err + "\n")
          response.end()
          return
        }

        response.writeHead(200)
        response.write(file, "binary")
        response.end()
      })
    })
  }
}).listen(parseInt(port, 10))

console.log("Static file server running at\n  => http://localhost:" + port + "/\nCTRL + C to shutdown")
