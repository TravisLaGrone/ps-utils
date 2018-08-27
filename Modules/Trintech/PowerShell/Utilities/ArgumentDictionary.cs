namespace Trintech.PowerShell.Utilities
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Text;

    public class ArgumentDictionary : Dictionary<String, String>
    {
        public static const String NEW_ARGUMENT_OPERATOR = "-";
        public static const String ARGUMENT_VALUE_ASSIGNMENT_OPERATOR = ":";
        public static const String NULL_VALUE_REPRESENTATION = "$null";

        public static ArgumentDictionary From(IDictionary rawDictionary)
        {
            ArgumentDictionary argumentDictionary = new ArgumentDictionary();
            foreach (DictionaryEntry entry in rawDictionary) {
                String key = entry.Key.ToString();
                String value = entry.Value?.ToString() ?? NULL_VALUE_REPRESENTATION;
                argumentDictionary[key] = value;
            }
            return argumentDictionary;
        }

        public ArgumentDictionary() : base() { }

        public ArgumentDictionary(IDictionary<String, String> rawDictionary) : base(rawDictionary) { }

        public IList<String> ToArgumentList()
        {
            IList<String> argumentList = new List<String>(this.Count);
            foreach (KeyValuePair<String, String> entry in this) {
                String name = NEW_ARGUMENT_OPERATOR + entry.Key + ARGUMENT_VALUE_ASSIGNMENT_OPERATOR;
                String value = entry.Value;
                argumentList.Add(name);
                argumentList.Add(value);
            }
            return argumentList;
        }
    }
}