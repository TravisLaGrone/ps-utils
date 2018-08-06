namespace Trintech.PowerShell.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Management.Automation;

    public class PSEqualityComparer : IEqualityComparer<object>
    {
        private Func<object,object,bool> EqualityPredicate;
        private Func<object,int> HashFunction;

        public EqualityComparer(ScriptBlock equalityScript, ScriptBlock hashScript)
        {
            this.EqualityPredicate = (x, y) => {
                return equalityScript.Invoke(null, x, y);
            };
            this.HashFunction = (obj) => {
                return hashScript.Invoke(null, obj);
            };
        }

        public override bool Equals(object x, object y)
        {
            return EqualityPredicate(x, y);
        }

        public override int GetHashCode(object obj)
        {
            return HashFunction(obj);
        }
    }
}