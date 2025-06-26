#!/bin/sh
# iot_nano_agent_installer
# Base package manager for "IoT Nano Agent" on Linux.
#
# Requirements:
#   1. Manager requirements: e.g., curl and sha256sum/shasum.
#   2. IoT Nano Agent requirements: additional dependencies required by the package.

# Constants
MANAGER_VERSION="1.0"
GIT_REPO="CheckPointSW/IoT-Nano-Agent-Installer"  # Updated repo.
DEFAULT_INSTALL_PATH="/etc/cp/"
INSTALLED_VERSION_FILE="$DEFAULT_INSTALL_PATH/VERSION"
MANIFEST_TEMP="/tmp/iot_nano_agent_manifest.txt"
PACKAGE_TEMP="/tmp/iot_nano_agent_package.sh"  # Self-extracting installer.
WLP_CONFIG_TMP_DIR="/tmp/wlp_config"
WLP_DIRECTORY="$DEFAULT_INSTALL_PATH/workloadProtection"

# Basic curl options
CURL_OPTS="-fsSLk"

# Default variables (overridable via flags)
PLATFORM=""
VERSION_OVERRIDE=""
UPDATE_FLAG=0
CLEAN_FLAG=0         # --clean: do not backup/restore configuration during install.

usage() {
    cat <<EOF
IoT Nano Agent Installer $MANAGER_VERSION

Usage:
  $0 install [--version VERSION] [--update] [--clean]
      Install IoT Nano Agent if not already installed.
      --version       Specify a particular version to install.
      --update        Force an update if a newer version is available.
      --clean         Install without backing up/restoring configuration.

  $0 uninstall
      Uninstall IoT Nano Agent (removes installed files).

  $0 version [--latest | --list]
      Show the currently installed IoT Nano Agent version.
      --latest       Show the latest available package version.
      --list         Show the installed version and list all available versions.

Global options:
  -nc, --no-colors        Disable colored output
  -h,  --help             Show this help message
EOF

    # If a numeric argument was provided, use it as exit code; otherwise exit 0
    if [ -n "$1" ]; then
        exit "$1"
    else
        exit 0
    fi
}

NO_COLORS=0
HELP=0

# Configure ANSI color variables (or disable them)
configure_colors() {
    if [ "$NO_COLORS" -eq 1 ] || [ ! -t 1 ]; then
        RED=''
        ORANGE=''
        NC=''
    else
        RED='\033[0;31m'
        ORANGE='\033[38;5;208m'
        NC='\033[0m'
    fi
}

error() {
    printf "${RED}[Error] %s${NC}\n" "$*"
}

warning() {
    printf "${ORANGE}[Warning] %s${NC}\n" "$*"
}

cleanup() {
    rm -f "$MANIFEST_TEMP" "$PACKAGE_TEMP"
}

trap cleanup EXIT

# Manager requirements: Check for commands required by the manager.
check_manager_requirements() {
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required but not installed."
        exit 1
    fi

    if command -v sha256sum >/dev/null 2>&1; then
        CHECKSUM_CMD="sha256sum"
    elif command -v shasum >/dev/null 2>&1; then
        CHECKSUM_CMD="shasum -a 256"
    else
        error "No SHA256 utility found. Please install sha256sum or shasum."
        exit 1
    fi
}

# IoT Nano Agent requirements:
check_nano_agent_requirements() {
    CHECK_REQUIREMENTS_API="https://iapi-services-ucs.checkpoint.com/public/api/support-center-mms/api/getDownloadPath/137051"
    # Get the JSON response from the API
    get_path_response=$(curl -s $CHECK_REQUIREMENTS_API)

    # Extract the filePath value using sed
    download_url=$(echo "$get_path_response" | sed -n 's/.*"filePath":[[:space:]]*"\([^"]*\)".*/\1/p')

    # Check if the extraction was successful
    if [ -z "$download_url" ]; then
        error "Unable to extract download URL" >&2
        exit 1
    fi

    # Check if /tmp/check_requirements.sh exists
    if [ -f /tmp/check_requirements.sh ]; then
        echo "/tmp/check_requirements.sh already exists. Using the existing file."
    else
        echo "Downloading check_requirements.sh from: $download_url"
        # Download the file and save it to a temporary location
        curl $CURL_OPTS -o /tmp/check_requirements.sh "$download_url" || {
            error "Failed to download check_requirements.sh." >&2
            exit 1
        }
    fi

    # Ensure the script is executable
    chmod +x /tmp/check_requirements.sh

    # build up any flags for check_requirements
    check_args=
    if [ "$NO_COLORS" -eq 1 ]; then
        check_args="-nc"
    fi

    printf "\nChecking requiremenets...\n"
    /tmp/check_requirements.sh $check_args || {
        error "Installation stopped due to missing critical requirement" >&2
        exit 1
    }
    echo ""
}

# Auto-detect architecture if not overridden.
detect_platform() {
    # Try 1: uname -m
    ARCH=$(uname -m)
    # If empty, try 2: arch
    if [ -z "$ARCH" ]; then
        ARCH=$(arch)
    fi
    # If still empty, try 3: file /sbin/agetty (if it exists)
    if [ -z "$ARCH" ] && [ -f /sbin/agetty ]; then
        ARCH=$(file /sbin/agetty | sed -n 's/.*\(x86-64\|aarch64\|arm\).*/\1/p')
    fi

    if [ -z "$ARCH" ]; then
        error "Unable to detect system architecture." >&2
        exit 1
    fi

    case "$ARCH" in
        x86_64|x86-64)
            PLATFORM="x86"
            ;;
        aarch64)
            PLATFORM="aarch64"
            ;;
        armv7l|armv6l|arm)
            PLATFORM="arm32"
            ;;
        *)
            PLATFORM="$ARCH"
            ;;
    esac
}

# Get the currently installed IoT Nano Agent version.
get_installed_version() {
    if [ -f "$INSTALLED_VERSION_FILE" ]; then
        cat "$INSTALLED_VERSION_FILE"
    else
        echo "none"
    fi
}

# Download the manifest file using raw.githubusercontent.com.
download_manifest() {
    API_URL="https://api.github.com/repos/${GIT_REPO}/contents/manifests/${PLATFORM}"
    echo "Downloading manifest from ${API_URL}"
    curl -L $CURL_OPTS \
         -H "Accept: application/vnd.github.v3.raw" \
         -o "${MANIFEST_TEMP}" \
         "${API_URL}" || {
             error "Failed to download manifest."
             exit 1
         }
}

# Extract the latest version from the manifest.
get_latest_version_from_manifest() {
    head -n 1 "$MANIFEST_TEMP" | awk '{print $1}'
}

# Extract the expected SHA256 checksum for the given version.
get_expected_checksum() {
    version="$1"
    grep "^${version} " "$MANIFEST_TEMP" | awk '{print $2}'
}

# List all available versions from the manifest.
list_available_versions() {
    awk '{print $1}' "$MANIFEST_TEMP" | sort -rV | uniq
}

# Scan a JSON‐array “[ {...},{...},… ]” and print the first {...} whose “name”
# field matches $asset
find_release() {
  asset_name=$1
  json_array=$2

  printf '%s\n' "$json_array" | awk -v asset="$asset_name" '
    BEGIN { level = 0; token = "" }
    {
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c == "{") {
          if (level == 0) token = ""    # starting new top‐level object
          level++
          token = token c
        }
        else if (level > 0) {
          token = token c
          if (c == "}") {
            level--
            if (level == 0) {
              # finished one full object in token
              if (token ~ "\"name\"[[:space:]]*:[[:space:]]*\"" asset "\"") {
                print token
                exit
              }
            }
          }
        }
      }
    }
  '
}

# Given a JSON‐object “{…}” print its "assets": [ … ] substring
get_assets() {
  obj=$1
  printf '%s' "$obj" \
    | sed -n 's/.*"assets"[[:space:]]*:[[:space:]]*\(\[[^]]*\]\).*/\1/p'
}

find_asset() {
  name=$1
  arr=$2
  printf '%s\n' "$arr" | awk -v asset="$name" '
    BEGIN { lvl=0; tok="" }
    {
      for (i=1; i<=length($0); i++) {
        c=substr($0,i,1)
        if (c=="{") {
          if (lvl==0) tok=""
          lvl++; tok=tok c
        } else if (lvl>0) {
          tok=tok c
          if (c=="}") {
            lvl--
            if (lvl==0 && tok ~ "\"name\"[[:space:]]*:[[:space:]]*\"" asset "\"") {
              print tok; exit
            }
          }
        }
      }
    }
  '
}

extract_asset_id() {
    asset=$1
    releases=$2

    release_obj=$(find_release "$asset" "$releases")
    assets_block=$(get_assets "$release_obj")
    asset_obj=$(find_asset "$asset" "$assets_block")
    asset_id=$(printf '%s\n' "$asset_obj" \
        | sed 's/\(.*"name"[[:space:]]*:[[:space:]]*"'$asset'"\).*/\1/' \
        | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p'
    )

    echo "$asset_id"
}

download_package() {
    # $1: platform (e.g., "x86")
    # $2: version (e.g., "2025.1.1")
    echo "Fetching release information for version $2"

    # Fetch all releases
    releases=$(curl -L $CURL_OPTS \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/${GIT_REPO}/releases")

    if [ $? -ne 0 ] || [ -z "$releases" ]; then
         error "Failed to fetch release information."
         exit 1
    fi

    asset_name="nano_agent-${1}-${2}.sh"
    echo "Looking for $asset_name"

    # Find the asset ID for the specified asset name
    asset_id=$(extract_asset_id "$asset_name" "$releases")
    echo "Asset ID: $asset_id"
    if [ $? -ne 0 ] || [ -z "$asset_id" ]; then
         error "Failed to extract asset ID for $asset_name."
         exit 1
    fi

    ASSET_API_URL="https://api.github.com/repos/${GIT_REPO}/releases/assets/${asset_id}"
    echo "Downloading installation..."
    curl -L $CURL_OPTS \
         -H "Accept: application/octet-stream" \
         -H "X-GitHub-Api-Version: 2022-11-28" \
         "$ASSET_API_URL" -o "$PACKAGE_TEMP" || {
         error "Failed to download package."
         exit 1
    }
}

# Verify the downloaded package checksum.
verify_checksum() {
    expected_checksum="$1"
    if [ -z "$expected_checksum" ]; then
        error "Expected checksum not found in manifest."
        exit 1
    fi
    echo "Verifying checksum..."
    computed_checksum=$($CHECKSUM_CMD "$PACKAGE_TEMP" | awk '{print $1}')
    if [ "$computed_checksum" != "$expected_checksum" ]; then
        error "Checksum verification failed. Expected $expected_checksum but got $computed_checksum."
        exit 1
    fi
    echo "Checksum verified."
}

backup_configuration() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="${WLP_CONFIG_TMP_DIR}_${TIMESTAMP}"
    mkdir -p "$BACKUP_DIR"
    for item in wlp.conf antisi filemon killswitch sshaudit sshd; do
        cp -r "$WLP_DIRECTORY/$item" "$BACKUP_DIR"
    done
    echo "Configuration backup created at $BACKUP_DIR"
}

restore_configuration() {
    echo "Searching for configuration backups..."
    last_backup=$(ls -td ${WLP_CONFIG_TMP_DIR}_* 2>/dev/null | head -n 1)
    if [ -z "$last_backup" ]; then
         echo "No configuration backup found in ${WLP_CONFIG_TMP_DIR}_* - using deafult"
         exit 0
    fi
    cp -r "$last_backup"/* "$WLP_DIRECTORY"
    if [ $? -eq 0 ]; then
         rm -rf "$last_backup"
         echo "Configuration backup from $last_backup restored and removed."
    else
         warning "Failed to restore configuration backup from $last_backup."
         exit 1
    fi
}

install_package() {
    VERSION="$1"
    echo "Installing IoT Nano Agent..."
    chmod +x "$PACKAGE_TEMP"

    FLAGS="--install --offline_mode"
    if ! sh -c "$PACKAGE_TEMP $FLAGS"; then
        error "Installation failed while executing the self-extracting package."
        exit 1
    fi

    if [ ! -d "$DEFAULT_INSTALL_PATH" ]; then
        mkdir -p "$DEFAULT_INSTALL_PATH" || exit 1
    fi

    echo "$VERSION" > "$INSTALLED_VERSION_FILE"
    find "$DEFAULT_INSTALL_PATH" -type d | xargs chmod a+rx
    printf "\nIoT Nano Agent version $VERSION installed successfully.\n"
}

uninstall_package() {
    if [ -d "$DEFAULT_INSTALL_PATH" ]; then
        echo "Uninstalling IoT Nano Agent from $DEFAULT_INSTALL_PATH..."
        if ! cpnano -u -y; then
            error "Failed uninstalling IoT Nano Agent."
            echo "This changes require root permissions - try running with sudo."
            exit 1
        fi
        rm -rf "$DEFAULT_INSTALL_PATH"
    else
        echo "IoT Nano Agent is not installed."
    fi
}

# Main processing
# 1) Sweep through $@, detect -nc/--no-colors and -h/--help, 
#    accumulate everything else in clean_args
clean_args=
while [ $# -gt 0 ]; do
    case "$1" in
        -nc|--no-colors)
            NO_COLORS=1
            shift
            ;;
        -h|--help)
            HELP=1
            shift
            ;;
        *)
            # wrap in quotes so multi-word args survive
            clean_args="$clean_args \"$1\""
            shift
            ;;
    esac
done

# 2) Replace positional parameters with the remaining args
eval set -- $clean_args

# 3) Now that NO_COLORS is known, init colors
configure_colors

# 4) If help was requested globally, show usage
if [ "$HELP" -eq 1 ]; then
    usage
fi

# 5) Must have at least one real command
if [ $# -lt 1 ]; then
    usage 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
    install)
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --version)
                    shift
                    VERSION_OVERRIDE="$1"
                    ;;
                --update)
                    UPDATE_FLAG=1
                    ;;
                --clean)
                    CLEAN_FLAG=1
                    ;;
                *)
                    echo "Unknown flag: $1"
                    usage 1
                    ;;
            esac
            shift
        done
        ;;
    uninstall)
        ;;
    version)
        ;;
    *)
        error "Unknown command or flag '$COMMAND'"
        usage 1
        ;;
esac

case "$COMMAND" in
    install)
        check_manager_requirements
        detect_platform
        download_manifest
        if [ -n "$VERSION_OVERRIDE" ]; then
            version_to_install="$VERSION_OVERRIDE"
        else
            version_to_install=$(get_latest_version_from_manifest)
        fi
        installed_version=$(get_installed_version)
        if [ "$UPDATE_FLAG" -eq 1 ]; then
            if [ "$installed_version" = "$version_to_install" ]; then
                echo "IoT Nano Agent is already up-to-date - Version: $installed_version"
                exit 0
            fi
        else
            if [ "$installed_version" != "none" ]; then
                if [ "$installed_version" = "$(get_latest_version_from_manifest)" ]; then
                    echo "IoT Nano Agent is already installed and up-to-date - Version: $installed_version"
                    exit 0
                else
                    echo "IoT Nano Agent is already installed - Version: $installed_version"
                fi
                if [ "$installed_version" != "$version_to_install" ]; then
                    printf "\nUse flag --update to install version $version_to_install.\n"
                fi
                exit 0
            fi
        fi
        expected_checksum=$(get_expected_checksum "$version_to_install")
        check_nano_agent_requirements
        download_package "$PLATFORM" "$version_to_install"
        verify_checksum "$expected_checksum"
        if [ "$installed_version" != "none" ]; then
            if [ "$CLEAN_FLAG" -ne 1 ]; then
                echo "Backing up configurations"
                backup_configuration
            fi
            uninstall_package
            printf "\n"
        fi
        install_package "$version_to_install"
        if [ "$CLEAN_FLAG" -ne 1 ]; then
            restore_configuration
        fi
        ;;
    version)
        detect_platform
        if [ "$#" -gt 0 ]; then
            case "$1" in
                --latest)
                    check_manager_requirements
                    download_manifest
                    latest_ver=$(get_latest_version_from_manifest)
                    echo "Platform: $PLATFORM"
                    echo "Latest available IoT Nano Agent version: $latest_ver"
                    ;;
                --list)
                    check_manager_requirements
                    download_manifest
                    installed_version=$(get_installed_version)
                    available_versions=$(list_available_versions)
                    echo "Platform: $PLATFORM"
                    echo "Installed IoT Nano Agent version: $installed_version"
                    echo "Available versions:"
                    echo "$available_versions"
                    ;;
                *)
                    error "Unknown option for version command '$1'"
                    usage 1
                    ;;
            esac
        else
            installed_version=$(get_installed_version)
            echo "Platform: $PLATFORM"
            echo "Installed IoT Nano Agent version: $installed_version"
        fi
        ;;
    uninstall)
        uninstall_package
        ;;
esac

cleanup