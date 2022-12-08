drop table if exists nodes_tmp1;
create table nodes_tmp1 as
with centroid as (
	select 
		tags->>'name' name, 
		st_centroid(st_collect(geom)) geom
	from nodes 
	group by tags->>'name'
),
filtered as ( 
	select distinct 
		c.*
	from nodes n
	left join centroid c 
		on n.tags->>'name' = c.name
	where st_distance(c.geom, n.geom) <= 500
)
select 
	tags->>'name' name, 
	c.geom centroid,
	st_collect(st_makeline(c.geom, n.geom)) lines,
	st_buffer(st_transform(st_collect(st_makeline(c.geom, n.geom)), 4326)::geography, 10) buffers
from nodes n
left join filtered c 
	on n.tags->>'name' = c.name
group by tags->>'name', c.geom