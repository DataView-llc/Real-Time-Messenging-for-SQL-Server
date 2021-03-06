/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE TYPE [RTM].[ProcedureConfigurationVariables_Memory] AS TABLE(
	[id] [int] IDENTITY(1,1) NOT NULL,
	[ProcedureName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[varName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[varValueInt] [int] NULL,
	[varValueString] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	INDEX [ix1] NONCLUSTERED 
(
	[id] ASC
)
)
WITH ( MEMORY_OPTIMIZED = ON )
GO
