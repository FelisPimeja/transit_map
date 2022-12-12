-- This config example file is released into the Public Domain.

-- This file shows how to use multi-stage processing to bring tags from
-- relations into ways.

-- This will only import ways tagged as highway. The 'rel_refs' text column
-- will contain a comma-separated list of all ref tags found in parent
-- relations with type=route and route=road. The 'rel_ids' column will be
-- an integer array containing the relation ids. These could be used, for
-- instance, to look up other relation tags from the 'routes' table.

-- Table structure
local tables = {}

tables.nodes = osm2pgsql.define_node_table('nodes', {
    { column = 'tags',     type = 'jsonb' },
    -- { column = 'rel_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs)
    { column = 'geom',     type = 'point', projection = 4326, not_null = true },
}, { schema = 'flex' })

tables.ways = osm2pgsql.define_way_table('ways', {
    { column = 'tags',     type = 'jsonb' },
    -- { column = 'rel_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs)
    { column = 'geom',     type = 'linestring', projection = 4326, not_null = true },
}, { schema = 'flex' })

tables.route = osm2pgsql.define_relation_table('route', {
    { column = 'tags', type = 'jsonb' },
    { column = 'members', type = 'jsonb' },
    { column = 'geom', type = 'geometrycollection', projection = 4326 },
}, { schema = 'flex' })

tables.route_master = osm2pgsql.define_relation_table('route_master', {
    { column = 'tags', type = 'jsonb' },
    { column = 'members', type = 'jsonb' },
    { column = 'geom', type = 'geometrycollection', projection = 4326 },
}, { schema = 'flex' })

tables.stop_area = osm2pgsql.define_relation_table('stop_area', {
    { column = 'tags', type = 'jsonb' },
    { column = 'members', type = 'jsonb' },
    { column = 'geom', type = 'geometrycollection', projection = 4326 },
}, { schema = 'flex' })

tables.stop_area_group = osm2pgsql.define_relation_table('stop_area_group', {
    { column = 'tags', type = 'jsonb' },
    { column = 'members', type = 'jsonb' },
    { column = 'geom', type = 'geometrycollection', projection = 4326 },
}, { schema = 'flex' })

-- Preprocess data
local w2r = {}

function clean_tags(tags)
    tags.odbl = nil
    tags.created_by = nil
    tags.source = nil
    tags['source:ref'] = nil

    return next(tags) == nil
end

function osm2pgsql.process_node(object)
    if object.tags.highway == ('bus_stop' or 'platform' or 'stop') or object.tags.railway == ('tram_stop' or 'halt' or 'platform' or 'station' or 'stop') then
        -- return clean_tags(object.tags)
        tables.nodes:insert({
            tags = object.tags,
            geom = object:as_point()
        })
    end
end

function osm2pgsql.process_way(object)
    -- We are only interested in highways
    if not (object.tags.highway or object.tags.railway) then
        return
    end

    clean_tags(object.tags)

    -- Data we will store in the "highways" table always has the tags from
    -- the way
    local row = {
        tags = object.tags,
        geom = object:as_linestring()
    }

    -- If there is any data from parent relations, add it in
    local d = w2r[object.id]
    if d then
        local refs = {}
        local ids = {}
        for rel_id, rel_ref in pairs(d) do
            refs[#refs + 1] = rel_ref
            ids[#ids + 1] = rel_id
        end
        table.sort(refs)
        table.sort(ids)
        row.rel_refs = table.concat(refs, ',')
        row.rel_ids = '{' .. table.concat(ids, ',') .. '}'
    end

    tables.ways:insert(row)
end

function osm2pgsql.process_relation(object)
    if object.tags.type == ('route') and object.tags.ref then
        -- return clean_tags(object.tags)
        tables.route:insert({
            tags = object.tags,
            members = object.members,
            geom = object:as_geometrycollection()
        })

    elseif object.tags.type == 'route_master' then
        -- return clean_tags(object.tags)
        tables.route_master:insert({
            tags = object.tags,
            members = object.members,
            geom = object:as_geometrycollection()
        })
    
    elseif object.tags.public_transport == 'stop_area' then
        -- return clean_tags(object.tags)
        tables.stop_area:insert({
            tags = object.tags,
            members = object.members,
            geom = object:as_geometrycollection()
        })

    elseif object.tags.public_transport == 'stop_area_group' then
        -- return clean_tags(object.tags)
        tables.stop_area_group:insert({
            tags = object.tags,
            members = object.members,
            geom = object:as_geometrycollection()
        })
    end
end

