#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux

### Install Iosevka fonts

# Enable Iosevka COPR
dnf5 -y copr enable bb010g/iosevka

# Enable Nerd Fonts COPR
dnf5 -y copr enable aquacash5/nerd-fonts

# Install all four font variants
dnf5 install -y \
    iosevka-fonts \
    iosevka-term-fonts \
    iosevka-nerd-fonts \
    iosevka-term-nerd-fonts

# Rebuild font cache
fc-cache -f -v

# Disable COPR repositories in the final image
dnf5 -y copr disable bb010g/iosevka
dnf5 -y copr disable aquacash5/nerd-fonts

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
