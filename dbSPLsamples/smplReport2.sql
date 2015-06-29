CREATE PROCEDURE Report_ZDruk220Administracja
	@idUrzad uniqueidentifier,
	@numerDowoduPrzyjecia int, 
	@nazwaPrenumeratora varchar(60)
AS
/*lista dowodów przyjecia*/
select 
	numerDowoduPrzyjecia, nazwaPrenumeratora, ulicaPrenumeratora, miastoPrenumeratora, NIPPrenumeratora,
	nazwaTytulu1, nazwaTytulu2, miesiacZamowieniaOd, miesiacZamowieniaDo, rokZamowieniaOd, rokZamowieniaDo,
	ZamowieniaPrenumeraty.ilosc, cenaPrenumeraty, PNAPrenumeratora
from
	SprzedazPrenumeraty INNER JOIN
	ZamowieniaPrenumeraty ON (ZamowieniaPrenumeraty.idZamowieniaPrenumeraty = SprzedazPrenumeraty.idZamowieniaPrenumeraty)
where
	(ZamowieniaPrenumeraty.numerDowoduPrzyjecia = @numerDowoduPrzyjecia)
	AND (ZamowieniaPrenumeraty.numerDowoduPrzyjecia IS NOT NULL)
	AND (ZamowieniaPrenumeraty.nazwaPrenumeratora = @nazwaPrenumeratora)
	AND (ZamowieniaPrenumeraty.nazwaPrenumeratora IS NOT NULL)
	AND (ZamowieniaPrenumeraty.idUrzad = @idUrzad)

/*numer faktury*/
select numerFaktury from SprzedazPrenumeraty
join ZamowieniaPrenumeraty on  ZamowieniaPrenumeraty.idZamowieniaPrenumeraty = SprzedazPrenumeraty.idZamowieniaPrenumeraty
join Operacja on idSprzedazPrenumeraty = Operacja.idOperacja
left outer join PozycjaDokumentuFinansowego on PozycjaDokumentuFinansowego.idOperacja = Operacja.idOperacja 
/*left outer AS.*/ join Faktura on Faktura.idFaktura = PozycjaDokumentuFinansowego.idDokumentFinansowy 
where
	(ZamowieniaPrenumeraty.numerDowoduPrzyjecia = @numerDowoduPrzyjecia)
	AND (ZamowieniaPrenumeraty.numerDowoduPrzyjecia IS NOT NULL)
	AND (ZamowieniaPrenumeraty.nazwaPrenumeratora = @nazwaPrenumeratora)
	AND (ZamowieniaPrenumeraty.nazwaPrenumeratora IS NOT NULL)
	AND (ZamowieniaPrenumeraty.idUrzad = @idUrzad)
GO
