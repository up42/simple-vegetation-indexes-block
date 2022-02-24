## Configuration for the Makefile.
SRC := shell
MANIFEST_JSON := UP42Manifest.json
UP42_DOCKERFILE := Dockerfile
## Job params for OneAtlas (Pléiades & SPOT sensors).
JOB_CONFIG_OA := $(SRC)/examples/params_oa.json
## Job params for Sentinel-2.
JOB_CONFIG_S2 := $(SRC)/examples/params_s2.json
DOCKER_TAG := simple-vegetation-indexes
## Options for running the container (block) locally.
DOCKER_RUN_OPTIONS := --mount type=bind,src=$(OUTPUT_DIR),dst=/tmp/output --mount type=bind,src=$(INPUT_DIR),dst=/tmp/input
