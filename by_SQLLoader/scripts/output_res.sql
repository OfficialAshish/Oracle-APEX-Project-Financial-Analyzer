-- Configure the SQL*Plus environment for clean report output
SET SERVEROUTPUT ON 
SET FEEDBACK OFF
SET LINESIZE 280
SET PAGESIZE 120
COLUMN project_id FORMAT A15
COLUMN project_name FORMAT A50
COLUMN start_date FORMAT A12
COLUMN end_date FORMAT A12
COLUMN total_revenue FORMAT A15
COLUMN total_cost FORMAT A15
COLUMN profit_loss FORMAT A15
COLUMN gross_margin_pct FORMAT A15

-- Start of the main execution block
SPOOL full_project_report.txt
BEGIN
  -- Print the main report header
  DBMS_OUTPUT.PUT_LINE('--- Full Project Financials Report ---');
  DBMS_OUTPUT.PUT_LINE('Generated On: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
  DBMS_OUTPUT.PUT_LINE(RPAD('=', 180, '='));
  DBMS_OUTPUT.PUT_LINE(
    RPAD('Project ID', 15) || ' | ' ||
    RPAD('Project Name', 50) || ' | ' ||
    RPAD('Start Date', 12) || ' | ' ||
    RPAD('End Date', 12) || ' | ' ||
    RPAD('Total Revenue', 15) || ' | ' ||
    RPAD('Total Cost', 15) || ' | ' ||
    RPAD('Profit/Loss', 15) || ' | ' ||
    'Gross Margin %'
  );
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 180, '-'));

  -- Loop through every distinct, non-null project ID from the PROJECTS table
  FOR proj_cursor IN (
    SELECT DISTINCT project_id
    FROM PROJECTS
    WHERE project_id IS NOT NULL
    ORDER BY project_id
  )
  LOOP
    -- For each distinct project_id, call the financial calculation function.
    -- The function correctly handles multiple instances (different dates) for the same ID.
    FOR rec IN (
      SELECT *
      FROM TABLE(project_financials_pkg.calculate_project_financials(proj_cursor.project_id))
    )
    LOOP
      -- Print the formatted result row for each project instance
      DBMS_OUTPUT.PUT_LINE(
        RPAD(rec.project_id, 15) || ' | ' ||
        RPAD(SUBSTR(rec.project_name, 1, 48), 50) || ' | ' ||
        TO_CHAR(rec.start_date, 'YYYY-MM-DD') || ' | ' ||
        TO_CHAR(rec.end_date, 'YYYY-MM-DD') || ' | ' ||
        LPAD(TO_CHAR(rec.total_revenue, 'FM999,999,990.00'), 15) || ' | ' ||
        LPAD(TO_CHAR(rec.total_cost, 'FM999,999,990.00'), 15) || ' | ' ||
        LPAD(TO_CHAR(rec.profit_loss, 'FM999,999,990.00'), 15) || ' | ' ||
        LPAD(TO_CHAR(rec.gross_margin_pct, 'FM990,999.00') || '%', 15)
      );
    END LOOP;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(RPAD('=', 180, '='));
  DBMS_OUTPUT.PUT_LINE('--- End of Report ---');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('An unexpected error occurred during report generation: ' || SQLERRM);
END;
/
SPOOL OFF 
PROMPT
PROMPT Report also saved as full_project_report.txt . Check for details.
-- EXIT