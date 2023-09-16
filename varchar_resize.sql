-- When running a block like this you must be sure of the commands that are 
-- going to be ran.
-- So before compiling/running the block, instead of EXECUTE IMMEDIATE, run 
-- DBMS_OUTPUT.PUT_LINE('');

DECLARE
    l_new_size NUMBER := 200;
    l_stmnt    VARCHAR2(200);
BEGIN
    FOR schema_rec IN (SELECT DISTINCT owner, table_name
                         FROM all_tables
                        WHERE table_name = 'TABLE_NAME')
    LOOP
        -- Alter the table in the current schema resizing the column
        l_stmnt := 'ALTER TABLE ' || schema_rec.owner || '.' ||
                   schema_rec.table_name || ' MODIFY COLUMN_NAME VARCHAR2(' ||
                   l_new_size || ');';
    
        EXECUTE IMMEDIATE l_stmnt;
    
        COMMIT;
    
        -- Check for triggers using your column
        FOR trigr_rec IN (SELECT DISTINCT trigger_name
                            FROM all_triggers
                           WHERE table_owner = schema_rec.owner
                             AND table_name = schema_rec.table_name
                             AND dbms_metadata.get_ddl('TRIGGER',
                                                       trigger_name,
                                                       table_owner) LIKE
                                 '%COLUMN_NAME%')
        LOOP
            -- And recompile them to be sure everything runs as it ran
            l_stmnt := 'ALTER TRIGGER ' || schema_rec.owner || '.' ||
                       trigr_rec.trigger_name || ' COMPILE;';
        
            EXECUTE IMMEDIATE l_stmnt;
        END LOOP;
    
        -- Check for packages using your column
        FOR pkg_rec IN (SELECT DISTINCT NAME, TYPE
                          FROM dba_source
                         WHERE owner = schema_rec.owner
                           AND UPPER(text) LIKE UPPER('%COLUMN_NAME%')
                           AND TYPE NOT IN ('TRIGGER'))
        LOOP
            -- And recompile them to be sure everything runs as it ran
            l_stmnt := 'ALTER PACKAGE ' || schema_rec.owner || '.' ||
                       pkg_rec.name || ' COMPILE;';
        
            EXECUTE IMMEDIATE l_stmnt;
        END LOOP;
    END LOOP;
END;
