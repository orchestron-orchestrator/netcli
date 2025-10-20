.PHONY: $(addprefix platform-wait-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE))

$(addprefix platform-wait-,$(ROUTERS_XR)):
# Wait for "smartlicserver[212]: %LICENSE-SMART_LIC-3-COMM_FAILED : Communications failure with the Cisco Smart License Utility (CSLU) : Unable to resolve server hostname/domain name" to appear in the container logs
	timeout --foreground $(WAIT) bash -c "until docker logs $(TESTENV)-$(@:platform-wait-%=%) 2>&1 | grep -q 'smartlicserver'; do sleep 1; done"
	docker run $(INTERACTIVE) --rm --network container:$(TESTENV)-netcli ghcr.io/notconf/notconf:debug netconf-console2 --host $(@:platform-wait-%=%) --port 830 --user clab --pass clab@123 --hello

$(addprefix platform-wait-,$(ROUTERS_CRPD)):
# Wait for "Server listening on unix:/var/run/japi_na-grpcd" to appear in the container logs
	timeout --foreground $(WAIT) bash -c "until docker logs $(TESTENV)-$(@:platform-wait-%=%) 2>&1 | grep -q 'Server listening on unix:/var/run/japi_na-grpcd'; do sleep 1; done"
	docker run $(INTERACTIVE) --rm --network container:$(TESTENV)-netcli ghcr.io/notconf/notconf:debug netconf-console2 --host $(@:platform-wait-%=%) --port 830 --user clab --pass clab@123 --hello

$(addprefix platform-wait-,$(ROUTERS_XE)):
# Wait for "Startup complete" to appear in the vrnetlab container logs
	timeout --foreground $(WAIT) bash -c "until docker logs $(TESTENV)-$(@:platform-wait-%=%) 2>&1 | grep -q 'Startup complete'; do sleep 1; done"

.PHONY: cli $(addprefix platform-cli-,$(ROUTERS_XR) $(ROUTERS_CRPD) $(ROUTERS_XE))

$(addprefix platform-cli-,$(ROUTERS_XR)):
	docker exec -it $(TESTENV)-$(subst platform-cli-,,$@) /pkg/bin/xr_cli.sh

$(addprefix platform-cli-,$(ROUTERS_CRPD)):
	docker exec -it $(TESTENV)-$(subst platform-cli-,,$@) cli

$(addprefix platform-cli-,$(ROUTERS_XE)):
	@CONTAINER_IP=$$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(TESTENV)-$(@:platform-cli-%=%)); \
	echo "Connecting to IOS XE console at $$CONTAINER_IP:5000"; \
	telnet $$CONTAINER_IP 5000
