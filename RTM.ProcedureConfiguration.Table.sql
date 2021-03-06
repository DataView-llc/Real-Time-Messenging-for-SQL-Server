/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE TABLE [RTM].[ProcedureConfiguration]
(
	[id] [int] IDENTITY(1,1) NOT NULL,
	[SchemaName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProcedureName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[varName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[varValueInt] [int] NULL,
	[varValueString] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Modify_TS] [datetime2](7) NOT NULL,
	[Modify_ID] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,

 PRIMARY KEY NONCLUSTERED HASH 
(
	[SchemaName],
	[ProcedureName],
	[varName]
)WITH ( BUCKET_COUNT = 8192)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )
GO
