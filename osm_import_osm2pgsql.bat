@echo off
FOR /F "eol=# tokens=*" %%i IN (%~dp0\.env) DO SET %%i

@echo on
@REM osm2pgsql -c -d %PGDB% -U %PGUSER% -H %PGHOST% -S %DIR%osm2pgsql.style %DATADIR%test1.osm
osm2pgsql -c -d %PGDB% -U %PGUSER% -H %PGHOST% --output=flex -S %DIR%routes.lua --hstore --multi-geometry %DATADIR%test1.osm
@REM osm2pgsql --cache 1024 --number-processes 4 --verbose --create --database mc --output=flex --style bus-routes.lua --slim --flat-nodes nodes.cache --hstore --multi-geometry --drop