
-- Configure the SQL*Plus environment for clean output
SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
SET TERMOUT ON
SET LINESIZE 200
SET PAGESIZE 60

-- SECTION 1: SEARCH FOR A PROJECT ---------------------------------------------
PROMPT
PROMPT --- Project Search ---

ACCEPT search_term CHAR PROMPT 'Enter a project name to search for (or type EXIT to quit): '

-- Use a simple PL/SQL block to check for the EXIT command
-- WHENEVER SQLERROR EXIT will catch the raised error and terminate the client script
WHENEVER SQLERROR EXIT
BEGIN
  IF UPPER('&search_term') = 'EXIT' THEN
    -- Raising an error is the cleanest way to signal the script to stop
    RAISE_APPLICATION_ERROR(-20001, 'User requested exit. Goodbye!');
  END IF;
END;
/
-- IMPORTANT: Turn off the auto-exit behavior for subsequent blocks
WHENEVER SQLERROR CONTINUE

-- Execute the search and display results in a PL/SQL block
DECLARE
  v_project_list  SYS_REFCURSOR;
  v_proj_id       PROJECTS.PROJECT_ID%TYPE;
  v_proj_name     PROJECTS.PROJECT_NAME%TYPE;
  v_start_date    PROJECTS.START_DATE%TYPE;
  v_end_date      PROJECTS.END_DATE%TYPE;
  v_row_count     NUMBER := 0;
BEGIN
  project_financials_pkg.search_projects(
    p_project_name => '&search_term',
    p_project_list => v_project_list
  );

  DBMS_OUTPUT.PUT_LINE(CHR(10));
  DBMS_OUTPUT.PUT_LINE('--- Search Results ---');
  DBMS_OUTPUT.PUT_LINE(RPAD('Project ID', 15) || ' | ' || RPAD('Project Name', 50) || ' | ' || RPAD('Start Date', 12) || ' | ' || 'End Date');
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 15, '-') || ' | ' || RPAD('-', 50, '-') || ' | ' || RPAD('-', 12, '-') || ' | ' || RPAD('-', 10, '-'));
  DBMS_OUTPUT.NEW_LINE;

  LOOP
    FETCH v_project_list INTO v_proj_id, v_proj_name, v_start_date, v_end_date;
    EXIT WHEN v_project_list%NOTFOUND;
    v_row_count := v_row_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      RPAD(v_proj_id, 15) || ' | ' ||
      RPAD(SUBSTR(v_proj_name, 1, 58), 50) || ' | ' ||
      TO_CHAR(v_start_date, 'YYYY-MM-DD') || ' | ' ||
      TO_CHAR(v_end_date, 'YYYY-MM-DD')
    );
  END LOOP;
  CLOSE v_project_list;

  IF v_row_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No projects found matching "&search_term".');
  END IF;
END;
/


-- SECTION 2: CALCULATE FINANCIALS -------------------------------------------
PROMPT
PROMPT --- Financial Calculation ---

ACCEPT project_id_input CHAR PROMPT 'Enter Project ID for details (or type BACK to search again, or EXIT to quit): '

-- Another PL/SQL block to handle EXIT and BACK commands
WHENEVER SQLERROR EXIT
DECLARE
  v_command VARCHAR2(100) := UPPER('&project_id_input');
BEGIN
  IF v_command = 'EXIT' THEN
    RAISE_APPLICATION_ERROR(-20001, 'User requested exit. Goodbye!');
  ELSIF v_command = 'BACK' THEN
    -- To go "BACK", we raise a specific, harmless error that we will ignore
    -- This stops the current script execution before the calculation runs
    RAISE_APPLICATION_ERROR(-20002, 'Go back');
  END IF;
END;
/
-- Ignore the "BACK" error and continue to the loop command at the end
WHENEVER SQLERROR CONTINUE

-- Execute the financial calculation, which is automatically skipped if 'BACK' or 'EXIT' was chosen
DECLARE
  v_row_count NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE(CHR(10));
  DBMS_OUTPUT.PUT_LINE('--- Financials for Project ID: &project_id_input ---');
  DBMS_OUTPUT.PUT_LINE(RPAD('Project Name', 50) || ' | ' || RPAD('Total Revenue', 18) || ' | ' || RPAD('Total Cost', 18) || ' | ' || RPAD('Profit/Loss', 18) || ' | ' || 'Gross Margin %');
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 50, '-') || ' | ' || RPAD('-', 18, '-') || ' | ' || RPAD('-', 18, '-') || ' | ' || RPAD('-', 18, '-') || ' | ' || RPAD('-', 15, '-'));

  FOR rec IN (SELECT * FROM TABLE(project_financials_pkg.calculate_project_financials('&project_id_input')))
  LOOP
    v_row_count := v_row_count + 1;
    
    DBMS_OUTPUT.PUT_LINE(
      RPAD(SUBSTR(rec.project_name, 1, 50), 50) || ' | ' ||
      RPAD(TO_CHAR(rec.total_revenue, 'FM999,999,990.00'), 18) || ' | ' ||
      RPAD(TO_CHAR(rec.total_cost, 'FM999,999,990.00'), 18) || ' | ' ||
      RPAD(TO_CHAR(rec.profit_loss, 'FM999,999,990.00'), 18) || ' | ' ||
      RPAD(TO_CHAR(rec.gross_margin_pct, 'FM999,999.00') || '%', 15)
    );
    
  END LOOP;

  IF v_row_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No financial data found for Project ID "&project_id_input".');
  END IF;
END;
/

-- SECTION 3: LOOP -------------------------------------------------------------
PROMPT
PROMPT Returning to search...
-- This line causes the script to re-run itself from the beginning, creating the loop.
-- _SQLPLUS_SCRIPT is a built-in variable(but not working in 11g) that holds the name of the current file.
-- @&_SQLPLUS_SCRIPT
@'&1'