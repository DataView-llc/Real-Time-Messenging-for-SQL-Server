/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE TABLE [RTM].[ServiceBroker_Metrics](
	[row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Queue] [varchar](256) NOT NULL,
	[Processing_Step] [int] NOT NULL,
	[Delivery_Lag_MS] [bigint] NULL,
	[Processing_Time_MS] [bigint] NULL,
	[Received_Count] [int] NULL,
	[Processed_Count] [int] NULL,
	[Insert_Count] [int] NULL,
	[Update_Count] [int] NULL,
	[Delete_Count] [int] NULL,
	[Insert_TS] [datetime] NOT NULL,
	[Server_Name] [varchar](255) NULL,
	[Message_type_name] [sysname] NULL,
	[Retry_Count] [int] NULL,
	[Expired_Count] [int] NULL,
	[ExecutionID] [uniqueidentifier] NULL,
	[Receive_Processing_Time_MS] [bigint] NULL,
	[Received_XML_Count] [int] NULL,
	[Received_Processed_Count] [int] NULL,
	[SP2_Processing_Time_MS] [bigint] NULL,
	[Insert_BASE_Count] [int] NULL,
	[Update_BASE_Count] [int] NULL,
	[Delete_BASE_Count] [int] NULL,
	[Insert_REOCCUR_Count] [int] NULL,
	[Update_REOCCUR_Count] [int] NULL,
	[Delete_REOCCUR_Count] [int] NULL,
	[Insert_BASE_Retry_Count] [int] NULL,
	[Update_BASE_Retry_Count] [int] NULL,
	[Delete_BASE_Retry_Count] [int] NULL,
	[Insert_REOCCUR_Retry_Count] [int] NULL,
	[Update_REOCCUR_Retry_Count] [int] NULL,
	[Delete_REOCCUR_Retry_Count] [int] NULL,
	[Error_Count] [int] NULL,
 CONSTRAINT [ServiceBrokerMetrics_PK] UNIQUE CLUSTERED 
(
	[Insert_TS] ASC,
	[row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
