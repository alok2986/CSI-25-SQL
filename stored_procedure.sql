DELIMITER $$

CREATE PROCEDURE GetEmployeeHierarchy()
BEGIN
    WITH RECURSIVE EmployeeHierarchy AS (
        SELECT
            EmpId,
            EmpName,
            ManagerId,
            1 AS Level,
            EmpName AS HierarchyPath
        FROM Employee
        WHERE ManagerId IS NULL

        UNION ALL

        SELECT
            e.EmpId,
            e.EmpName,
            e.ManagerId,
            eh.Level + 1,
            CONCAT(eh.HierarchyPath, ' > ', e.EmpName)
        FROM Employee e
        JOIN EmployeeHierarchy eh ON e.ManagerId = eh.EmpId
    )

    SELECT
        EmpId,
        EmpName,
        ManagerId,
        Level,
        HierarchyPath
    FROM EmployeeHierarchy
    ORDER BY HierarchyPath;
END $$

DELIMITER ;



CALL GetEmployeeHierarchy();
