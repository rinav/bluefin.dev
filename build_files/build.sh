#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Customize Bluefin system Flatpaks

sed -i \
    -e '/^flatpak "it.mijorus.smile"$/d' \
    -e '/^flatpak "io.gitlab.adhami3310.Impression"$/d' \
    -e '/^flatpak "org.gnome.SimpleScan"$/d' \
    /usr/share/ublue-os/homebrew/system-flatpaks.Brewfile

### Add preferred system Flatpaks
echo "Adding preferred applications to system-flatpaks.Brewfile:"
tee -a /usr/share/ublue-os/homebrew/system-flatpaks.Brewfile \
    < /ctx/system-flatpaks.Brewfile

echo "========== Flatpak first-boot preinstall declarations =========="
cat /usr/share/flatpak/preinstall.d/90-local-apps.preinstall
echo "========== Flatpak configuration complete =========="

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

# Enable Niri official COPR
dnf5 -y copr enable yalter/niri

# Enable Dux official COPR
dnf5 -y copr enable duxlabs/dux-repo
dnf5 -y copr enable duxlabs/dms

# Prevent Dux repositories from supplying Niri
dnf5 config-manager setopt \
    'copr:copr.fedorainfracloud.org:duxlabs:dms.excludepkgs=niri' \
    'copr:copr.fedorainfracloud.org:duxlabs:dux-repo.excludepkgs=niri' \
    'coprdep:copr.fedorainfracloud.org:duxlabs:dux-repo.excludepkgs=niri'

# Install all four font variants
dnf5 install -y \
    iosevka-fonts \
    iosevka-term-fonts \
    iosevka-nerd-fonts \
    iosevka-term-nerd-fonts

# Install desktop stack and applications
dnf5 install -y \
    --setopt=install_weak_deps=True \
    niri \
    quickshell \
    dms \
    noctalia \
    dux-gop \
    dux-search \
    dux-calendar \
    dux-files \
    ghostty \
    alacritty \
    gtk4-layer-shell

# Rebuild font cache
fc-cache -f -v

# Disable COPR repositories in the final image
dnf5 -y copr disable bb010g/iosevka
dnf5 -y copr disable aquacash5/nerd-fonts

dnf5 -y copr disable yalter/niri
dnf5 -y copr disable duxlabs/dux-repo
dnf5 -y copr disable duxlabs/dms

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
