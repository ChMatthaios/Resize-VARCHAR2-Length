DECLARE
    l_new_size     NUMBER := 200;
    l_altr_stmnt   VARCHAR2 (200) := 'ALTER SESSION SET CURRENT_SCHEMA = ';
    l_exec_stmnt   VARCHAR2 (200)
                       := 'ALTER TABLE TABLE_NAME MODIFY COLUMN_NAME VARCHAR2(';
    l_exec_trigr   VARCHAR2 (200) := 'ALTER TRIGGER ';
    l_exec_pkg     VARCHAR2 (200) := 'ALTER PACKAGE ';
BEGIN
    FOR schema_rec IN (SELECT DISTINCT owner, table_name
                         FROM all_tables
                        WHERE table_name = 'TABLE_NAME')
    LOOP
        DBMS_OUTPUT.put_line (l_altr_stmnt || schema_rec.owner || ';');
        DBMS_OUTPUT.put_line (l_exec_stmnt || l_new_size || ');');

        FOR trigr_rec
            IN (SELECT DISTINCT trigger_name
                  FROM all_triggers
                 WHERE     table_owner = schema_rec.owner
                       AND table_name = schema_rec.table_name
                       AND DBMS_METADATA.get_ddl ('TRIGGER',
                                                  trigger_name,
                                                  table_owner) LIKE
                               '%COLUMN_NAME%')
        LOOP
            DBMS_OUTPUT.put_line (
                   l_exec_trigr
                || schema_rec.owner
                || '.'
                || trigr_rec.trigger_name
                || ' COMPILE;');
        END LOOP;

        FOR pkg_rec
            IN (SELECT DISTINCT name, TYPE
                  FROM dba_source
                 WHERE     owner = schema_rec.owner
                       AND UPPER (text) LIKE UPPER ('%COLUMN_NAME%')
                       AND TYPE NOT IN ('TRIGGER'))
        LOOP
            DBMS_OUTPUT.put_line (
                   l_exec_pkg
                || schema_rec.owner
                || '.'
                || pkg_rec.name
                || ' COMPILE;');
        END LOOP;
    END LOOP;
END;
