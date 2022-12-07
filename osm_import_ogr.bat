@echo off
FOR /F "eol=# tokens=*" %%i IN (%~dp0\.env) DO SET %%i

set startTime=%time%

@REM :: Importing routes
@REM @echo on
@REM ogr2ogr PostgreSQL PG:"dbname=%PGDB% user=%PGUSER% password=%PGPASS% host=%PGHOST% port=%PGPORT%" ^
@REM  -sql "drop table if exists public.route;"
@REM ogr2ogr -f PostgreSQL PG:"dbname=%PGDB% user=%PGUSER% password=%PGPASS% host=%PGHOST% port=%PGPORT%" "%OSMDATA%" ^
@REM  -sql "select type, route, via, name, official_name, ref, operator, network, interval, duration, colour, service, other_tags, geometry from lines where type='route' union all select type, route, via, name, official_name, ref, operator, network, interval, duration, colour, service, other_tags, geometry from multilinestrings where type='route';" ^
@REM  --config OSM_CONFIG_FILE "%OSM_CONFIG%" ^
@REM  --config PG_USE_COPY YES ^
@REM  --config MAX_TMPFILE_SIZE 2048 ^
@REM  -nln public.route ^
@REM  -nlt MULTILINESTRING ^
@REM  -lco GEOMETRY_NAME=geom ^
@REM  -lco SPATIAL_INDEX=NONE ^
@REM  -lco COLUMN_TYPES=other_tags=hstore ^
@REM  -lco FID=id ^
@REM  -dialect SQLite ^
@REM  -overwrite

ogr2ogr PostgreSQL PG:"dbname=%PGDB% user=%PGUSER% password=%PGPASS% host=%PGHOST% port=%PGPORT%" ^
 -sql "drop table if exists public.transport_pnt;"
ogr2ogr -f PostgreSQL PG:"dbname=%PGDB% user=%PGUSER% password=%PGPASS% host=%PGHOST% port=%PGPORT%" "%OSMDATA%" ^
 -sql "select public_transport, highway, railway, station, name, other_tags, geometry from points where public_transport in ('platform', 'stop_position', 'station', 'stop_area') or highway in ('bus_stop') or railway in ('station', 'platform', 'halt') or station in ('subway');" ^
 --config OSM_CONFIG_FILE "%OSM_CONFIG%" ^
 --config PG_USE_COPY YES ^
 --config MAX_TMPFILE_SIZE 2048 ^
 -nln public.transport_pnt ^
 -nlt POINT ^
 -lco GEOMETRY_NAME=geom ^
 -lco SPATIAL_INDEX=NONE ^
 -lco COLUMN_TYPES=other_tags=hstore ^
 -lco FID=id ^
 -dialect SQLite ^
 -overwrite


@REM :: Importing railways
@REM @echo on
@REM ogr2ogr PostgreSQL PG:"dbname=%PGDB% user=%PGUSER% password=%PGPASSWORD host=%PGHOST% port=%PGPORT%" ^
@REM  -sql "drop table if exists public.railway;^
@REM ogr2ogr -f PostgreSQL PG:"dbname=%PGDB% user=%PGUSER% password=%PGPASS% host=%PGHOST% port=%PGPORT%" "%OSMDATA%" ^
@REM  -sql "select railway type, name, service, null id_gis, other_tags, geometry from lines where railway is not null" ^
@REM  --config OSM_CONFIG_FILE "%OSM_CONFIG%" ^
@REM  --config PG_USE_COPY YES ^
@REM  --config MAX_TMPFILE_SIZE 2048 ^
@REM  -nln public.railway ^
@REM  -nlt MULTILINESTRING ^
@REM  -lco GEOMETRY_NAME=geom ^
@REM  -lco SPATIAL_INDEX=NONE ^
@REM  -lco COLUMN_TYPES=other_tags=hstore,id_gis=smallint ^
@REM  -lco FID=id ^
@REM  -dialect SQLite ^
@REM  -overwrite





@REM :: Приведение, обработка, индексы и комментарии
@REM ogr2ogr ^
@REM  PostgreSQL PG:"dbname=%PGDB% user=%PGUSER% password=%PGPASSWORD host=%PGHOST% port=%PGPORT%" ^
@REM  -sql ^
@REM "/* Проверка геометрии, id_gis и площади */ ^
@REM update russia.railway_osm set geom = st_collectionextract(st_makevalid(st_removerepeatedpoints(st_snaptogrid(geom, 0.0000001))), 2); ^
@REM delete from russia.railway_osm where st_isempty(geom) is true; ^
@REM alter table russia.railway_osm add constraint fk_id_gis foreign key(id_gis) references russia.city(id_gis); ^
@REM create index on russia.railway_osm using gist(geom);^
@REM update russia.railway_osm b set id_gis = bn.id_gis from russia.city bn where st_within(b.geom, bn.geom); ^
@REM /* Индексы */ ^
@REM create index on russia.railway_osm(type); ^
@REM create index on russia.railway_osm(id_gis); ^
@REM create index on russia.railway_osm(name); ^
@REM create index on russia.railway_osm(service); ^
@REM create index on russia.railway_osm using gin(other_tags); ^
@REM create index railway_osm_geog_idx on russia.railway_osm using gist((geom::geography)); ^
@REM /* Комментарии */ ^
@REM comment on table russia.railway_osm is 'Железные дороги (OpenStreetMap). Актуальность - %date%';^
@REM comment on column russia.railway_osm.id is 'Первичный ключ';^
@REM comment on column russia.railway_osm.type is 'Тип железной дороги по OpenStreetMap. См. https://wiki.openstreetmap.org/wiki/Key:railway';^
@REM comment on column russia.railway_osm.name is 'Название дороги или улицы которая по ней проходит';^
@REM comment on column russia.railway_osm.service is 'Тип сервисного жд пути. См. https://wiki.openstreetmap.org/wiki/Key:railway:service';^
@REM comment on column russia.railway_osm.other_tags is 'Прочие теги';^
@REM comment on column russia.railway_osm.geom is 'Геометрия';^
@REM comment on column russia.railway_osm.id_gis is 'id_gis города. Внешний ключ';"


echo Importing railways Start: %startTime%   Finish: %time%

