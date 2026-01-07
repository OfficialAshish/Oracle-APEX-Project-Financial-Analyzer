OPTIONS (SKIP = 1)
LOAD DATA
    INFILE 'data/employees.csv'
    INTO TABLE employees
    REPLACE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' 
    TRAILING NULLCOLS
    (
        employee_id   ,
        employee_name ,
        designation   ,
        grade         ,
        competency    NULLIF competency=BLANKS,
        annual_ctc    
    )