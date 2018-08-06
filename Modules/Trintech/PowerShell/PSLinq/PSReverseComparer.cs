namespace Trintech.PowerShell.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Management.Automation;

    public class PSReverseComparer : IComparer<object>
    {
        private Func<object,object,int> ComparisonFunction;

        public PSReverseComparer(ScriptBlock comparisonScript)
        {
            this.ComparisonFunction = (x, y) => {
                return comparisonScript.Invoke(null, x, y);
            };
        }

        public override int Compare(object x, object y)
        {
            return ComparisonFunction(y, x);
        }
    }
}