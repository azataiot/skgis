.PHONY: help add-target remove-target remove-target-file update-targets

.DEFAULT_GOAL := help

INDEX_FILE = ~/.Makefiles/index.txt

# -- global targets--
## This help screen
help:
	@echo "Available targets:"
	@awk '/^[a-zA-Z\-\_0-9%:\\ ]+/ { \
	  helpMessage = match(lastLine, /^## (.*)/); \
	  if (helpMessage) { \
	    helpCommand = $$1; \
	    helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
	    gsub("\\\\", "", helpCommand); \
	    gsub(":+$$", "", helpCommand); \
	    printf "  \x1b[32;01m%-35s\x1b[0m %s\n", helpCommand, helpMessage; \
	  } \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u

## Update the index of available Makefiles
update-targets:
	@echo "Fetching directory structure from the repository..."
	@curl -s "https://raw.githubusercontent.com/azataiot/reusable-makefiles/dev/index.txt" > $(INDEX_FILE)
	@echo "Updated the Makefile index."


## Add a reusable Makefile from the repository
add-target:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Please specify a target path using 'make add-target <path>'"; \
		exit 1; \
	fi; \
	TARGET_PATH=$(filter-out $@,$(MAKECMDGOALS)); \
	if grep -q "$$TARGET_PATH/Makefile" $(INDEX_FILE); then \
		mkdir -p ~/.Makefiles/$$TARGET_PATH; \
		wget -q --no-check-certificate -O ~/.Makefiles/$$TARGET_PATH/Makefile https://github.com/azataiot/reusable-makefiles/raw/dev/$$TARGET_PATH/Makefile; \
		if ! grep -q "include ~/.Makefiles/$$TARGET_PATH/Makefile" Makefile; then \
			echo "include ~/.Makefiles/$$TARGET_PATH/Makefile" >> Makefile; \
			PHONY_TARGETS=$$(awk '/.PHONY:/ {for (i=2; i<=NF; i++) print $$i}' ~/.Makefiles/$$TARGET_PATH/Makefile | tr '\n' ' '); \
			echo ".PHONY: $$PHONY_TARGETS" >> Makefile; \
			echo "Added $$TARGET_PATH Makefile to the current project."; \
		else \
			echo "$$TARGET_PATH Makefile is already included in the current project, skipping."; \
		fi; \
	else \
		echo "Error: $$TARGET_PATH Makefile not found in the index."; \
	fi

## Remove a reusable Makefile reference from the current Makefile
remove-target:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Please specify a target path using 'make remove-target <path>'"; \
		exit 1; \
	fi; \
	TARGET_PATH=$(filter-out $@,$(MAKECMDGOALS)); \
	if grep -q "include ~/.Makefiles/$$TARGET_PATH/Makefile" Makefile; then \
		if grep -q "$$TARGET_PATH/Makefile" $(INDEX_FILE); then \
			PHONY_TARGETS=$$(awk '/.PHONY:/ {for (i=2; i<=NF; i++) print $$i}' ~/.Makefiles/$$TARGET_PATH/Makefile 2>/dev/null | tr '\n' ' '); \
			sed -i.bak "/.PHONY: $$PHONY_TARGETS/d" Makefile; \
			sed -i.bak "/include ~/.Makefiles\/$$TARGET_PATH\/Makefile/d" Makefile; \
			echo "Removed $$TARGET_PATH Makefile reference and its .PHONY targets from the current project."; \
			rm -f Makefile.bak; \
		else \
			echo "Error: $$TARGET_PATH Makefile not found in the index."; \
		fi; \
	else \
		echo "$$TARGET_PATH Makefile is not included in the current project."; \
	fi






## Remove a downloaded Makefile from disk
remove-target-file:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Please specify a target path using 'make remove-target-file <path>'"; \
		exit 1; \
	fi; \
	TARGET_PATH=$(filter-out $@,$(MAKECMDGOALS)); \
	if grep -q "$$TARGET_PATH/Makefile" $(INDEX_FILE); then \
		rm -rf ~/.Makefiles/$$TARGET_PATH; \
		echo "Removed $$TARGET_PATH Makefile from disk."; \
	else \
		echo "Error: $$TARGET_PATH Makefile not found in the index."; \
	fi


# This is a workaround to allow passing arguments to Make targets
%:
	@: