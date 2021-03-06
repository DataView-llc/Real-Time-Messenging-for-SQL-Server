/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE TABLE [RTM].[ServiceBrokerStats](
	[ServiceBrokerStats_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Insert_TS] [datetime2](7) NOT NULL,
	[Database_Name] [nvarchar](255) NULL,
	[Queue] [sysname] NOT NULL,
	[Queue_State] [nvarchar](255) NULL,
	[Messages_in_Queue] [bigint] NULL,
	[is_activation_enabled] [bit] NOT NULL,
	[current_readers] [int] NULL,
	[max_readers] [smallint] NULL,
	[last_empty_rowset_time] [datetime] NULL,
	[last_activated_time] [datetime] NULL,
	[tasks_waiting] [int] NULL,
	[activation_procedure] [nvarchar](1000) NULL,
	[is_receive_enabled] [bit] NOT NULL,
	[is_enqueue_enabled] [bit] NOT NULL,
	[is_retention_enabled] [bit] NOT NULL,
	[is_poison_message_handling_enabled] [bit] NULL,
 CONSTRAINT [ServiceBrokerStats_PK] UNIQUE CLUSTERED 
(
	[ServiceBrokerStats_ID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [RTM].[ServiceBrokerStats] ADD  CONSTRAINT [DF__ServiceBr__Inser__6450BA2D]  DEFAULT (sysdatetime()) FOR [Insert_TS]
GO
