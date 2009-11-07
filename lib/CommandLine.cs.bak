using System;
using System.Collections;
using System.Collections.Specialized;
using System.Text.RegularExpressions;

namespace CommandLine {

    public class Arguments{

        public StringDictionary Parameters;
	public string[] Args;

        public Arguments(string[] args) {
	    ArrayList originalArgs = new ArrayList(args);

            Parameters = new StringDictionary();
            Regex Spliter = new Regex(@"^-{1,2}|^/|=|:",
                RegexOptions.IgnoreCase|RegexOptions.Compiled);

            Regex Remover = new Regex(@"^['""]?(.*?)['""]?$",
                RegexOptions.IgnoreCase|RegexOptions.Compiled);

            string Parameter = null;
            string[] Parts;

            // Valid parameters forms:
            // {-,/,--}param{ ,=,:}((",')value(",'))
            // Examples: 
            // -param1 value1 --param2 /param3:"Test-:-work" 
            //   /param4=happy -param5 '--=nice=--'
            foreach(string Txt in args)
            {
                // Look for new parameters (-,/ or --) and a
                // possible enclosed value (=,:)
                Parts = Spliter.Split(Txt,3);
		Console.WriteLine("Parts Length: " + Parts.Length.ToString() + " for Text: " + Txt);

                switch(Parts.Length) {

                // Found a value (for the last parameter) found (space separator))
                case 1:
                    if(Parameter != null) {
                        if(!Parameters.ContainsKey(Parameter)) {
                            Parts[0] = Remover.Replace(Parts[0], "$1");
                            Parameters.Add(Parameter, Parts[0]);
			    originalArgs.Remove(Txt);
                        }
                        Parameter=null;
                    }
                    break; // else Error: no parameter waiting for a value (skipped)

                // Found just a parameter, eg. -x
                case 2:
                    // The last parameter is still waiting. With no value, set it to true.
                    if(Parameter != null) {
                        if(!Parameters.ContainsKey(Parameter)) 
                            Parameters.Add(Parameter, "true");
			    originalArgs.Remove(Txt);
                    }
		    originalArgs.Remove(Parts[1]);
                    Parameter=Parts[1];
                    break;

                // Parameter with enclosed value
                case 3:
                    // The last parameter is still waiting. 
                    // With no value, set it to true.
                    if(Parameter != null) {
                        if(!Parameters.ContainsKey(Parameter)) 
                            Parameters.Add(Parameter, "true");
			    originalArgs.Remove(Txt);
                    }

                    Parameter = Parts[1];

                    // Remove possible enclosing characters (",')
                    if(!Parameters.ContainsKey(Parameter)) {
                        Parts[2] = Remover.Replace(Parts[2], "$1");
                        Parameters.Add(Parameter, Parts[2]);
			    originalArgs.Remove(Txt);
                    }

                    Parameter=null;
                    break;
                }
            }
	    // end of for each

            // In case a parameter is still waiting
            if(Parameter != null){
                if(!Parameters.ContainsKey(Parameter)) 
                    Parameters.Add(Parameter, "true");
            }

	    Args = originalArgs.ToArray( typeof(string) ) as string[];
        }

        // Retrieve a parameter value if it exists 
        // (overriding C# indexer property)
        public string this [string Param] {
            get {
                return( Parameters[Param] );
            }
        }

    }
}
