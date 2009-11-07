namespace CommandLine

import System.Text.RegularExpressions

[System.Reflection.DefaultMember("Indexer")]
class Arguments:
"""For easy command line parsing.  Taken from: http://www.codeproject.com/KB/recipes/command_line.aspx"""

	[Property(Parameters)] _params as Hash
	[Property(Arguments)]  _args   as (string)

	def constructor(argv as (string)):
		params = {}
		args   = List(argv)

		spliter = Regex("""^-{1,2}|^/|=|:""",      RegexOptions.IgnoreCase|RegexOptions.Compiled)
		remover = Regex("""^['""]?(.*?)['""]?$""", RegexOptions.IgnoreCase|RegexOptions.Compiled)

		param = null as string   # the current parameter
		parts = null as (string) # the current parts of the split argument

		for part in argv:
			
			# look for starts of new parameters, eg. -x --x /x ... and look for =foo :foo
			parts = spliter.Split(part, 3)

			# tweet the algorithm to accept http://fooo.com[:80]/whatever as a value
			if parts.Length > 0:
				if parts[0].ToLower().StartsWith("http"):
					parts    = array(string, 1)
					parts[0] = part

			# probably a value, eg. 5
			if parts.Length == 1:
				if param != null:
					if params[param] == null:
						params[param] = remover.Replace(parts[0], "$1")
						args.Remove(part)
					else:
						param = null

			# probably a parameter, eg. -x
			elif parts.Length == 2:
				params[param] = true if param != null and params[param] == null
				param = parts[1]
				args.Remove(part)

			# parameter with value, like -x:5 or -x=5
			elif parts.Length == 3:
				params[param] = true if param != null and params[param] == null
				param = parts[1]
				params[param] = remover.Replace(parts[2], "$1")
				args.Remove(part)
				param = null

		params[param] = true if param != null and params[param] == null
		Parameters = params
		Arguments  = args.ToArray(string)

	Indexer(name as string):
		get:
			return Parameters[name]
