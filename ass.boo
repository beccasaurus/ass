"""ASS module for .NET Assembly management"""

import System
import System.IO
import System.IO.Path as IoPath
import System.Net
import System.Text
import System.Reflection
import System.Collections.Generic.Dictionary as Dict

import CommandLine from "lib/CommandLine.dll"
import FormUpload  from "lib/FormUpload.dll"

class ASS:
"""The primary class and namespace for the ASS .NET assembly management tool"""
	[Property(Path)] static private _path = "/home/remi/.ass/assemblies"

	# Static helper methods and properties

	static Packages as (Package):
		get:
			if Directory.Exists(ASS.Path):
				return [ Package(dir) for dir in Directory.GetDirectories(ASS.Path) ].ToArray(Package)
			else:
				return array(Package, 0)
				
	static PackageNames as (string):
		get:
			return [ package.Name for package in Packages ].ToArray(string)

	static UserAgent as string:
		get:
			return "ASS .Net Package Manager"

	static DefaultRepository as Repository:
		get:
			return Repository("http://localhost:15924")
			
	static def GetPath() as string:
		return Path
	
	static def GetPath(x as string) as string:
		return IoPath.Combine(Path, x)
	
	static def GetPath(x as string, y as string) as string:
		return IoPath.Combine( GetPath(x), y )
	
	static def GetPath(x as string, y as string, z as string) as string:
		return IoPath.Combine( GetPath(x, y), z )
				
	static def GetPackage(name as string) as Package:
		return List(Packages).Find() do (package as Package):
			return package.Name.ToLower() == name.ToLower()

	static def GetPackageVersion(name, version) as PackageVersion:
		return List( GetPackage(name).Versions ).Find() do (version as PackageVersion):
			return version.Name == version

	static def GetAssembly(name) as Assembly:
		return GetPackage(name).Assembly

	static def Install(name_or_file as string) as PackageVersion:
		if File.Exists(name_or_file):
			return InstallFromFile(name_or_file)
		else:
			return InstallFromWeb(name_or_file)

	static def InstallFromFile(path) as PackageVersion:
		assembly = Assembly.LoadFrom(path)
		name     = assembly.GetName().Name
		version  = assembly.GetName().Version.ToString()
		dll_name = "${ name }-${ version }.dll"

		Directory.CreateDirectory( ASS.GetPath(name, version) )
		File.Copy(path, ASS.GetPath(name, version, dll_name), true)

		return GetPackageVersion(name, version)

	static def InstallFromWeb(name) as PackageVersion:
		temporary_filename = "${ name }.dll"
		ASS.DefaultRepository[name].DownloadTo(temporary_filename)
		InstallFromFile(temporary_filename)

	static def Uninstall(name):
		Directory.Delete( GetPackage(name).Path, true )


	# Util

	class Util:
	"""Generic helper methods not specific to ASS.  These are just generally helpful ... but we use them here."""
	
		static def AssemblyInfo(assembly as Assembly) as Hash:
		"""Returns a Hash of useful information about a given Assembly"""
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

		static def FileBytes(filepath as string) as (byte):
			stream = FileStream(filepath, FileMode.Open, FileAccess.Read)
			bytes  = array(byte, stream.Length)
			stream.Read(bytes, 0, bytes.Length)
			stream.Close()
			return bytes

	# Package

	class Package:
	"""Represents a .NET assembly and (unique name) and its versions (can have many versions)."""
		[Property(Path)] _path as string

		def constructor(path as string):
			Path = path

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

	# PackageVersion

	class PackageVersion:
	"""Represents a particular version of a Package.  The actual assemblies are associated with a particular version."""
		[Property(Path)]    _path    as string
		[Property(Package)] _package as Package

		def constructor(package as Package, path as string):
			Package = package
			Path    = path

		Name as string:
			get:
				return IoPath.GetFileName(Path)

		AssemblyPath as string:
			get:
				return Directory.GetFiles(Path, "*.dll")[0]

		Assembly as System.Reflection.Assembly:
			get:
				return Assembly.LoadFrom(AssemblyPath)

	# Repository

	[System.Reflection.DefaultMember("Indexer")]
	class Repository:
	"""Represents a remote ASS repository of assemblies that responds to a standard RESTful API"""
		[Property(URL)] _url as string

		def constructor(url as string):
			URL = url

		Indexer(name as string):
			get:
				return Repository.Package(self, name)

		def Path(relative_path as string) as string:
			without_slash = /\/(.*)/.Match(relative_path).Groups[1].Value
			return IoPath.Combine(URL, without_slash)

		def GET(relative_path as string) as string:
			print "Requesting ${ Path(relative_path) }"
			return UTF8Encoding().GetString(WebClient().DownloadData( Path(relative_path) ))

		def Search(query):
			print "Searching for ${ query } on ${ URL }"
			return GET("/?q=${ query }")

		def Push(filepath):
			params = Dict[of string, object]()
			for info in ASS.Util.AssemblyInfo(Assembly.LoadFrom(filepath)):
				params[info.Key] = info.Value

			bytes = ASS.Util.FileBytes(filepath)
			params.Add("file", FormUpload.FileParameter(bytes, IoPath.GetFileName(filepath), "plain/text"))

			# do a POST to / with a User-Agent and params
			print Path("/")
			FormUpload.MultipartFormDataPost(Path("/"), ASS.UserAgent, params)

		# Package

		class Package:
		"""Represents a Package on a remote server which we can access via web services"""
			[Property(Name)]       _name as string
			[Property(Repository)] _repo as Repository

			def constructor(repo as Repository, name as string):
				Repository = repo
				Name       = name

			DownloadPath as string:
				get:
					return Repository.Path("/${ Name }.dll")

			def DownloadTo(local_path as string):
				using writer = BinaryWriter(File.Open(local_path, FileMode.Create)):
					writer.Write( WebClient().DownloadData(DownloadPath) )

	# CLI

	class CLI:
	"""Command line interface for ass.exe"""
		[Property(Command)]      _command   as string   # ass.exe [install] foo --source http://foo.com
		[Property(Arguments)]    _arguments as (string) # ass.exe install [foo] --source http://foo.com
		[Property(Options)]      _options   as Hash     # ass.exe install foo [--source http://foo.com]

		def constructor(argv as (string)):
			parser    = Arguments(argv)
			Options   = parser.Parameters
			Arguments = parser.Arguments
			Command   = (Arguments[0] if Arguments.Length > 0 else null)

		Repository as ASS.Repository:
			get:
				option = GetOption('s', 'source')
				return (ASS.DefaultRepository if option == null else Repository(option))

		def GetOption(short_version, long_version) as string:
			option = Options[short_version]
			option = Options[long_version] if option == null
			return option as string

		def Run():
			if Command == null:
				Usage()
				return

			var = (Arguments[1] if Arguments.Length > 1 else null)

			if Command == 'help':
				Usage()
			elif Command == 'list':
				PrintList()
			elif Command == 'search':
				Search(var)
			elif Command == 'install':
				Install(var)
			elif Command == 'push':
				Push(var)
			elif Command == 'uninstall':
				Uninstall(var)
			elif Command == 'show':
				Show(var)
			else:
				print "Unknown Command: ${ Command }"


		def Usage():
			print "ASS Usage ..."

		def PrintList():
			print "Available Assemblies:\n"
			for package in ASS.Packages:
				print "${ package.Name } (${ List(package.Versions).Join(',') })"

		def Install(file_or_name as string):
			packageVersion = ASS.Install(file_or_name)
			print "Installed #{ packageVersion.Package.Name } #{ packageVersion.Name }"

		def Push(filepath):
			Repository.Push(filepath)

		def Search(query):
			print "Search Results:\n" + Repository.Search(query)

		def Uninstall(name as string):
			ASS.Uninstall(name)
			print "Uninstalled all versions of ${ name }"

		def Show(name as string):
			PrintOutAssemblyInfo(ASS.GetAssembly(name))

		def PrintOutAssemblyInfo(assembly as Assembly):
			for info in ASS.Util.AssemblyInfo(assembly):
				print "${ info.Key }: ${ info.Value }"

# the "main" method

ASS.CLI(argv).Run()

[assembly: AssemblyTitle('ASS')]
[assembly: AssemblyDescription('.NET Assembly Management')]
