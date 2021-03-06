/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE PROCEDURE [RTM].[SendMessageToAnyService] (
	@FromService sysname
   ,@ToService sysname
   ,@Contract sysname
   ,@MessageType sysname
   ,@MessageBody XML )
AS
	BEGIN

			--Find the starting state of XACT_ABORT
		DECLARE @XACT_ABORT BIT = 0;  
		IF ( ( 16384 & @@OPTIONS ) = 16384 )
			SET @XACT_ABORT = 1;  
		
		--turn XACT_ABORT off to prevent transactions from rolling back automatically
		SET XACT_ABORT OFF;



		DECLARE @ch UNIQUEIDENTIFIER;
		DECLARE @details NVARCHAR(255)
		DECLARE @GetCHSuccess BIT = 1;
		DECLARE @TransactionCount INT;
		SET @TransactionCount = @@TRANCOUNT;

		BEGIN TRY 
			IF @TransactionCount = 0
				BEGIN TRANSACTION;
			ELSE
				SAVE TRANSACTION [SavePoint];

            
		--obtain the latest open conversation handle 
			EXECUTE [RTM].[GetConversationHandleBySPID]
				@InitiatorService = @FromService
			   ,@TargetService = @ToService
			   ,@Contract = @Contract
			   ,@ch = @ch OUTPUT;

			IF ( @ch IS NULL )
				BEGIN
					SET @GetCHSuccess = 0;

					BEGIN DIALOG CONVERSATION @ch
					FROM SERVICE @FromService
					TO SERVICE @ToService
					ON CONTRACT @Contract
					WITH ENCRYPTION = OFF;
				END;


			--If there wasn't an initial transaction, commit the new transaction
			IF @TransactionCount = 0
				COMMIT TRANSACTION;

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
											[FromService] = @FromService
										   ,[ToService] = @ToService
										   ,[Contract] = @Contract
										   ,[Error_Number] = Error_Number()
										   ,[Object_Name] = Object_Name(@@PROCID)
										   ,[Error_Line] = Error_Line()
										   ,[Error_Message] = Error_Message()
										   ,[Error_Severity] = Error_Severity()
										   ,[Error_State] = Error_State()
										   ,[GetDate] = GetDate()
										   ,[SUser_SName] = SUser_SName()
										   ,[SPID] = @@SPID
										   ,[TranCount] = @@TRANCOUNT
										   ,[initialTranCount] = @TransactionCount
									 FOR
									   XML PATH
									 )




--			IF @@TRANCOUNT > 0
			BEGIN
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

						EXEC [RTM].[AddEvent]
							@Level = N'WARNING'
						   ,@Source = N'[RTM].[SendMessageToAnyService]'
						   ,@Details = @details
						   ,@IntResult = 0
						   ,@SessionId = NULL
						   ,@Message_Body = @xml_error_details;
					END;

				IF ( Xact_State() ) = 1 AND
					@TransactionCount = 0
					BEGIN
                    
						ROLLBACK TRANSACTION;
						EXEC [RTM].[AddEvent]
							@Level = N'WARNING'
						   ,@Source = N'[RTM].[SendMessageToAnyService]'
						   ,@Details = N'Rolling back current transaction.'
						   ,@IntResult = 0
						   ,@SessionId = NULL
						   ,@Message_Body = @xml_error_details;
					END;
							
				IF ( Xact_State() ) = 1 AND
					@TransactionCount > 0
					BEGIN
                  
						ROLLBACK TRANSACTION [SavePoint]; 
						EXEC [RTM].[AddEvent]
							@Level = N'WARNING'
						   ,@Source = N'[RTM].[SendMessageToAnyService]'
						   ,@Details = N'Transaction rolled back to the Save Point'
						   ,@IntResult = 0
						   ,@SessionId = NULL
						   ,@Message_Body = @xml_error_details;
					END;
			END


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
						   ,@MessageBody
						   ,'RTM';
                       
			THROW; 

		END CATCH
    
	--manage send as it's own try block
		BEGIN TRY
		
			SEND ON CONVERSATION @ch MESSAGE TYPE @MessageType (@MessageBody);
			

			IF @GetCHSuccess = 0
				BEGIN
					END CONVERSATION @ch;
				END;

		END TRY
		
		BEGIN CATCH
			SET @ErrorNumber = Error_Number();
			SET @ErrorSource = Object_Name(@@PROCID);
			SET @ErrorLine = Error_Line();
			SET @ErrorMessage = Error_Message();
			SET @ErrorSeverity = Error_Severity();
			SET @ErrorState = Error_State();
			SET @ErrorUser = SUser_SName();

			SET @xml_error_details = (
									   SELECT
											[FromService] = @FromService
										   ,[ToService] = @ToService
										   ,[Contract] = @Contract
										   ,[Error_Number] = Error_Number()
										   ,[Object_Name] = Object_Name(@@PROCID)
										   ,[Error_Line] = Error_Line()
										   ,[Error_Message] = Error_Message()
										   ,[Error_Severity] = Error_Severity()
										   ,[Error_State] = Error_State()
										   ,[GetDate] = GetDate()
										   ,[SUser_SName] = SUser_SName()
										   ,[SPID] = @@SPID
										   ,[TranCount] = @@TRANCOUNT
										   ,[initialTranCount] = @TransactionCount
									 FOR
									   XML PATH
									 )
		
			EXEC [RTM].[AddEvent]
				@Level = N'WARNING'
			   ,@Source = N'[RTM].[SendMessageToAnyService]'
			   ,@Details = N'Send on conversation error'
			   ,@IntResult = 0
			   ,@SessionId = NULL
			   ,@Message_Body = @xml_error_details;

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
						   ,@MessageBody
						   ,'RTM';

			THROW;

		END CATCH


		IF @XACT_ABORT = 1
			BEGIN
				SET XACT_ABORT ON;
			END
	END;


GO
