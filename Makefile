# Global vars
VERSION ?= 1.0.0
BUILD_DATE ?= $(shell date -u +%Y-%m-%d)

# List of image variants to build
VARIANTS := full web light

# Function to check expired temp fix
check_temp_fix_limits:
	@echo "🔍 Checking temp_fix_limit dates..."
	@bad_files=$$( \
		grep -rho 'temp_fix_limit="[0-9\-]\+"' sources/install | \
		sed 's/.*="\([0-9\-]*\)".*/\1/' | \
		while read date; do \
			if [ "$$(date -d "$$date" +%s)" -lt "$$(date +%s)" ]; then \
				echo "$$date"; \
			fi; \
		done \
	); \
	if [ -n "$$bad_files" ]; then \
		echo "❌ ERROR: The following temp_fix_limit dates are in the past:"; \
		echo "$$bad_files"; \
		exit 1; \
	fi


# Build base image
.PHONY: base
base:
	docker buildx build \
		--build-arg VERSION=$(VERSION) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg TAG=base \
		-f base.dockerfile \
		-t lksec/mandalore:base .

# Build image variant : full, web, light
.PHONY: full web light
full web light: check_temp_fix_limits
	docker buildx build \
			--build-arg VERSION=$(VERSION) \
			--build-arg BUILD_DATE=$(BUILD_DATE) \
			--build-arg TAG=$@ \
			-f $@.dockerfile \
			-t lksec/mandalore:$@ .

# Build all
.PHONY: all
all: $(VARIANTS)

.PHONY: check_temp_fixes
check_temp_fixes:
	@echo "🔍 Listing all temp_fix_limit occurrences..."
	@echo
	@grep -rn 'temp_fix_limit="[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}"' sources/install | \
	while IFS=: read -r file line text; do \
		date=$$(echo $$text | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}'); \
		if [ "$$(date -d "$$date" +%s)" -lt "$$(date +%s)" ]; then \
			echo "❌ $$file:$$line - expired → $$text"; \
		else \
			echo "✅ $$file:$$line - valid   → $$text"; \
		fi \
	done


# Cleanup
.PHONY: clean
clean:
	@echo "🧹 Removal of Docker mandaloreimages..."
	@docker image rm -f $(shell docker images --format '{{.Repository}}' | grep mandalore) 2>/dev/null || true
