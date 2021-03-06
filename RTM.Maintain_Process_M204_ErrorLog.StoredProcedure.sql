/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/


CREATE PROCEDURE [RTM].[Maintain_Process_M204_ErrorLog] ( @hours INT = 504, @SessionID UNIQUEIDENTIFIER = NULL  )
    WITH EXECUTE AS OWNER
AS 

--EXEC [RTM].[Maintain_Process_M204_ErrorLog]

    BEGIN


        DECLARE @dt DATETIME2;
		DECLARE @DeleteCount BIGINT

        SELECT
                @dt = DATEADD(HOUR, @hours * -1, SYSDATETIME());

        DELETE FROM
                [RTM].[Process_M204_ErrorLog]
            WHERE
                [Error_Date] <= @dt;
		
		SET @DeleteCount = @@ROWCOUNT

		DECLARE @Details NVARCHAR(255) = N'Deleted '+CAST(ISNULL(@DeleteCount,0) AS NVARCHAR(10))+' log records from [RTM].[Process_M204_ErrorLog] older than ' + CAST(@hours AS NVARCHAR(5)) + N' hours'

		DECLARE @Source NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		IF @SessionID IS NULL set @SessionID  = NEWID();

		EXEC [RTM].[AddEvent]
		    @Level = N'INFO'
		   ,@Source = @Source
		   ,@Details = @Details
		   ,@IntResult = 1
		   ,@SessionId = @SessionID
		   ,@Message_Body = NULL 

	

    END;



GO
