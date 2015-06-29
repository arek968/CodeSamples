using System;
using System.Data;
using POSTDATA.ePoczta.TypeDef;
using POSTDATA.eCommon.TypeDef;
using POSTDATA.ePoczta.DataAccess;
using POSTDATA.ePoczta.BusinessRules.Internal.Reports;
using POSTDATA.ePoczta.Results.Reports;
using POSTDATA.ePoczta.BusinessRules.Administracja.Reports ;
using POSTDATA.eCommon.Results.Reports;

namespace POSTDATA.ePoczta.BusinessRules.Administracja.Reports
{
	public sealed class BDruk220 : BReportBase
	{
		/// <summary>
		/// Metoda zwraca przygotowane dane wydruku dowodu przyjêcia prenumeraty
		/// </summary>
		/// <param name="Parameters"></param>
		/// <returns></returns>
		public CReport DajWydruk(RDruk220 par)
		{			
			if (par.NumerDowodu == "")
			{
				CReport raport = new CReport();
				foreach (int NumerKlienta in par.NumerKlienta)
				{
					DataSet ds = Port.ZamowieniaPrenumeraty.DajKolNumeryZamowienPrenumeratyKlienta(NumerKlienta, AktualnyKontekst.Kontekst.idUrzad, AktualnyKontekst.Kontekst.idDzienUrzedu, AktualnyKontekst.Kontekst.idUzytkownik, AktualnyKontekst.Kontekst.idLokalizacja);
					System.Data.DataTable tb =	ds.Tables[0];
					
					foreach (DataRow Row in ds.Tables[0].Rows)
					{
						string NumerDowoduPrzyjecia = Row["NumerDowoduPrzyjecia"].ToString();
						string NazwaPrenumeratora = Row["NazwaPrenumeratora"].ToString();

						raport.AddRange( new ZDruk220Administracja(new Guid("00000000-0000-0000-0000-000000000227")).PrepareReport(  AktualnyKontekst.Kontekst.idUrzad, NumerDowoduPrzyjecia,  NazwaPrenumeratora).Pages );
						raport.AddRange( new ZDruk220DowodAdministracja(new Guid("00000000-0000-0000-0000-000000000227")).PrepareReport(  AktualnyKontekst.Kontekst.idUrzad, NumerDowoduPrzyjecia,  NazwaPrenumeratora).Pages );
					}
				}
				return raport;
			}
			else 
			{
				CReport raport = new CReport();
				raport.AddRange( new ZDruk220Administracja(new Guid("00000000-0000-0000-0000-000000000227")).PrepareReport(  AktualnyKontekst.Kontekst.idUrzad, par.NumerDowodu,  par.NazwaPrenumeratora).Pages );
				raport.AddRange( new ZDruk220DowodAdministracja(new Guid("00000000-0000-0000-0000-000000000227")).PrepareReport( AktualnyKontekst.Kontekst.idUrzad, par.NumerDowodu,  par.NazwaPrenumeratora).Pages );
				return raport;
			}

			
		}
	}
}
