-- Execute the stored procedure
EXEC SP_hierarchy;

-- View the results
SELECT 
    EMPLOYEEID,
    REPORTINGTO,
    EMAILID,
    [LEVEL],
    FIRSTNAME,
    LASTNAME
FROM 
    Employee_Hierarchy
ORDER BY 
    [LEVEL], 
    EMPLOYEEID;

PRINT 'Employee hierarchy generated successfully';
