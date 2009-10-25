import System
import System.IO
import System.Reflection

class ASS:
	[Property(Path)] static private _path = "/home/remi/.ass/assemblies"

def Usage():
	print "ass.exe Usage"

def PrintList():
	print "Available Assemblies:\n"
	if Directory.Exists(ASS.Path):
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
		dll_path     = Path.Combine(path, "${ assemblyName.Name }-${ assemblyName.Version }.dll")
		Directory.CreateDirectory(path)
		File.Copy(args[0], dll_path, true)
		print "Installed ${ assemblyName.Name }-${ assemblyName.Version }"
	else:
		print "Not a file ... not supported yet!"

def Uninstall(args as List):
	path = Path.Combine(ASS.Path, args[0])
	if Directory.Exists(path):
		Directory.Delete(path, true)
		print "Uninstalled all versions of ${ args[0] }"
	else:
		print "${ args[0] } not found"

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
elif command == 'uninstall':
	Uninstall(args)
else:
	print "Unknown command: ${ command }"
