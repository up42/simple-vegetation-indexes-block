## Include the configuration.
include config.mk

VALIDATE_ENDPOINT := https://api.up42.com/validate-schema/block
REGISTRY := registry.up42.com
CURL := curl
DOCKER := docker

build: $(MANIFEST_JSON)
ifdef UID
	$(DOCKER) build --build-arg manifest="$$(cat $<)" -f $(UP42_DOCKERFILE) -t $(REGISTRY)/$(UID)/$(DOCKER_TAG) .
else
	$(DOCKER) build --build-arg manifest="$$(cat $<)" -f $(UP42_DOCKERFILE) -t $(DOCKER_TAG) .
endif

clean-build: $(MANIFEST_JSON)
ifdef UID
	$(DOCKER) build --pull --no-cache --build-arg manifest="$$(cat $<)" -f $(UP42_DOCKERFILE) -t $(REGISTRY)/$(UID)/$(DOCKER_TAG) .
else
	$(DOCKER) build --pull --no-cache --build-arg manifest="$$(cat $<)" -f $(UP42_DOCKERFILE) -t $(DOCKER_TAG) .
endif

validate: $(MANIFEST_JSON)
	$(CURL) -X POST -H 'Content-Type: application/json' -d @$^ $(VALIDATE_ENDPOINT)

push:
	$(DOCKER) push $(REGISTRY)/$(UID)/$(DOCKER_TAG)

login:
	$(DOCKER) login -u $(USERNAME) https://$(REGISTRY)

run-s2: $(JOB_CONFIG_S2) build

	$(DOCKER) run -e UP42_TASK_PARAMETERS="$$(cat $<)" $(DOCKER_RUN_OPTIONS) $(DOCKER_TAG)

run-oa: $(JOB_CONFIG_OA) build

	$(DOCKER) run -e UP42_TASK_PARAMETERS="$$(cat $<)" $(DOCKER_RUN_OPTIONS) $(DOCKER_TAG)

clean:
	$(DOCKER) system prune -f

.PHONY: build login push test install run run-oa run-s2 clean
