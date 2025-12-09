# Tilemaker Guide for Geezer Guides

This guide explains how to generate MBTiles files using Tilemaker for use in the Geezer Guides app.

## Prerequisites

- Tilemaker installed (you mentioned you have this)
- OSM data extract for your region

## Step 1: Download OSM Data

Download the OSM extract for your region from Geofabrik:

**For Barcelona:**
```bash
wget https://download.geofabrik.de/europe/spain/catalunya-latest.osm.pbf
```

**For Eleuthera:**
```bash
wget https://download.geofabrik.de/central-america/bahamas-latest.osm.pbf
```

## Step 2: Basic Tilemaker Command

Generate an MBTiles file with default OSM schema:

```bash
tilemaker --input catalunya-latest.osm.pbf \
  --output barcelona.mbtiles \
  --process resources/process-openmaptiles.lua \
  --config resources/config-openmaptiles.json \
  --bbox 2.05,41.32,2.25,41.47
```

**Explanation:**
- `--input`: OSM PBF file
- `--output`: Output MBTiles file
- `--process`: Lua config defining which features to extract
- `--config`: JSON config for zoom levels and tile settings
- `--bbox`: Bounding box (minLon,minLat,maxLon,maxLat) to limit the area

## Step 3: Custom Lua Configuration (For Thematic Layers)

Create a custom Lua file to extract specific features:

**Example: `process-geezerguides.lua`**

```lua
-- Tilemaker configuration for Geezer Guides
-- Extracts thematic layers: transport, food, entertainment, hotels, waypoints

-- Base layers (always needed)
node_keys = {"amenity", "shop", "tourism", "cuisine", "public_transport"}
way_keys = {"highway", "building", "waterway", "natural", "landuse"}

-- WATER LAYER
function attribute_function(attr)
    if attr["natural"] == "water" or attr["waterway"] then
        return {
            layer = "water",
            minzoom = 0
        }
    end
end

-- TRANSPORTATION LAYER (roads, rail, bus stops)
function way_function(way)
    local highway = way:Find("highway")
    local railway = way:Find("railway")

    if highway ~= "" then
        local layer = "transportation"
        local class = highway

        -- Determine road class
        if highway == "motorway" or highway == "trunk" then
            class = "motorway"
        elseif highway == "primary" or highway == "secondary" then
            class = "primary"
        elseif highway == "tertiary" then
            class = "tertiary"
        elseif highway == "residential" or highway == "unclassified" then
            class = "street"
        else
            class = "minor"
        end

        way:Layer(layer, false)
        way:Attribute("class", class)
        way:MinZoom(5)
    end

    if railway ~= "" then
        way:Layer("transportation", false)
        way:Attribute("class", "rail")
        way:MinZoom(8)
    end
end

function node_function(node)
    local public_transport = node:Find("public_transport")

    -- TRANSPORT POIs (bus stops, metro stations)
    if public_transport == "stop_position" or public_transport == "platform" then
        node:Layer("transport_poi", true)
        node:Attribute("name", node:Find("name"))
        node:Attribute("type", node:Find("public_transport"))
        node:MinZoom(13)
    end

    -- FOOD LAYER (restaurants, cafes, bars)
    local amenity = node:Find("amenity")
    if amenity == "restaurant" or amenity == "cafe" or amenity == "bar" or amenity == "fast_food" then
        node:Layer("food_poi", true)
        node:Attribute("name", node:Find("name"))
        node:Attribute("cuisine", node:Find("cuisine"))
        node:Attribute("type", amenity)
        node:MinZoom(14)
    end

    -- ENTERTAINMENT LAYER (museums, theaters, parks)
    local tourism = node:Find("tourism")
    if tourism == "museum" or tourism == "gallery" or tourism == "attraction" or
       tourism == "viewpoint" or tourism == "theme_park" then
        node:Layer("entertainment_poi", true)
        node:Attribute("name", node:Find("name"))
        node:Attribute("type", tourism)
        node:MinZoom(13)
    end

    -- HOTELS LAYER (hotels, hostels, guest houses)
    if tourism == "hotel" or tourism == "hostel" or tourism == "guest_house" or tourism == "apartment" then
        node:Layer("hotel_poi", true)
        node:Attribute("name", node:Find("name"))
        node:Attribute("type", tourism)
        node:MinZoom(13)
    end
end
```

## Step 4: Custom Config JSON

Create a config file that defines zoom levels:

**Example: `config-geezerguides.json`**

```json
{
  "layers": {
    "water": { "minzoom": 0, "maxzoom": 14 },
    "transportation": { "minzoom": 5, "maxzoom": 14 },
    "building": { "minzoom": 13, "maxzoom": 14 },
    "transport_poi": { "minzoom": 13, "maxzoom": 14 },
    "food_poi": { "minzoom": 14, "maxzoom": 14 },
    "entertainment_poi": { "minzoom": 13, "maxzoom": 14 },
    "hotel_poi": { "minzoom": 13, "maxzoom": 14 }
  },
  "settings": {
    "minzoom": 0,
    "maxzoom": 14,
    "basezoom": 14,
    "compress": "gzip"
  }
}
```

## Step 5: Generate MBTiles with Custom Config

```bash
tilemaker --input catalunya-latest.osm.pbf \
  --output barcelona.mbtiles \
  --process process-geezerguides.lua \
  --config config-geezerguides.json \
  --bbox 2.05,41.32,2.25,41.47 \
  --verbose
```

## Step 6: Add to Flutter App

Once you have the MBTiles file:

1. Copy it to the project:
   ```bash
   cp barcelona.mbtiles "assets/maps/"
   ```

2. Update `pubspec.yaml` to uncomment the asset:
   ```yaml
   assets:
     - assets/osm_bright.json
     - assets/maps/barcelona.mbtiles
   ```

3. Run Flutter:
   ```bash
   flutter pub get
   flutter run --release
   ```

## Verifying MBTiles

You can inspect your MBTiles file using SQLite:

```bash
sqlite3 barcelona.mbtiles
```

```sql
-- Show metadata
SELECT * FROM metadata;

-- Show available zoom levels
SELECT DISTINCT zoom_level FROM tiles ORDER BY zoom_level;

-- Count tiles at each zoom level
SELECT zoom_level, COUNT(*) as tile_count
FROM tiles
GROUP BY zoom_level
ORDER BY zoom_level;

-- Show a sample tile
SELECT zoom_level, tile_column, tile_row, length(tile_data) as size_bytes
FROM tiles
LIMIT 5;
```

## Troubleshooting

**Problem: Tiles are empty or not rendering**
- Check that your bbox coordinates are correct (minLon,minLat,maxLon,maxLat)
- Verify layer names in your Lua config match the style JSON
- Ensure zoom levels in config match what MapLibre expects

**Problem: File too large**
- Reduce maxzoom (14 is usually sufficient for city-level detail)
- Narrow the bounding box to only cover essential areas
- Remove unnecessary POI layers

**Problem: Missing features**
- Check your Lua config includes the OSM tags you need
- Verify minzoom settings allow features to appear
- Use `--verbose` flag to see what Tilemaker is processing

## Layer Names in App

The app's style JSON (`assets/osm_bright.json`) expects these standard layers:
- `water` - Water bodies
- `waterway` - Rivers, streams
- `landuse` - Parks, residential areas
- `building` - Buildings (zoom 13+)
- `transportation` - Roads, railways
- `transportation_name` - Road labels
- `place` - City/town labels
- `poi` - Points of interest

You can add custom layers to the style JSON by editing it and adding new layer definitions that match your Lua output.

## Next Steps

1. Generate MBTiles for Barcelona and Eleuthera
2. Test locally to verify layer rendering
3. Upload to AWS for distribution (instructions TBD)
4. Implement download manager in app to fetch MBTiles bundles
