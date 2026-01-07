-- =============================================================================
-- PACKAGES
-- =============================================================================


CREATE OR REPLACE PACKAGE project_financials_pkg AS
  -- A record type to hold the results of the financial calculations
  TYPE project_financials_rec IS RECORD (
    project_id          VARCHAR2(80),
    project_name        VARCHAR2(150),
    start_date          DATE,
    end_date            DATE,
    total_revenue       NUMBER,
    total_cost          NUMBER,
    profit_loss         NUMBER,
    gross_margin_pct    NUMBER
  );

  -- A table type to hold a collection of the financial records
  TYPE project_financials_tbl IS TABLE OF project_financials_rec;

  -- Procedure to search for projects by a partial name
  PROCEDURE search_projects (
    p_project_name IN VARCHAR2,
    p_project_list OUT SYS_REFCURSOR
  );

  -- Procedure to calculate the financials for a given project ID
  FUNCTION calculate_project_financials (
    p_project_id IN VARCHAR2
  ) RETURN project_financials_tbl PIPELINED;

END project_financials_pkg;
/

CREATE OR REPLACE PACKAGE BODY project_financials_pkg AS

  -- =============================================================================
  -- Public Procedures and Functions
  -- =============================================================================

  /**
   * Searches for projects by a partial name and returns a list of matches.
   * This helps the user find the correct project_id.
   */
  PROCEDURE search_projects (
    p_project_name IN VARCHAR2,
    p_project_list OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN p_project_list FOR
      SELECT DISTINCT
        project_id,
        project_name,
        start_date,
        end_date
      FROM
        PROJECTS
      WHERE
        lower(project_name) LIKE '%' || lower(p_project_name) || '%'
        AND project_id IS NOT NULL -- Exclude projects with null IDs
      ORDER BY
        project_name, start_date;
  END search_projects;

  /**
   * A pipelined table function that calculates and returns financial details
   * for all instances of a given project_id.
   */
  FUNCTION calculate_project_financials (
    p_project_id IN VARCHAR2
  ) RETURN project_financials_tbl PIPELINED IS
    -- Keeping constants for the cost calculation now.
    -- This makes the formula easier to read and modify.
    V_WORKING_DAYS_PER_YEAR CONSTANT NUMBER := 252;
    V_HOURS_PER_DAY CONSTANT NUMBER := 9;
    V_TOTAL_HOURS_PER_YEAR CONSTANT NUMBER := V_WORKING_DAYS_PER_YEAR * V_HOURS_PER_DAY;

    v_rec project_financials_rec;

  BEGIN
    -- This single cursor now performs all the necessary calculations by joining
    -- the tables and using a subquery for the cost calculation.
    FOR proj IN (
      SELECT
        p.project_id,
        p.project_name,
        p.start_date,
        p.end_date,
        -- Calculate total revenue, treating NULL CR/SOW values as 0.
        p.TOTAL_REVENUE AS calculated_revenue,
        -- (NVL(p.original_sow_amount, 0) + NVL(p.cr_1, 0) + NVL(p.cr_2, 0) + NVL(p.cr_3, 0)) AS calculated_revenue,
        -- Subquery to calculate the total project cost.
        -- This is the core of the fix, replacing the function call.
        (
          SELECT SUM(t.time_worked * (e.annual_ctc / V_TOTAL_HOURS_PER_YEAR))
          FROM TIMESHEETS t
          JOIN EMPLOYEES e ON t.employee_id = e.employee_id
          WHERE t.project_name = p.project_name
            -- Crucially, filter timesheets for this specific project instance's date range.
            AND t.daily_date BETWEEN p.start_date AND p.end_date
        ) AS calculated_cost
      FROM
        PROJECTS p
      WHERE
        p.project_id = p_project_id
        -- AND p.project_id IS NOT NULL
    )
    LOOP
      -- Assign the pre-calculated values from the cursor to the record type.
      v_rec.project_id    := proj.project_id;
      v_rec.project_name  := proj.project_name;
      v_rec.start_date    := proj.start_date;
      v_rec.end_date      := proj.end_date;
      v_rec.total_revenue := proj.calculated_revenue;
      v_rec.total_cost    := NVL(proj.calculated_cost, 0); -- Ensure cost is 0 if no timesheets exist.

      -- Calculate profit/loss.
      v_rec.profit_loss := v_rec.total_revenue - v_rec.total_cost;

      -- Calculate gross margin percentage, safely handling division by zero.
      IF v_rec.total_revenue > 0 THEN
        v_rec.gross_margin_pct := ROUND((v_rec.profit_loss / v_rec.total_revenue) * 100, 2);
      ELSE
        v_rec.gross_margin_pct := 0;
      END IF;

      -- Pipe the completed record out of the function.
      PIPE ROW(v_rec);

    END LOOP;

    RETURN;

  EXCEPTION
    WHEN OTHERS THEN
      -- Basic error logging for unexpected issues.
      DBMS_OUTPUT.PUT_LINE('An unexpected error occurred in calculate_project_financials for project_id ' || p_project_id || ': ' || SQLERRM);
      RETURN; -- Stop execution and return gracefully on error.
  END calculate_project_financials;

END project_financials_pkg;
/