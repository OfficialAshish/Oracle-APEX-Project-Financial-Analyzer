-- =============================================================================
-- Schema for Project_Health Oracle 23ai Application
-- =============================================================================
-- This script creates all the necessary tables, sequences, indexes, and packages
-- required for the Project_Health application to run correctly.
--
-- To execute, connect to your Oracle database as the application user (e.g., "ASHISH")
-- and run this script.
-- =============================================================================

-- Drop existing objects (optional, for a clean slate)
BEGIN
  FOR i IN (SELECT table_name FROM user_tables WHERE table_name IN ('TIMESHEETS', 'PROJECTS', 'EMPLOYEES', 'UPLOAD_AUDIT', 'CRUD_AUDIT')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || i.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR i IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN ('PROJECT_ASSIGNMENT_SEQ', 'TIMESHEET_SEQ', 'CRUD_AUDIT_SEQ')) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || i.sequence_name;
  END LOOP;
END;
/

-- =============================================================================
-- SEQUENCES
-- =============================================================================

CREATE SEQUENCE TIMESHEET_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE CRUD_AUDIT_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- =============================================================================
-- TABLES
-- Not using references as data mostly fails relationship in excels..
-- =============================================================================


CREATE TABLE EMPLOYEES (
    employee_id        VARCHAR2(80)    PRIMARY KEY,
    employee_name      VARCHAR2(150)   NOT NULL,
    designation        VARCHAR2(80),
    grade              VARCHAR2(10),
    competency         VARCHAR2(80),
    annual_ctc         NUMBER(12,2)
);

CREATE TABLE PROJECTS (
    project_id          VARCHAR2(80) ,
    project_name        VARCHAR2(150),
    client_name         VARCHAR2(150),
    start_date          DATE,
    end_date            DATE,
    total_revenue       NUMBER(15,2),
    original_sow_amount NUMBER(15,2),
    cr_1                NUMBER(15,2),
    cr_2                NUMBER(15,2),
    cr_3                NUMBER(15,2)
    -- ,project_status      VARCHAR2(80)
);


CREATE TABLE TIMESHEETS (
    timesheet_id         NUMBER PRIMARY KEY,
    employee_id          VARCHAR2(80) NOT NULL,
    employee_name        VARCHAR2(150),
    email                VARCHAR2(150),
    daily_date           DATE NOT NULL,
    week_starts_on       DATE,
    time_worked          NUMBER(4,2),
    approved_by          VARCHAR2(150),
    approved_on          TIMESTAMP,
    time_card_state      VARCHAR2(80),
    task_type            VARCHAR2(30),
    task_type_category   VARCHAR2(80),
    task_name            VARCHAR2(150),
    timesheet_user       VARCHAR2(30),
    resource_is_active   VARCHAR2(30),
    employee_type        VARCHAR2(30),
    irm                  VARCHAR2(150),
    srm                  VARCHAR2(150),
    resource_entity      VARCHAR2(150),
    project_name         VARCHAR2(150),
    customer_name        VARCHAR2(150)
    -- ,CONSTRAINT fk_ts_employee FOREIGN KEY (employee_id) REFERENCES EMPLOYEES(employee_id) ON DELETE CASCADE
    -- ,CONSTRAINT fk_ts_project FOREIGN KEY (project_id) REFERENCES PROJECTS(project_id) ON DELETE CASCADE
);

CREATE TABLE UPLOAD_AUDIT (
    upload_id VARCHAR2(32) PRIMARY KEY,
    username VARCHAR2(100) NOT NULL,
    table_name VARCHAR2(128) NOT NULL,
    file_name VARCHAR2(255) NOT NULL,
    file_hash VARCHAR2(64) NOT NULL,
    rows_loaded NUMBER,
    rows_rejected NUMBER,
    load_mode VARCHAR2(20),
    upload_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    status VARCHAR2(20) NOT NULL,
    CONSTRAINT chk_upload_status CHECK (status IN ('SUCCESS', 'FAILED'))
);

CREATE TABLE CRUD_AUDIT (
    action_id NUMBER PRIMARY KEY,
    username VARCHAR2(100) NOT NULL,
    table_name VARCHAR2(128) NOT NULL,
    action_type VARCHAR2(20) NOT NULL,
    record_id VARCHAR2(100),
    action_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT chk_crud_action CHECK (action_type IN ('CREATE', 'UPDATE', 'DELETE'))
);

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX idx_employees_name ON EMPLOYEES(employee_name);
CREATE INDEX idx_projects_name ON PROJECTS(project_name);
CREATE INDEX idx_ts_employee_id ON TIMESHEETS(employee_id);
CREATE INDEX idx_ts_project_id ON TIMESHEETS(project_name);
CREATE INDEX idx_ts_daily_date ON TIMESHEETS(daily_date);

-- =============================================================================
-- RUNNING PACKAGES Script
-- =============================================================================
@'scripts/create_pkg.sql'


exit;