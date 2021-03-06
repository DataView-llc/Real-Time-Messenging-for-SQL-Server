/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/
 -- =========================================================================================================
  /* 

Developed by DataView, LLC

Versioned 4/8/2016 (KjM):
--Add a check for intial transaction count, handle transaction commit/rollback in catch

Versioned 4/12/2016 (BPC):
--Check for transaction count when XACT_STATE() = -1. If transaction count = 0, rollback all, ELSE rollback to 
--savepoint transaction

Versioned 7/6/2016 (BPC):
--only using conversations not within N minutes (@Expiration_Minutes_delta) of expiration

Versioned 8/18/2016 (BPC/KjM):
--reduced calls to [RTM].[SPID_CONVERSATION] to 2 from 3. Pull the top ch from [RTM].[SPID_CONVERSATION], if
--it doesn't exist create it and return it. Everything done with (NOLOCK) to increase potential performance.
--Risk of dirty read reduce by expiration_delta variable and conversation cleanup procedure changes made previously.

*/
    -- ==========================================================================================================


CREATE PROCEDURE [RTM].[GetConversationHandleBySPID] (
	@InitiatorService VARCHAR(250)
   ,@TargetService VARCHAR(250)
   ,@Contract VARCHAR(250)
   ,@ch UNIQUEIDENTIFIER OUTPUT )
AS
	BEGIN

	--set lifespan in seconds (24 hours x 60 minutes x 60 seconds) X 4 days
		DECLARE @lifetime INT = ( 24 * 60 * 60 ) * 4;
		DECLARE @SessionID UNIQUEIDENTIFIER = NewId();
		DECLARE @RandomExecutionRate INT = 20000
		DECLARE @details NVARCHAR(255)
		DECLARE @TransactionCount INT;
		DECLARE @Expiration_Minutes_delta INT = 30
		SET @TransactionCount = @@TRANCOUNT;

		DECLARE @Expiration_delta DATETIME = DateAdd(MINUTE, @Expiration_Minutes_delta, GetUtcDate())

		BEGIN TRY
			IF @TransactionCount = 0
				BEGIN TRANSACTION;
			ELSE
				SAVE TRANSACTION [SavePoint];

			IF (
				 SELECT (Round ((Rand () * (@RandomExecutionRate - 1)), 0) + 1)
			   ) = 1
				BEGIN TRY
					BEGIN
						EXEC [RTM].[Maintain_SPID_CONVERSATION]
							@SessionID;
					END;
				END TRY 
				BEGIN CATCH
                    
					DECLARE @xml XML
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
									   ,[Xact_State] = Xact_State()
							   FOR
								 XML PATH
							   )
					
					IF Error_Number() = 1222
						EXEC [RTM].[AddEvent]
						@Level = N'WARNING'
					   ,@Source = N'[RTM].[GetConversationHandleBySPID]'
					   ,@Details = N'Timeout on [RTM].[Maintain_SPID_CONVERSATION]'
					   ,@IntResult = 0
					   ,@SessionId = @SessionID
					   ,@Message_Body = @xml;
					ELSE
						EXEC [RTM].[AddEvent]
						@Level = N'WARNING'
					   ,@Source = N'[RTM].[GetConversationHandleBySPID]'
					   ,@Details = N'Error on [RTM].[Maintain_SPID_CONVERSATION] FROM [RTM].[SPID_CONVERSATION]'
					   ,@IntResult = 0
					   ,@SessionId = @SessionID
					   ,@Message_Body = @xml;
					
				END CATCH;
                
				--just to be sure this is null before trying to populate it
			SET @ch = NULL 

		--Find a ch that is valid for at least N expiration minutes and return as @ch
			SELECT TOP 1
					@ch = [ce].[conversation_handle]
				FROM
					[RTM].[SPID_CONVERSATION] [sc] WITH ( NOLOCK )
				JOIN [sys].[conversation_endpoints] [ce] WITH ( NOLOCK ) ON [sc].[CONVERSATION_HANDLE] = [ce].[conversation_handle] AND
																			[ce].[state] IN ( 'CO', 'SO' )
				WHERE
					[sc].[SPID] = @@SPID AND
					[sc].[INITIATOR_SERVICE] = @InitiatorService AND
					[sc].[TARGET_SERVICE] = @TargetService AND
					[sc].[CONTRACT] = @Contract AND
					[ce].[lifetime] > @Expiration_delta 

			--if we don't find a ch, make one
			IF @ch IS NULL
				BEGIN
					BEGIN DIALOG CONVERSATION @ch
					FROM SERVICE @InitiatorService
					TO SERVICE @TargetService
					ON CONTRACT @Contract
					WITH ENCRYPTION = OFF, LIFETIME = @lifetime;

					INSERT [RTM].[SPID_CONVERSATION]
							( [SPID]
							,[INITIATOR_SERVICE]
							,[TARGET_SERVICE]
							,[CONTRACT]
							,[CONVERSATION_HANDLE]
							,[Modify_TS]
							,[Modify_ID] )
							SELECT
									@@SPID
								   ,@InitiatorService
								   ,@TargetService
								   ,@Contract
								   ,@ch
								   ,GetDate()
								   ,SUser_Name();


					IF (
						 SELECT (Round ((Rand () * (10 - 1)), 0) + 1)
					   ) = 1
						BEGIN
							BEGIN TRY
								EXECUTE [RTM].[Cleanup_Unusable_Conversations]
									@SessionID;
							END TRY 
							BEGIN CATCH
                                
								EXEC [RTM].[AddEvent]
									@Level = N'WARNING'
								   ,@Source = N'[RTM].[GetConversationHandleBySPID]'
								   ,@Details = N'Deadlock on [RTM].[Cleanup_Unusable_Conversations]'
								   ,@IntResult = 0
								   ,@SessionId = @SessionID
								   ,@Message_Body = NULL;

							END CATCH;
						END;
				END;

			--If there wasn't an initial transaction, commit the new transaction
			IF @TransactionCount = 0
				COMMIT TRANSACTION;

			RETURN


		END TRY

		BEGIN CATCH
            
			DECLARE @ErrorNumber INT				= Error_Number();
			DECLARE @ErrorSource NVARCHAR(255)		= Object_Name(@@PROCID);
			DECLARE @ErrorLine INT					= Error_Line();
			DECLARE @ErrorMessage NVARCHAR(4000)	= Error_Message();
			DECLARE @ErrorSeverity INT				= Error_Severity();
			DECLARE @ErrorState INT					= Error_State();
			DECLARE @ErrorUser sysname				= SUser_SName();

			DECLARE @xml_error_details XML 

			SET @xml_error_details = (
									   SELECT
											[InitiatorService] = @InitiatorService
										   ,[TargetService] = @TargetService
										   ,[Contract] = @Contract
										   ,[TransactionCount] = @TransactionCount
									 FOR
									   XML PATH
									 )

			EXEC [RTM].[AddEvent]
				@Level = N'WARNING'
			   ,@Source = N'[RTM].[GetConversationHandleBySPID]'
			   ,@Details = @details
			   ,@IntResult = 0
			   ,@SessionId = @SessionID
			   ,@Message_Body = @xml_error_details;

			IF ( Xact_State() ) = -1
				BEGIN



					IF @TransactionCount = 0
						BEGIN
							ROLLBACK TRANSACTION;
							SET @details = N'The transaction is in an uncommittable state. Rolling back transaction.'
						END
                        
					ELSE
						BEGIN
							ROLLBACK TRANSACTION [SavePoint]
							SET @details = N'The transaction is in an uncommittable state. Rolling back transaction to Save Point.'
						END
                      

				END;

			IF ( Xact_State() ) = 1 AND
				@TransactionCount = 0
				BEGIN
                    
					ROLLBACK TRANSACTION;
					EXEC [RTM].[AddEvent]
						@Level = N'WARNING'
					   ,@Source = N'[RTM].[GetConversationHandleBySPID]'
					   ,@Details = N'Rolling back current transaction.'
					   ,@IntResult = 0
					   ,@SessionId = @SessionID
					   ,@Message_Body = @xml_error_details;
				END;
							
			IF ( Xact_State() ) = 1 AND
				@TransactionCount > 0
				BEGIN
                  
					ROLLBACK TRANSACTION [SavePoint]; 
					EXEC [RTM].[AddEvent]
						@Level = N'WARNING'
					   ,@Source = N'[RTM].[GetConversationHandleBySPID]'
					   ,@Details = N'Transaction rolled back to the Save Point'
					   ,@IntResult = 0
					   ,@SessionId = @SessionID
					   ,@Message_Body = @xml_error_details;
				END;


			INSERT INTO [RTM].[Process_M204_ErrorLog]
					( [Error_Number]
					,[Error_Source]
					,[Error_Line]
					,[Error_Message]
					,[Error_Severity]
					,[Error_State]
					,[Error_Date]
					,[Error_User_System]
					,[Message_Body]
					,[Source_Process] )
					SELECT
							@ErrorNumber
						   ,@ErrorSource
						   ,@ErrorLine
						   ,@ErrorMessage
						   ,@ErrorSeverity
						   ,@ErrorState
						   ,GetDate()
						   ,@ErrorUser
						   ,@xml_error_details
						   ,'RTM';

		

			SET @ch = NULL;
		END CATCH;

	END;




GO
