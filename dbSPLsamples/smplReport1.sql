CREATE PROCEDURE Report_ZZEW_WszystkieOperacjeWyeksportowaneDokumenty
	@idDzienUrzedu uniqueidentifier
AS

DECLARE @idTypPozycjiKwotowej384Kwota uniqueidentifier
DECLARE @idTypPozycjiKwotowej384Oplata uniqueidentifier
DECLARE @idTypPozycjiKwotowej384Zwloka uniqueidentifier

SELECT
	@idTypPozycjiKwotowej384Kwota = CASE WHEN TypPozycjiKwotowej.nazwa = 'Kwota' THEN TypPozycjiKwotowej.idTypPozycjiKwotowej ELSE @idTypPozycjiKwotowej384Kwota END,
	@idTypPozycjiKwotowej384Oplata = CASE WHEN TypPozycjiKwotowej.nazwa = 'Opłata' THEN TypPozycjiKwotowej.idTypPozycjiKwotowej ELSE @idTypPozycjiKwotowej384Oplata END,
	@idTypPozycjiKwotowej384Zwloka = CASE WHEN TypPozycjiKwotowej.nazwa = 'Za zwłokę' THEN TypPozycjiKwotowej.idTypPozycjiKwotowej ELSE @idTypPozycjiKwotowej384Zwloka END
FROM TypPozycjiKwotowej
WHERE TypPozycjiKwotowej.idTypOperacji = '00000000-0000-0000-0000-000000000384'

SELECT
	COUNT(*) as Ilosc,
	TypOperacji.pelenSymbolOperacji,
	TypOperacji.nazwa,
	'' as Podtytul1,
	SUM(ISNULL(PK.Oplata, 0.0)) as Oplata,
	SUM(ISNULL(PK.Kwota, 0.0)) as Kwota,
	SUM(ISNULL(PK.Zwloka, 0.0)) as Zwloka
FROM
	TypOperacji INNER JOIN
	(
		SELECT
			Operacja.idTypOperacji,
			SUM(CASE WHEN TypPozycjiKwotowej.nazwa IN ('Kwota', 'Abonament', 'Upomnienie') THEN PozycjaKwotowa.wartosc ELSE 0.0 END) as Kwota,
			SUM(CASE WHEN TypPozycjiKwotowej.nazwa = 'Opłata' THEN PozycjaKwotowa.wartosc ELSE 0.0 END) as Oplata,
			SUM(CASE WHEN TypPozycjiKwotowej.nazwa = 'Za zwłokę' THEN PozycjaKwotowa.wartosc ELSE 0.0 END) as Zwloka
		FROM
			Operacja INNER JOIN
			PozycjaKwotowa ON (Operacja.idOperacja = PozycjaKwotowa .idOperacja) INNER JOIN
			TypPozycjiKwotowej ON (PozycjaKwotowa.idTypPozycjiKwotowej = TypPozycjiKwotowej.idTypPozycjiKwotowej AND TypPozycjiKwotowej.idTypOperacji = Operacja.idTypOperacji)
		WHERE
			(Operacja.idTypOperacji BETWEEN '00000000-0000-0000-0000-000000000326' AND '00000000-0000-0000-0000-000000000382') --Optymalizacja
			AND (Operacja.idDzienUrzedu = @idDzienUrzedu)
			AND (Operacja.stateInDataBase <> 'S')
			AND (Operacja.idSesjaEksportuOperacji IS NOT NULL)
			AND (TypPozycjiKwotowej.nazwa IN ('Kwota', 'Opłata', 'Za zwłokę', 'Abonament', 'Upomnienie'))
		GROUP BY Operacja.idTypOperacji, Operacja.idOperacja
			
	) as PK ON (PK.idTypOperacji = TypOperacji.idTypOperacji)
WHERE
	(TypOperacji.idTypOperacji BETWEEN '00000000-0000-0000-0000-000000000326' AND '00000000-0000-0000-0000-000000000382') --Optymalizacja
	AND (TypOperacji.czyModulObslugiWplat = 1)
GROUP BY TypOperacji.pelenSymbolOperacji, TypOperacji.nazwa

UNION ALL

SELECT
	COUNT(*) as Ilosc,
	'384' as pelenSymbolOperacji,
	'Wpłata PLUS' as nazwa,
	CASE WplataPLUS.sposobPrzekazywaniaDanych
		WHEN 'E' THEN 'elektronicznie'
		WHEN 'P' THEN 'papierowo'
		WHEN 'O' THEN 'Infotransfer ' + CASE Instytucja.nazwaSkrocona WHEN NULL THEN '<Brak Odbiorcy>' ELSE Instytucja.nazwaSkrocona END
		ELSE WplataPLUS.sposobPrzekazywaniaDanych END as Podtytul1,
	SUM(ISNULL(PK.Oplata, 0.0)) as Oplata,
	SUM(ISNULL(PK.Kwota, 0.0)) as Kwota,
	SUM(ISNULL(PK.Zwloka, 0.0)) as Zwloka
FROM
	Operacja INNER JOIN
	WplataPLUS ON (Operacja.idOperacja = WplataPLUS.idWplataPLUS) INNER JOIN
	(
		SELECT
			PozycjaKwotowa.idOperacja,
			SUM(CASE WHEN PozycjaKwotowa.idTypPozycjiKwotowej = @idTypPozycjiKwotowej384Kwota THEN PozycjaKwotowa.wartosc ELSE 0.0 END) as Kwota,
			SUM(CASE WHEN PozycjaKwotowa.idTypPozycjiKwotowej = @idTypPozycjiKwotowej384Oplata THEN PozycjaKwotowa.wartosc ELSE 0.0 END) as Oplata,
			SUM(CASE WHEN PozycjaKwotowa.idTypPozycjiKwotowej = @idTypPozycjiKwotowej384Zwloka THEN PozycjaKwotowa.wartosc ELSE 0.0 END) as Zwloka
		FROM
			PozycjaKwotowa
		WHERE
			PozycjaKwotowa.idTypPozycjiKwotowej IN (@idTypPozycjiKwotowej384Kwota, @idTypPozycjiKwotowej384Oplata, @idTypPozycjiKwotowej384Zwloka)
		GROUP BY PozycjaKwotowa.idOperacja
			
	) as PK ON (PK.idOperacja = Operacja.idOperacja) LEFT OUTER JOIN
	
	(UmowaNaPrzekazywanieDanych INNER JOIN
	Instytucja ON (Instytucja.idInstytucja = UmowaNaPrzekazywanieDanych.idInstytucja))

		ON (WplataPLUS.sposobPrzekazywaniaDanych = 'O')
		AND (WplataPLUS.idUmowaNaPrzekazywanieDanych = UmowaNaPrzekazywanieDanych.idUmowaNaPrzekazywanieDanych)
		AND (UmowaNaPrzekazywanieDanych.dataOd <= Operacja.dataUrzedu or UmowaNaPrzekazywanieDanych.dataOd IS NULL)
		AND (UmowaNaPrzekazywanieDanych.dataDo >= Operacja.dataUrzedu or UmowaNaPrzekazywanieDanych.DataDo IS NULL)
WHERE
	(Operacja.idTypOperacji = '00000000-0000-0000-0000-000000000384')
	AND (Operacja.idDzienUrzedu = @idDzienUrzedu)
	AND (Operacja.stateInDataBase <> 'S')
	AND (Operacja.idSesjaEksportuOperacji IS NOT NULL)

GROUP BY WplataPLUS.sposobPrzekazywaniaDanych, Instytucja.idInstytucja, Instytucja.nazwaSkrocona
ORDER BY  2, 4
GO

