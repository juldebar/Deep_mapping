SELECT 'DROP VIEW "' || table_name || '"";'   FROM information_schema.views WHERE table_name LIKE 'view_session%'
