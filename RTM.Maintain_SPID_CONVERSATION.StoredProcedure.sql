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

Versioned 4/11/2016 (BPC):
--Added updated transaction logic, including check for incoming transaction and transaction savepoint.

*/
    -- ==========================================================================================================


CREATE PROCEDURE [RTM].[Maintain_SPID_CONVERSATION] (
     @SessionID UNIQUEIDENTIFIER = NULL
    )
AS --EXEC [RTM].[Maintain_SPID_CONVERSATION]

--DECLARE @SessionID UNIQUEIDENTIFIER = NULL

    SET DEADLOCK_PRIORITY LOW
    SET LOCK_TIMEOUT 1000

    BEGIN

        DECLARE @DeleteCount BIGINT;

        DECLARE @TransactionCount INT;
        SET @TransactionCount = @@TRANCOUNT;


        DECLARE @convolist TABLE (
             [rownum] INT IDENTITY(1, 1)
            ,[ID] INT PRIMARY KEY CLUSTERED
            ,[SPID] INT NOT NULL
            ,[INITIATOR_SERVICE] VARCHAR(250) NOT NULL
            ,[TARGET_SERVICE] VARCHAR(250) NOT NULL
            ,[CONTRACT] sysname NOT NULL
            ,[CONVERSATION_HANDLE] UNIQUEIDENTIFIER NULL
            );

        INSERT INTO @convolist
                ( [ID]
                ,[SPID]
                ,[INITIATOR_SERVICE]
                ,[TARGET_SERVICE]
                ,[CONTRACT]
                ,[CONVERSATION_HANDLE] )
                SELECT
                        [sc].[ID]
                       ,[sc].[SPID]
                       ,[sc].[INITIATOR_SERVICE]
                       ,[sc].[TARGET_SERVICE]
                       ,[sc].[CONTRACT]
                       ,[sc].[CONVERSATION_HANDLE]
                    FROM
                        [RTM].[SPID_CONVERSATION] [sc] WITH ( READPAST )
                    LEFT JOIN [sys].[conversation_endpoints] [ce] WITH ( READPAST ) ON [sc].[CONVERSATION_HANDLE] = [ce].[conversation_handle] AND [ce].[state] IN ( 'CO', 'SO' )
                    WHERE
                        [ce].[conversation_handle] IS NULL;

        BEGIN TRY

            IF @TransactionCount = 0
                BEGIN TRANSACTION;
            ELSE
                SAVE TRANSACTION [SavePoint];

            DELETE
                    [sc]
                FROM
                    [RTM].[SPID_CONVERSATION] [sc]
                JOIN @convolist [c] ON [sc].[ID] = [c].[ID];

            SET @DeleteCount = @@ROWCOUNT;

            DECLARE @xml XML; 
            SET @xml = ( SELECT [Output] = 'No Conversations Ended'
                FOR
                         XML PATH );

            DECLARE @Source NVARCHAR(255) = OBJECT_NAME(@@PROCID);
            IF @SessionID IS NULL
                SET @SessionID = NEWID();

			DECLARE @Details NVARCHAR(255) 
				SET @Details = N'No records deleted from [RTM].[SPID_CONVERSATION]';

            IF @DeleteCount > 0
                BEGIN
                    
					
					SET @Details = N'Deleted ' + CAST(ISNULL(@DeleteCount, 0) AS NVARCHAR(10)) + ' records from [RTM].[SPID_CONVERSATION]';

                    SET @xml = ( SELECT * FROM @convolist [c]
                        FOR
                                 XML PATH );


                END;

		

            EXEC [RTM].[AddEvent]
                @Level = N'INFO'
               ,@Source = @Source
               ,@Details = @Details
               ,@IntResult = 1
               ,@SessionId = @SessionId
               ,@Message_Body = @xml; 

		--If there wasn't an initial transaction, commit the new transaction
            IF @TransactionCount = 0
                COMMIT TRANSACTION


        END TRY 
        BEGIN CATCH
		
       
            IF ( XACT_STATE() ) = -1
                BEGIN
                    
                    ROLLBACK TRANSACTION;
                    EXEC [RTM].[AddEvent]
                        @Level = N'WARNING'
                       ,@Source = N'[RTM].[Maintain_SPID_CONVERSATION]'
                       ,@Details = N'The transaction is in an uncommittable state. Rolling back transaction.'
                       ,@IntResult = 0
                       ,@SessionId = @SessionID
                       ,@Message_Body = @xml;
                END;

            IF ( XACT_STATE() ) = 1 AND @TransactionCount = 0
                BEGIN
                    
                    ROLLBACK TRANSACTION;
                    EXEC [RTM].[AddEvent]
                        @Level = N'WARNING'
                       ,@Source = N'[RTM].[Maintain_SPID_CONVERSATION]'
                       ,@Details = N'Rolling back current transaction.'
                       ,@IntResult = 0
                       ,@SessionId = @SessionID
                       ,@Message_Body = @xml;
                END;
							
            IF ( XACT_STATE() ) = 1 AND @TransactionCount > 0
                BEGIN
                  
                    ROLLBACK TRANSACTION [SavePoint]; 
                    EXEC [RTM].[AddEvent]
                        @Level = N'WARNING'
                       ,@Source = N'[RTM].[Maintain_SPID_CONVERSATION]'
                       ,@Details = N'Transaction rolled back to the Save Point'
                       ,@IntResult = 0
                       ,@SessionId = @SessionID
                       ,@Message_Body = @xml;
                END;

        END CATCH        

    END;                

GO
