#!/bin/bash

set -ouex pipefail

# Load shared registry functions
source /ctx/scripts/registry.sh

# Copy custom system files into the root filesystem.
copy_system_files() {
    cp -avf "/ctx/system_files"/. /
}

# Remove unwanted upstream Flatpaks and add configured applications.

# Generate system Flatpak declarations from the TOML registry.
configure_flatpaks() {
    local brewfile="/usr/share/ublue-os/homebrew/system-flatpaks.Brewfile"
    local preinstall="/usr/share/flatpak/preinstall.d/90-local-apps.preinstall"
    local flatpak_groups
    local group
    local apps
    local app

    # Remove unwanted upstream Flatpak declarations.
    sed -i \
        -e '/^flatpak "it.mijorus.smile"$/d' \
        -e '/^flatpak "io.gitlab.adhami3310.Impression"$/d' \
        -e '/^flatpak "org.gnome.SimpleScan"$/d' \
        "$brewfile"

    # Reset the preinstall manifest before generating it.
    : > "$preinstall"

    echo "Adding preferred applications to system-flatpaks.Brewfile:"

    flatpak_groups="$(list_registry_groups flatpaks)"

    while IFS= read -r group; do
        [[ -n "$group" ]] || continue

        echo "# ${group^}" >> "$brewfile"

        apps="$(read_registry flatpaks "$group")"

        while IFS= read -r app; do
            [[ -n "$app" ]] || continue

            # Add the application to the Homebrew Brewfile.
            printf 'flatpak "%s"\n' "$app" >> "$brewfile"

            # Generate its Flatpak preinstall declaration.
            printf '[Flatpak Preinstall %s]\nBranch=stable\n\n' \
                "$app" >> "$preinstall"
        done <<< "$apps"

        echo >> "$brewfile"
    done <<< "$flatpak_groups"

    echo "========== Flatpak preinstall manifest =========="
    cat "$preinstall"
    echo "========== Flatpak configuration complete =========="
}


# Enable all configured COPR repositories.
enable_copr_repositories() {
    local repositories="$1"
    local repository

    while IFS=$'\t' read -r repository _ _; do
        [[ -n "$repository" ]] || continue
        dnf5 -y copr enable "$repository"
    done <<< "$repositories"
}

# Apply package exclusions configured for COPR repositories.
configure_copr_exclusions() {
    local repositories="$1"
    local repository
    local exclusions
    local exclude_dependencies
    local excluded_packages
    local options
    local package

    while IFS=$'\t' read -r repository exclusions exclude_dependencies; do
        [[ -n "$repository" ]] || continue
        [[ "$exclusions" != "-" ]] || continue

        IFS=',' read -ra excluded_packages <<< "$exclusions"

        options=()

        for package in "${excluded_packages[@]}"; do
            options+=("copr:copr.fedorainfracloud.org:${repository//\//:}.excludepkgs=${package}")
        done

        if [[ "$exclude_dependencies" == "true" ]]; then
            for package in "${excluded_packages[@]}"; do
                options+=("coprdep:copr.fedorainfracloud.org:${repository//\//:}.excludepkgs=${package}")
            done
        fi

        dnf5 config-manager setopt "${options[@]}"
    done <<< "$repositories"
}

# Install configured font and desktop packages.
install_packages() {
    # Packages can be installed from any enabled yum repo on the image.
    # RPMfusion repos are available by default in ublue main images
    # List of rpmfusion packages can be found here:
    # https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

    # this installs a package from fedora repos
    # dnf5 install -y tmux

    # Keep Homebrew font installation disabled while using RPM packages.
    # brew bundle --file=/ctx/fonts.Brewfile

    # Install regular font variants
    local font_packages_output
    local font_packages=()

    font_packages_output="$(read_registry packages fonts)"

    if [[ -n "$font_packages_output" ]]; then
        mapfile -t font_packages <<< "$font_packages_output"
        dnf5 install -y "${font_packages[@]}"
    fi

    # Install desktop stack and applications
    local desktop_packages_output
    local desktop_packages=()

    desktop_packages_output="$(read_registry packages desktop)"

    if [[ -n "$desktop_packages_output" ]]; then
        mapfile -t desktop_packages <<< "$desktop_packages_output"
        dnf5 install -y --setopt=install_weak_deps=True "${desktop_packages[@]}"
    fi
}

# Rebuild the font cache after installing fonts.
rebuild_font_cache() {
    fc-cache -f -v
}

# Disable configured COPR repositories after installation.
disable_copr_repositories() {
    local repositories="$1"
    local repository

    while IFS=$'\t' read -r repository _ _; do
        [[ -n "$repository" ]] || continue
        dnf5 -y copr disable "$repository"
    done <<< "$repositories"
}

# Enable required system services.
enable_system_services() {
    systemctl enable podman.socket
}

# Build execution
copy_system_files
configure_flatpaks

copr_repositories="$(read_registry coprs)"

enable_copr_repositories "$copr_repositories"
configure_copr_exclusions "$copr_repositories"
install_packages
rebuild_font_cache
disable_copr_repositories "$copr_repositories"
enable_system_services
