USE [Jeunesse_Back]
GO
-- ========== --
--   tables   --
-- ========== -- 
IF OBJECT_ID(N'dbo.SDN_Match_Log', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_Match_Log;
GO
CREATE TABLE dbo.SDN_Match_Log(SDN_Match_LogPK INT PRIMARY KEY IDENTITY(1,1)
                             ,Match_Type       VARCHAR(15) NOT NULL
                             ,MainFK           INT NOT NULL
                             ,sdnFK            INT NOT NULL
                             ,sdn_addFK        INT
                             ,DateEntered      DATE NOT NULL);

GO 
IF OBJECT_ID(N'dbo.SDN_BlockProfiles_Log', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_BlockProfiles_Log;
GO
CREATE TABLE dbo.SDN_BlockProfiles_Log(SDN_BlockProfiles_LogPK INT PRIMARY KEY IDENTITY(1,1)
                                     ,MainFK                 INT NOT NULL
                                     ,Blocked                BIT NOT NULL
                                     ,EnteredMainFK          INT NOT NULL
                                     ,Notes                  VARCHAR(1000)
                                     ,DateEntered            DATETIME NOT NULL);
GO
IF OBJECT_ID(N'dbo.SDN_MainProfile_new', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_MainProfile_new;
GO
CREATE TABLE [dbo].[SDN_MainProfile_new] ( [SDN_MainProfile_newPK] INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
                                          ,[MainFK]                INT NOT NULL
                                          ,[SiteURL]               VARCHAR(50)
                                          ,[fname]                 NVARCHAR(50)
                                          ,[lname]                 NVARCHAR(50)
                                          ,[country]               VARCHAR(50)
                                          ,[city]                  NVARCHAR(50)
                                          ,[address1]              NVARCHAR(250)
                                          ,[address2]              NVARCHAR(250)
                                          ,[address3]              NVARCHAR(250)
                                          ,[country2]              VARCHAR(2)
                                          ,[city2]                 NVARCHAR(50)
                                          ,[shipaddr1]             NVARCHAR(250)
                                          ,[shipaddr2]             NVARCHAR(250)
                                          ,[shipaddr3]             NVARCHAR(250));
GO
-- ========== --
--   sprocs   --
-- ========== --
IF OBJECT_ID(N'dbo.sp_SDN_GetProfileCurrentStatus', N'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_SDN_GetProfileCurrentStatus AS BEGIN END')
GO
--=======================================================================
-- YYYYMMDD_####  Author                    Description
-- 20200713_0001  Vasyl Yeleiko (VY)        Created. (Task #20253)
-- ======================================================================
ALTER PROCEDURE dbo.sp_SDN_GetProfileCurrentStatus 
                        @MainFK INT -- User's MainPK
AS
BEGIN
    SET NOCOUNT ON
    SELECT TOP (1) 
           Blocked 
        FROM Jeunesse_Back.dbo.SDN_BlockProfiles_Log
        WHERE MainFK  = @MainFK
        ORDER BY DateEntered DESC
END
GO

IF OBJECT_ID(N'dbo.sp_SDN_SetProfileCurrentStatus', N'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_SDN_SetProfileCurrentStatus AS BEGIN END')
GO
--=======================================================================
-- YYYYMMDD_####  Author                    Description
-- 20200713_0001  Vasyl Yeleiko (VY)        Created. (Task #20253)
-- ======================================================================
ALTER PROCEDURE dbo.sp_SDN_SetProfileCurrentStatus 
                        @MainFK        INT NOT NULL   -- MainPK of user which nedd to be blocked or unblocked
                       ,@Blocked       BIT NOT NULL   -- Action Block(true) or Unblock(false)
                       ,@EnteredMainFK INT NOT NULL   -- Who made this change(MAinPK of Admin)
                       ,@Notes         VARCHAR(1000)                             
AS
BEGIN
    SET NOCOUNT ON 
    DECLARE  @DateEntered DATETIME = GETDATE()

    INSERT INTO dbo.SDN_BlockProfiles_Log ( MainFK, Blocked, EnteredMainFK, Notes, DateEntered )
    VALUES (@MainFK, @Blocked, @EnteredMainFK, Notes, @DateEntered)
 END
GO

IF OBJECT_ID(N'dbo.sp_SDN_UpsertSDN_MainProfile_new', N'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_SDN_UpsertSDN_MainProfile_new AS BEGIN RETURN; END')
GO
--=====================================================================================================
-- Purpose: upsert dbo.SDN_MainProfile_new
--=====================================================================================================
-- YYYY-MM-DD_####  Author                 Description
-- 2020-07-09_0001  Vasyl Yeleiko (VY)     Created.(TFS# #####)
--===================================================================================================== 
ALTER PROCEDURE dbo.sp_SDN_UpsertSDN_MainProfile_new
                              @MainFK    INT            -- MainPK for new or updated user 
                             ,@SiteURL   VARCHAR(50)    -- new or updated SiteURL
                             ,@fname     NVARCHAR(50)   -- new or updated fname
                             ,@lname     NVARCHAR(50)   -- new or updated lname
                             ,@country   VARCHAR(50)    -- new or updated country
                             ,@city      NVARCHAR(50)   -- new or updated city
                             ,@address1  NVARCHAR(250)  -- new or updated address1
                             ,@address2  NVARCHAR(250)  -- new or updated address2
                             ,@address3  NVARCHAR(250)  -- new or updated address3
                             ,@country2  VARCHAR(2)     -- new or updated country2
                             ,@city2     NVARCHAR(50)   -- new or updated city2
                             ,@shipaddr1 NVARCHAR(250)  -- new or updated shipaddr1
                             ,@shipaddr2 NVARCHAR(250)  -- new or updated shipaddr2
                             ,@shipaddr3 NVARCHAR(250)  -- new or updated shipaddr3
AS
BEGIN
    SET NOCOUNT ON;
    --Normalization, avoid duplicates
    SET @shipaddr3 = IIF(@shipaddr3 = @shipaddr2 OR @shipaddr3 = @shipaddr1,'',@shipaddr3)
    SET @shipaddr2 = IIF(@shipaddr2 = @shipaddr3 OR @shipaddr2 = @shipaddr1,'',@shipaddr2)
    SET @shipaddr1 = IIF(@shipaddr1 = @shipaddr2 OR @shipaddr3 = @shipaddr1,'',@shipaddr1)
    SET @shipaddr3 = IIF((@shipaddr3 = @address3 OR @shipaddr3 = @address2 OR @shipaddr3 = @address1) AND @country = @country2 AND @city = @city2,'',@shipaddr3)
    SET @shipaddr2 = IIF((@shipaddr2 = @address3 OR @shipaddr2 = @address2 OR @shipaddr2 = @address1) AND @country = @country2 AND @city = @city2,'',@shipaddr2)
    SET @shipaddr1 = IIF((@shipaddr1 = @address3 OR @shipaddr1 = @address2 OR @shipaddr1 = @address1) AND @country = @country2 AND @city = @city2,'',@shipaddr1)
    SET @country2 = IIF(@shipaddr1 = @shipaddr2 AND @shipaddr1 = @shipaddr3,'',@country2)
    SET @city2 = IIF(@shipaddr1 = @shipaddr2 AND @shipaddr1 = @shipaddr3,'',@city2)
    SET @address3 = IIF(@address3 = @address2 OR @address3 = @address1,'',@address3)
    SET @address2 = IIF(@address3 = @address2 OR @address2 = @address1,'',@address2)

    --upsert
    IF EXISTS(SELECT 1 FROM Jeunesse_Back.dbo.SDN_MainProfile_new WHERE MainFK = @MainFK)
    BEGIN 
        UPDATE dbo.SDN_MainProfile_new
            SET SiteURL = @SiteURL
               ,fname = @fname    
               ,lname = @lname    
               ,country = @country  
               ,city = @city     
               ,address1 = @address1 
               ,address2 = @address2 
               ,address3 = @address3 
               ,country2 = @country2 
               ,city2 = @city2    
               ,shipaddr1 = @shipaddr1
               ,shipaddr2 = @shipaddr2
               ,shipaddr3 = @shipaddr3
            WHERE MainFK = @MainFK
    END
    ELSE 
    BEGIN
    INSERT INTO dbo.SDN_MainProfile_new ( MainFK, SiteURL, fname, lname, country, city, address1, address2, address3, country2, city2, shipaddr1, shipaddr2, shipaddr3 )
    VALUES ( @MainFK, @SiteURL, @fname, @lname, @country, @city, @address1, @address2, @address3, @country2, @city2, @shipaddr1, @shipaddr2, @shipaddr3 )
    END  
END 