#!/usr/bin/env bash
# install_hadoop.sh — Install Hadoop on Linux with JDK 17
# Tested on Ubuntu 22.04/24.04 and Debian 12.
# Run as a non-root user with sudo access:
#   chmod +x install_hadoop.sh && ./install_hadoop.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — adjust these before running
# ---------------------------------------------------------------------------
HADOOP_VERSION="3.5.0"
HADOOP_MIRROR="https://downloads.apache.org/hadoop/common"
INSTALL_DIR="/opt/hadoop"
HADOOP_USER="${SUDO_USER:-$USER}"   # the user who will own the Hadoop install

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
info()  { echo "[INFO]  $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

require_root() {
    [[ $EUID -eq 0 ]] || error "Please run this script with sudo: sudo ./install_hadoop.sh"
}

# ---------------------------------------------------------------------------
# 1. Ensure JDK 17 is installed
#    Hadoop 3.3+ officially supports (and recommends) JDK 17.
# ---------------------------------------------------------------------------
install_jdk17() {
    info "Checking for JDK 17..."

    if java -version 2>&1 | grep -q '"17'; then
        info "JDK 17 is already installed: $(java -version 2>&1 | head -1)"
        return
    fi

    info "Installing OpenJDK 17..."
    if command -v apt-get &>/dev/null; then
        apt-get update -q
        apt-get install -y openjdk-17-jdk
    elif command -v dnf &>/dev/null; then
        dnf install -y java-17-openjdk-devel
    elif command -v yum &>/dev/null; then
        yum install -y java-17-openjdk-devel
    else
        error "Unsupported package manager. Install OpenJDK 17 manually and re-run."
    fi

    # Set JDK 17 as the default if multiple JDKs are present (Debian/Ubuntu)
    if command -v update-alternatives &>/dev/null; then
        JAVA17=$(update-java-alternatives -l 2>/dev/null | awk '/java-17/{print $3"/bin/java"}' | head -1 || true)
        if [[ -n "$JAVA17" ]]; then
            update-alternatives --set java "$JAVA17" || true
        fi
    fi

    info "JDK version: $(java -version 2>&1 | head -1)"
}

# ---------------------------------------------------------------------------
# 2. Install system dependencies
# ---------------------------------------------------------------------------
install_deps() {
    info "Installing system dependencies (ssh, rsync, wget)..."
    if command -v apt-get &>/dev/null; then
        apt-get install -y ssh rsync wget
    elif command -v dnf &>/dev/null; then
        dnf install -y openssh-server rsync wget
    elif command -v yum &>/dev/null; then
        yum install -y openssh-server rsync wget
    fi
}

# ---------------------------------------------------------------------------
# 3. Download and verify Hadoop
# ---------------------------------------------------------------------------
download_hadoop() {
    local tarball="hadoop-${HADOOP_VERSION}.tar.gz"
    local url="${HADOOP_MIRROR}/hadoop-${HADOOP_VERSION}/${tarball}"

    if [[ -d "${INSTALL_DIR}" ]]; then
        info "Hadoop already present at ${INSTALL_DIR} — skipping download."
        return
    fi

    info "Downloading Hadoop ${HADOOP_VERSION}..."
    wget -q --show-progress -O "/tmp/${tarball}" "${url}"

    info "Downloading SHA-512 checksum..."
    wget -q -O "/tmp/${tarball}.sha512" "${url}.sha512"

    info "Verifying checksum..."
    pushd /tmp > /dev/null
    sha512sum -c "${tarball}.sha512"
    popd > /dev/null

    info "Extracting to ${INSTALL_DIR}..."
    mkdir -p "${INSTALL_DIR}"
    tar -xzf "/tmp/${tarball}" -C "${INSTALL_DIR}" --strip-components=1
    chown -R "${HADOOP_USER}:${HADOOP_USER}" "${INSTALL_DIR}"
    rm -f "/tmp/${tarball}" "/tmp/${tarball}.sha512"
}

# ---------------------------------------------------------------------------
# 4. Configure Hadoop environment (hadoop-env.sh)
# ---------------------------------------------------------------------------
configure_hadoop_env() {
    local hadoop_env="${INSTALL_DIR}/etc/hadoop/hadoop-env.sh"
    local java_home
    java_home=$(dirname "$(dirname "$(readlink -f "$(which java)")")")

    info "Setting JAVA_HOME=${java_home} in hadoop-env.sh..."

    # Remove any existing JAVA_HOME line and then append the correct one
    sed -i '/^export JAVA_HOME/d' "${hadoop_env}"
    echo "export JAVA_HOME=${java_home}" >> "${hadoop_env}"

    # Hadoop 3.3+ with JDK 17 requires the following add-opens flags to avoid
    # illegal reflective access warnings/errors introduced in Java 9+.
    if ! grep -q 'HADOOP_OPTS.*add-opens' "${hadoop_env}"; then
        cat >> "${hadoop_env}" <<'EOF'

# JDK 17 compatibility: allow Hadoop's internal reflection usage
export HADOOP_OPTS="\
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/java.lang.invoke=ALL-UNNAMED \
  --add-opens=java.base/java.io=ALL-UNNAMED \
  --add-opens=java.base/java.net=ALL-UNNAMED \
  --add-opens=java.base/java.nio=ALL-UNNAMED \
  --add-opens=java.base/java.util=ALL-UNNAMED \
  --add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
  --add-opens=java.base/sun.nio.ch=ALL-UNNAMED \
  --add-opens=java.base/sun.nio.cs=ALL-UNNAMED \
  ${HADOOP_OPTS}"
EOF
    fi
}

# ---------------------------------------------------------------------------
# 5. Write minimal core-site.xml for pseudo-distributed / local mode
# ---------------------------------------------------------------------------
configure_core_site() {
    local core_site="${INSTALL_DIR}/etc/hadoop/core-site.xml"
    info "Writing core-site.xml..."
    cat > "${core_site}" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <!-- Default filesystem: local mode. Change to hdfs://localhost:9000 for HDFS. -->
  <property>
    <name>fs.defaultFS</name>
    <value>file:///</value>
  </property>
</configuration>
EOF
}

# ---------------------------------------------------------------------------
# 6. Add environment variables to the installing user's shell profile
# ---------------------------------------------------------------------------
configure_shell_profile() {
    local profile_file
    local user_home
    user_home=$(eval echo "~${HADOOP_USER}")

    if [[ -f "${user_home}/.zshrc" ]]; then
        profile_file="${user_home}/.zshrc"
    else
        profile_file="${user_home}/.bashrc"
    fi

    if grep -q "HADOOP_HOME" "${profile_file}" 2>/dev/null; then
        info "HADOOP_HOME already set in ${profile_file} — skipping."
        return
    fi

    info "Appending Hadoop environment variables to ${profile_file}..."
    cat >> "${profile_file}" <<EOF

# --- Hadoop ---
export HADOOP_HOME=${INSTALL_DIR}
export HADOOP_CONF_DIR=\${HADOOP_HOME}/etc/hadoop
export PATH=\${PATH}:\${HADOOP_HOME}/bin:\${HADOOP_HOME}/sbin
EOF

    chown "${HADOOP_USER}:${HADOOP_USER}" "${profile_file}"
    info "Source '${profile_file}' or open a new terminal to apply changes."
}

# ---------------------------------------------------------------------------
# 7. Smoke test
# ---------------------------------------------------------------------------
smoke_test() {
    info "Running smoke test: hadoop version..."
    export PATH="${INSTALL_DIR}/bin:${PATH}"
    if sudo -u "${HADOOP_USER}" "${INSTALL_DIR}/bin/hadoop" version; then
        info "Hadoop installed successfully."
    else
        error "Smoke test failed. Check the logs above."
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
require_root
install_jdk17
install_deps
download_hadoop
configure_hadoop_env
configure_core_site
configure_shell_profile
smoke_test

info "Done. Hadoop ${HADOOP_VERSION} is ready."
info "To switch to pseudo-distributed (HDFS) mode, update core-site.xml and"
info "hdfs-site.xml in ${INSTALL_DIR}/etc/hadoop/ then run hdfs namenode -format."
