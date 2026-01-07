
-- Steps, (Currently use SQLPLUS its safe and working)
-- Enable server output to see the results
SET SERVEROUTPUT ON;

-- Declare a ref cursor variable to hold the results
VAR project_cursor REFCURSOR;

-- Execute the search procedure
BEGIN
  project_financials_pkg.search_projects(
    p_project_name => 'Helena', -- The approximate project name
    p_project_list => :project_cursor
  );
END;
/

-- Print the results from the ref cursor
PRINT project_cursor;

-- This will give you a list of all projects that have "Helena" in their name, along with their project IDs.
-- Step 2: Calculate the Financials
-- Once you have the project_id from the search results, you can use the calculate_project_financials function to get the detailed financial breakdown.
-- Use the project ID you found in the previous step
SELECT *
FROM TABLE(project_financials_pkg.calculate_project_financials('PRJ0531395'));
