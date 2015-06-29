CREATE  PROCEDURE Report_EksportOperacjiGrupy4
	@idUrzad uniqueidentifier,
	@idDzienUrzad uniqueidentifier
AS
SELECT operacja.idOperacja as UIG
	,typOperacji.pelenSymbolOperacji 
	,isnull(CzynnoscDodatkowaLokatyBP.rodzaj,'') as rodzaj
	,(CASE WHEN  TypPozycjiKwotowej.nazwa = 'Opłata' THEN ISNULL(PozycjaKwotowa.wartosc, 0) ELSE 0 END) AS Oplata
	,(CASE WHEN  TypPozycjiKwotowej.nazwa = 'Kwota' THEN ISNULL(PozycjaKwotowa.wartosc, 0) ELSE 0 END) AS Kwota
	,operacja.czasRejestracji
	,isnull((CASE WHEN  Operacja.idTypOperacji = '00000000-0000-0000-0000-000000000472' THEN WplataNaLokateBP.numerLokaty ELSE (CASE WHEN  Operacja.idTypOperacji = '00000000-0000-0000-0000-000000000477' THEN WyplataLokatyBP.numerLokaty ELSE (CzynnoscDodatkowaLokatyBP.nrLokaty) END) END),'') AS numerLokaty
	,isnull(WplataNaLokateBP.terminLokaty,'') as terminLokaty

FROM operacja
	INNER JOIN operacjaBankowa on operacjaBankowa.idoperacjaBankowa = operacja.idoperacja
	INNER JOIN TypOperacji on TypOperacji.idTypOperacji = operacja.idTypOperacji
	INNER JOIN TypPozycjiKwotowej ON (Operacja.idTypOperacji = TypPozycjiKwotowej.idTypOperacji AND (TypPozycjiKwotowej.nazwa = 'Kwota' OR TypPozycjiKwotowej.nazwa = 'Opłata') )  
	INNER JOIN PozycjaKwotowa ON (PozycjaKwotowa.idOperacja = Operacja.idOperacja AND PozycjaKwotowa.idTypPozycjiKwotowej = TypPozycjiKwotowej.idTypPozycjiKwotowej)
	LEFT OUTER JOIN WyplataLokatyBP on WyplataLokatyBP.idWyplataLokatyBP = operacja.idoperacja
	LEFT OUTER JOIN WplataNaLokateBP on WplataNaLokateBP.idWplataNaLokateBP = operacja.idoperacja
	LEFT OUTER JOIN CzynnoscDodatkowaLokatyBP on CzynnoscDodatkowaLokatyBP.idCzynnoscDodatkowaLokatyBP = operacja.idoperacja
	--LEFT OUTER JOIN CzynnoscNiefinansowaGIRO on CzynnoscNiefinansowaGIRO.idCzynnoscNiefinansowaGIRO = operacja.idoperacja
	
WHERE 
	Operacja.idTypOperacji IN (
	'00000000-0000-0000-0000-000000000472', '00000000-0000-0000-0000-000000000477'
	, '00000000-0000-0000-0000-000000000468')
--, '00000000-0000-0000-0000-000000000469')
	AND (Operacja.stateInDataBase <> 'S')
	AND (Operacja.rodzajoperacji = 'N')
	AND (Operacja.idDzienUrzedu =  @idDzienUrzad)
	AND (Operacja.idUrzad = @idUrzad)
GO