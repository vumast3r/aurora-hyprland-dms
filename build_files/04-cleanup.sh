#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Cleanup"

# Disable all COPR repos
for i in /etc/yum.repos.d/_copr:*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

# Clean up build artifacts
rm -rf /tmp/build_files /tmp/system_files

# bootc filesystem expectations
rm -rf /var/tmp /var/cache
mkdir -p /var/tmp /var/cache

echo "::endgroup::"
