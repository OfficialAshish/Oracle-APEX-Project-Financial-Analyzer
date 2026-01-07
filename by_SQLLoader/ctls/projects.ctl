OPTIONS (SKIP = 1)
LOAD DATA
    INFILE 'data/projects.csv'
    INTO TABLE projects
    REPLACE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' 
    TRAILING NULLCOLS
    (
        project_id                 NULLIF project_id=BLANKS,
        project_name              CHAR(200) NULLIF project_name=BLANKS,
        client_name               CHAR(200) NULLIF client_name=BLANKS,
        start_date                "CASE WHEN :start_date IS NULL OR TRIM(:start_date)='' 
                                        THEN NULL 
                                        ELSE TO_DATE(:start_date, 'DD-MM-YYYY') END",
        end_date                  "CASE WHEN :end_date IS NULL OR TRIM(:end_date)='' 
                                        THEN NULL 
                                        ELSE TO_DATE(:end_date, 'DD-MM-YYYY') END",
        total_revenue             "CASE WHEN :total_revenue IS NULL OR TRIM(:total_revenue)='' 
                                        THEN NULL 
                                        ELSE TO_NUMBER(REPLACE(REPLACE(:total_revenue, '$',''),',','')) END",
        original_sow_amount       "CASE WHEN :original_sow_amount IS NULL OR TRIM(:original_sow_amount)='' 
                                        THEN NULL 
                                        ELSE TO_NUMBER(REPLACE(REPLACE(:original_sow_amount, '$',''),',','')) END",
        cr_1  "CASE 
                WHEN :cr_1 IS NULL OR TRIM(:cr_1)='' 
                    OR REPLACE(REPLACE(TRIM(:cr_1),'$',''),',','') IN ('-','.') 
                THEN NULL 
                ELSE TO_NUMBER(REPLACE(REPLACE(TRIM(:cr_1),'$',''),',','')) 
            END",

        cr_2  "CASE 
                WHEN :cr_2 IS NULL OR TRIM(:cr_2)='' 
                    OR REPLACE(REPLACE(TRIM(:cr_2),'$',''),',','') IN ('-','.') 
                THEN NULL 
                ELSE TO_NUMBER(REPLACE(REPLACE(TRIM(:cr_2),'$',''),',','')) 
            END",

        cr_3  "CASE 
                WHEN :cr_3 IS NULL OR TRIM(:cr_3)='' 
                    OR REPLACE(REPLACE(TRIM(:cr_3),'$',''),',','') IN ('-','.') 
                THEN NULL 
                ELSE TO_NUMBER(REPLACE(REPLACE(TRIM(:cr_3),'$',''),',','')) 
            END"
       -- project_status          CHAR(50) NULLIF project_status=BLANKS
    )
