/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE TABLE [RTM].[sysEvent](
	[EventPK] [bigint] IDENTITY(1,1) NOT NULL,
	[Logged] [datetime2](7) NOT NULL,
	[Level] [nvarchar](50) NOT NULL,
	[User] [nvarchar](50) NOT NULL,
	[Source] [nvarchar](4000) NULL,
	[Details] [nvarchar](4000) NULL,
	[IntResult] [int] NULL,
	[SessionId] [uniqueidentifier] NULL,
	[Message_body] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [RTM].[sysEvent] ADD  CONSTRAINT [DF_sysEvent_Logged]  DEFAULT (sysdatetime()) FOR [Logged]
GO
ALTER TABLE [RTM].[sysEvent] ADD  CONSTRAINT [DF_sysEvent_Level]  DEFAULT ('INFO') FOR [Level]
GO
ALTER TABLE [RTM].[sysEvent] ADD  CONSTRAINT [DF_sysEvent_User]  DEFAULT (original_login()) FOR [User]
GO
