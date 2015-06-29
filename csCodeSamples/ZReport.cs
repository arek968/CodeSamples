using System;
using System.Data;
using System.Collections;
using System.Collections.Specialized;
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
	public abstract class ZReport
	{
		protected bool DrukZageszczony = false;
		private static string FVersion = null;

		private const int lineWidth = 80;
		private readonly int liczbaZnakowWWierszu = lineWidth;
		protected string NazwaWydruku;
		protected string SymbolWydruku;
		
		protected string sep1 = string.Empty;
		protected string sep2 = string.Empty;
		protected string sep3 = string.Empty;


		protected bool AbsoluteBreak = false;
		
		protected CPrintParams PrintParams = new CPrintParams(); //new CRange());
		protected CReport PreparedReport;
		protected int CurrentPage;
		protected int CurrentRow;
		protected DataSet ReportDataSet;

		protected TTypWydruku TypWydruku;
		protected string DayInTXT;
		protected StringCollection calculatedFields;		
		PJednostkaOrganizacyjna PortJednOrg = Port.JednostkaOrganizacyjna;

		protected ZReport(Guid idTypWydruku)
		{
			this.liczbaZnakowWWierszu = lineWidth;
			Inicjuj(idTypWydruku);
		}

		public ZReport(Guid idTypWydruku, int liczbaZnakowWWierszu)
		{
			this.liczbaZnakowWWierszu = liczbaZnakowWWierszu;
			Inicjuj(idTypWydruku);
		}

		protected string Version
		{
			get
			{
				if(FVersion == null)
				{
					FVersion = CurrentVersion.AssemblyInformationalVersion;
				}
				return FVersion;
			}
		}

		protected virtual string DajNazweUrzedu()
		{
			TJednostkaOrganizacyjna Urzad = AktualnyKontekst.Urzad;
			string nazwaUrzad = string.Empty;
			if(Urzad != null)
			{
				nazwaUrzad = Urzad.nazwaSpecified ? Urzad.nazwa : string.Empty;
			}
			if(nazwaUrzad.Length > 45) nazwaUrzad = nazwaUrzad.Substring(0, 45);
			return nazwaUrzad;
		}

		//Domyœlny nag³ówek wydruku
		protected string oh1  = "{0, -51}{1, 29}";
		protected string oh2  = "Urz¹d Pocztowy:   {0, -46}{1, 16}";
		protected string oh2a = "System: e-Poczta";
		protected string oh3  = "Stempel okrêgowy: {0, 4}{1, 58}";
		protected string oh3a = "Wersja: {0,-8}";
		protected string oh4  = "Nazwa rachunku:   {0,-45}{1,10}";
		protected string oh5  = "Numer rachunku:   {0,-45}{1,10}";
		protected string oh6  = "{0,74}";
		protected string oh7  = "{0,74}";
		protected string oh8  = "{0,74}";
		private TRachunekBankowy[] KolRachunekBankowy = null;
		private void Inicjuj(Guid idTypWydruku)
		{
			sep1 = sep1.PadRight(liczbaZnakowWWierszu, '-');
			sep2 = sep2.PadRight(liczbaZnakowWWierszu, '=');
			sep3 = sep3.PadRight(liczbaZnakowWWierszu, '_');
			//PreparedReport = new CReport();
			TKontekst Kontekst = AktualnyKontekst.Kontekst;
			TDzienUrzedu DzienUrzedu = AktualnyKontekst.DzienUrzedu;
			if(DzienUrzedu != null)
			{
				DayInTXT = CData.ToShortDateString(DzienUrzedu.data);
			}
			TJednostkaOrganizacyjna Urzad = AktualnyKontekst.Urzad;
			TJednostkaOrganizacyjna Rup = AktualnyKontekst.RUP;
			TRachunekBankowy RachunekBankowy = null;
			if(KolRachunekBankowy == null)
			{
				KolRachunekBankowy = Port.RachunekBankowy.DajRachunekBankowy(Rup.dn);
			}
			foreach(TRachunekBankowy rb in KolRachunekBankowy)
			{
				if(rb.celeSpecified && (rb.cele.IndexOf("A") >= 0) && !rb.zablokowany)
				{
					RachunekBankowy = rb;
					break;
				}
			}
			if(RachunekBankowy == null) RachunekBankowy = new TRachunekBankowy();

			DateTime d = DateTime.Now;
			string nazwaRup = Rup.nazwaSpecified ? Rup.nazwa : string.Empty;
			if(nazwaRup.Length > 50) nazwaRup = nazwaRup.Substring(0, 50);

			oh1  = string.Format(oh1, nazwaRup, "Wydrukowano: " + CData.ToShortDateString() + " " + d.Hour.ToString().PadLeft(2, '0') + ":" + d.Minute.ToString().PadLeft(2, '0'));
			oh2  = string.Format(oh2, DajNazweUrzedu(), oh2a);
			
			//oh3  = string.Format(oh3, Urzad.symbolKsiegowySpecified ? Urzad.symbolKsiegowy : string.Empty, String.Format(oh3a, "alfa"));

			oh3a = String.Format(oh3a, Version);
			if(Urzad != null)
			{
				oh3  = string.Format(oh3, Urzad.stepelOkregowySpecified ? Urzad.stepelOkregowy : string.Empty, oh3a);
			}
			else
			{
				oh3  = string.Format(oh3, string.Empty, oh3a);
			}
			if(RachunekBankowy != null)
			{
				oh4  = string.Format(oh4, RachunekBankowy.nazwaSpecified ? RachunekBankowy.nazwa : string.Empty, "...........");
				oh5  = string.Format(oh5, RachunekBankowy.numerSpecified ? CNumerRachunku.FormatujNRB(RachunekBankowy.numer)  : string.Empty, ".         .");
			}
			else
			{
				oh4  = string.Format(oh4, string.Empty, "...........");
				oh5  = string.Format(oh5, string.Empty, ".         .");
			}
			
			TypWydruku = new TTypWydruku();
			TypWydruku.nazwa = "WYDRUK...";
			TypWydruku.liczbaPozycji = -1;

			//odczytanie typu wydruku z bazy
			if(Guid.Empty != idTypWydruku)
			{
				TTypWydruku TypWydruku1 = Port.TypWydruku.ReadBusObjId(idTypWydruku);
				if(TypWydruku1 != null)
				{
					TypWydruku.nazwa = TypWydruku1.nazwaSpecified ? TypWydruku1.nazwa : string.Empty;
					TypWydruku.liczbaPozycji = TypWydruku1.liczbaPozycjiSpecified ? TypWydruku1.liczbaPozycji : -1;
					TypWydruku.czyAutomatyczny = TypWydruku1.czyAutomatyczny;
					TypWydruku.czyDoEksportu = TypWydruku1.czyDoEksportu;
					TypWydruku.czyDoKonfiguracji = TypWydruku1.czyDoKonfiguracji;
					TypWydruku.czyDoKonfiguracjiORJ = TypWydruku1.czyDoKonfiguracjiORJ;
					TypWydruku.czyWydrukOddzielny = TypWydruku1.czyWydrukOddzielny;
					TypWydruku.czyZmianaArkuszowania = TypWydruku1.czyZmianaArkuszowania;
					TypWydruku.id = TypWydruku1.id;
					if(TypWydruku1.numerWydrukuSpecified) TypWydruku.numerWydruku = TypWydruku1.numerWydruku;
					if(TypWydruku1.opisSpecified) TypWydruku.opis = TypWydruku1.opis;
					if(TypWydruku1.podtytulSpecified) TypWydruku.podtytul = TypWydruku1.podtytul;
					if(TypWydruku1.rodzajSpecified) TypWydruku.rodzaj = TypWydruku1.rodzaj;
					if(TypWydruku1.symbolSpecified) TypWydruku.symbol = TypWydruku1.symbol;
					TypWydruku.stateInDatabase = TypWydruku1.stateInDatabase;
					if(TypWydruku1.symbolWykazuSpecified) TypWydruku.symbolWykazu = TypWydruku1.symbolWykazu;

					if(AktualnyKontekst.Kontekst.idUrzadSpecified)
					{
						if(TypWydruku1.czyDoKonfiguracji)
						{
							TTypWydrukuUrzad TypWydrukuUrzad = Port.TypWydrukuUrzad.DajTypWydrukuUrzad(AktualnyKontekst.Kontekst.idUrzad, TypWydruku1.id);
							if(TypWydrukuUrzad != null)
							{
								TypWydruku.liczbaPozycji = TypWydrukuUrzad.liczbaPozycji;
							}
						}
					}
					else if(AktualnyKontekst.Kontekst.idRUPSpecified && TypWydruku1.czyDoKonfiguracjiORJ)
					{
						TTypWydrukuORJ TypWydrukuORJ = Port.TypWydrukuORJ.DajTypWydrukuORJ(TypWydruku1.id, AktualnyKontekst.Kontekst.idRUP);
						if(TypWydrukuORJ != null)
						{
							TypWydruku.liczbaPozycji = TypWydrukuORJ.liczbaPozycji;
						}
					}
				}
			}

			NazwaWydruku = TypWydruku.nazwa.ToUpper();
			SymbolWydruku = TypWydruku.symbolSpecified ? TypWydruku.symbol.ToUpper() : string.Empty;
			oh6 = String.Format(oh6, ".   m.p.  .");
			oh7 = String.Format(oh7, ".         .");
			oh8 = String.Format(oh8, "...........");

			ReportDataSet = null;

			//utworzenei kolekcji pól wylicznych
			calculatedFields = new StringCollection();
		}

		protected virtual void PrintOfficeHeader()
		{
			PreparedReport.AddLine(oh1,CurrentPage);
			if(AktualnyKontekst.Kontekst.idUrzadSpecified)
			{
				PreparedReport.AddLine(oh2, CurrentPage);
				PreparedReport.AddLine(oh3, CurrentPage);
				PreparedReport.AddLine(oh4, CurrentPage);
				PreparedReport.AddLine(oh5, CurrentPage);
				PreparedReport.AddLine(oh6, CurrentPage);
				PreparedReport.AddLine(oh7, CurrentPage);
				PreparedReport.AddLine(oh8, CurrentPage);
			}
			else
			{
				PreparedReport.AddLine(oh2a.PadLeft(80), CurrentPage);
				PreparedReport.AddLine(oh3a.PadLeft(80), CurrentPage);
			}
		}

		protected virtual  bool AdditionalConditionsForFinishPage()
		{
			return false;
		}
		
		protected virtual DataSet GetData(params object[] parameterValues)
		{
			DataSet ds = Port.Report.ReadDataSet(this.GetType().Name, parameterValues);
			UstawKolekcjeUzytkownikow(ds);
			return ds;
		}
		
		protected virtual void FinishPage()
		{
			PrintColumnsFooter();
			PrintReportFooter();
		}
		
		protected virtual void PrintColumnsFooter()
		{
		}
		
		protected virtual void PrintColumnsHeader()
		{
		}
		
		protected virtual void PrintLastPageFooter()
		{
			/*
			PreparedReport.AddLine(string.Empty, CurrentPage);
			PreparedReport.AddLine(string.Empty, CurrentPage);
			PreparedReport.AddLine(string.Empty, CurrentPage);
			PreparedReport.AddLine(string.Empty, CurrentPage);
			PreparedReport.AddLine(EKodySterujaceWydruku.StartCondensed+ "Data i godzina wydruku: "+CData.ToShortDateString(DateTime.Now)+"  "+DateTime.Now.Hour.ToString().PadLeft(2,'0')+":"+DateTime.Now.Minute.ToString().PadLeft(2,'0')+EKodySterujaceWydruku.EndCondensed,CurrentPage);
			*/
		}
		
		protected virtual void PrintReportFooter()
		{
		}
		
		protected void PrintReportName(string name)
		{
			PreparedReport.AddLine(string.Empty, CurrentPage);
			PreparedReport.AddLine(name, CurrentPage);
		}

		protected virtual void PrintReportName()
		{
			PrintReportName(String.Format("{0,-10} {1," + NazwaWydruku.Length.ToString()+ "}", SymbolWydruku, NazwaWydruku));
		}

		protected virtual void PrintReportHeader()
		{
			PrintReportName();
			if(DayInTXT != null && DayInTXT.Length > 0)
			{
				PreparedReport.AddLine(string.Empty, CurrentPage);
				PreparedReport.AddLine(String.Format("{0,28}", String.Format("Dzieñ: {0}", DayInTXT)), CurrentPage);
			}
		}

		public virtual void Reset()
		{
		}
		
		public virtual string[] RowToText(DataRow Row)
		{
			return new string[0];
		}
		
		public virtual void StartPage()
		{
			CurrentPage = PreparedReport.AddPage(TypWydruku.id);
			PrintParams.PageTo = CurrentPage;
			//if(PrintParams.DynamicRange) PrintParams.Range.Add(CurrentPage);
			
			PrintOfficeHeader();
			PrintReportHeader();
			SumRowBeforeData();
			PrintColumnsHeader();
		}
		
		// Funkcja zwi¹zane z podsumowaniami cz¹stkowymi
		public virtual void SumRowBeforeData()
		{
		}
		
		protected CPlikEksportImport FExportFile;
				
		public virtual CReport PrepareReport(params object[] parameterValues)
		{
			return PreparedReport = new CReport();
		}
		
		public CReport outerPreparedReport
		{
			get
			{
				return PreparedReport;
			}
		}
		
		protected void AddPreparedPage(string s)
		{
			if(s == null) return;
			if(!DrukZageszczony)
			{
				PreparedReport.AddLine(s, CurrentPage);
			}
			else
			{
				PreparedReport.AddLine(EKodySterujaceWydruku.StartCondensed + s + EKodySterujaceWydruku.EndCondensed, CurrentPage);
			}
		}
		
		protected void AddPreparedPage(string[] lines)
		{
			if(lines == null) return;
			foreach(string s in lines)
			{
				AddPreparedPage(s);
			}
		}
		
		public string getReportAsString(bool onlyNew)
		{
			PrepareReport(onlyNew);
			return PreparedReport.ToString();
		}

		private DataSet PrzetworzonyDataSet = null;

		protected void UstawKolekcjeUzytkownikow(DataSet ds)
		{
			if(ds == null || ds.Tables.Count == 0) return;
			DataTable table0 = ds.Tables[0];
			if(table0 == null) return;
			
			//Zapobiega wielokrotnemu wo³aniu
			if(PrzetworzonyDataSet == ds) return;
			PrzetworzonyDataSet = ds;

			string[] kolNazwKolumnUzytkownikow = DajListeKolumnZIdUzytkownikow();			
			if(kolNazwKolumnUzytkownikow == null || kolNazwKolumnUzytkownikow.Length == 0) return;
			
			foreach(string nazwaKolumny in kolNazwKolumnUzytkownikow)
			{
				if(nazwaKolumny == null || nazwaKolumny.Length == 0) continue;
				if(table0.Columns.Contains(nazwaKolumny))
				{
					if(!table0.Columns.Contains(nazwaKolumny + "_Nazwisko"))
						table0.Columns.Add(nazwaKolumny + "_Nazwisko", typeof(string));
					if(!table0.Columns.Contains(nazwaKolumny + "_Imie"))
						table0.Columns.Add(nazwaKolumny + "_Imie", typeof(string));
					if(!table0.Columns.Contains(nazwaKolumny + "_login"))
						table0.Columns.Add(nazwaKolumny + "_login", typeof(string));
					
					Hashtable HtIdUzytkownik = new Hashtable();

					foreach(System.Data.DataRow Row in table0.Rows)
					{
						if(!Row.IsNull(nazwaKolumny))
						{
							Guid idUzytkownik = (Guid)Row[nazwaKolumny];
							HtIdUzytkownik[idUzytkownik] = idUzytkownik;
						}
					}
					ArrayList kolIdUzytkownik = new ArrayList(HtIdUzytkownik.Values);
					Guid[] KolId = (Guid[])kolIdUzytkownik.ToArray(typeof(Guid));

					TUzytkownik[] kolUzytkownik = Port.Uzytkownik.DajKolUzytkownik(KolId);
					Hashtable daneUzytkownikow = new Hashtable();
					foreach(TUzytkownik uzytkownik in kolUzytkownik)
					{
						daneUzytkownikow[uzytkownik.id] = uzytkownik;
					}

					foreach(System.Data.DataRow Row in table0.Rows)
					{
						if((!Row.IsNull(nazwaKolumny)))
						{
							Guid idUzytkownik = (Guid)Row[nazwaKolumny];
							TUzytkownik uzytkownik = (TUzytkownik)daneUzytkownikow[idUzytkownik];
							if(uzytkownik != null)
							{
								Row[nazwaKolumny + "_Nazwisko"] = uzytkownik.nazwiskoSpecified ? uzytkownik.nazwisko : string.Empty;
								Row[nazwaKolumny + "_Imie"] = uzytkownik.imieSpecified ? uzytkownik.imie : string.Empty;
								Row[nazwaKolumny + "_Login"] = uzytkownik.loginSpecified ? uzytkownik.login : string.Empty;
							}
							else
							{
								Row[nazwaKolumny + "_Nazwisko"] = string.Empty;
								Row[nazwaKolumny + "_Imie"] = string.Empty;
								Row[nazwaKolumny + "_Login"] = string.Empty;
							}
						}
						else
						{
							Row[nazwaKolumny + "_Nazwisko"] = string.Empty;
							Row[nazwaKolumny + "_Imie"] = string.Empty;
							Row[nazwaKolumny + "_Login"] = string.Empty;
						}
					}
										
					//Nie mo¿na nadpisywaæ sortowania pochodz¹cego z bazy,
					//bo zestawienia siê Ÿle wykonuj¹
					//table0.DefaultView.Sort = nazwaKolumny+"_Nazwisko";
						
				}
			}
		}

		protected virtual string[] DajListeKolumnZIdUzytkownikow()
		{
			return new string[] {"idUzytkownik"};
		}

		protected void SprawdzIstnienieDniaUrzedu(DateTime data)
		{
			TDzienUrzedu dzienUrzedu = Port.DzienUrzedu.DajDzienUrzeduData(AktualnyKontekst.Kontekst.idUrzad,data);
			if(dzienUrzedu == null)
			{
				throw new EServerBusinessException(626);
			}
		}
	
		protected virtual bool CzyDrukowacWiersz(System.Data.DataRow Row)
		{
			return true;
		}

		protected int SzerokoscDruku
		{			
			get
			{
				return this.liczbaZnakowWWierszu;
			}
		}
	
	}
}
