-- =============================================================================
-- COMPLETE PROJECT FINANCIALS SETUP SCRIPT
-- =============================================================================

-- Step 1: Clean existing objects
BEGIN
    -- Drop specific tables if they exist
    FOR t IN (
        SELECT table_name 
        FROM user_tables 
        WHERE table_name IN ('EMPLOYEES', 'PROJECTS', 'TIMESHEETS')
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE "' || t.table_name || '" CASCADE CONSTRAINTS PURGE';
    END LOOP;

    -- Drop error logging tables if they exist
    FOR e IN (
        SELECT table_name 
        FROM user_tables 
        WHERE table_name LIKE 'ERR$_%'
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE "' || e.table_name || '" PURGE';
    END LOOP;

    -- Drop packages if they exist
    FOR pkg IN (
        SELECT object_name 
        FROM user_objects 
        WHERE object_type = 'PACKAGE' 
          AND object_name IN ('PROJECT_FINANCIALS_PKG', 'CLIENT_REPORTS_PKG')
    ) LOOP
        EXECUTE IMMEDIATE 'DROP PACKAGE "' || pkg.object_name || '"';
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Cleanup completed successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Cleanup warning: ' || SQLERRM);
END;
/

-- Step 2: Create Tables
CREATE TABLE EMPLOYEES (
    employee_id        VARCHAR2(80),
    employee_name      VARCHAR2(150),
    email              VARCHAR2(150),
    designation        VARCHAR2(80),
    grade              VARCHAR2(10),
    competency         VARCHAR2(80),
    annual_ctc         NUMBER(12,2),
    bill_rate          NUMBER(8,2)
);

CREATE TABLE PROJECTS (
    project_id          VARCHAR2(80),
    project_name        VARCHAR2(150),
    client_name         VARCHAR2(150),
    start_date          DATE,
    end_date            DATE,
    total_revenue       NUMBER(15,2),
    original_sow_amount NUMBER(15,2),
    cr_1                NUMBER(15,2),
    cr_2                NUMBER(15,2),
    cr_3                NUMBER(15,2)
);

CREATE TABLE TIMESHEETS (
    employee_id          VARCHAR2(80),
    employee_name        VARCHAR2(150),
    daily_date           DATE,
    project_id           VARCHAR2(80),
    project_name         VARCHAR2(150),
    time_worked          NUMBER(4,2),
    approved_by          VARCHAR2(150),
    time_card_state      VARCHAR2(80),
    employee_type        VARCHAR2(30),
    resource_is_active   VARCHAR2(30),
    timesheet_user       VARCHAR2(30),
    resource_entity      VARCHAR2(150),
    customer_name        VARCHAR2(150),
    task_name            VARCHAR2(150),
    task_type            VARCHAR2(30),
    task_type_category   VARCHAR2(80),
    irm                  VARCHAR2(150),
    srm                  VARCHAR2(150),
    email                VARCHAR2(150),
    week_starts_on       DATE,
    approved_on          TIMESTAMP
);

-- Step 3: Create Error Logging Tables
BEGIN
    DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => 'EMPLOYEES');
    DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => 'PROJECTS');
    DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => 'TIMESHEETS');
    DBMS_OUTPUT.PUT_LINE('Error logging tables created.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error logging setup failed: ' || SQLERRM);
END;
/

-- Step 4: Project Financials Package
CREATE OR REPLACE PACKAGE project_financials_pkg AS
  TYPE project_financials_rec IS RECORD (
    project_id       VARCHAR2(80),
    project_name     VARCHAR2(150),
    start_date       DATE,
    end_date         DATE,
    total_revenue    NUMBER,
    total_cost       NUMBER,
    profit_loss      NUMBER,
    gross_margin_pct NUMBER,
    resource_count   NUMBER,
    avg_employee_ctc NUMBER
  );

  TYPE project_financials_tbl IS TABLE OF project_financials_rec;

  FUNCTION calculate_project_financials(
    p_project_id IN VARCHAR2 DEFAULT NULL
  ) RETURN project_financials_tbl PIPELINED;
END project_financials_pkg;
/

CREATE OR REPLACE PACKAGE BODY project_financials_pkg AS
  FUNCTION calculate_project_financials(
    p_project_id IN VARCHAR2 DEFAULT NULL
  ) RETURN project_financials_tbl PIPELINED IS
    
    v_working_days_per_year CONSTANT NUMBER := 200;
    v_hours_per_day         CONSTANT NUMBER := 9;
    v_total_hours_per_year  CONSTANT NUMBER := v_working_days_per_year * v_hours_per_day;
    v_rec                   project_financials_rec;
    
  BEGIN
    FOR proj IN (
      WITH timesheet_aggregates AS (
        SELECT
          t.project_name,
          t.daily_date,
          t.employee_id,
          t.time_worked,
          e.annual_ctc
        FROM timesheets t
        JOIN employees e ON t.employee_id = e.employee_id
        WHERE t.time_card_state = 'TimeCard Approved'
      )
      SELECT
        p.project_id,
        p.project_name,
        p.start_date,
        p.end_date,
        NVL(p.total_revenue, 0) AS calculated_revenue,
        (
          SELECT SUM(ta.time_worked * (ta.annual_ctc / v_total_hours_per_year))
          FROM timesheet_aggregates ta
          WHERE ta.project_name = p.project_name
            AND ta.daily_date BETWEEN p.start_date AND p.end_date
        ) AS calculated_cost,
        (
          SELECT COUNT(DISTINCT ta.employee_id)
          FROM timesheet_aggregates ta
          WHERE ta.project_name = p.project_name
            AND ta.daily_date BETWEEN p.start_date AND p.end_date
        ) AS resource_count,
        (
          SELECT AVG(ta.annual_ctc)
          FROM timesheet_aggregates ta
          WHERE ta.project_name = p.project_name
            AND ta.daily_date BETWEEN p.start_date AND p.end_date
        ) AS avg_ctc
      FROM projects p
      WHERE (p_project_id IS NULL OR p.project_id = p_project_id)
        AND p.project_id IS NOT NULL
        AND p.start_date IS NOT NULL
        AND p.end_date IS NOT NULL
      ORDER BY p.project_id, p.start_date
    ) LOOP
      
      v_rec.project_id        := proj.project_id;
      v_rec.project_name      := proj.project_name;
      v_rec.start_date        := proj.start_date;
      v_rec.end_date          := proj.end_date;
      v_rec.total_revenue     := proj.calculated_revenue;
      v_rec.total_cost        := NVL(proj.calculated_cost, 0);
      v_rec.resource_count    := NVL(proj.resource_count, 0);
      v_rec.avg_employee_ctc  := NVL(proj.avg_ctc, 0);
      v_rec.profit_loss       := v_rec.total_revenue - v_rec.total_cost;

      IF v_rec.total_revenue > 0 THEN
        v_rec.gross_margin_pct := ROUND((v_rec.profit_loss / v_rec.total_revenue) * 100, 2);
      ELSE
        v_rec.gross_margin_pct := 0;
      END IF;

      PIPE ROW(v_rec);
    END LOOP;
    
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error in calculate_project_financials: ' || SQLERRM);
      RETURN;
  END calculate_project_financials;
END project_financials_pkg;
/

-- Step 5: Client Reports Package
CREATE OR REPLACE PACKAGE client_reports_pkg AS
  TYPE client_profitability_rec IS RECORD (
    client_name         VARCHAR2(150),
    total_revenue       NUMBER,
    total_cost          NUMBER,
    net_profit_loss     NUMBER,
    overall_gross_margin NUMBER
  );

  TYPE client_profitability_tbl IS TABLE OF client_profitability_rec;

  FUNCTION get_client_profitability RETURN client_profitability_tbl PIPELINED;
END client_reports_pkg;
/

CREATE OR REPLACE PACKAGE BODY client_reports_pkg AS
  FUNCTION get_client_profitability RETURN client_profitability_tbl PIPELINED IS
    v_rec client_profitability_rec;
    v_working_days_per_year CONSTANT NUMBER := 252;
    v_hours_per_day         CONSTANT NUMBER := 8;
    v_total_hours_per_year  CONSTANT NUMBER := v_working_days_per_year * v_hours_per_day;
  BEGIN
    FOR client_rec IN (
      WITH project_financials AS (
        SELECT
          p.client_name,
          (NVL(p.original_sow_amount, 0) + NVL(p.cr_1, 0) + NVL(p.cr_2, 0) + NVL(p.cr_3, 0)) AS project_revenue,
          (
            SELECT SUM(t.time_worked * (e.annual_ctc / v_total_hours_per_year))
            FROM timesheets t
            JOIN employees e ON t.employee_id = e.employee_id
            WHERE t.project_name = p.project_name 
              AND t.daily_date BETWEEN p.start_date AND p.end_date
          ) AS project_cost
        FROM projects p
        WHERE p.client_name IS NOT NULL
      )
      SELECT
        client_name,
        SUM(project_revenue) AS total_revenue,
        SUM(NVL(project_cost, 0)) AS total_cost
      FROM project_financials
      GROUP BY client_name
      ORDER BY client_name
    )
    LOOP
      v_rec.client_name       := client_rec.client_name;
      v_rec.total_revenue     := NVL(client_rec.total_revenue, 0);
      v_rec.total_cost        := NVL(client_rec.total_cost, 0);
      v_rec.net_profit_loss   := v_rec.total_revenue - v_rec.total_cost;

      IF v_rec.total_revenue > 0 THEN
        v_rec.overall_gross_margin := ROUND((v_rec.net_profit_loss / v_rec.total_revenue) * 100, 2);
      ELSE
        v_rec.overall_gross_margin := 0;
      END IF;

      PIPE ROW(v_rec);
    END LOOP;
    
    RETURN;
  END get_client_profitability;
END client_reports_pkg;
/

-- Step 6: Final Status Check
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== SETUP COMPLETE ===');
    DBMS_OUTPUT.PUT_LINE('Tables created: EMPLOYEES, PROJECTS, TIMESHEETS');
    DBMS_OUTPUT.PUT_LINE('Packages created: PROJECT_FINANCIALS_PKG, CLIENT_REPORTS_PKG');
    DBMS_OUTPUT.PUT_LINE('Error logging tables created for data loading');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Usage examples:');
    DBMS_OUTPUT.PUT_LINE('-- All projects: SELECT * FROM TABLE(project_financials_pkg.calculate_project_financials());');
    DBMS_OUTPUT.PUT_LINE('-- Single project: SELECT * FROM TABLE(project_financials_pkg.calculate_project_financials(''PROJ001''));');
    DBMS_OUTPUT.PUT_LINE('-- Client report: SELECT * FROM TABLE(client_reports_pkg.get_client_profitability());');
END;
/


CREATE OR REPLACE PACKAGE employee_project_pkg AS
  OVERHEAD_CHARGES CONSTANT NUMBER := 0;
  USD_TO_INR       CONSTANT NUMBER := 85;
  EMP_HOURS        CONSTANT NUMBER := 1800; -- 200 days x 9 hours

  TYPE emp_margin_row IS RECORD (
    employee_id       VARCHAR2(80),
    employee_name     VARCHAR2(150),
    designation       VARCHAR2(80),
    grade             VARCHAR2(10),
    competency        VARCHAR2(80),
    annual_ctc        NUMBER(12,2),
    bill_rate         NUMBER,
    gross_margin_pct  NUMBER
  );

  TYPE emp_margin_tab IS TABLE OF emp_margin_row;

  FUNCTION get_employee_margin(p_emp_id VARCHAR2 DEFAULT NULL)
    RETURN emp_margin_tab PIPELINED;
END employee_project_pkg;
/

CREATE OR REPLACE PACKAGE BODY employee_project_pkg AS
  FUNCTION get_employee_margin(p_emp_id VARCHAR2 DEFAULT NULL)
    RETURN emp_margin_tab PIPELINED
  IS
    CURSOR c_emp IS
      SELECT employee_id, employee_name, designation, grade, competency,
             annual_ctc, bill_rate
      FROM employees
      WHERE p_emp_id IS NULL OR employee_id = p_emp_id;

    l_row emp_margin_row;
    l_total_cost NUMBER;
    bill_rate_inr_tot NUMBER;   -- DECLARE HERE
  BEGIN
    FOR r IN c_emp LOOP
      l_row.employee_id    := r.employee_id;
      l_row.employee_name  := r.employee_name;
      l_row.designation    := r.designation;
      l_row.grade          := r.grade;
      l_row.competency     := r.competency;
      l_row.annual_ctc     := r.annual_ctc;
      l_row.bill_rate      := r.bill_rate; 
      
      bill_rate_inr_tot := r.bill_rate * EMP_HOURS * USD_TO_INR; 
      l_total_cost      := r.annual_ctc + OVERHEAD_CHARGES;

      IF l_row.bill_rate > 0 THEN
        l_row.gross_margin_pct := ROUND(
          ((bill_rate_inr_tot - l_total_cost) / bill_rate_inr_tot) * 100, 2
        );
      ELSE
        l_row.gross_margin_pct := NULL;
      END IF;
      
      PIPE ROW(l_row);
    END LOOP;
    RETURN;
  END get_employee_margin;
END employee_project_pkg;
/
