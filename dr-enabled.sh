#!/bin/bash
# dr-enabled.sh - list enabled modules
drush pm-list --pipe --type=module --status=enabled --no-core | tr '\n' ' ' && echo ' '
