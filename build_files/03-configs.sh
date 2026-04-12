#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Install configs and system files"

# Copy system files into the image
rsync -rvKl /tmp/system_files/ /

# Enable essential services
systemctl enable sddm.service
systemctl enable NetworkManager.service
systemctl enable bluetooth.service

echo "::endgroup::"
