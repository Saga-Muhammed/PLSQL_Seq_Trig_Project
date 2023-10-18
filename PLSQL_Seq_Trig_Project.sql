DECLARE 
  l_max_value NUMBER; 
    CURSOR tab_cursor IS 
    SELECT cc.table_name, cc.column_name 
    FROM user_cons_columns cc
    JOIN user_constraints c ON cc.constraint_name = c.constraint_name
    JOIN user_tab_columns tc ON cc.table_name = tc.table_name AND cc.column_name = tc.column_name 
    WHERE c.constraint_type = 'P' 
    AND tc.data_type IN ('NUMBER', 'INTEGER', 'FLOAT'); 
BEGIN 
  FOR tab_record IN tab_cursor LOOP
    DECLARE 
      l_table_name user_tab_columns.table_name%TYPE := tab_record.table_name; 
      l_column_name user_tab_columns.column_name%TYPE := tab_record.column_name; 
      l_sequence_name VARCHAR2(30); 
    CURSOR seq_cursor IS
    SELECT * FROM user_sequences WHERE sequence_name = SUBSTR(l_table_name || '_' || l_column_name || '_SEQ', 1, 30);
    BEGIN
      -- Drop existing sequences 
      FOR seq_record IN seq_cursor
        LOOP 
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || seq_record.sequence_name; 
      END LOOP;

      -- Get the maximum value 
      EXECUTE IMMEDIATE 'SELECT NVL(MAX(' || l_column_name || '), 0) + 1 FROM ' || l_table_name INTO l_max_value;

      -- Set the sequence name 
      l_sequence_name := SUBSTR(l_table_name || '_' || l_column_name || '_SEQ', 1, 30); 
/*
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || tc.table_name || '_SEQ ' ||
      'START WITH (SELECT  NVL (MAX(' || tc.column_name || '),0) + 1 FROM ' || tc..table_name || ') ' ||
*/
      -- Create the sequence using the calculated value and the sequence name
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || l_sequence_name || ' ' || 'START WITH ' || l_max_value || ' ' || 'INCREMENT BY 1';

     -- Create a trigger 
      EXECUTE IMMEDIATE '
        CREATE OR REPLACE TRIGGER trigg_insert_' || l_table_name || ' 
        BEFORE INSERT ON ' || l_table_name || ' 
        FOR EACH ROW 
        BEGIN 
          :new.' || l_column_name || ' := ' || l_sequence_name || '.NEXTVAL; 
        END;';
      
    END;
  END LOOP; 
END; 
