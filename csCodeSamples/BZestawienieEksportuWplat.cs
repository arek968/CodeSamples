using System;
using POSTDATA.ePoczta.TypeDef;
using POSTDATA.ePoczta.DataAccess;
using POSTDATA.ePoczta.BusinessRules.Internal.Reports;
using POSTDATA.eCommon.Results.Reports;
using POSTDATA.ePoczta.Results.Reports;

namespace POSTDATA.ePoczta.BusinessRules.Administracja.Reports
{
	public sealed class BZestawienieEksportuWplat : BReportBase
	{
		public TTypOperacji[] DajKolTypOperacji()
		{
			return Port.TypOperacji.DajKolTypOperacjiMOW();
		}

		public CReport DajWydruk(RZestawienieEksportuWplat par)
		{
			return new ZZestawienieEksportuWplat(new Guid("00000000-0000-0000-0000-000000000322")).PrepareReport(par);
		}
	}
}
