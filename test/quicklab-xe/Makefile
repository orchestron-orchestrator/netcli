TESTENV=netcli-quicklab-xe
TEST_BINARY=router_example_iosxe

# Define router types
ROUTERS_XR=
ROUTERS_CRPD=
ROUTERS_XE=xe1

# Image path for vrnetlab containers
IMAGE_PATH ?= ghcr.io/orchestron-orchestrator/
WAIT=240

# Include common makefiles first
include ../common/clab.mk
include ../common/containers.mk
include ../common/quicklab.mk

# Override start target to start both XE container and netcli container
.PHONY: start
start: build-netcli-image
	@echo "Creating network $(TESTENV)..."
	docker network create $(TESTENV) || true
	@echo "Starting IOS XE container..."
	docker run -td --name $(TESTENV)-xe1 --network-alias xe1 --rm --privileged \
		--network $(TESTENV) \
		$(IMAGE_PATH)vrnetlab/vr-c8000v:17.15.03a --username clab --password clab@123 --trace
	@echo "Starting netcli container..."
	docker run -td --name $(TESTENV)-netcli --rm \
		--network $(TESTENV) \
		netcli-base bash -c "while true; do sleep 3600; done"
	@echo "Waiting for IOS XE to boot (this may take 2-3 minutes)..."

# Override stop target to stop both containers and remove network
.PHONY: stop
stop:
	@echo "Stopping containers..."
	@docker stop $(TESTENV)-netcli || true
	@docker stop $(TESTENV)-xe1 || true
	@echo "Removing network..."
	@docker network rm $(TESTENV) || true
