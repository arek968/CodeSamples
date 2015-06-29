CREATE PROCEDURE Report_EksportDoFK
	@idUrzad uniqueidentifier,
	@dataOd DateTime,
	@dataDo DateTime
AS

DECLARE @GUID_EMPTY uniqueidentifier
SET @GUID_EMPTY = CAST('00000000-0000-0000-0000-000000000000' AS uniqueidentifier)

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*Deklaracje tablic (zmiennych) tymczasowych*/
/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
DECLARE @TmpOperacja TABLE
(
	idOperacja uniqueidentifier NOT NULL PRIMARY KEY clustered,
	czyBezgotowkowo bit NOT NULL,
	idTypOperacji uniqueidentifier NOT NULL,
	symbolGrupy char(1) COLLATE database_default NOT NULL,
	symbolOperacji char(2) COLLATE database_default NOT NULL,
	nazwaOperacji varchar(50) COLLATE database_default NOT NULL,
	idPodtytulOrm uniqueidentifier NULL,
	nazwa varchar(100) COLLATE database_default NULL
)

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*Pobranie operacji*/
/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
INSERT INTO @TmpOperacja
SELECT
	Operacja.idOperacja,
	Operacja.czyBezgotowkowo,
	TypOperacji.idTypOperacji,
	TypOperacji.symbolGrupy,
	TypOperacji.symbolOperacji,
	TypOperacji.nazwa,
	CASE WHEN TypOperacji.symbolGrupy = '8' THEN Operacja.idPodtytulORM WHEN TypOperacji.pelenSymbolOperacji IN ('455', '456') THEN @GUID_EMPTY ELSE NULL END,
	CASE WHEN TypOperacji.pelenSymbolOperacji IN ('455', '456') THEN 'nazwa' ELSE NULL END
FROM
	Operacja INNER JOIN
	TypOperacji ON (TypOperacji.idTypOperacji = Operacja.idTypOperacji)
WHERE
	(Operacja.dataUrzedu BETWEEN @dataOd AND @dataDo)
	AND (Operacja.idUrzad = @idUrzad)
	AND (Operacja.stateInDatabase <> 'S')
	AND (TypOperacji.numerPozycjiRozliczeniaKasjera IS NOT NULL) 
	AND (TypOperacji.czyEksportORM = 1)
	AND (TypOperacji.stateInDataBase <> 'S')
	AND (Operacja.idTypOperacji > '00000000-0000-0000-0000-000000000001')

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*Pobranie podtytułów operacji*/
/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/*Grupa 8*/
UPDATE @TmpOperacja SET
	nazwa = PodtytulORM.nazwa
FROM 
	@TmpOperacja AS TmpOperacja INNER JOIN
	PodtytulORM ON (TmpOperacja.idPodtytulORM = PodtytulORM.idPodtytulORM)
WHERE	
	(TmpOperacja.symbolGrupy = '8')
	AND (TmpOperacja.idPodtytulORM IS NOT NULL)

/*Grupa 0*/
UPDATE @TmpOperacja SET
	idPodtytulOrm = OperacjaKasjera.idPodtytul,
	nazwa = Podtytul.nazwa
FROM 
	@TmpOperacja AS TmpOperacja INNER JOIN
	OperacjaKasjera ON (TmpOperacja.idOperacja = OperacjaKasjera.idOperacjaKasjera) INNER JOIN
	Podtytul ON (OperacjaKasjera.idPodtytul = Podtytul.idPodtytul)
WHERE	
	(TmpOperacja.symbolGrupy = '0')
	AND (OperacjaKasjera.idPodtytul IS NOT NULL)

/*Grupa 4*/
UPDATE @TmpOperacja SET
	idPodtytulOrm = DaneCentrali.idDaneCentrali,
	nazwa = DaneCentrali.nazwa
FROM 
	@TmpOperacja AS TmpOperacja LEFT OUTER JOIN
	(
	OperacjaBankowa INNER JOIN
	PozycjaUmowyZBankiem ON (PozycjaUmowyZBankiem.idPozycjaUmowyZBankiem = OperacjaBankowa.idPozycjaUmowyZBankiem) INNER JOIN
	UmowaZBankiem ON (UmowaZBankiem.idUmowaZBankiem = PozycjaUmowyZBankiem.idUmowaZBankiem) INNER JOIN
	DaneCentrali ON (DaneCentrali.idCentrala = UmowaZBankiem.idCentrala AND DaneCentrali.dataPoczatku <= @dataDo AND DaneCentrali.stateInDatabase <> 'S' AND ISNULL(DaneCentrali.dataKonca, @dataDo) >= @dataDo)
	) ON (TmpOperacja.idOperacja = OperacjaBankowa.idOperacjaBankowa)
WHERE	
	(TmpOperacja.symbolGrupy = '4')
	AND (TmpOperacja.symbolOperacji NOT IN ('55', '56'))

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*PozycjaKwotowa*/
SELECT
	TmpOperacja.idTypOperacji AS idTypOperacji,
	TmpOperacja.czyBezgotowkowo AS czyBezgotowkowo,
	TmpOperacja.symbolGrupy AS symbolGrupy,
	TmpOperacja.symbolOperacji AS symbolOperacji,
	TmpOperacja.nazwaOperacji AS nazwaOperacji,
	TmpOperacja.idPodtytulOrm AS idPodtytulOrm,
	TmpOperacja.nazwa AS nazwa,
	TypPozycjiKwotowej.idTypPozycjiKwotowej AS idTypPozycjiKwotowej,
	TypPozycjiKwotowej.nazwa AS nazwatpk,
	TypPozycjiKwotowej.czyFiskalna AS czyFiskalna,
	TypPozycjiKwotowej.czyUjemna AS czyUjemna,
	ISNULL(PozycjaDokumentuFinansowego.skrotVAT, '') AS skrotVat,
	SUM(PozycjaKwotowa.wartosc) AS WARTOSC,
	SUM(PozycjaDokumentuFinansowego.wartoscBrutto) AS BRUTTO,
	SUM(PozycjaDokumentuFinansowego.wartoscNetto) AS NETTO,
	SUM(PozycjaDokumentuFinansowego.wartoscVAT) AS VAT, 
	COUNT(*) AS ilosc
FROM
	@TmpOperacja AS TmpOperacja INNER JOIN
	TypPozycjiKwotowej ON (TypPozycjiKwotowej.idTypOperacji = TmpOperacja.idTypOperacji AND TypPozycjiKwotowej.czyEksportORM = 1) INNER JOIN
	PozycjaKwotowa ON (PozycjaKwotowa.idOperacja = TmpOperacja.idOperacja AND PozycjaKwotowa.idTypPozycjiKwotowej = TypPozycjiKwotowej.idTypPozycjiKwotowej) LEFT OUTER JOIN
	(
		PozycjaDokumentuFinansowego INNER JOIN
		Paragon ON (Paragon.idParagon = PozycjaDokumentuFinansowego.idDokumentFinansowy) -- Bez faktur, bo może być ich wiele, a paragon zawsze tylko 1
	) ON (PozycjaDokumentuFinansowego.idOperacja = TmpOperacja.idOperacja AND PozycjaDokumentuFinansowego.idTypPozycjiKwotowej = TypPozycjiKwotowej.idTypPozycjiKwotowej AND PozycjaDokumentuFinansowego.stateInDatabase <> 'S')
GROUP BY
	TmpOperacja.idTypOperacji, TmpOperacja.czyBezgotowkowo, TmpOperacja.symbolGrupy, TmpOperacja.symbolOperacji, TmpOperacja.nazwaOperacji, TmpOperacja.idPodtytulOrm, TmpOperacja.nazwa,
	TypPozycjiKwotowej.idTypPozycjiKwotowej, TypPozycjiKwotowej.nazwa, TypPozycjiKwotowej.czyFiskalna, TypPozycjiKwotowej.czyUjemna, ISNULL(PozycjaDokumentuFinansowego.skrotVAT, '')
GO


if exists (select * from sysobjects where id = object_id(N'[dbo].[Report_EksportOperacjiDoMRUM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    drop procedure [dbo].[Report_EksportOperacjiDoMRUM]
GO




CREATE PROCEDURE Report_EksportOperacjiDoMRUM
	@dataOd dateTime,
	@dataDo dateTime,
	@idUrzad uniqueidentifier
AS

DECLARE @Tempek TABLE
(
	idOperacja uniqueidentifier not null primary key clustered,
	idTypOperacji uniqueidentifier not null,
	pelenSymbolOperacji char(3) COLLATE database_default,
	ilosc money,
	instytucja_mru int,
	umowa_mru varchar(25) COLLATE database_default,
	pozycja_mru int,
	dataoperacji DateTime,
	kategoriaZwrotu varchar(1) COLLATE database_default,
	idPozycjaUmowyNaOperacjePocz uniqueidentifier,
	idTypOperacjiZwrotu uniqueidentifier,
	mruIdUmowy varchar(10) COLLATE database_default,
	mruIdKartyUmowy varchar(10) COLLATE database_default,
	czyCzynnosciOpustowe bit
)

INSERT INTO @tempek
SELECT
	idOperacja,
	Operacja.idTypOperacji,
	pelenSymbolOperacji,
	ilosc,
	Instytucja.mruRefKey,
	UmowaNaOperacjePocztowe.numer,
	PozycjaUmowyNaOperacjepocz.mruRefKey,
	Operacja.dataUrzedu AS data,
	PozycjaUmowyNaOperacjePocz.kategoriaOperacjiZwrotu,
	PozycjaUmowyNaOperacjePocz.idPozycjaUmowyNaOperacjePocz,
	PozycjaUmowyNaOperacjePocz.idTypOperacjiZwrotu,
	UmowaNaOperacjePocztowe.mruIdUmowy,
	UmowaNaOperacjePocztowe.mruIdKartyUmowy,
	ISNULL(PozycjaUmowyNaOperacjePocz.czyCzynnosciOpustowe, 0)
FROM
	Operacja inner join
	PozycjaUmowyNaOperacjePocz on Operacja.idPozycjaUmowyNaOperacjePocz = PozycjaUmowyNaOperacjePocz.idPozycjaUmowyNaOperacjePocz inner join
	UmowaNaOperacjePocztowe on UmowaNaOperacjePocztowe.idUmowaNaOperacjePocztowe = PozycjaUmowyNaOperacjePocz.idUmowaNaOperacjePocztowe inner join
	TypOperacji on TypOperacji.idTypOperacji = PozycjaUmowyNaOperacjePocz.idTypOperacji inner join
	Instytucja on Instytucja.idInstytucja = UmowaNaOPeracjePocztowe.idInstytucja
WHERE
	Operacja.stateInDataBase <> 'S' And
	Operacja.idUrzad = @idUrzad and
	Operacja.dataUrzedu between @dataOd and @dataDo and
	UmowaNaOperacjePocztowe.mruRefKey is not null and
	PozycjaUmowyNaOperacjePOcz.mruRefKey is not null  and 
	Operacja.idPozycjaUmowyNaOperacjePocz IS NOT NULL
	AND (Operacja.idTypOperacji > '00000000-0000-0000-0000-000000000001')

SELECT *
FROM
(

SELECT
	Tempek.mruIdUmowy,
	Tempek.mruIdKartyUmowy,
	Tempek.idTypOperacjiZwrotu,
	Tempek.idPozycjaUmowyNaOperacjePocz,
	Tempek.idOperacja,
	Tempek.pelenSymbolOperacji,
	Tempek.ilosc as LICZBA,
	Tempek.instytucja_mru,
	Tempek.umowa_mru,
	Tempek.pozycja_mru,
	Tempek.dataOperacji,
	masa,
	czyPriorytetowa,
	swiadczeniaDodatkowe as SWIADDOD,
	(CASE pelenSymbolOperacji when '812' then NadaniePocztex.typEms 
				     when '887' then ZwrotKrajowyZagraniczny.typEMS
				     when '889' then WydanieOpakowaniaEMS.typEMS
				      else NULL end)as PRZESYLKA,
	(CASE pelenSymbolOperacji when '812' then NadaniePocztex.termin 
				      when '887' then ZwrotKrajowyZagraniczny.termin
				      else NULL end)as TERMSERW,
	NadaniePocztex.odleglosc as ODLEG,	
	NadaniePocztex.sposobPotwierdzeniaDoreczenia as POTW_DOR,
	(CASE pelenSymbolOperacji when '812' then NadaniePocztex.sposobPotwierdzeniaOdbioru 
				     when '887' then ZwrotKrajowyZagraniczny.sposobPotwierdzeniaOdbioru
				   else NULL end) as POTW_ODB,
	(CASE pelenSymbolOperacji when '812' then NadaniePocztex.terminPotwierdzeniaOdbioru 
				    when '887' then ZwrotKrajowyZagraniczny.terminPotwierdzeniaOdbioru 
				    else NULL end) as POTW_ODB_TERM,
	(case pelenSymbolOperacji when '812' then NadaniePocztex.kwotaPobrania 
			                 when '848' then NadaniePrzesylkiPobraniowej.kwotapobrania 
			                 when '887' then ZwrotKrajowyZagraniczny.kwotapobrania 
	else NULL end) as POBRANIE,
	(case pelenSymbolOperacji when '812' then NadaniePocztex.SposobPobrania 
			                 when '848' then NadaniePrzesylkiPobraniowej.sposobPobrania
				    when '887' then ZwrotKrajowyZagraniczny.rodzajPobrania
	else NULL end) as POBRANIE_FORMA,
	(CASE pelenSymbolOperacji when '812' then NadaniePocztex.UiszczaOplate 
				     when '887' then ZwrotKrajowyZagraniczny.uiszczaOplate
				     else NULL end)as UISZCZA,
	(CASE pelenSymbolOperacji when '812' then NadaniePocztex.terminDlaZwrotuDokumentow
				     when '887' then ZwrotKrajowyZagraniczny.terminDlaZwrotuDokumentow
				     else NULL end)as TERMSERW_ZWROT,
	(CASE pelenSymbolOperacji when '812' then NadaniePocztex.odlegloscDlaZwrotuDokumentow
				     when '887' then ZwrotKrajowyZagraniczny.odlegloscDlaZwrotuDokumentow
				     else NULL end)as ODLEG_ZWROT,
	NadaniePocztex.nazwaAdresata as ADRESAT,
	NadaniePocztex.kodPocztowy as ADRKOD,
	NadaniePocztex.miejscowosc as ADRMIASTO,
	NadaniePocztex.ulica as ADRULICA,
	NadaniePrzesylkiDworcowej.czyListDworcowy as LISTDWORCOWY,
	OperacjaListowoPaczkowa.czyPriorytetowa as KATEGORIA,
	OperacjaListowoPaczkowa.czyEgzbibl as EGZBIBL,
	OperacjaListowoPaczkowa.czyDlaOciemnialych as OCIEMN,
	OperacjaListowoPaczkowa.czyPosteRestante as POSTERESTANTE,
	OperacjaListowoPaczkowa.iloscPakietow as LICZBA_PAK,
	NadanieDrukuBezadresowego.liczbaPlacowek as LICZBA_PLAC_DOR,
	NadanieDrukuBezadresowego.liczbaPunktowDoreczen as LICZBA_PKT_DOR,
	NadanieListuPoleconegoKraj.czyNalepkaKlienta as RODZNALEPKI,
	NULL as KRAJUE,
	NULL as KRAJ,
	StrefaCenowa.symbol as STREFACEN,
	(case pelenSymbolOperacji when '812'  then NadaniePocztex.wartosc
				    when '844' then NadanieListWartosciowyKraj.wartosc 
			                 when '864' then NadanieListWartosciowyKraj.wartosc
				    when '846' then NadaniePaczkiKraj.wartosc
				    when '866' then NadaniePaczkiKraj.wartosc 
      			                 when '847' then NadaniePaczkiPLUS.wartosc
				   when '848' then NadaniePrzesylkiPobraniowej.wartosc
	else NULL end) as WARTOSC,
	(case pelenSymbolOperacji when '812' then NadaniePocztex.numerNadania
				    when '814' then NadaniePrzesylkiDworcowej.numerNadania	 
				    when '844' then NadanieListWartosciowyKraj.numerNadania
				    when '864' then NadanieListWartosciowyKraj.numerNadania
				    when '845' then NadanieListuPoleconegoKraj.numerNadania
				    when '865' then NadanieListuPoleconegoKraj.numerNadania				   
				    when '846' then NadaniePaczkiKraj.numerNadania
				    when '866' then NadaniePaczkiKraj.numerNadania
			                 when '847' then NadaniePaczkiPLUS.numerNadania
				    when '848' then NadaniePrzesylkiPobraniowej.numerNadania	
	else NULL end) as NRNADANIA,
	OperacjaDodatkowaCUP.nazwaPozycjiCUP as POZ_GRUPY,
	OperacjaDodatkowaCUP.cenaJednostkowa as CENA_JEDNOST,
	OperacjaNaKsiege.liczbaPotwierdzenOdbioru as ILOSC_PO,
	Tempek.KategoriaZwrotu AS KATEGORIA_1,
	ZwrotKrajowyZagraniczny.czyZwrotPriorytet as ZWROT_PRIORYTET,
	ZwrotKrajowyZagraniczny.kwotaOplaty as KWOTA_NADANIA,
	ZwrotKrajowyZagraniczny.zawartosc AS ZAWARTOSC,
	OperacjaListowoPaczkowa.czynnosciOpustowe AS CZYNNOSC,
	Tempek.czyCzynnosciOpustowe
FROM
	@tempek as Tempek inner join
	OperacjaNaKsiege on OperacjaNaKsiege.idOperacjaNaKsiege = Tempek.idOperacja inner join
	OperacjaListowoPaczkowa on Tempek.idOperacja = OperacjaListowoPaczkowa.idOperacjaListowoPaczkowa left join
	NadanieListuPoleconegoKraj on Tempek.idOperacja = NadanieListuPoleconegoKraj.idNadanieListuPoleconegoKraj left join
	NadanieListWartosciowyKraj on Tempek.idOperacja = NadanieListWartosciowyKraj.idNadanieListWartosciowyKraj left join
	NadaniePaczkiKraj on Tempek.idOperacja = NadaniePaczkiKraj.idNadaniePaczkiKraj left join
	NadaniePaczkiPLUS on Tempek.idOperacja = NadaniePaczkiPLUS.idNadaniePaczkiPLUS left join
	NadaniePocztex on Tempek.idOperacja = NadaniePocztex.idNadaniePocztex left join
	NadaniePrzesylkiDworcowej on Tempek.idOperacja = NadaniePrzesylkiDworcowej.idNadaniePrzesylkiDworcowej left join
	NadanieDrukuBezadresowego on (Tempek.idOperacja = NadanieDrukuBezadresowego.idNadanieDrukuBezadresowego AND pelenSymbolOperacji = '843') left join
	NadanieProbkiTowaru on (Tempek.idOperacja = NadanieProbkiTowaru.idNadanieProbkiTowaru AND pelenSymbolOperacji = '849') left join
	NadaniePrzesylkiPobraniowej on Tempek.idOperacja = NadaniePrzesylkiPobraniowej.idNadaniePrzesylkiPobraniowej left join
	OperacjaDodatkowaCUP on Tempek.idOperacja = OperacjaDodatkowaCUP.idOperacjaDodatkowaCUP left join
	ZwrotKrajowyZagraniczny ON (Tempek.idOperacja = ZwrotKrajowyZagraniczny.idZwrotKrajowyZagraniczny AND pelenSymbolOperacji = '887')LEFT JOIN
	WydanieOpakowaniaEMS ON (Tempek.idOperacja = WydanieOpakowaniaEMS.idWydanieOpakowaniaEMS AND pelenSymbolOperacji = '889') LEFT OUTER JOIN
	StrefaCenowa on StrefaCenowa.idStrefaCenowa = OperacjaListowoPaczkowa.idStrefaCenowa

union all 

select 
	Tempek.mruIdUmowy,
	Tempek.mruIdKartyUmowy,
	Tempek.idTypOperacjiZwrotu,
	Tempek.idPozycjaUmowyNaOperacjePocz,
	Tempek.idOperacja,
	Tempek.pelenSymbolOperacji,
	Tempek.ilosc as LICZBA,
	Tempek.instytucja_mru,
	Tempek.umowa_mru,
	Tempek.pozycja_mru,
	Tempek.dataOperacji,
	masa,
	czyPriorytetowa,
	swiadczeniaDodatkowe as SWIADDOD,
	NadanieEMSPocztexZagr.typEMS as PRZESYLKA,
	NULL as TERMSERW,
	NULL as ODLEG,
	NULL as POTW_DOR,
	NULL as POTW_ODB,
	NULL as POTW_ODB_TERM,
	NULL as POBRANIE,
	NULL as POBRANIE_FORMA,
	NULL as UISZCZA,
	NULL as TERMSERW_ZWROT,
	NULL as ODLEG_ZWROT,
	(case pelenSymbolOperacji when '831' then NadanieEMSPocztexZagr.nazwaAdresata 
				    when '878' then NadaniePaczkiZagr.nazwaAdresata 
	else NULL end) as ADRESAT,
	NadanieEMSPocztexZagr.kodPNAZagraniczny as ADRKOD,
	NadanieEMSPocztexZagr.miejscowosc as ADRMIASTO,
	NULL as ADRULICA,
	NULL as LISTDWORCOWY,
	OperacjaListowoPaczkowaZagr.czyPriorytetowa as KATEGORIA,
	NULL as EGZBIBL,
	NULL as OCIEMN,
	OperacjaListowoPaczkowaZagr.czyPosterestante  as POSTERESTANTE,
	NULL as LICZBA_PAK,
	NULL as LICZBA_PLAC_DOR,
	NULL as LICZBA_PKT_DOR,
	NadaniePrzesylkiZwyklejZagr.czyNalepkaKlienta as RODZNALEPKI,
	Kraj.KrajUE as KRAJUE,
	Kraj.symbolISO as KRAJ,
	StrefaCenowa.symbol as STREFACEN,
	(case pelenSymbolOperacji when '878' then NadaniePaczkiZagr.wartosc 
				    when '877' then NadanieListWartosciowyZagr.wartosc
				    when '879' then NadanieListWartosciowyZagr.wartosc
				    when '880' then NadanieListWartosciowyZagr.wartosc
				    when '881' then NadanieListWartosciowyZagr.wartosc
	else NULL end )as WARTOSC,
	(case pelenSymbolOperacji when '831' then NadanieEMSPOcztexZagr.numerNadania
				    when '878' then NadaniePaczkiZagr.numerNadania
				    when '870' then NadaniePrzesylkiZwyklejZagr.numerNadania
				    when '872' then NadaniePrzesylkiZwyklejZagr.numerNadania
				    when '874' then NadaniePrzesylkiZwyklejZagr.numerNadania
				    when '875' then NadaniePrzesylkiZwyklejZagr.numerNadania
				    when '877' then NadanieListWartosciowyZagr.numerNadania
				    when '879' then NadanieListWartosciowyZagr.numerNadania
				    when '880' then NadanieListWartosciowyZagr.numerNadania
				    when '881' then NadanieListWartosciowyZagr.numerNadania

	else NULL end) as NRNADANIA,
	NULL as POZ_GRUPY,
	NULL as CENA_JEDNOST,
	OperacjaNaKsiege.liczbaPotwierdzenOdbioru as ILOSC_PO,
	Tempek.KategoriaZwrotu AS KATEGORIA_1,
	NULL as ZWROT_PRIORYTET,
	NULL as KWOTA_NADANIA,
	NULL as ZAWARTOSC,
	OperacjaListowoPaczkowaZagr.czynnosciOpustowe AS CZYNNOSC,
	Tempek.czyCzynnosciOpustowe
from 	
	@tempek as Tempek inner join
	OperacjaNaKsiege on OperacjaNaKsiege.idOPeracjaNaKsiege = Tempek.idOperacja inner join
	OperacjaListowoPaczkowaZagr on Tempek.idOperacja = OperacjaListowoPaczkowaZagr.idOperacjaListowoPaczkowaZagr left join
	NadanieListWartosciowyZagr on Tempek.idOperacja = NadanieListWartosciowyZagr.idNadanieListWartosciowyZagr left join
	NadaniePaczkiZagr on Tempek.idOperacja = NadaniePaczkiZagr.idNadaniePaczkiZagr left join
	NadanieEMSPOcztexZagr on Tempek.idOperacja = NadanieEMSPOcztexZagr.idNadanieEMSPocztexZagr left join
	NadaniePrzesylkiZwyklejZagr on NadaniePrzesylkiZwyklejZagr.idNadaniePrzesylkiZwyklejZagr = OperacjaListowoPaczkowaZagr.idOperacjaListowoPaczkowaZagr left join
	Kraj on Kraj.idKraj = OperacjaListowoPaczkowaZagr.idKraj left join 
	StrefaCenowa on StrefaCenowa.idStrefaCenowa = OperacjaListowoPaczkowaZagr.idStrefaCenowa
) as P order by pelenSymbolOperacji,dataoperacji

	    
SELECT
	Tempek.idOperacja,
	Tempek.pelenSymbolOperacji,
	TypPozycjiKwotowej.nazwaAtrybutuMrum,
	SUM(wartosc) as wartosc
FROM
	@Tempek as Tempek INNER JOIN
	PozycjaKwotowa ON (PozycjaKwotowa.idOperacja = Tempek.idOperacja) INNER JOIN
	TypPozycjiKwotowej ON (TypPozycjiKwotowej.idTypPozycjiKwotowej = PozycjaKwotowa.idTypPozycjiKwotowej)
WHERE
	TypPozycjiKwotowej.nazwaAtrybutuMrum is not null
GROUP BY Tempek.idOperacja, Tempek.pelenSymbolOperacji, TypPozycjiKwotowej.nazwaAtrybutuMrum


GO

