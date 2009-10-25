namespace Animals

import System.Reflection

class Dog:
	[Property(Name)] _name as string

	def constructor(name):
		Name = name

	def Bark():
		print "Woof!  My name is ${ Name }"

[assembly: AssemblyTitle('Animals')]
[assembly: AssemblyDescription('An assembly with dogs and stuff')]
