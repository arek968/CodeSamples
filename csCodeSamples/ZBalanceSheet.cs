using System;
using System.Data;
using System.Collections;
using System.Configuration;
using POSTDATA.ePoczta.TypeDef;
using POSTDATA.eCommon.TypeDef;
using POSTDATA.ePoczta.DataAccess;
using POSTDATA.eCommon.DataAccess;
using POSTDATA.eCommon.SystemFrameworks;
using POSTDATA.ePoczta.BusinessRules.Internal;
using POSTDATA.eCommon.Controls;
using POSTDATA.ePoczta.Results.Rejestracja;
using POSTDATA.ePoczta.BusinessRules;
using POSTDATA.ePoczta.Results.Reports;
using POSTDATA.eCommon.Results.Reports;

namespace POSTDATA.ePoczta.BusinessRules.Internal.Reports
{
	public abstract class ZBalanceSheet : ZReport
	{
		protected ZBalanceSheet(Guid idTypWydruku) : base(idTypWydruku) {}
		protected ZBalanceSheet(Guid idTypWydruku, int liczbaZnakowWWierszu) : base(idTypWydruku, liczbaZnakowWWierszu) {}
		
		public override void StartPage()
		{
			base.StartPage();
			PreparedReport.Pages[CurrentPage].CzyDrukowac = true;
		}
		
		protected virtual bool CzyLiczbaPozycjiNaStronieOznaczaLiczbeWierszy()
		{
			//W przypadku wartoœci "true" - nie jest wo³ana metoda AdditionalConditionsForFinishPage
			return false;
		}

		public override CReport PrepareReport(params object[] parameterValues)
		{
			base.PrepareReport(parameterValues);			
			ReportDataSet = GetData(parameterValues);
			if(ReportDataSet == null || ReportDataSet.Tables.Count == 0 || ReportDataSet.Tables[0] ==  null) throw new EServerBusinessException(1414);
			UstawKolekcjeUzytkownikow(ReportDataSet);
			System.Data.DataTable tb =	ReportDataSet.Tables[0];
			int i = 1;
			bool bNowaStrona = true;
			DataView dv = tb.DefaultView;
			int LiczbaWierszy = dv.Count;

			for(CurrentRow = 0; CurrentRow < LiczbaWierszy; CurrentRow++)
			{
				System.Data.DataRow Row = dv[CurrentRow].Row;
				
				if(bNowaStrona)
				{
					StartPage();
					PreparedReport.Pages[CurrentPage].CzyDrukowac = false;
					bNowaStrona = false;
				}

				string[] ss = RowToText(Row); // w RowToText mo¿e byæ zrobione zliczanie

				if(CzyDrukowacWiersz(Row))
				{
					PreparedReport.Pages[CurrentPage].CzyDrukowac = true;
					if(ss != null && ss.Length > 0) // Zliczanie wierszy tylko jeœli rekord zmieniany na 1 lub wiêcej wierszy
					{
						if(!CzyLiczbaPozycjiNaStronieOznaczaLiczbeWierszy())
						{
							AddPreparedPage(ss);
					
							bNowaStrona = AdditionalConditionsForFinishPage();
							if (!bNowaStrona) bNowaStrona = (i == TypWydruku.liczbaPozycji) && (TypWydruku.liczbaPozycji > 0) && (TypWydruku.liczbaPozycji < 1000);
							if(bNowaStrona)
							{
								FinishPage();
								i = 0;
							}
							i++;
						}
						else
						{
							foreach(string s in ss)
							{
								if(s == null) continue;
								
								if(bNowaStrona)
								{
									StartPage();
									PreparedReport.Pages[CurrentPage].CzyDrukowac = false;
									bNowaStrona = false;
								}
								
								AddPreparedPage(s);
								
								//bNowaStrona = AdditionalConditionsForFinishPage();
								if (!bNowaStrona) bNowaStrona = (i == TypWydruku.liczbaPozycji) && (TypWydruku.liczbaPozycji > 0) && (TypWydruku.liczbaPozycji < 1000);
								if(bNowaStrona)
								{
									FinishPage();
									i = 0;
								}
								i++;
							}
						}
					}
				}
			}
			if(!bNowaStrona)
			{	
				FinishPage();
			}

			// usuniêcie stron, które nie bêd¹ drukowane
			if(ConfigurationSettings.AppSettings["PrzesylacWydrukowaneArkusze"] != "1")
			{
				PreparedReport.UsunStronyNieDrukowane();
				CurrentPage = PreparedReport.Pages.Length - 1;
				if(CurrentPage < 0) CurrentPage = 0;
			}
			
			// uwaga! podsumowanie raportu dodawane jest do ostatniej drukowanej strony
			if(PreparedReport.Pages.Length > 0)
			{
				PrintLastPageFooter();
			}

			return PreparedReport;
		}
	}
}


