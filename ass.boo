"""ASS module for .NET Assembly management"""

import System
import System.IO
import System.Reflection

class ASS:
"""The primary class and namespace for the ASS .NET assembly management tool"""

	[Property(Path)] static private _path = "/home/remi/.ass/assemblies"

	static def GetAssembly(name) as Assembly:
		path = System.IO.Path.Combine(ASS.Path, name)
		if Directory.Exists(path):
			firstVersionDir = Directory.GetDirectories(path)[0]
			firstFileInDir  = Directory.GetFiles(firstVersionDir)[0]
			return Assembly.LoadFrom(firstFileInDir)

	class CLI:
	"""Command line interface for ass.exe"""

		[Property(ARGS)] _args as List

		def constructor(argv as (string)):
			ARGS = List(argv)

		def Run():
			args = ARGS

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
			elif command == 'show':
				Show(args)
			else:
				print "Unknown command: ${ command }"


		def Usage():
			print "ass.exe Usage"

		def PrintList():
			print "Available Assemblies:\n"
			if Directory.Exists(ASS.Path):
				availableAssemblyNames = Directory.GetDirectories(ASS.Path)
				for name in availableAssemblyNames:
					print System.IO.Path.GetFileName(name)
					for version in Directory.GetDirectories(name):
						print '  ' + System.IO.Path.GetFileName(version)

		def Install(args as List):
			if File.Exists(args[0]):
				assemblyName = Assembly.LoadFrom(args[0]).GetName()
				path         = System.IO.Path.Combine(assemblyName.Name, assemblyName.Version.ToString())
				path         = System.IO.Path.Combine(ASS.Path, path)
				dll_path     = System.IO.Path.Combine(path, "${ assemblyName.Name }-${ assemblyName.Version }.dll")
				Directory.CreateDirectory(path)
				File.Copy(args[0], dll_path, true)
				print "Installed ${ assemblyName.Name }-${ assemblyName.Version }"
			else:
				print "Not a file ... not supported yet!"

		def Uninstall(args as List):
			path = System.IO.Path.Combine(ASS.Path, args[0])
			if Directory.Exists(path):
				Directory.Delete(path, true)
				print "Uninstalled all versions of ${ args[0] }"
			else:
				print "${ args[0] } not found"

		def Show(args as List):
			path = System.IO.Path.Combine(ASS.Path, args[0])
			if Directory.Exists(path):
				PrintOutAssemblyInfo(ASS.GetAssembly(args[0]))
			else:
				print "${ args[0] } not found"

		def PrintOutAssemblyInfo(assembly as Assembly):
			print "FullName: ${ assembly.FullName }"	
			print "Name: ${ assembly.GetName().Name }"	
			print "Version: ${ assembly.GetName().Version.ToString() }\n"

			for attr in assembly.GetCustomAttributes(true):
				type  = attr.GetType()
				match = /Assembly(\w+)Attribute/.Match(type.Name)
				if match.Success:
					prop = type.GetProperty(match.Groups[1].Value)
					if prop != null:
						print prop.Name + ': ' + prop.GetValue(attr, null)

ASS.CLI(argv).Run()

[assembly: AssemblyTitle('ASS')]
[assembly: AssemblyDescription('.NET Assembly Management')]
