if exists (select * from dbo.systypes where name = N'DTYPWYLICZENIOWY')
exec sp_droptype N'DTYPWYLICZENIOWY'
GO


EXEC sp_addtype N'DTYPWYLICZENIOWY', N'char (1)', N'not null'
GO
