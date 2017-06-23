-- Based on https://github.com/oVirt/ovirt-engine/blob/bf3abca7848496f7cf60d44d9335e2ec0bd3f852/packaging/setup/plugins/ovirt-engine-setup/ovirt-engine/upgrade/asynctasks.py#L228
--
CREATE OR REPLACE FUNCTION __temp_query_get_running_commands()
  RETURNS TABLE(command_type integer, command_id uuid, created_at timestamptz, status VARCHAR(20)) AS
$PROCEDURE$
BEGIN
    -- command_entities is available only in Engine db >= 3.5
    IF EXISTS (SELECT column_name
               FROM information_schema.columns
               WHERE table_name='command_entities') THEN
        RETURN QUERY EXECUTE format('
        SELECT
                command_entities.command_type,
                command_entities.command_id,
                command_entities.created_at,
                command_entities.status
        FROM
                command_entities
        WHERE
                command_entities.callback_enabled = ''true'' AND
                command_entities.callback_notified = ''false''
       ');
   END IF;
END; $PROCEDURE$
LANGUAGE plpgsql;
SELECT __temp_query_get_running_commands();
DROP FUNCTION __temp_query_get_running_commands();