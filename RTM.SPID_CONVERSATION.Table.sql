/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE TABLE [RTM].[SPID_CONVERSATION](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SPID] [int] NOT NULL,
	[INITIATOR_SERVICE] [varchar](250) NOT NULL,
	[TARGET_SERVICE] [varchar](250) NOT NULL,
	[CONTRACT] [sysname] NOT NULL,
	[CONVERSATION_HANDLE] [uniqueidentifier] NULL,
	[Modify_TS] [datetime] NULL,
	[Modify_ID] [varchar](256) NULL,
 CONSTRAINT [PK_SPID_CONVERSATION] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [RTM].[SPID_CONVERSATION] ADD  CONSTRAINT [DF__SPID_CONV__Modif__0CBDA119]  DEFAULT (getdate()) FOR [Modify_TS]
GO
ALTER TABLE [RTM].[SPID_CONVERSATION] ADD  CONSTRAINT [DF__SPID_CONV__Modif__0DB1C552]  DEFAULT (suser_sname()) FOR [Modify_ID]
GO
