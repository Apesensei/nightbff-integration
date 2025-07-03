# NightBFF Integration Repository Helper Makefile

# Path to the canonical integration env file in backend repo
ENV_SRC ?= ../config/env/integration.env
ENV_DEST = .env.integration

.PHONY: copy-env

# Copies the canonical env file into this repo root for local docker-compose usage.
copy-env:
	@if [ ! -f $(ENV_SRC) ]; then \
		echo "Cannot find $(ENV_SRC). Run from project root or set ENV_SRC."; \
		exit 1; \
	fi
	@echo "Copying $(ENV_SRC) → $(ENV_DEST)" && cp $(ENV_SRC) $(ENV_DEST)

# Remove generated env file (cleanup)
.PHONY: clean-env
clean-env:
	rm -f $(ENV_DEST)
	@echo "Removed $(ENV_DEST)" 