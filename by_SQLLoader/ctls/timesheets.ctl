OPTIONS (SKIP = 1)
LOAD DATA
    INFILE 'data/timesheets.csv'
    INTO TABLE timesheets
    REPLACE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' 
    TRAILING NULLCOLS
    (
        employee_id,
        employee_name,
        email,
        daily_date CHAR(20) "CASE WHEN :daily_date IS NULL OR TRIM(:daily_date)='' 
                        THEN NULL 
                        ELSE TO_DATE(TRIM(:daily_date),'YYYY-MM-DD') END",

        week_starts_on   "CASE WHEN :week_starts_on IS NULL OR TRIM(:week_starts_on)='' 
                            THEN NULL 
                            ELSE TO_TIMESTAMP(:week_starts_on,'YYYY-MM-DD HH24:MI:SS') END",
        
        time_worked,
        approved_by,
        approved_on      "CASE WHEN :approved_on IS NULL OR TRIM(:approved_on)='' 
                            THEN NULL 
                            ELSE TO_TIMESTAMP(:approved_on,'YYYY-MM-DD HH24:MI:SS') END",
        time_card_state,
        task_type,
        task_type_category,
        task_name,
        timesheet_user,
        resource_is_active,
        employee_type            NULLIF employee_type=BLANKS,
        irm,
        srm,
        resource_entity           NULLIF resource_entity=BLANKS,
        project_name           NULLIF project_name=BLANKS,
        customer_name           NULLIF customer_name=BLANKS,
        timesheet_id           "TIMESHEET_SEQ.NEXTVAL"
    )

