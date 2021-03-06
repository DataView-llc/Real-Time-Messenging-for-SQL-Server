/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/


CREATE TYPE [RTM].[tableMessages_Memory] AS TABLE(
	[queuing_order] [bigint] NULL,
	[conversation_handle] [uniqueidentifier] NULL,
	[message_type_name] [sysname] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[message_enqueue_time] [datetime] NULL,
	[payload] [varbinary](max) NULL,
	INDEX [ix1] NONCLUSTERED 
(
	[queuing_order] ASC
)
)
WITH ( MEMORY_OPTIMIZED = ON )
GO
