CREATE TABLE [dbo].[SprzedazPrenumeraty] (
	[idSprzedazPrenumeraty]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[cenaPrenumeraty] [money] NULL ,
	[idZamowieniaPrenumeraty] [uniqueidentifier] NOT NULL ,
	[symbolTypuPrenumeraty] [int] NULL ,
	[symbolTypuRejonu] [DTYPWYLICZENIOWY] NULL ,
	[idRep] [uniqueidentifier] NOT NULL 
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SprzedazPrenumeraty] WITH NOCHECK ADD 
	CONSTRAINT [PK_idSprzedazPrenumeraty] PRIMARY KEY  CLUSTERED 
	(
		[idSprzedazPrenumeraty]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SprzedazPrenumeraty] ADD 
	CONSTRAINT [DF_SprzedazPrenumeraty_idSprzedazPrenumeraty] DEFAULT (newid()) FOR [idSprzedazPrenumeraty]
GO

 CREATE  INDEX [IX_SprzedazPrenumeraty_idZamowieniaPrenumeraty] ON [dbo].[SprzedazPrenumeraty]([idZamowieniaPrenumeraty]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SprzedazPrenumeraty] ADD 
	CONSTRAINT [FK_SprzedazPrenumeraty_Operacja] FOREIGN KEY 
	(
		[idSprzedazPrenumeraty]
	) REFERENCES [dbo].[Operacja] (
		[idOperacja]
	) NOT FOR REPLICATION ,
	CONSTRAINT [FK_SprzedazPrenumeraty_ZamowieniaPrenumeraty] FOREIGN KEY 
	(
		[idZamowieniaPrenumeraty]
	) REFERENCES [dbo].[ZamowieniaPrenumeraty] (
		[idZamowieniaPrenumeraty]
	) NOT FOR REPLICATION 
GO

alter table [dbo].[SprzedazPrenumeraty] nocheck constraint [FK_SprzedazPrenumeraty_Operacja]
GO