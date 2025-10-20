build-netcli-image:
	docker build -t netcli-base -f ../common/Dockerfile.netcli .

licenses/%:
# Ensure the symlink to the licenses private repo exists in the project root
	@if [ ! -d ../../licenses ]; then \
		echo "Error: licenses directory not found."; \
		if [ ! -d ../../../licenses ]; then \
			REMOTE_URL=$$(git remote get-url origin); \
			if echo "$$REMOTE_URL" | grep -q "^https://"; then \
				LICENSES_URL="$$(echo "$$REMOTE_URL" | sed -E 's|([^/]+)/[^/]+$$|\1/licenses.git|')"; \
			else \
				LICENSES_URL="$$(echo "$$REMOTE_URL" | sed -E 's|:([^/]+)/[^/]+$$|:\1/licenses.git|')"; \
			fi; \
			echo "Cloning licenses repository from $$LICENSES_URL"; \
			(cd ../../.. && git clone "$$LICENSES_URL") || \
			(echo "Failed to clone licenses repository." && exit 1); \
		else \
			echo "Found existing licenses repository at ../../../licenses"; \
		fi; \
		echo "Creating symlink to licenses directory..."; \
		ln -s ../licenses ../../licenses || \
		(echo "Failed to create symlink to licenses directory." && exit 1); \
	fi
# Copy the requested license file to the test directory. We run containerlab in
# a container, meaning we cannot follow a symlink outside of the current
# project directory.
	mkdir -p licenses
	cp ../../licenses/$* $@

start: build-netcli-image
	$(CLAB_BIN) deploy --topo $(TESTENV:netcli-%=%).clab.yml --log-level debug --reconfigure

stop:
	$(CLAB_BIN) destroy --topo $(TESTENV:netcli-%=%).clab.yml --log-level debug

.PHONY: wait $(addprefix wait-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE))
WAIT?=60
wait: $(addprefix platform-wait-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE))

copy:
	docker cp ../../out/bin/$(TEST_BINARY) $(TESTENV)-netcli:/$(TEST_BINARY)

run:
	docker exec $(INTERACTIVE) $(TESTENV)-netcli /$(TEST_BINARY) --rts-bt-dbg

ifndef CI
INTERACTIVE=-it
endif

.PHONY: shell
shell:
	docker exec -it $(TESTENV)-netcli bash -l

.PHONY: $(addprefix cli-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE))
$(addprefix cli-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE)): cli-%: platform-cli-%

.PHONY: $(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE))
$(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE)):
	docker run $(INTERACTIVE) --rm --network container:$(TESTENV)-netcli ghcr.io/notconf/notconf:debug netconf-console2 --host $(@:get-dev-config-%=%) --port 830 --user clab --pass clab@123 --get-config

# Filter to remove Junos metadata attributes that change with each commit
FILTER_JUNOS_METADATA = sed 's/ junos:commit-seconds="[0-9]*"//g; s/ junos:commit-localtime="[^"]*"//g; s/ junos:commit-user="[^"]*"//g'

.phony: test
test::
	$(MAKE) $(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE)) | $(FILTER_JUNOS_METADATA) > config-snapshot-before.txt
	for router in $(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE); do \
		docker exec $(INTERACTIVE) $(TESTENV)-netcli /$(TEST_BINARY) --address $$router --port 22 --username clab --password clab@123; \
	done
	$(MAKE) $(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE)) | $(FILTER_JUNOS_METADATA) > config-snapshot-after.txt
	diff -u config-snapshot-before.txt config-snapshot-after.txt

.PHONY: save-logs
save-logs: $(addprefix save-logs-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE))

.PHONY: $(addprefix save-logs-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE))
$(addprefix save-logs-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE)):
	mkdir -p logs
	docker logs --timestamps $(TESTENV)-$(@:save-logs-%=%) > logs/$(@:save-logs-%=%)_docker.log 2>&1
	$(MAKE) get-dev-config-$(@:save-logs-%=%) > logs/$(@:save-logs-%=%)_netconf.log || true
