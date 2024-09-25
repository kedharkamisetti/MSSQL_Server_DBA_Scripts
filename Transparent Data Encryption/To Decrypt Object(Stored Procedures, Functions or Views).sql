USE <DBName>
go
DECLARE @objid INT,@objtype NVARCHAR(50),@objtypicalstm NVARCHAR(4000),@objencrypted BIT
DECLARE @objschemaname nvarchar(255), @objname nvarchar(255)
set @objschemaname='<Schema_name>'
set @objname='<object_name>'
SELECT TOP 1 @objid=o,@objname = n,@objtype = t,@objtypicalstm=s,@objencrypted = (SELECT ([encrypted]) FROM syscomments WHERE [id] = x.o and colid = 1)
FROM
(
SELECT object_id o, name n,
CASE WHEN [type] = 'P' THEN N'PROCEDURE'
WHEN [type] = 'V' THEN 'VIEW'
WHEN [type] IN ('FN','TF','IF') THEN N'FUNCTION'
ELSE [type]
END t,
CASE WHEN [type] = 'P' THEN N'WITH ENCRYPTION AS'
WHEN [type] = 'V' THEN N'WITH ENCRYPTION AS SELECT 123 ABC'
WHEN [type] IN ('FN','TF','IF') THEN N' () RETURNS INT WITH ENCRYPTION AS BEGIN RETURN 1 END'
ELSE [type]
END s
FROM sys.all_objects WHERE [type] NOT IN ('S','U','PK','F','D','SQ','IT','X','PC','FS','AF')
AND name = @objname AND (SCHEMA_NAME([schema_id]) = COALESCE(@objschemaname,'dbo'))
) x
SET NOCOUNT ON
IF @objencrypted <> 0
BEGIN
IF EXISTS
(
SELECT * FROM sys.dm_exec_connections ec JOIN sys.endpoints e
on (ec.[endpoint_id]=e.[endpoint_id])
WHERE e.[name]='Dedicated Admin Connection'
AND ec.[session_id] = @@SPID
)
    BEGIN
        DECLARE @ChunkNumber INT,@ChunkPiece NVARCHAR(MAX),@CompareChunksAtPosition INT,@DummyChunk NVARCHAR(MAX),@DummyObject VARBINARY(MAX),@EncryptedChunk NVARCHAR(MAX),@EncryptedObject VARBINARY(MAX),@p INT,@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX),@QueryForDummyObject NVARCHAR(MAX),@ReplacementText NVARCHAR(4000)
        SELECT @EncryptedObject = [imageval] FROM [sys].[sysobjvalues] WHERE [objid] = @objid AND [valclass] = 1
            BEGIN TRANSACTION
            SET @p = 1
            SET @p1= N'ALTER'+SPACE(1)+@objtype+SPACE(1)+ISNULL((@objschemaname+'.'),'')+@objname +SPACE(1)+@objtypicalstm;
            SET @p1=@p1+REPLICATE('-',4000-LEN(@p1))
            SET @p2 = REPLICATE('-',8000)
            SET @QueryForDummyObject = N'EXEC(@p1'
                WHILE @p <=CEILING(DATALENGTH(@EncryptedObject) / 8000.0)
                BEGIN
                SET @QueryForDummyObject=@QueryForDummyObject+N'+@f'
                SET @p =@p +1
                END
            SET @QueryForDummyObject=@QueryForDummyObject+')'
            EXEC sp_executesql @QueryForDummyObject,N'@p1 NVARCHAR(4000),@f VARCHAR(8000)',@p1=@p1,@f=@p2
            SET @DummyObject=(SELECT [imageval] FROM [sys].[sysobjvalues] WHERE [objid] = @objid and [valclass] = 1)
            ROLLBACK TRANSACTION
            SET @ChunkNumber=1
            WHILE @ChunkNumber<=CEILING(DATALENGTH(@EncryptedObject) / 8000.0)
            BEGIN
            SELECT @EncryptedChunk = SUBSTRING(@EncryptedObject, (@ChunkNumber - 1) * 8000 + 1, 8000)
            SELECT @DummyChunk = SUBSTRING(@DummyObject, (@ChunkNumber - 1) * 8000 + 1, 8000)
                IF @ChunkNumber=1
                BEGIN
                SET @ReplacementText=N'CREATE'+SPACE(1)+@objtype+SPACE(1)+ISNULL((@objschemaname+'.'),'')+@objname +SPACE(1)+@objtypicalstm+REPLICATE('-',4000)
                END
                ELSE
                BEGIN
                SET @ReplacementText=REPLICATE('-', 4000)
                END
            SET @ChunkPiece = REPLICATE(N'A', (DATALENGTH(@EncryptedChunk) / 2))
            SET @CompareChunksAtPosition=1
            WHILE @CompareChunksAtPosition<=DATALENGTH(@EncryptedChunk)/2
                BEGIN
                SET @ChunkPiece = STUFF(@ChunkPiece, @CompareChunksAtPosition, 1, NCHAR(UNICODE(SUBSTRING(@EncryptedChunk, @CompareChunksAtPosition, 1)) ^                (UNICODE(SUBSTRING(@ReplacementText, @CompareChunksAtPosition, 1)) ^ UNICODE(SUBSTRING(@DummyChunk, @CompareChunksAtPosition, 1)))))
                SET @CompareChunksAtPosition=@CompareChunksAtPosition+1
                END
            PRINT @ChunkPiece
            SET @ChunkNumber=@ChunkNumber+1
            END
        END
        ELSE
        BEGIN
            PRINT 'Use a DAC Connection'
        END
    END
ELSE
BEGIN
    PRINT 'Object not encrypted or not found'
END
SET QUOTED_IDENTIFIER OFF
GO