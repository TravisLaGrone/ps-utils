namespace Trintech.PowerShell.Linq
{
    using System.Collections;
    using System.Collections.Generic;

    public class PSEnumerator : IEnumerator<object>
    {
        private IEnumerator Enumerator;

        public PSEnumerator(IEnumerator enumerator)
        {
            this.Enumerator = enumerator;
        }

        public override object Current
        {
            return this.Enumerator.Current;
        }

        public override bool MoveNext()
        {
            return this.Enumerator.MoveNext();
        }

        public override void Reset()
        {
            this.Enumerator.Reset();
        }
    }
}
