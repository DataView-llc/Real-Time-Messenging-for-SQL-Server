/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/


CREATE TABLE [RTM].[Process_M204_ErrorLog](
	[RowNum] [bigint] IDENTITY(1,1) NOT NULL,
	[Error_Number] [int] NOT NULL,
	[Error_Source] [varchar](256) NULL,
	[Error_Line] [int] NULL,
	[Error_Message] [varchar](max) NULL,
	[Error_Severity] [int] NULL,
	[Error_State] [int] NULL,
	[Error_Date] [datetime] NULL,
	[Error_User_System] [sysname] NULL,
	[Message_Body] [xml] NULL,
	[Reprocessed] [bit] NULL,
	[message_type_name] [sysname] NULL,
	[Source_Process] [varchar](255) NULL,
	[M204_File] [varchar](255) NULL,
	[record_key] [numeric](30, 0) NULL,
	[dts_dttmsp] [bigint] NULL,
	[rectype] [varchar](255) NULL,
	[message_ts] [datetime2](7) NULL,
	[binary_payload] [varbinary](max) NULL,
	[XML_payload] [xml] NULL,
	[ProgramID] [varchar](255) NULL,
	[Procedure] [varchar](255) NULL,
 CONSTRAINT [Process_M204_ErrorLog_PK] PRIMARY KEY CLUSTERED 
(
	[RowNum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
