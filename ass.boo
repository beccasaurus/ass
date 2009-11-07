"""ASS module for .NET Assembly management"""

import System
import System.IO
import System.IO.Path as IoPath
import System.Net
import System.Text
import System.Reflection
import System.Collections.Generic.Dictionary as Dict
import FormUpload from "lib/FormUpload.dll"

class ASS:
"""The primary class and namespace for the ASS .NET assembly management tool"""

	[Property(Path)] static private _path = "/home/remi/.ass/assemblies"

	static Packages as (Package):
		get:
			return [ Package(dir) for dir in Directory.GetDirectories(ASS.Path) ].ToArray(Package)
				

	static PackageNames as (string):
		get:
			return [ package.Name for package in Packages ].ToArray(string)
				
	static def GetPackage(name as string) as Package:
		return List(Packages).Find() do (package as Package):
			return package.Name.ToLower() == name.ToLower()

	static def GetPackageVersion(name, version) as Package:
		return List( GetPackage(name).Versions ).Find() do (version as PackageVersion):
			return version.Name == version

	static def GetAssembly(name) as Assembly:
		return GetPackage(name).Assembly

	class Package:
	"""Represents a .NET assembly and (unique name) and its versions (can have many versions)."""
		[Property(Path)] _path as string

		Name as string:
			get:
				return IoPath.GetFileName(Path)

		VersionNames as (string):
			get:
				return [ version.Name for version in Versions ].ToArray(string)

		Versions as (PackageVersion):
			get:
				return [ PackageVersion(self, dir) for dir in Directory.GetDirectories(Path) ].ToArray(PackageVersion)

		MostRecentVersion as PackageVersion:
			get:
				return Versions[0]

		Assembly as System.Reflection.Assembly:
			get:
				return MostRecentVersion.Assembly

		def constructor(path as string):
			Path = path

	class PackageVersion:
	"""Represents a particular version of a Package.  The actual assemblies are associated with a particular version."""
		[Property(Path)]    _path    as string
		[Property(Package)] _package as Package

		Name as string:
			get:
				return IoPath.GetFileName(Path)

		AssemblyPath as string:
			get:
				return Directory.GetFiles(Path, "*.dll")[0]

		Assembly as System.Reflection.Assembly:
			get:
				return Assembly.LoadFrom(AssemblyPath)
				

		def constructor(package as Package, path as string):
			Package = package
			Path    = path

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
			elif command == 'search':
				Search(args[0])
			elif command == 'install':
				Install(args)
			elif command == 'push':
				Push(args[0])
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
			for package in ASS.Packages:
				print "${ package.Name } (${ List(package.Versions).Join(',') })"

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
				server    = "http://localhost:15924/" # make this dynamic
				url       = "${ server }/${ args[0] }.dll"
				dll_bytes = WebClient().DownloadData(url)
				
				using writer = BinaryWriter(File.Open("${ args[0] }.dll", FileMode.Create)):
					writer.Write(dll_bytes)

				assemblyName = Assembly.LoadFrom("${ args[0] }.dll").GetName()
				path         = System.IO.Path.Combine(assemblyName.Name, assemblyName.Version.ToString())
				path         = System.IO.Path.Combine(ASS.Path, path)
				dll_path     = System.IO.Path.Combine(path, "${ assemblyName.Name }-${ assemblyName.Version }.dll")
				Directory.CreateDirectory(path)
				File.Copy("${ args[0] }.dll", dll_path, true)
				print "Installed ${ assemblyName.Name }-${ assemblyName.Version }"

		def Push(filepath):
			server = "http://localhost:15924/" # make this dynamic
			if File.Exists(filepath):
				# get bytes for file
				stream = FileStream(filepath, FileMode.Open, FileAccess.Read)
				bytes  = array(byte, stream.Length)
				stream.Read(bytes, 0, bytes.Length)
				stream.Close()

				# setup POST params
				params = Dict[of string, object]()
				for info in AssemblyInfo(Assembly.LoadFrom(filepath)):
					params[info.Key] = info.Value
				params.Add("file", FormUpload.FileParameter(bytes, filepath, "plain/text"))

				# do the POST
				response = FormUpload.MultipartFormDataPost(server, "ASS .Net Package Manager", params)

			else:
				print "Not a file ... not supported yet!"

		def Search(query):
			server   = "http://localhost:15924/" # make this dynamic
			url      = "${ server }?q=${ query }"
			response = UTF8Encoding().GetString(WebClient().DownloadData(url))
			print "Search Results:\n"
			print response

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

		def AssemblyInfo(assembly as Assembly) as Hash:
			info = {
				'FullName': assembly.FullName,
				'Name':     assembly.GetName().Name,
				'Version':  assembly.GetName().Version.ToString()
			}
			for attr in assembly.GetCustomAttributes(true):
				type  = attr.GetType()
				match = /Assembly(\w+)Attribute/.Match(type.Name)
				if match.Success:
					prop = type.GetProperty(match.Groups[1].Value)
					if prop != null:
						info[prop.Name] = prop.GetValue(attr, null)
			return info

		def PrintOutAssemblyInfo(assembly as Assembly):
			for info in AssemblyInfo(assembly):
				print "${ info.Key }: ${ info.Value }"

ASS.CLI(argv).Run()

[assembly: AssemblyTitle('ASS')]
[assembly: AssemblyDescription('.NET Assembly Management')]
