/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE VIEW [RTM].[ServiceBrokerStats_VW]
AS
    SELECT [Database_Name] = Db_Name()
          ,[schema] = [sch].[name]
          ,[Queue] = [sq].[name]
          ,[Queue_State] = [qm].[state]
          ,[Messages_in_Queue] = [p].[rows]
          ,[sq].[is_activation_enabled]
          ,[EnableActivation] = Concat('ALTER QUEUE  [', [sch].[name], '].[', [sq].[name], '] WITH  ACTIVATION (  STATUS = ON )')
          ,[DisableActivation] = Concat('ALTER QUEUE  [', [sch].[name], '].[', [sq].[name], '] WITH  ACTIVATION (  STATUS = OFF)')
          ,[at].[current_readers]
          ,[sq].[max_readers]
          ,[qm].[last_empty_rowset_time]
          ,[qm].[last_activated_time]
          ,[queue_last_modify_date] = [sq].[modify_date]
          ,[qm].[tasks_waiting]
          ,[bat].[spid]
          ,[blocked] = [syspr].[blocking_session_id]
          ,[waittime] = [syspr].[wait_time]
          ,[lastwaittype] = [syspr].[last_wait_type]
          ,[wait_resource] = [syspr].[wait_resource]
          ,[cmd] = [syspr].[command]
          ,[sq].[activation_procedure]
          ,[sq].[is_receive_enabled]
          ,[sq].[is_enqueue_enabled]
          ,[sq].[is_retention_enabled]
          ,[sq].[is_poison_message_handling_enabled]

    FROM   [sys].[service_queues] [sq] WITH ( NOLOCK )
           LEFT JOIN [sys].[dm_broker_queue_monitors] [qm] WITH ( NOLOCK ) ON [qm].[queue_id]    = [sq].[object_id]
           LEFT JOIN [sys].[dm_broker_activated_tasks] [bat] WITH ( NOLOCK ) ON [bat].[queue_id] = [sq].[object_id]
           LEFT JOIN [sys].[dm_exec_requests] [syspr] WITH ( NOLOCK ) ON [bat].[spid]            = [syspr].[session_id]
           LEFT JOIN [sys].[objects] [o2] WITH ( NOLOCK ) ON [o2].[parent_object_id]             = [sq].[object_id]
           LEFT JOIN [sys].[schemas] [sch] ON [sch].[schema_id]                                  = [sq].[schema_id]
           LEFT JOIN [sys].[partitions] [p] WITH ( NOLOCK ) ON [p].[object_id]                   = [o2].[object_id]
                                                               AND [p].[index_id]                = 1
           LEFT JOIN
           (   SELECT [queue_id]
                     ,[current_readers] = Count(*)
               FROM   [sys].[dm_broker_activated_tasks]
               GROUP BY
                      [queue_id] ) [at] ON [sq].[object_id]                                         = [at].[queue_id]
    WHERE  [sq].[is_ms_shipped] = 0
    UNION ALL
    SELECT [Database_Name] = Db_Name()
          ,[schema] = 'sys'
          ,[Queue] = 'Transmission_Queue'
          ,[Queue_State] = NULL
          ,[Messages_in_Queue] = [p].[rows]
          ,[is_activation_enabled] = 0
          ,[EnableActivation] = NULL
          ,[DisableActivation] = NULL
          ,[current_readers] = NULL
          ,[max_readers] = NULL
          ,[last_empty_rowset_time] = NULL
          ,[queue_last_modify_date] = NULL
          ,[last_activated_time] = NULL
          ,[tasks_waiting] = NULL
          ,[spid] = NULL
          ,[blocked] = NULL
          ,[waittime] = NULL
          ,[lastwaittype] = NULL
          ,[wait_resource] = NULL
          ,[cmd] = NULL
          ,[activation_procedure] = NULL
          ,[is_receive_enabled] = 0
          ,[is_enqueue_enabled] = 0
          ,[is_retention_enabled] = 0
          ,[is_poison_message_handling_enabled] = NULL

    FROM   [sys].[partitions] [p]
    WHERE  [p].[object_id] = Object_Id('sys.sysxmitqueue');







GO
