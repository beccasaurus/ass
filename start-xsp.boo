import System.IO
import System.Net
import Mono.WebServer from "Mono.WebServer2.dll"

xspSource = XSPWebSource(IPAddress.Any, 6789)
appServer = ApplicationServer(xspSource)

dir   = Directory.GetCurrentDirectory()
parts = /:/.Split(dir)
dir   = parts[ parts.Length - 1 ]

path = "/:"
path += dir
path += "/custom-http-handler/" 

print "Path: ${ path }"

appServer.AddApplicationsFromCommandLine(path)
appServer.Start(true)

System.Threading.Thread.Sleep(10000)
