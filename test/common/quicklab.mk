build-netcli-image:
	docker build -t netcli-base -f ../common/Dockerfile.netcli .

start: build-netcli-image
	$(CLAB_BIN) deploy --topo $(TESTENV:netcli-%=%).clab.yml --log-level debug --reconfigure

stop:
	$(CLAB_BIN) destroy --topo $(TESTENV:netcli-%=%).clab.yml --log-level debug

.PHONY: wait $(addprefix wait-,$(ROUTERS_XR) $(ROUTERS_CRPD))
WAIT?=60
wait: $(addprefix platform-wait-,$(ROUTERS_XR) $(ROUTERS_CRPD))

copy:
	docker cp ../../out/bin/router_example $(TESTENV)-netcli:/router_example

run:
	docker exec $(INTERACTIVE) $(TESTENV)-netcli /router_example --rts-bt-dbg

ifndef CI
INTERACTIVE=-it
endif

.PHONY: shell
shell:
	docker exec -it $(TESTENV)-netcli bash -l

.PHONY: $(addprefix cli-,$(ROUTERS_XR) $(ROUTERS_CRPD))
$(addprefix cli-,$(ROUTERS_XR) $(ROUTERS_CRPD)): cli-%: platform-cli-%

.PHONY: $(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD))
$(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD)):
	docker run $(INTERACTIVE) --rm --network container:$(TESTENV)-netcli ghcr.io/notconf/notconf:debug netconf-console2 --host $(@:get-dev-config-%=%) --port 830 --user clab --pass clab@123 --get-config

.phony: test
test::
	$(MAKE) $(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD))

.PHONY: save-logs
save-logs: $(addprefix save-logs-,$(ROUTERS_XR) $(ROUTERS_CRPD))

.PHONY: $(addprefix save-logs-,$(ROUTERS_XR) $(ROUTERS_CRPD))
$(addprefix save-logs-,$(ROUTERS_XR) $(ROUTERS_CRPD)):
	mkdir -p logs
	docker logs --timestamps $(TESTENV)-$(@:save-logs-%=%) > logs/$(@:save-logs-%=%)_docker.log 2>&1
	$(MAKE) get-dev-config-$(@:save-logs-%=%) > logs/$(@:save-logs-%=%)_netconf.log || true
