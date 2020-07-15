USE [J_Reporting]
GO
-- ========== --
--   tables   --
-- ========== --
IF OBJECT_ID(N'dbo.SDN_MainProfile', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_MainProfile;
GO
CREATE TABLE [dbo].[SDN_MainProfile] ( [SDN_MainProfilePK]   INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
                                      ,[MainFK]              INT NOT NULL
                                      ,[SiteURL]             VARCHAR(50)
                                      ,[fname]               NVARCHAR(50)
                                      ,[lname]               NVARCHAR(50)
                                      ,[country]             VARCHAR(50)
                                      ,[city]                NVARCHAR(50)
                                      ,[address1]            NVARCHAR(250)
                                      ,[address2]            NVARCHAR(250)
                                      ,[address3]            NVARCHAR(250)
                                      ,[country2]            VARCHAR(2)
                                      ,[city2]               NVARCHAR(50)
                                      ,[shipaddr1]           NVARCHAR(250)
                                      ,[shipaddr2]           NVARCHAR(250)
                                      ,[shipaddr3]           NVARCHAR(250)
                                      ,[Tfname]              NVARCHAR(50)
                                      ,[Tlname]              NVARCHAR(50)
                                      ,[Tcity]               NVARCHAR(50)
                                      ,[Taddress1]           NVARCHAR(250)
                                      ,[Taddress2]           NVARCHAR(250)
                                      ,[Taddress3]           NVARCHAR(250)
                                      ,[Tcity2]              NVARCHAR(50)
                                      ,[Tshipaddr1]          NVARCHAR(250)
                                      ,[Tshipaddr2]          NVARCHAR(250)
                                      ,[Tshipaddr3]          NVARCHAR(250)
                                      ,[NewOne]              BIT );
GO

IF OBJECT_ID(N'dbo.SDN_MainProfile_Split', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_MainProfile_Split;
GO
CREATE TABLE [dbo].[SDN_MainProfile_Split] ( [SDN_MainProfile_SplitPK] INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
                                               ,[MainFK]                 INT NOT NULL
                                               ,[SplitName]              VARCHAR(250)
                                               ,[SplitAddress]           VARCHAR(250)
                                               ,[SplitShipAddress]       VARCHAR(250) );
GO

CREATE NONCLUSTERED INDEX [IDX_SDN_MainProfile_Split_MainFK_Includes] ON [dbo].[SDN_MainProfile_Split] ([MainFK])
INCLUDE ([SplitName],[SplitAddress],[SplitShipAddress])
GO
 
IF OBJECT_ID(N'dbo.SDN_main', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_main;
GO
CREATE TABLE dbo.SDN_main ( sdnPK      INT PRIMARY KEY CLUSTERED
                           ,SDN_Name   VARCHAR(350)
                           ,SDN_Type   VARCHAR(20)
                           ,Program    VARCHAR(200)
                           ,Title      VARCHAR(250)
                           ,Call_Sign  VARCHAR(20)
                           ,Vess_type  VARCHAR(50)
                           ,Tonnage    VARCHAR(30)
                           ,GRT        VARCHAR(20)
                           ,Vess_flag  VARCHAR(50)
                           ,Vess_owner VARCHAR(200)
                           ,Remarks    VARCHAR(4000)
                           ,NewOne     BIT )
GO

IF OBJECT_ID(N'dbo.SDN_add', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_add;
GO

CREATE TABLE dbo.SDN_add ( sdn_addPK   INT PRIMARY KEY
                          ,sdnFK       INT NOT NULL
                          ,[Address]   VARCHAR(750)
                          ,City        VARCHAR(120)
                          ,Country     VARCHAR(250)
                          ,Add_remarks VARCHAR(200)
                          ,NewOne      BIT )
GO

IF OBJECT_ID(N'dbo.SDN_alt', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_alt;
GO
CREATE TABLE dbo.SDN_alt ( sdn_altPK  INT PRIMARY KEY
                          ,sdnFK      INT NOT NULL
                          ,alt_Type   VARCHAR(8)
                          ,alt_name   VARCHAR(350)
                          ,alt_remark VARCHAR(200)
                          ,NewOne     BIT )
GO

IF OBJECT_ID(N'dbo.SDN_com', N'U') IS NOT NULL
   DROP TABLE dbo.SDN_com;
GO
CREATE TABLE dbo.SDN_com ( sdnFK   INT NOT NULL
                          ,comment VARCHAR(2000)
                          ,NewOne  BIT )
GO

-- ========== --
--  function  --
-- ========== --
IF OBJECT_ID(N'dbo.fn_SDN_SplitString', N'IF') IS NULL
    EXEC('CREATE FUNCTION dbo.fn_SDN_SplitString AS BEGIN RETURN; END')
GO
--=======================================================================
-- YYYYMMDD_####  Author                    Description
-- 20190923_0001  Vasyl Yeleiko (VY)        Created. (Task #20253)
-- ======================================================================
create FUNCTION [dbo].[fn_SDN_SplitString] (@text VARCHAR(1000))
                                   
RETURNS @Strings TABLE( [value] VARCHAR(250))
AS
BEGIN
    DECLARE @i     INT = 1
           ,@ascii INT
    WHILE @i <= LEN(@text)
        BEGIN
            SET @ascii = ASCII(SUBSTRING(@text, @i, 1))
            SET @text = CASE WHEN (@ascii >= 65 AND @ascii <= 90) OR (@ascii >= 97 AND @ascii <= 122)
                             THEN @text
                             ELSE STUFF(@text, @i, 1, ',')  END
            SET @i = @i+1
         END
    SET @text = LTRIM(RTRIM(@text))
    DECLARE @index INT = -1
    WHILE (LEN(@text) > 0)
        BEGIN
            SET @index = CHARINDEX(',' , @text)
            IF (@index = 0) AND (LEN(@text) > 0)
                BEGIN
                    INSERT INTO @Strings VALUES (@text)
                    BREAK
                END
            IF (@index > 1)
                BEGIN
                    INSERT INTO @Strings VALUES (LEFT(@text, @index - 1))
                    SET @text = RIGHT(@text, (LEN(@text) - @index))
                END
            ELSE
                BEGIN
                    SET @text = RIGHT(@text, (LEN(@text) - @index))
                END
        END
    RETURN
END
GO
-- =========== --
--    sproc    --
-- =========== --
IF OBJECT_ID(N'dbo.sp_SSIS_SDN_MainProfile_DeleteUnused', N'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_SSIS_SDN_MainProfile_DeleteUnused AS BEGIN RETURN; END')
GO
--=====================================================================================================
-- Purpose: delete records which not exist on dbo.Main
--=====================================================================================================
-- YYYY-MM-DD_####  Author                 Description
-- 2020-07-09_0001  Vasyl Yeleiko (VY)     Created.(TFS# #####)
--===================================================================================================== 
ALTER PROCEDURE dbo.sp_SSIS_SDN_MainProfile_DeleteUnused
AS
BEGIN
    SET NOCOUNT ON;
    -- delete unused records
    DELETE mp
        FROM dbo.SDN_MainProfile         AS mp
        LEFT JOIN Jeunesse_Back.dbo.Main AS m ON m.MainPK = mp.MainFK
        WHERE m.MainPK IS NULL 
END
GO

IF OBJECT_ID(N'dbo.sp_SSIS_SDN_MergeSplitTable', N'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_SSIS_SDN_MergeSplitTable AS BEGIN RETURN; END')
GO
--=====================================================================================================
-- Purpose: merge dbo.SDN_MainProfile_Split with new records 
--=====================================================================================================
-- YYYY-MM-DD_####  Author                 Description
-- 2020-07-09_0001  Vasyl Yeleiko (VY)     Created.(TFS# #####)
--===================================================================================================== 
ALTER PROCEDURE dbo.sp_SSIS_SDN_MergeSplitTable
AS
BEGIN
    SET NOCOUNT ON;
    -- delete unused
    DELETE mps
        FROM dbo.SDN_MainProfile_Split AS mps
        LEFT JOIN dbo.SDN_MainProfile  AS mp ON mp.MainFK = mps.MainFK
        WHERE mp.SDN_MainProfilePK IS NULL 
           OR mp.NewOne = 1

    -- insert new
    INSERT INTO dbo.SDN_MainProfile_Split (MainFK, SplitAddress)
        SELECT mp.MainFK
              ,a.value
            FROM dbo.SDN_MainProfile AS mp 
            OUTER APPLY dbo.fn_SDN_SplitString(ISNULL(mp.Taddress1, mp.address1) + ' ' + COALESCE(mp.Taddress2, mp.address2,'') + ' ' + COALESCE(mp.Taddress3, mp.address3,'')) AS a
            WHERE mp.NewOne = 1
              AND LEN(a.value)>2 

    INSERT INTO dbo.SDN_MainProfile_Split (MainFK, SplitShipAddress)
        SELECT mp.MainFK
              ,a.value
            FROM dbo.SDN_MainProfile AS mp 
            OUTER APPLY dbo.fn_SDN_SplitString(COALESCE(Tshipaddr1, shipaddr1, '')+' ' + COALESCE(Tshipaddr2, shipaddr2,'')+' '+COALESCE(Tshipaddr3, shipaddr3,'')) AS a
            WHERE mp.NewOne = 1
              AND LEN(a.value)>2
            
    INSERT INTO dbo.SDN_MainProfile_Split (MainFK, SplitName)
        SELECT mp.MainFK
              ,a.value
            FROM dbo.SDN_MainProfile AS mp 
            OUTER APPLY dbo.fn_SDN_SplitString(COALESCE(Tfname, fname, '')+' '+COALESCE(Tlname, lname,'')) AS a
            WHERE mp.NewOne = 1
              AND LEN(a.value)>2

END


 
--    -- ====================== --
--    -- Check existing records --
--    -- ====================== --
--    -- prepare profiles to check if any changes
--    SELECT m.MainPK
--          ,m.SiteURL
--          ,m.fname
--          ,m.lname
--          ,m.country
--          ,m.city   
--          ,m.address1
--          ,m.address2
--          ,m.address3
--          ,m.country2
--          ,m.city2
--          ,m.shipaddr1
--          ,m.shipaddr2
--          ,m.shipaddr3
--        INTO #Main_Original
--        FROM Jeunesse_Back.dbo.Main                AS m
--        INNER JOIN J_Reporting.dbo.MainProfile_SDN AS mp ON mp.MainFK = m.MainPK -- 0sec

--    UPDATE d
--        SET d.shipaddr3 = ''
--        FROM #Main_Original AS d
--        WHERE (ISNULL(d.shipaddr3,'') = ISNULL(d.shipaddr2,'') OR ISNULL(d.shipaddr3,'') = ISNULL(d.shipaddr1,''))
          
--    UPDATE d
--        SET d.shipaddr2 = ''
--        FROM #Main_Original AS d
--        WHERE (ISNULL(d.shipaddr2,'') = ISNULL(d.shipaddr3,'') OR ISNULL(d.shipaddr2,'') = ISNULL(d.shipaddr1,''))
          
--    UPDATE d
--        SET d.shipaddr1 = ''
--        FROM #Main_Original AS d
--        WHERE (ISNULL(d.shipaddr1,'') = ISNULL(d.address1,'') OR ISNULL(d.shipaddr1,'') = ISNULL(d.address2,'') OR ISNULL(d.shipaddr1,'') = ISNULL(d.address3,'')) 
--          AND ISNULL(d.country2,'') = ISNULL(d.country, '')
--          AND ISNULL(d.city2,'') = ISNULL(d.city, '')
          
--    UPDATE d
--        SET d.shipaddr2 = ''
--        FROM #Main_Original AS d
--        WHERE (ISNULL(d.shipaddr2,'') = ISNULL(d.address1,'') OR ISNULL(d.shipaddr2,'') = ISNULL(d.address2,'') OR ISNULL(d.shipaddr2,'') = ISNULL(d.address3,''))
--          AND ISNULL(d.country2,'') = ISNULL(d.country, '')
--          AND ISNULL(d.city2,'') = ISNULL(d.city, '')
                 
--    UPDATE d
--        SET d.shipaddr3 = ''
--        FROM #Main_Original AS d
--        WHERE (ISNULL(d.shipaddr3,'') = ISNULL(d.address1,'') OR ISNULL(d.shipaddr3,'') = ISNULL(d.address2,'') OR ISNULL(d.shipaddr3,'') = ISNULL(d.address3,''))
--          AND ISNULL(d.country2,'') = ISNULL(d.country, '')
--          AND ISNULL(d.city2,'') = ISNULL(d.city, '')
        
--    UPDATE d
--        SET d.address3 = ''
--        FROM #Main_Original AS d
--        WHERE ISNULL(d.address3, '') = ISNULL(d.address2,'') OR ISNULL(d.address3, '') = ISNULL(d.address1,'')          
        

--    UPDATE d
--        SET d.address2 = ''
--        FROM #Main_Original AS d
--        WHERE ISNULL(d.address2, '') = ISNULL(d.address1,'') OR ISNULL(d.address2, '') = ISNULL(d.address3,'')          
        

--    UPDATE d
--        SET d.address1 = ''
--        FROM #Main_Original AS d
--        WHERE ISNULL(d.address1, '') = ISNULL(d.address2,'') OR ISNULL(d.address1, '') = ISNULL(d.address3,'')          
         
--    UPDATE d 
--        SET d.country2 = ''
--           ,d.city2 = ''
--        FROM #Main_Original AS d
--        WHERE d.shipaddr1 = ''
--          AND d.shipaddr2 = ''
--          AND d.shipaddr3 = ''
--                               --0sec
--    UPDATE mp 
--        SET mp.SiteURL = m.SiteURL
--           ,mp.fname = m.fname
--           ,mp.lname = m.lname
--           ,mp.country = m.country
--           ,mp.city = m.city
--           ,mp.address1 = m.address1
--           ,mp.address2 = m.address2
--           ,mp.address3 = m.address3
--           ,mp.country2 = m.country2
--           ,mp.city2 = m.city2
--           ,mp.shipaddr1 = m.shipaddr1
--           ,mp.shipaddr2 = m.shipaddr2
--           ,mp.shipaddr3 = m.shipaddr3
--           ,mp.NewOne = 1
--        FROM dbo.MainProfile_SDN AS mp
--        INNER JOIN #Main_Original AS m ON m.MainPK = mp.MainFK
--        WHERE mp.SiteURL <> m.SiteURL
--           OR mp.fname <> m.fname
--           OR mp.lname <> m.lname
--           OR mp.country <> m.country
--           OR mp.city <> m.city
--           OR mp.address1 <> m.address1
--           OR mp.address2 <> m.address2
--           OR mp.address3 <> m.address3
--           OR mp.country2 <> m.country2
--           OR mp.city2 <> m.city2
--           OR mp.shipaddr1 <> m.shipaddr1
--           OR mp.shipaddr2 <> m.shipaddr2
--           OR mp.shipaddr3 <> m.shipaddr3                            
                                  
--    -- ====================== --
--    -- Check for new  records --
--    -- ====================== --
--    -- prepare new profiles to insert      
--    SELECT m.MainPK
--          ,m.SiteURL
--          ,m.fname
--          ,m.lname
--          ,m.country
--          ,m.city
--          ,m.address1
--          ,m.address2
--          ,m.address3
--          ,m.country2
--          ,m.city2
--          ,m.shipaddr1
--          ,m.shipaddr2
--          ,m.shipaddr3
--        INTO #Main_NewOne
--        FROM Jeunesse_Back.dbo.Main               AS m
--        LEFT JOIN J_Reporting.dbo.MainProfile_SDN AS mp ON mp.MainFK = m.MainPK
--        WHERE mp.MainFK IS NULL      --23sec

--    UPDATE d
--        SET d.shipaddr3 = ''
--        FROM #Main_NewOne AS d
--        WHERE (ISNULL(d.shipaddr3,'') = ISNULL(d.shipaddr2,'') OR ISNULL(d.shipaddr3,'') = ISNULL(d.shipaddr1,''))
          
--    UPDATE d
--        SET d.shipaddr2 = ''
--        FROM #Main_NewOne AS d
--        WHERE (ISNULL(d.shipaddr2,'') = ISNULL(d.shipaddr3,'') OR ISNULL(d.shipaddr2,'') = ISNULL(d.shipaddr1,''))
          
--    UPDATE d
--        SET d.shipaddr1 = ''
--        FROM #Main_NewOne AS d
--        WHERE (ISNULL(d.shipaddr1,'') = ISNULL(d.address1,'') OR ISNULL(d.shipaddr1,'') = ISNULL(d.address2,'') OR ISNULL(d.shipaddr1,'') = ISNULL(d.address3,'')) 
--          AND ISNULL(d.country2,'') = ISNULL(d.country, '')
--          AND ISNULL(d.city2,'') = ISNULL(d.city, '')
          
--    UPDATE d
--        SET d.shipaddr2 = ''
--        FROM #Main_NewOne AS d
--        WHERE (ISNULL(d.shipaddr2,'') = ISNULL(d.address1,'') OR ISNULL(d.shipaddr2,'') = ISNULL(d.address2,'') OR ISNULL(d.shipaddr2,'') = ISNULL(d.address3,''))
--          AND ISNULL(d.country2,'') = ISNULL(d.country, '')
--          AND ISNULL(d.city2,'') = ISNULL(d.city, '')
                 
--    UPDATE d
--        SET d.shipaddr3 = ''
--        FROM #Main_NewOne AS d
--        WHERE (ISNULL(d.shipaddr3,'') = ISNULL(d.address1,'') OR ISNULL(d.shipaddr3,'') = ISNULL(d.address2,'') OR ISNULL(d.shipaddr3,'') = ISNULL(d.address3,''))
--          AND ISNULL(d.country2,'') = ISNULL(d.country, '')
--          AND ISNULL(d.city2,'') = ISNULL(d.city, '')
        
--    UPDATE d
--        SET d.address3 = ''
--        FROM #Main_NewOne AS d
--        WHERE ISNULL(d.address3, '') = ISNULL(d.address2,'') OR ISNULL(d.address3, '') = ISNULL(d.address1,'')          
        

--    UPDATE d
--        SET d.address2 = ''
--        FROM #Main_NewOne AS d
--        WHERE ISNULL(d.address2, '') = ISNULL(d.address1,'') OR ISNULL(d.address2, '') = ISNULL(d.address3,'')          
        

--    UPDATE d
--        SET d.address1 = ''
--        FROM #Main_NewOne AS d
--        WHERE ISNULL(d.address1, '') = ISNULL(d.address2,'') OR ISNULL(d.address1, '') = ISNULL(d.address3,'')          
         
--    UPDATE d 
--        SET d.country2 = ''
--           ,d.city2 = ''
--        FROM #Main_NewOne AS d
--        WHERE d.shipaddr1 = ''
--          AND d.shipaddr2 = ''
--          AND d.shipaddr3 = ''      -- 2min 4sec

--    INSERT INTO dbo.MainProfile_SDN ( MainFK, SiteURL, fname, lname, country, city, address1, address2, address3, 
--                                      country2, city2, shipaddr1, shipaddr2, shipaddr3, NewOne )
--        SELECT MainPK
--              ,SiteURL
--              ,fname
--              ,lname
--              ,country
--              ,city
--              ,address1
--              ,address2
--              ,address3
--              ,country2
--              ,city2
--              ,shipaddr1
--              ,shipaddr2
--              ,shipaddr3
--              ,1
--            FROM #Main_NewOne

--    -- ===================== --
--    -- affect splitted table --
--    -- ===================== --
--    -- delete unused
--    DELETE mps
--        FROM dbo.MainProfile_SDN_Splitted AS mps
--        LEFT JOIN dbo.MainProfile_SDN     AS mp ON mp.MainFK = mps.MainFK
--        WHERE mp.MainProfile_SDNPK IS NULL 
--           OR mp.NewOne = 1

--    -- insert new
--    INSERT INTO dbo.MainProfile_SDN_Splitted (MainFK, SplittedAddress)
--        SELECT mp.MainFK
--              ,a.value
--            FROM dbo.MainProfile_SDN AS mp 
--            OUTER APPLY dbo.fn_SDN_SplitString(ISNULL(mp.Taddress1, mp.address1) + ' ' + COALESCE(mp.Taddress2, mp.address2,'') + ' ' + COALESCE(mp.Taddress3, mp.address3,'')) AS a
--            WHERE mp.NewOne = 1
--              AND LEN(a.value)>2 

--    INSERT INTO dbo.MainProfile_SDN_Splitted (MainFK, SplittedShipAddress)
--        SELECT mp.MainFK
--              ,a.value
--            FROM dbo.MainProfile_SDN AS mp 
--            OUTER APPLY dbo.fn_SDN_SplitString(COALESCE(Tshipaddr1, shipaddr1, '')+' ' + COALESCE(Tshipaddr2, shipaddr2,'')+' '+COALESCE(Tshipaddr3, shipaddr3,'')) AS a
--            WHERE mp.NewOne = 1
--              AND LEN(a.value)>2
            
--    INSERT INTO dbo.MainProfile_SDN_Splitted (MainFK, SplittedName)
--        SELECT mp.MainFK
--              ,a.value
--            FROM dbo.MainProfile_SDN AS mp 
--            OUTER APPLY dbo.fn_SDN_SplitString(COALESCE(Tfname, fname, '')+' '+COALESCE(Tlname, lname,'')) AS a
--            WHERE mp.NewOne = 1
--              AND LEN(a.value)>2
            
--    IF OBJECT_ID('tempdb..#Main_Original') IS NOT NULL
--        DROP TABLE #Main_Original
--    IF OBJECT_ID('tempdb..#Main_NewOne') IS NOT NULL
--        DROP TABLE #Main_NewOne            
--END
