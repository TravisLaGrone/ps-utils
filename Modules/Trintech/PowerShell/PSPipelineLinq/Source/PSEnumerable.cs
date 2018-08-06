namespace Trintech.PowerShell.Linq
{
	using System.Collections;
	using System.Collections.Generic;

	using Trintech.PowerShell.Linq;

	public class PSEnumerable : IEnumerable<object>
	{
		private IEnumerator<object> Enumerator;

		public PSEnumerable(IEnumerator enumerator)
		{
			this.Enumerator = new PSEnumerator(enumerator);
		}

		public IEnumerator<object> GetEnumerator()
		{
			return this.Enumerator;
		}
	}
}
