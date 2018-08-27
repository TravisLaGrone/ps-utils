namespace Trintech.PowerShell.Utilities
{
    using System;
    using System.Collections;
    using System.Collections.Generic;

    using Trintech.PowerShell.Utilities;

    public class ArgumentDictionaryCombinationTree : DictionaryCombinationTree<String, String>
    {
        public static ArgumentDictionaryTree From(IDictionary rawTree)
        {
            var tree = new ArgumentDictionaryTree();
            foreach (DictionaryEntry entry in rawTree) {
                var arguments = new ArgumentDictionary(entry.Key);
                var subTree = (null != entry.Value) ? ArgumentDictionaryTree.From(entry.Value) : null;
                tree[arguments] = subTree;
            }
            return tree;
        }

        public ArgumentDictionaryTree() : base() { }

        public ArgumentDictionaryTree(IDictionary<IDictionary<String, String>, U> rawTree) where U : IDictionary<IDictionary<String, String>> : base(rawTree) { }
    }
}