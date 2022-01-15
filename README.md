# indoor=

indoor= generate Mapbox's Vector Tiles (MVT) of [OpenStreetMap][osm] indoor data. It implements parts of [Simple Indoor Tagging][s-i-t].

Discover:

- [the frontend, indoorequal.org](https://github.com/indoorequal/indoorequal.org)
- [the library to integrate indoor=, mapbox-gl-indoorequal](https://github.com/indoorequal/mapbox-gl-indoorequal)
- [the library to integrate indoor=, openlayers-indoorequal](https://github.com/indoorequal/openlayers-indoorequal)
- [the vector tile schema](https://indoorequal.com/doc/schema)

indoor= is build with [openmaptiles-tools][omt-tools].

## Development

In development, you should disable tiles caching.

Edit `docker-compose.override.yml`:

    version: "3"
    services:
      postserve:
        ports:
        - "8090:8090"
      postserve-cache:

And follow the usage instructions.

You can also run tests written with [pgTAP][]:

    ./script/test

## Usage

To start the initial import of the planet:

    ./script/import

To use another area than the planet, open `.env` file and update the `AREA` variable with the name of your area. Use `make list-geofabrik` to find the available names.
Then run `./script/import`.

To start a one-time update and invalidate the tile cache:

    ./script/update

To generate a mbtiles file located at `data/tiles.mbtiles`

    make generate-tiles-pg

Warning: Depending of the AREA, it can takes a lot of time to generate the mbtiles.


## Running in production

To run the service in production with tiles caching:

    docker-compose up -d postserve postserve-cache

The tiles will be available at http://localhost:8090/

To serve the tiles on another host than `localhost:8090`, for instance `indoorequal.org`, update the `postserve` service and add the `--serve` command line argument with the host.

    postserve --serve=https://indoorequal.org indoorequal.yaml

## License

All code in this repository is under the [BSD license](./LICENSE.md) and the cartography decisions encoded in the schema and SQL are licensed under [CC-BY](./LICENSE.md).

Products or services using maps derived from indoor= schema need to visibly credit "IndoorEqual.org" and "OpenMapTiles.org" or reference "indoor=" and "OpenMapTiles" with a link to https://indoorequal.org/ and https://openmaptiles.org/. Exceptions to attribution requirement can be granted on request.

For a browsable electronic map based on indoor=, OpenMapTiles and OpenStreetMap data, the
credit should appear in the corner of the map. For example:

[© indoor=](https://indoorequal.org/) [© OpenMapTiles](https://openmaptiles.org/) [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright)

For printed and static maps a similar attribution should be made in a textual
description near the image, in the same fashion as if you cite a photograph.

[osm]: https://openstreetmap.org/
[s-i-t]: https://wiki.openstreetmap.org/wiki/Simple_Indoor_Tagging
[omt-tools]: https://github.com/openmaptiles/openmaptiles-tools
[pgtap]: https://pgtap.org/
