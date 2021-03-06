/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

 -- =========================================================================================================
  /* 

Developed by DataView, LLC

Versioned 4/7/2016 (BPC):
--To try and reduce locking, added LOCK_TIMEOUT and READPAST hints. This code should run often and clear out locked 
--records on the next run
--added error handling and rollback on error

Versioned 4/11/2016 (BPC):
--Added updated transaction logic, including check for incoming transaction and transaction savepoint.

Versioned 5/27/2016 (KjM):
--Added check, when retrieving errored conversation handles, against sys.transmission_queue to ensure 
--we don't clean up conversations that still have associated messages caught in the sys.transmission_queue.

Versioned 7/6/2016 (BPC):
--Added columns [far_service] ,[state] ,[receive_sequence] ,[send_sequence], [lifetime] to 
	@convolist in order to expand information written to sys.Event
--Added logic to leave ERROR conversations for set time period after error by adding ce.[lifetime] >= DATEADD(MINUTE, @cleanup_lag_minutes , ce.[lifetime])
	to where clause of @convolist select. This should help to avoid ending conversations in error and losing messages.

Versioned 7/18/2016 (BPC):
--corrected logic from previous change where conversations were not being ended. Corrected logic uses GETUTCDATE() >= DATEADD(MINUTE, @cleanup_lag_minutes, [ce].[lifetime])
--to determine if a conversation in ER has waited long enough to end. 

Versioned 11/20/2017 (BPC):
--removed print statement when catching 8426 error (convo not found) 
*/
    -- ==========================================================================================================


CREATE PROCEDURE [RTM].[Cleanup_Unusable_Conversations] (
	@SessionID UNIQUEIDENTIFIER = NULL )
AS
	BEGIN

		SET LOCK_TIMEOUT 2000;


	--exec [RTM].[Cleanup_Unusable_Conversations]
	
		IF @SessionID IS NULL
			SET @SessionID = NewId();

		DECLARE @cleanup_lag_minutes INT = 360 --6 hours
		DECLARE @cleanup_lag_TS DATETIME = DateAdd(MINUTE, @cleanup_lag_minutes, GetUtcDate())



		DECLARE @convolist TABLE (
			[rownum] INT IDENTITY(1, 1)
						 NOT NULL
		   ,[conversation_handle] UNIQUEIDENTIFIER NOT NULL
		   ,[far_service] NVARCHAR(256) NULL
		   ,[state] CHAR(2) NULL
		   ,[receive_sequence] BIGINT NULL
		   ,[send_sequence] BIGINT NULL
		   ,[lifetime] DATETIME NULL );





		DECLARE @maxrow INT = 1;
		DECLARE @count INT = 1;
		DECLARE @convo UNIQUEIDENTIFIER;
		DECLARE @xml XML;
		DECLARE @TransactionCount INT;
		SET @TransactionCount = @@TRANCOUNT;
		DECLARE @procname NVARCHAR(255) = Object_Name(@@PROCID);

		BEGIN TRY
			IF @TransactionCount = 0
				BEGIN TRANSACTION;
			ELSE
				SAVE TRANSACTION [SavePoint];

			INSERT INTO @convolist
					SELECT TOP 500
							[ce].[conversation_handle]
						   ,[ce].[far_service]
						   ,[ce].[state]
						   ,[ce].[receive_sequence]
						   ,[ce].[send_sequence]
						   ,[ce].[lifetime]
						FROM
							[sys].[conversation_endpoints] [ce] WITH ( READPAST )
						WHERE
							[ce].[state] IN ( 'ER', 'DI', 'CD', 'DO' ) AND
							GetUtcDate() >= DateAdd(MINUTE, @cleanup_lag_minutes, [ce].[lifetime]) AND
							NOT EXISTS ( SELECT
												1
											FROM
												[sys].[transmission_queue] AS [TQ] WITH ( NOLOCK )
											WHERE
												[ce].[conversation_handle] = [TQ].[conversation_handle] );

			SELECT
					@maxrow = Max([c].[rownum])
				FROM
					@convolist [c];

	--SELECT @maxrow


			WHILE @maxrow >= @count
				BEGIN
    
					SELECT
							@convo = [c].[conversation_handle]
						FROM
							@convolist [c]
						WHERE
							[c].[rownum] = @count;

	--SELECT @convo
					BEGIN TRY
						END CONVERSATION @convo; 
					END TRY
					BEGIN CATCH
						IF Error_Number() = 8426
							CONTINUE
						ELSE
							THROW;
					END CATCH
                    

					SET @count = @count + 1;
				END;
		
			SET @xml = (
						 SELECT [Output] = 'No Conversations Ended'
					   FOR
						 XML PATH
					   );

			IF @maxrow >= 1
				BEGIN
					SET @xml = (
								 SELECT *, [Cleanup_TS] = @cleanup_lag_TS FROM @convolist [c]
							   FOR
								 XML PATH
							   );
				END;

			

			--If there wasn't an initial transaction, commit the new transaction
			IF @TransactionCount = 0
				COMMIT TRANSACTION;

			EXEC [RTM].[AddEvent]
				@Level = N'INFO'
			   ,@Source = @procname
			   ,@Details = N'Cleaning up unusable broker conversations. Success.'
			   ,@IntResult = 1
			   ,@SessionId = @SessionID
			   ,@Message_Body = @xml;	


		END TRY 
		BEGIN CATCH
		
		
		
			SET @xml = (
						 SELECT
								[Error_Number] = Error_Number()
							   ,[Object_Name] = Object_Name(@@PROCID)
							   ,[Error_Line] = Error_Line()
							   ,[Error_Message] = Error_Message()
							   ,[Error_Severity] = Error_Severity()
							   ,[Error_State] = Error_State()
							   ,[GetDate] = GetDate()
							   ,[SUser_SName] = SUser_SName()
							   ,[SPID] = @@SPID
							   ,[TranCount] = @@TRANCOUNT
					   FOR
						 XML PATH
					   )

			EXEC [RTM].[AddEvent]
				@Level = N'WARNING'
			   ,@Source = @procname
			   ,@Details = N'Cleaning up unusable broker conversations. Error.'
			   ,@IntResult = 0
			   ,@SessionId = @SessionID
			   ,@Message_Body = @xml;	


			IF ( Xact_State() ) = -1
				BEGIN
                    
					ROLLBACK TRANSACTION;
					EXEC [RTM].[AddEvent]
						@Level = N'WARNING'
					   ,@Source = N'[RTM].[Cleanup_Unusable_Conversations]'
					   ,@Details = N'The transaction is in an uncommittable state. Rolling back transaction.'
					   ,@IntResult = 0
					   ,@SessionId = @SessionID
					   ,@Message_Body = @xml;
				END;

			IF ( Xact_State() ) = 1 AND
				@TransactionCount = 0
				BEGIN
                    
					ROLLBACK TRANSACTION;
					EXEC [RTM].[AddEvent]
						@Level = N'WARNING'
					   ,@Source = N'[RTM].[Cleanup_Unusable_Conversations]'
					   ,@Details = N'Rolling back current transaction.'
					   ,@IntResult = 0
					   ,@SessionId = @SessionID
					   ,@Message_Body = @xml;
				END;
							
			IF ( Xact_State() ) = 1 AND
				@TransactionCount > 0
				BEGIN
                  
					ROLLBACK TRANSACTION [SavePoint]; 
					EXEC [RTM].[AddEvent]
						@Level = N'WARNING'
					   ,@Source = N'[RTM].[Cleanup_Unusable_Conversations]'
					   ,@Details = N'Transaction rolled back to the Save Point'
					   ,@IntResult = 0
					   ,@SessionId = @SessionID
					   ,@Message_Body = @xml;
				END;


		END CATCH;   
	END; 
GO
