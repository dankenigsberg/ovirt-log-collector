--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--
COPY (
    SELECT
        row_number() OVER (ORDER BY vs.vds_name, n.name NULLs last) AS "NO.",
        n.name AS "Network",
        vs.vds_name AS "Host Name",
        sp.name AS "Data Center",
        nic.name AS "Attached to NIC",
        CASE
            WHEN nic.is_bond THEN (
                SELECT 'Bond(slaves:'||string_agg(slave.name, ', ')||')'
                FROM vds_interface slave
                WHERE slave.bond_name = nic.name AND slave.vds_id=nic.vds_id)
            WHEN n.vlan_id IS NOT NULL THEN 'VLAN' ELSE 'Regular NIC'
        END "NIC Type",

        ARRAY_TO_STRING(
            ARRAY[nic.mac_addr,
            (SELECT STRING_AGG(slave.mac_addr, ', ') FROM vds_interface slave WHERE slave.bond_name = nic.name AND slave.vds_id=nic.vds_id)],
            ', '
        ) AS "Related MAC addresses",
        n.addr AS "IPV4 Address",
        n.vlan_id AS "VLAN ID",
        n.mtu AS "MTU",
        n.description AS "Description",
        n.subnet AS "Subnet",
        n.gateway AS "Gateway"
    FROM
        network n
    LEFT OUTER JOIN storage_pool sp on n.storage_pool_id = sp.id
    LEFT OUTER JOIN vds_interface nic on n.name = nic.network_name
    LEFT OUTER JOIN vds_static vs on nic.vds_id = vs.vds_id
    ORDER BY vs.vds_name, n.name
) TO STDOUT WITH CSV DELIMITER E'\|' HEADER;
