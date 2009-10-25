import System
import System.IO
import System.Reflection

class ASS:
	[Property(Path)] static private _path = "/home/remi/.ass/assemblies"

def Usage():
	print "ass.exe Usage"

def PrintList():
	print "Available Assemblies:\n"
	availableAssemblyNames = Directory.GetDirectories(ASS.Path)
	for name in availableAssemblyNames:
		print Path.GetFileName(name)
		for version in Directory.GetDirectories(name):
			print '  ' + Path.GetFileName(version)

def Install(args as List):
	if File.Exists(args[0]):
		assemblyName = Assembly.LoadFrom(args[0]).GetName()
		path         = Path.Combine(assemblyName.Name, assemblyName.Version.ToString())
		path         = Path.Combine(ASS.Path, path)
		Directory.CreateDirectory(path)

		dll_path = Path.Combine(path, "${ assemblyName.Name }-${ assemblyName.Version }.dll")
		File.Copy(args[0], dll_path, true)
	else:
		print "Not a file ... not supported yet!"

# Option Parsing
args = List(argv)

if args.Count == 0:
	Usage()
	return

command = (args[0] as string).ToLower()
args.RemoveAt(0)

if command == 'help':
	Usage()

elif command == 'list':
	PrintList()

elif command == 'install':
	Install(args)

else:
	print "Unknown command: ${ command }"
