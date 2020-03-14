all: build/indoorequal.tm2source/data.yml build/mapping.yaml build/tileset.sql

help:
	@echo "=============================================================================="
	@echo " Indoor= https://github.com/indoorequal "
	@echo "Hints for designers:"
	@echo "  make start-postserve                 # start Postserver + Maputnik Editor [ see localhost:8088 ] "
	@echo "  make start-tileserver                # start klokantech/tileserver-gl [ see localhost:8080 ] "
	@echo "  "
	@echo "Hints for developers:"
	@echo "  make                                 # build source code"
	@echo "  make psql-vacuum-analyze             # PostgreSQL: VACUUM ANALYZE"
	@echo "  make psql-analyze                    # PostgreSQL: ANALYZE"
	@echo "  make generate-qareports              # generate reports [./build/qareports]"
	@echo "  make generate-devdoc                 # generate devdoc including graphs for all layers  [./build/devdoc]"
	@echo "  make etl-graph                       # hint for generating a single etl graph"
	@echo "  make mapping-graph                   # hint for generating a single mapping graph"
	@echo "  make import-sql-dev                  # start import-sql /bin/bash terminal"
	@echo "  make import-osm-dev                  # start import-osm /bin/bash terminal (imposm3)"
	@echo "  make clean-docker                    # remove docker containers, PG data volume"
	@echo "  make forced-clean-sql                # drop all PostgreSQL tables for clean environment"
	@echo "  make docker-unnecessary-clean        # clean unnecessary docker image(s) and container(s)"
	@echo "  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB"
	@echo "  make remove-docker-images            # remove openmaptiles docker images"
	@echo "  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM information"
	@echo "  make help                            # help about available commands"
	@echo "=============================================================================="

build:
	mkdir -p build

build/indoorequal.tm2source/data.yml: build
	mkdir -p build/indoorequal.tm2source
	docker-compose run --rm openmaptiles-tools generate-tm2source indoorequal.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > build/indoorequal.tm2source/data.yml

build/mapping.yaml: build
	docker-compose run --rm openmaptiles-tools generate-imposm3 indoorequal.yaml > build/mapping.yaml

build/tileset.sql: build
	docker-compose run --rm openmaptiles-tools generate-sql indoorequal.yaml > build/tileset.sql

clean:
	rm -f build/indoorequal.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql

db-start:
	docker-compose up -d postgres

psql: db-start
	docker-compose run --rm import-osm /usr/src/app/psql.sh

import-osm: db-start all
	docker-compose run --rm import-osm

import-sql: db-start all
	docker-compose run --rm import-sql

import-osmsql: db-start all
	docker-compose run --rm import-osm
	docker-compose run --rm import-sql

generate-tiles: db-start all
	rm -rf data/tiles.mbtiles
	if [ -f ./data/docker-compose-config.yml ]; then \
		docker-compose -f docker-compose.yml -f ./data/docker-compose-config.yml run --rm generate-vectortiles; \
	else \
		docker-compose run --rm generate-vectortiles; \
	fi
	docker-compose run --rm openmaptiles-tools  generate-metadata ./data/tiles.mbtiles
	docker-compose run --rm openmaptiles-tools  chmod 666         ./data/tiles.mbtiles


start-tileserver:
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Download/refresh klokantech/tileserver-gl docker image"
	@echo "* see documentation: https://github.com/klokantech/tileserver-gl"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker pull klokantech/tileserver-gl
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start klokantech/tileserver-gl "
	@echo "*       ----------------------------> check localhost:8080 "
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run -it --rm --name tileserver-gl -v $$(pwd)/data:/data -p 8080:80 klokantech/tileserver-gl

start-postserve:
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Bring up postserve at localhost:8090/tiles/{z}/{x}/{y}.pbf"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker-compose up -d postserve

layers = $(notdir $(wildcard layers/*)) # all layers

etl-graph:
	@echo 'Use'
	@echo '   make etl-graph-[layer]	to generate etl graph for [layer]'
	@echo '   example: make etl-graph-poi'
	@echo 'Valid layers: $(layers)'

# generate etl graph for a certain layer, e.g. etl-graph-building, etl-graph-place
etl-graph-%: layers/% build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/$*/$*.yaml ./build/devdoc

mappingLayers = $(notdir $(patsubst %/mapping.yaml,%, $(wildcard layers/*/mapping.yaml))) # layers with mapping.yaml

# generate mapping graph for a certain layer, e.g. mapping-graph-building, mapping-graph-place
mapping-graph:
	@echo 'Use'
	@echo '   make mapping-graph-[layer]	to generate mapping graph for [layer]'
	@echo '   example: make mapping-graph-poi'
	@echo 'Valid layers: $(mappingLayers)'

mapping-graph-%: ./layers/%/mapping.yaml build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-mapping-graph layers/$*/$*.yaml ./build/devdoc/mapping-diagram-$*

# generate all etl and mapping graphs
generate-devdoc: $(addprefix etl-graph-,$(layers)) $(addprefix mapping-graph-,$(mappingLayers))

forced-clean-sql:
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "DROP SCHEMA IF EXISTS public CASCADE ; CREATE SCHEMA IF NOT EXISTS public; "
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "CREATE EXTENSION hstore; CREATE EXTENSION postgis; CREATE EXTENSION unaccent; CREATE EXTENSION fuzzystrmatch; CREATE EXTENSION osml10n; CREATE EXTENSION pg_stat_statements;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "GRANT ALL ON SCHEMA public TO public;COMMENT ON SCHEMA public IS 'standard public schema';"

psql-analyze:
	@echo "Start - postgresql: ANALYZE VERBOSE ;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c 'ANALYZE VERBOSE;'
