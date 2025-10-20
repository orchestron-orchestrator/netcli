
.PHONY: build
build:
	acton build $(DEP_OVERRIDES) $(TARGET)

.PHONY: build-linux
build-linux:
	$(MAKE) build TARGET="--target x86_64-linux-gnu.2.27"

.PHONY: build-aarch64
build-aarch64:
	$(MAKE) build TARGET="--target aarch64-linux-gnu.2.27"

.PHONY: test
test:
	acton test $(DEP_OVERRIDES)
