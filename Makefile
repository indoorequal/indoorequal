#
# First section - common variable initialization
#

# Ensure that errors don't hide inside pipes
SHELL         = /bin/bash
.SHELLFLAGS   = -o pipefail -c

# Make all .env variables available for make targets
include .env

# Options to run with docker and docker-compose - ensure the container is destroyed on exit
# Containers run as the current user rather than root (so that created files are not root-owned)
DC_OPTS ?= --rm -u $(shell id -u):$(shell id -g)

# Local port to use with postserve
PPORT ?= 8090
export PPORT
# Local port to use with tileserver
TPORT ?= 8080
export TPORT

# Allow a custom docker-compose project name
ifeq ($(strip $(DC_PROJECT)),)
  DC_PROJECT := $(notdir $(shell pwd))
  DOCKER_COMPOSE := docker-compose
else
  DOCKER_COMPOSE := docker-compose --project-name $(DC_PROJECT)
endif

# Make some operations quieter (e.g. inside the test script)
ifeq ($(strip $(QUIET)),)
  QUIET_FLAG :=
else
  QUIET_FLAG := --quiet
endif

# Use `xargs --no-run-if-empty` flag, if supported
XARGS := xargs $(shell xargs --no-run-if-empty </dev/null 2>/dev/null && echo --no-run-if-empty)

# If running in the test mode, compare files rather than copy them
TEST_MODE?=no
ifeq ($(TEST_MODE),yes)
  # create images in ./build/devdoc and compare them to ./layers
  GRAPH_PARAMS=./build/devdoc ./layers
else
  # update graphs in the ./layers dir
  GRAPH_PARAMS=./layers
endif

# Set OpenMapTiles host
OMT_HOST := http://$(firstword $(subst :, ,$(subst tcp://,,$(DOCKER_HOST))) localhost)

# This defines an easy $(newline) value to act as a "\n". Make sure to keep exactly two empty lines after newline.
define newline


endef


#
# Determine area to work on
# If $(area) parameter is not set and data/*.osm.pbf finds only one file, use it as $(area).
# Otherwise all make targets requiring area param will show an error.
# Note: If there are no data files, and user calls  make download area=... once,
#       they will not need to use area= parameter after that because there will be just a single file.
#

# historically we have been using $(area) rather than $(AREA), so make both work
area ?= $(AREA)
# Ensure the $(AREA) param is set, or try to automatically determine it based on available data files
ifeq ($(strip $(area)),)
  # if $area is not set. set it to the name of the *.osm.pbf file, but only if there is only one
  data_files := $(wildcard data/*.osm.pbf)
  ifneq ($(word 2,$(data_files)),)
    AREA_ERROR := The 'area' parameter (or env var) has not been set, and there are more than one data/*.osm.pbf files: $(patsubst data/%.osm.pbf,'%',$(data_files))
  else
    ifeq ($(word 1,$(data_files)),)
      AREA_ERROR := The 'area' parameter (or env var) has not been set, and there are no data/*.osm.pbf files
    else
      # Keep just the name of the data file, without the .osm.pbf extension
      area := $(strip $(basename $(basename $(notdir $(data_files)))))
      # Rename area-latest.osm.pbf to area.osm.pbf
      # TODO: This if statement could be removed in a few months once everyone is using the file without the `-latest`?
      ifneq ($(area),$(area:-latest=))
        $(shell mv "data/$(area).osm.pbf" "data/$(area:-latest=).osm.pbf")
        area := $(area:-latest=)
        $(warning ATTENTION: File data/$(area)-latest.osm.pbf was renamed to $(area).osm.pbf.)
        AREA_INFO := Detected area=$(area) based on the found data/$(area)-latest.osm.pbf (renamed to $(area).osm.pbf). Use 'area' parameter (or env var) to override.
      else
        AREA_INFO := Detected area=$(area) based on the found data/ pbf file. Use 'area' parameter (or env var) to override.
      endif
    endif
  endif
endif

# If set, this file will be downloaded in download-osm and imported in the import-osm targets
PBF_FILE ?= data/$(area).osm.pbf

# For download-osm, allow URL parameter to download file from a given URL. Area param must still be provided.
ifneq ($(strip $(url)),)
  DOWNLOAD_AREA := $(url)
else
  DOWNLOAD_AREA := $(area)
endif

# The file is placed into the $EXPORT_DIR=/export (mapped to ./data)
export MBTILES_FILE ?= $(area).mbtiles
MBTILES_LOCAL_FILE = data/$(MBTILES_FILE)

ifeq ($(strip $(DIFF_MODE)),true)
  # import-osm implementation requires IMPOSM_CONFIG_FILE to be set to a valid file
  # For static (no-updates) import, we don't need to override the default value
  # For the update mode, set location of the dynamically-generated area-based config file
  export IMPOSM_CONFIG_FILE = data/$(area).repl.json
endif

# download-osm generates this file with metadata about the file
AREA_DC_CONFIG_FILE ?= data/$(area).dc-config.yml

ifeq ($(strip $(area)),)
  define assert_area_is_given
	@echo ""
	@echo "ERROR: $(AREA_ERROR)"
	@echo ""
	@echo "  make $@ area=<area-id>"
	@echo ""
	@echo "To download an area, use   make download <area-id>"
	@echo "To list downloadable areas, use   make list-geofabrik   and/or   make list-bbbike"
	@exit 1
  endef
else
  ifneq ($(strip $(AREA_INFO)),)
    define assert_area_is_given
	@echo "$(AREA_INFO)"
    endef
  endif
endif



#
#  TARGETS
#

.PHONY: all
all: init-dirs build/indoorequal.tm2source/data.yml build/mapping.yaml build-sql

.PHONY: help
help:
	@echo "=============================================================================="
	@echo " Indoor= https://github.com/indoorequal "
	@echo "Hints for testing areas                "
	@echo "  make list-geofabrik                  # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo " "
	@echo "Hints for designers:"
	@echo "  make start-maputnik                  # start Maputnik Editor + dynamic tile server [ see $(OMT_HOST):8088 ]"
	@echo "  make start-postserve                 # start dynamic tile server                   [ see $(OMT_HOST):$(PPORT) ]"
	@echo "  make start-tileserver                # start maptiler/tileserver-gl                [ see $(OMT_HOST):$(TPORT) ]"
	@echo " "
	@echo "Hints for developers:"
	@echo "  make                                 # build source code"
	@echo "  make list-geofabrik                  # list actual geofabrik OSM extracts for download"
	@echo "  make list-bbbike                     # list actual BBBike OSM extracts for download"
	@echo "  make download area=albania           # download OSM data from any source       and create config file"
	@echo "  make download-geofabrik area=albania # download OSM data from geofabrik.de     and create config file"
	@echo "  make download-osmfr area=asia/qatar  # download OSM data from openstreetmap.fr and create config file"
	@echo "  make download-bbbike area=Amsterdam  # download OSM data from bbbike.org       and create config file"
	@echo "  make generate-dc-config              # scan data file and generate tile generation config file with bbox"
	@echo "  make psql                            # start PostgreSQL console"
	@echo "  make psql-list-tables                # list all PostgreSQL tables"
	@echo "  make vacuum-db                       # PostgreSQL: VACUUM ANALYZE"
	@echo "  make analyze-db                      # PostgreSQL: ANALYZE"
	@echo "  make generate-qareports              # generate reports                                [./build/qareports]"
	@echo "  make generate-devdoc                 # generate devdoc including graphs for all layers [./layers/...]"
	@echo "  make bash                            # start openmaptiles-tools /bin/bash terminal"
	@echo "  make destroy-db                      # remove docker containers and PostgreSQL data volume"
	@echo "  make start-db                        # start PostgreSQL, creating it if it doesn't exist"
	@echo "  make stop-db                         # stop PostgreSQL database without destroying the data"
	@echo "  make clean-unnecessary-docker        # clean unnecessary docker image(s) and container(s)"
	@echo "  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB"
	@echo "  make remove-docker-images            # remove openmaptiles docker images"
	@echo "  make pgclimb-list-views              # list PostgreSQL public schema views"
	@echo "  make pgclimb-list-tables             # list PostgreSQL public schema tables"
	@echo "  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM information"
	@echo "  make help                            # help about available commands"
	@echo "=============================================================================="

.PHONY: init-dirs
init-dirs:
	@mkdir -p build/sql/parallel
	@mkdir -p build/indoorequal.tm2source
	@mkdir -p cache

build/indoorequal.tm2source/data.yml: init-dirs
ifeq (,$(wildcard build/indoorequal.tm2source/data.yml))
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools generate-tm2source indoorequal.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > $@
endif

build/mapping.yaml: init-dirs
ifeq (,$(wildcard build/mapping.yaml))
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools generate-imposm3 indoorequal.yaml > $@
	@echo 'use_single_id_space: true' >> build/mapping.yaml
endif

.PHONY: build-sql
build-sql: init-dirs
ifeq (,$(wildcard build/sql/run_last.sql))
	@mkdir -p build/sql/parallel
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash -c \
		'generate-sql indoorequal.yaml --dir ./build/sql \
		&& generate-sqltomvt indoorequal.yaml \
							 --key --gzip --postgis-ver 3.0.1 \
							 --function --fname=getmvt >> ./build/sql/run_last.sql'
endif

.PHONY: clean
clean:
	rm -rf build

.PHONY: destroy-db
# TODO:  Use https://stackoverflow.com/a/27852388/177275
destroy-db: DC_PROJECT := $(shell echo $(DC_PROJECT) | tr A-Z a-z)
destroy-db:
	$(DOCKER_COMPOSE) down -v --remove-orphans
	$(DOCKER_COMPOSE) rm -fv
	docker volume ls -q -f "name=^$(DC_PROJECT)_" | $(XARGS) docker volume rm
	rm -rf cache

.PHONY: start-db-nowait
start-db-nowait: init-dirs
	@echo "Starting postgres docker compose target using $${POSTGIS_IMAGE:-default} image (no recreate if exists)" && \
	$(DOCKER_COMPOSE) up --no-recreate -d postgres

.PHONY: start-db
start-db: start-db-nowait
	@echo "Wait for PostgreSQL to start..."
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools pgwait

.PHONY: stop-db
stop-db:
	@echo "Stopping PostgreSQL..."
	$(DOCKER_COMPOSE) stop postgres

.PHONY: list-geofabrik
list-geofabrik: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm list geofabrik

.PHONY: list-bbbike
list-bbbike: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm list bbbike

#
# download, download-geofabrik, download-osmfr, and download-bbbike are handled here
# The --imposm-cfg will fail for some of the sources, but we ignore that error -- only needed for diff mode
#
OSM_SERVERS := geofabrik osmfr bbbike
ALL_DOWNLOADS := $(addprefix download-,$(OSM_SERVERS)) download
OSM_SERVER=$(patsubst download,,$(patsubst download-%,%,$@))
.PHONY: $(ALL_DOWNLOADS)
$(ALL_DOWNLOADS): init-dirs
	@$(assert_area_is_given)
ifneq ($(strip $(url)),)
	$(if $(OSM_SERVER),$(error url parameter can only be used with non-specific download target:$(newline)       make download area=$(area) url="$(url)"$(newline)))
endif
ifeq (,$(wildcard $(PBF_FILE)))
 ifeq ($(strip $(DIFF_MODE)),true)
	@echo "Downloading $(DOWNLOAD_AREA) with replication support into $(PBF_FILE) and $(IMPOSM_CONFIG_FILE) from $(if $(OSM_SERVER),$(OSM_SERVER),any source)"
	@$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm $(OSM_SERVER) "$(DOWNLOAD_AREA)" \
				--imposm-cfg "$(IMPOSM_CONFIG_FILE)" \
				--output "$(PBF_FILE)"
 else
	@echo "Downloading $(DOWNLOAD_AREA) into $(PBF_FILE) from $(if $(OSM_SERVER),$(OSM_SERVER),any source)"
	@$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm $(OSM_SERVER) "$(DOWNLOAD_AREA)" \
				--output "$(PBF_FILE)"
 endif
	@echo ""
else
 ifeq ($(strip $(DIFF_MODE)),true)
  ifeq (,$(wildcard $(IMPOSM_CONFIG_FILE)))
	$(error \
		$(newline)   Data files $(PBF_FILE) already exists, but $(IMPOSM_CONFIG_FILE) does not. \
		$(newline)   You probably downloaded the data file before setting DIFF_MODE=true. \
		$(newline)   You can delete the data file  $(PBF_FILE) and re-run  make download \
		$(newline)   to re-download and generate config, or manually create  $(IMPOSM_CONFIG_FILE) \
		$(newline)   See example    https://github.com/openmaptiles/openmaptiles-tools/blob/v5.2/bin/config/repl_config.json \
		$(newline))
  else
	@echo "Data files $(PBF_FILE) and replication config $(IMPOSM_CONFIG_FILE) already exists, skipping the download."
  endif
 else
	@echo "Data files $(PBF_FILE) already exists, skipping the download."
 endif
endif

.PHONY: generate-dc-config
generate-dc-config:
	@$(assert_area_is_given)
ifeq (,$(wildcard $(AREA_DC_CONFIG_FILE)))
	@$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash -c ' \
		download-osm make-dc "$(PBF_FILE)" \
			--make-dc "$(AREA_DC_CONFIG_FILE)" \
			--id "$(area)"'
else
	@echo "Configuration file $(AREA_DC_CONFIG_FILE) already exists, no need to regenerate."
endif

.PHONY: psql
psql: start-db-nowait
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c 'pgwait && psql.sh'

.PHONY: import-osm
import-osm: all start-db-nowait
	@$(assert_area_is_given)
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c 'pgwait && import-osm $(PBF_FILE)'

.PHONY: update-osm
update-osm: all start-db-nowait
	@$(assert_area_is_given)
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c 'pgwait && import-update'

.PHONY: import-diff
import-diff: all start-db-nowait
	@$(assert_area_is_given)
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c 'pgwait && import-diff'

.PHONY: import-sql
import-sql: all start-db-nowait
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c 'pgwait && import-sql' | \
	  awk -v s=": WARNING:" '$$0~s{print; print "\n*** WARNING detected, aborting"; exit(1)} 1'

ifneq ($(wildcard $(AREA_DC_CONFIG_FILE)),)
  DC_CONFIG_TILES := -f docker-compose.yml -f $(AREA_DC_CONFIG_FILE)
endif
.PHONY: generate-tiles
generate-tiles: all start-db
	@$(assert_area_is_given)
	@echo "Generating tiles into $(MBTILES_LOCAL_FILE) (will delete if already exists)..."
	@rm -rf "$(MBTILES_LOCAL_FILE)"
	$(DOCKER_COMPOSE) $(DC_CONFIG_TILES) run $(DC_OPTS) generate-vectortiles
	@echo "Updating generated tile metadata ..."
	$(DOCKER_COMPOSE) $(DC_CONFIG_TILES) run $(DC_OPTS) openmaptiles-tools \
			mbtiles-tools meta-generate "$(MBTILES_LOCAL_FILE)" ./indoorequal.yaml --auto-minmax --show-ranges

.PHONY: start-tileserver
start-tileserver: init-dirs
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Download/refresh maptiler/tileserver-gl docker image"
	@echo "* see documentation: https://github.com/maptiler/tileserver-gl"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker pull maptiler/tileserver-gl
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start maptiler/tileserver-gl "
	@echo "*       ----------------------------> check $(OMT_HOST):$(TPORT) "
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run $(DC_OPTS) -it --name tileserver-gl -v $$(pwd)/data:/data -p $(TPORT):$(TPORT) maptiler/tileserver-gl --port $(TPORT)

.PHONY: start-postserve
start-postserve: start-db
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Bring up postserve at $(OMT_HOST):$(PPORT)"
	@echo "*     --> can view it locally (use make start-maputnik)"
	@echo "*     --> or can use https://maputnik.github.io/editor"
	@echo "* "
	@echo "*  set data source / TileJSON URL to $(OMT_HOST):$(PPORT)"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	$(DOCKER_COMPOSE) up -d postserve

.PHONY: stop-postserve
stop-postserve:
	$(DOCKER_COMPOSE) stop postserve

.PHONY: start-maputnik
start-maputnik: stop-maputnik start-postserve
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start maputnik/editor "
	@echo "*       ---> go to $(OMT_HOST):8088 "
	@echo "*       ---> set data source / TileJSON URL to $(OMT_HOST):$(PPORT)"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run $(DC_OPTS) --name maputnik_editor -d -p 8088:8888 maputnik/editor

.PHONY: stop-maputnik
stop-maputnik:
	-docker rm -f maputnik_editor

.PHONY: generate-qareports
generate-qareports: start-db
	./qa/run.sh

# generate all etl and mapping graphs
.PHONY: generate-devdoc
generate-devdoc: init-dirs
	mkdir -p ./build/devdoc && \
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c \
			'generate-etlgraph indoorequal.yaml $(GRAPH_PARAMS) && \
			 generate-mapping-graph indoorequal.yaml $(GRAPH_PARAMS)'

.PHONY: bash
bash: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash

.PHONY: import-wikidata
import-wikidata: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools import-wikidata --cache /cache/wikidata-cache.json indoorequal.yaml

.PHONY: reset-db-stats
reset-db-stats: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'SELECT pg_stat_statements_reset();'

.PHONY: list-views
list-views: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -A -F"," -P pager=off -P footer=off \
		-c "select schemaname, viewname from pg_views where schemaname='public' order by viewname;"

.PHONY: list-tables
list-tables: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -A -F"," -P pager=off -P footer=off \
		-c "select schemaname, tablename from pg_tables where schemaname='public' order by tablename;"

.PHONY: psql-list-tables
psql-list-tables: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c "\d+"

.PHONY: vacuum-db
vacuum-db: init-dirs
	@echo "Start - postgresql: VACUUM ANALYZE VERBOSE;"
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'VACUUM ANALYZE VERBOSE;'

.PHONY: analyze-db
analyze-db: init-dirs
	@echo "Start - postgresql: ANALYZE VERBOSE;"
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'ANALYZE VERBOSE;'

.PHONY: list-docker-images
list-docker-images:
	docker images | grep openmaptiles

.PHONY: refresh-docker-images
refresh-docker-images: init-dirs
ifneq ($(strip $(NO_REFRESH)),)
	@echo "Skipping docker image refresh"
else
	@echo ""
	@echo "Refreshing docker images... Use NO_REFRESH=1 to skip."
	docker-compose pull --ignore-pull-failures $(QUIET_FLAG) openmaptiles-tools generate-vectortiles postgres
endif

.PHONY: remove-docker-images
remove-docker-images:
	@echo "Deleting all openmaptiles related docker image(s)..."
	@$(DOCKER_COMPOSE) down
	@docker images "openmaptiles/*" -q                | $(XARGS) docker rmi -f
	@docker images "maputnik/editor" -q               | $(XARGS) docker rmi -f
	@docker images "maptiler/tileserver-gl" -q        | $(XARGS) docker rmi -f

.PHONY: clean-unnecessary-docker
clean-unnecessary-docker:
	@echo "Deleting unnecessary container(s)..."
	@docker ps -a -q --filter "status=exited" | $(XARGS) docker rm
	@echo "Deleting unnecessary image(s)..."
	@docker images | grep \<none\> | awk -F" " '{print $$3}' | $(XARGS) docker rmi

.PHONY: test-perf-null
test-perf-null: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools test-perf indoorequal.yaml --test null --no-color

.PHONY: build-test-pbf
build-test-pbf: init-dirs
	docker-compose run $(DC_OPTS) openmaptiles-tools /tileset/.github/workflows/build-test-data.sh

.PHONY: expire-tiles
expire-tiles:
	@echo "Expiring tiles"
	@find data/expire_tiles/???????? -name *.tiles | xargs cat > data/expire_tiles/expire_tiles.tiles
	@sed --in-place --expression=s/$$/\.pbf/ data/expire_tiles/expire_tiles.tiles
	$(DOCKER_COMPOSE) exec postserve-cache wget --input-file=/data/expire_tiles/expire_tiles.tiles --base=http://localhost/purge/tiles/ --quiet --output-file=/dev/null || true
	@rm -rf data/expire_tiles/
