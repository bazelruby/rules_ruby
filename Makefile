# vim: tabstop=8
# vim: shiftwidth=8
# vim: noexpandtab

# grep '^[a-z\-]*:' Makefile | cut -d: -f 1 | tr '\n' ' '
.PHONY:	 help update-changelog update-readme update

red             		:= \033[0;31m
bold             		:= \033[1;45m
yellow          		:= \033[0;33m
blue            		:= \033[0;34m
green           		:= \033[0;35m
clear           		:= \033[0m

RUBY_VERSION    		:= $(shell cat .ruby-version)
RULES_VERSION 	   		:= $(shell cat .rules_version)
OS	 		 	:= $(shell uname -s | tr '[:upper:]' '[:lower:]')

# see: https://stackoverflow.com/questions/18136918/how-to-get-current-relative-directory-of-your-makefile/18137056#18137056
SCREEN_WIDTH			:= 100
MAKEFILE_PATH 			:= $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR 			:= $(notdir $(patsubst %/,%,$(dir $(MAKEFILE_PATH))))
PATH				:= $(shell echo "$(HOME)/.rbenv/shims:$(PATH)")
RULES_VERSION			:= $(shell cat .rules_version)

help:	   			## Prints help message auto-generated from the comments.
				@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

update: 			update-changelog update-readme ## Runs all of the updates, add locally modiofied files to git.

update-changelog: 		## Auto-generate the doc/CHANGELOG (requires GITHUB_TOKEN env var set)
				@printf "\n$(bold)  👉    $(red)$(clear)  $(green)Regenerating CHANGELOG....$(clear)\n"
				@bash -c "$(BASHMATIC_HOME)/bin/regen-changelog"

update-readme:			## Generate the PDF version of the README
				@rm -fv README.pdf
				@printf "\n$(bold)  👉    $(red)$(clear)  $(green)Converting ASCIIDOC into the PDF...$(clear)\n"
				@$(BASHMATIC_HOME)/bin/adoc2pdf README.adoc 
				@git add README.pdf
				@open README.pdf

tag:				## Tag this commit with .rules_version and push to remote
				@git tag "v$(RULES_VERSION)" -f
				@git push --tags -f

