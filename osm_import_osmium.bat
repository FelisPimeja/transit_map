@echo off
FOR /F "eol=# tokens=*" %%i IN (%~dp0\.env) DO SET %%i

@echo on
:: filter dump
@REM osmium tags-filter %DATADIR%Moscow.osm.pbf wr/type=route wnr/public_transport=* wnr/station=* wnr/highway=bus_stop wnr/railway=station,hallt,stop,tram_stop -o %DATADIR%data_filtered.osm.pbf
osmium tags-filter %DATADIR%Moscow.osm r/type=route -o %DATADIR%test1.osm --overwrite
@REM osmium extract -b 37.340881,55.556447,37.869598,55.921354 %DATADIR%central-fed-district-latest.osm.pbf -o %DATADIR%clip.osm.pbf --overwrite


@REM psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDB% -c "drop table if exists public.osm;"
@REM osmium export -c %DIR%osmium_config.json -f pg %DATADIR%clip.osm.pbf  -v --progress | psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDB% -1 -c "create table osm(geog geography, osm_type text, osm_id bigint, osm_user text, ts timestamptz, way_nodes bigint[], tags jsonb); copy osm from stdin;"


@REM alter table osm alter geog set storage external, alter osm_type set storage main, alter osm_user set storage main, alter way_nodes set storage external, alter tags set storage external, set (fillfactor=100);
