-- Create the Employee_Hierarchy table
IF OBJECT_ID('Employee_Hierarchy', 'U') IS NOT NULL
    DROP TABLE Employee_Hierarchy;

CREATE TABLE Employee_Hierarchy (
    EMPLOYEEID VARCHAR(20),
    REPORTINGTO NVARCHAR(MAX),
    EMAILID NVARCHAR(MAX),
    [LEVEL] INT,
    FIRSTNAME NVARCHAR(MAX),
    LASTNAME NVARCHAR(MAX)
);

-- Create the EMPLOYEE_MASTER table if it doesn't exist
IF OBJECT_ID('EMPLOYEE_MASTER', 'U') IS NULL
BEGIN
    CREATE TABLE EMPLOYEE_MASTER (
        EmployeeID VARCHAR(20),
        ReportingTo NVARCHAR(MAX),
        EmailID NVARCHAR(MAX)
    );
END

-- Drop and recreate the FIRST_NAME function
IF OBJECT_ID('dbo.FIRST_NAME', 'FN') IS NOT NULL
    DROP FUNCTION dbo.FIRST_NAME;
GO

CREATE FUNCTION dbo.FIRST_NAME(@Email NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @FirstName NVARCHAR(MAX);
    SET @FirstName = SUBSTRING(@Email, 1, CHARINDEX('.', @Email) - 1);
    RETURN @FirstName;
END;
GO

-- Drop and recreate the LAST_NAME function
IF OBJECT_ID('dbo.LAST_NAME', 'FN') IS NOT NULL
    DROP FUNCTION dbo.LAST_NAME;
GO

CREATE FUNCTION dbo.LAST_NAME(@Email NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @LastName NVARCHAR(MAX);
    DECLARE @AtPos INT = CHARINDEX('@', @Email);
    DECLARE @DotPos INT = CHARINDEX('.', @Email);
    
    SET @LastName = SUBSTRING(@Email, @DotPos + 1, @AtPos - @DotPos - 1);
    RETURN @LastName;
END;
GO

-- Drop and recreate the stored procedure
IF OBJECT_ID('SP_hierarchy', 'P') IS NOT NULL
    DROP PROCEDURE SP_hierarchy;
GO

CREATE PROCEDURE SP_hierarchy
AS
BEGIN
    -- Truncate the target table
    TRUNCATE TABLE Employee_Hierarchy;
    
    -- First insert top level employees (those with ReportingTo NULL)
    INSERT INTO Employee_Hierarchy (EMPLOYEEID, REPORTINGTO, EMAILID, [LEVEL], FIRSTNAME, LASTNAME)
    SELECT 
        EmployeeID, 
        ReportingTo, 
        EmailID, 
        1 AS [LEVEL], 
        dbo.FIRST_NAME(EmailID) AS FIRSTNAME, 
        dbo.LAST_NAME(EmailID) AS LASTNAME
    FROM EMPLOYEE_MASTER
    WHERE ReportingTo IS NULL;
    
    -- Now recursively insert the rest of the hierarchy
    DECLARE @CurrentLevel INT = 1;
    DECLARE @RowsAffected INT = 1;
    
    WHILE @RowsAffected > 0
    BEGIN
        SET @CurrentLevel = @CurrentLevel + 1;
        
        INSERT INTO Employee_Hierarchy (EMPLOYEEID, REPORTINGTO, EMAILID, [LEVEL], FIRSTNAME, LASTNAME)
        SELECT 
            e.EmployeeID, 
            e.ReportingTo, 
            e.EmailID, 
            @CurrentLevel AS [LEVEL], 
            dbo.FIRST_NAME(e.EmailID) AS FIRSTNAME, 
            dbo.LAST_NAME(e.EmailID) AS LASTNAME
        FROM EMPLOYEE_MASTER e
        INNER JOIN Employee_Hierarchy h ON e.ReportingTo LIKE '%' + h.EMPLOYEEID
        WHERE h.[LEVEL] = @CurrentLevel - 1
        AND e.EmployeeID NOT IN (SELECT EMPLOYEEID FROM Employee_Hierarchy);
        
        SET @RowsAffected = @@ROWCOUNT;
    END
    
    -- Update ReportingTo to show the manager's name and ID more clearly
    UPDATE eh
    SET eh.REPORTINGTO = CONCAT(em.FIRSTNAME, ' ', em.LASTNAME, ' ', eh.REPORTINGTO)
    FROM Employee_Hierarchy eh
    CROSS APPLY (
        SELECT TOP 1 FIRSTNAME, LASTNAME 
        FROM Employee_Hierarchy 
        WHERE EMPLOYEEID = SUBSTRING(eh.REPORTINGTO, CHARINDEX('H', eh.REPORTINGTO), LEN(eh.REPORTINGTO))
    ) em
    WHERE eh.REPORTINGTO IS NOT NULL AND eh.REPORTINGTO LIKE '%H%';
END;
GO
