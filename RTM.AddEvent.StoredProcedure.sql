/****************************************************************************************************

Developed by DataView, LLC. All rights reserved. 

Licensed under GNU LESSER GENERAL PUBLIC LICENSE Version 3

Real Time Messenging Software for SQL Server


***************************************************************************************************/

CREATE PROCEDURE [RTM].[AddEvent]
    (
		@Level NVARCHAR(50) = 'INFO',
		@Source NVARCHAR(4000) = NULL,
		@Details NVARCHAR(4000) = NULL,
		@IntResult INT = NULL,
		@SessionId VARCHAR(255) = NULL,
		@Message_Body XML = NULL 
   )
AS
BEGIN
	INSERT INTO rtm.sysEvent (Level, Source, Details, IntResult, SessionId, [Message_body]) 
		SELECT @Level, @Source, @Details, @IntResult, CAST(@SessionId AS UNIQUEIDENTIFIER), @Message_Body

	--IF (dbo.IsDebugEnabled() > 0)
	--	EXEC dbo.AddDebugEvent  @Source, @Details, @IntResult, @SessionId

	--IF (@Level = 'ERROR' AND dbo.IsDebugEnabled() > 0)
	--BEGIN
	--	DECLARE @HTMLSource nvarchar(MAX)

	--	SET @HTMLSource = '<BR/>Error Recorded at: ' + CAST(GETDATE() AS varchar(20)) +
	--	'<table border="1">' +
	--	'<tr bgcolor=#C0C0C0><th>Source</th><th>Error</th><th>Error #</th><th>Session Id</th></tr><tr><td>' +
	--	@Source + '</td><td>' + @Details + '</td><td>' + CAST(@IntResult AS varchar(255)) + '</td><td>' + @SessionID + 
	--			'</td></tr>' +
	--	'</table>'

	--	EXECUTE [dbo].[SendEmail] 'Budget Template Upload Error', @HTMLSource
	--END
END












GO
