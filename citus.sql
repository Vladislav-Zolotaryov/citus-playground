CREATE extension citus;

select citus_remove_node('worker',5432);

CREATE DATABASE operational;
SELECT run_command_on_workers($cmd$ CREATE DATABASE operational $cmd$);

SELECT citus_set_coordinator_host('manager');

SELECT * from citus_add_node('a-worker', 5432);
SELECT * from citus_add_node('b-worker', 5432);
SELECT * from citus_add_node('c-worker', 5432);

create table actions (
    tenant_id varchar, id varchar, amount decimal,
    PRIMARY KEY(tenant_id, id)
);


SELECT isolate_tenant_to_new_shard(
  'actions', 'tenant-1', 'CASCADE'
);


SELECT citus_move_shard_placement(12345, 'from_host', 5432, 'to_host', 5432);


SELECT shardid, shardstate, shardlength, nodename, nodeport, placementid
  FROM pg_dist_placement AS placement,
       pg_dist_node AS node
 WHERE placement.groupid = node.groupid
   AND node.noderole = 'primary'
   AND shardid = (
     SELECT get_shard_id_for_distribution_column('actions', 'tenant-1')
   );


SELECT *
FROM citus_shards
WHERE table_name = 'actions'::regclass;


SELECT nodename, table_name, sum(shard_size)
FROM citus_shards
group by nodename, table_name having table_name = 'actions'::regclass;


SELECT * FROM get_rebalance_progress();

SELECT * FROM citus_get_active_worker_nodes();

SELECT table_name, table_size
  FROM citus_tables;

SELECT create_distributed_table('actions', 'tenant_id');

SELECT rebalance_table_shards('actions');

insert into actions (
    tenant_id, id, amount
)
select
    'tenant-1',
    gen_random_uuid (),
    random()
from generate_series(1, 1000000) s(i);


insert into actions (
    tenant_id, id, amount
)
select
    'tenant-2',
    gen_random_uuid (),
    random()
from generate_series(1, 200000) s(i);


insert into actions (
    tenant_id, id, amount
)
select
    'tenant-3',
    gen_random_uuid (),
    random()
from generate_series(1, 50000) s(i);


insert into actions (
    tenant_id, id, amount
)
select
    'tenant-4',
    gen_random_uuid (),
    random()
from generate_series(1, 50000) s(i);


insert into actions (
    tenant_id, id, amount
)
select
    'tenant-5',
    gen_random_uuid (),
    random()
from generate_series(1, 50000) s(i);


select count(1) from actions group by tenant_id;