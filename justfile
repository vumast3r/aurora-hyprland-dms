# This is a justfile. See https://github.com/casey/just
# This is only used for local development. The builds made on the Fedora
# infrastructure are run in Pungi.

# Set a default for some recipes
default_variant := "niri-caelestia"
# Default to unified compose now that it works
unified_core := "true"
# unified_core := "false"
force_nocache := "true"
# force_nocache := "false"

# Default compose
all:
    just compose niri-caelestia

# Basic validation to make sure the manifests are not completely broken
validate:
    ./ci/validate

# Output the processed manifest
manifest variant=default_variant:
    rpm-ostree compose tree --print-only --repo=repo fedora-{{variant}}.yaml

# Compose a specific variant of Fedora
compose variant=default_variant:
    #!/bin/bash
    set -euxo pipefail

    variant={{variant}}
    variant_pretty="Niri-Caelestia"

    on_failure() {
        just archive {{variant}} repo
    }
    trap "on_failure" ERR

    ./ci/validate > /dev/null || (echo "Failed manifest validation" && exit 1)

    just prep

    buildid="$(date '+%Y%m%d.0')"
    timestamp="$(date --iso-8601=sec)"
    echo "${buildid}" > .buildid

    version="$(rpm-ostree compose tree --print-only --repo=repo fedora-${variant}.yaml | jq -r '."automatic-version-prefix"')"

    echo "Composing ${variant_pretty} ${version}.${buildid} ..."

    ARGS="--repo=repo --cachedir=cache"
    if [[ {{unified_core}} == "true" ]]; then
        ARGS+=" --unified-core"
    else
        ARGS+=" --workdir=tmp"
        rm -rf ./tmp
        mkdir -p tmp
        export RPM_OSTREE_I_KNOW_NON_UNIFIED_CORE_IS_DEPRECATED=1
        export SYSTEMD_OFFLINE=1
    fi
    if [[ {{force_nocache}} == "true" ]]; then
        ARGS+=" --force-nocache"
    fi
    CMD="rpm-ostree"
    if [[ ${EUID} -ne 0 ]]; then
        SUDO="sudo rpm-ostree"
    fi

    ${CMD} compose tree ${ARGS} \
        --add-metadata-string="version=${variant_pretty} ${version}.${buildid}" \
        "fedora-${variant}.yaml" \
            |& tee "logs/${variant}_${version}_${buildid}.${timestamp}.log"

    if [[ ${EUID} -ne 0 ]]; then
        if [[ {{unified_core}} == "false" ]]; then
            sudo chown --recursive "$(id --user --name):$(id --group --name)" tmp
        fi
        sudo chown --recursive "$(id --user --name):$(id --group --name)" repo cache
    fi

    ostree summary --repo=repo --update

# Compose an OCI image
compose-image variant=default_variant:
    #!/bin/bash
    set -euxo pipefail

    variant={{variant}}
    variant_pretty="Niri-Caelestia"

    ./ci/validate > /dev/null || (echo "Failed manifest validation" && exit 1)

    just prep

    buildid="$(date '+%Y%m%d.0')"
    timestamp="$(date --iso-8601=sec)"
    echo "${buildid}" > .buildid

    version="$(rpm-ostree compose tree --print-only --repo=repo fedora-${variant}.yaml | jq -r '."automatic-version-prefix"')"

    echo "Composing ${variant_pretty} ${version}.${buildid} ..."

    ARGS="--cachedir=cache --initialize"
    if [[ {{force_nocache}} == "true" ]]; then
        ARGS+=" --force-nocache"
    fi
    CMD="rpm-ostree"
    if [[ ${EUID} -ne 0 ]]; then
        SUDO="sudo rpm-ostree"
    fi

    ${CMD} compose image ${ARGS} \
         --label="quay.expires-after=4w" \
        "fedora-${variant}.yaml" \
        "fedora-${variant}.ociarchive" \
            |& tee "logs/${variant}_${version}_${buildid}.${timestamp}.log"

# Last steps from the compose recipe that can easily fail when the sudo timeout is reached
compose-finalise:
    #!/bin/bash
    set -euxo pipefail

    if [[ ${EUID} -ne 0 ]]; then
        sudo chown --recursive "$(id --user --name):$(id --group --name)" repo cache
    fi
    ostree summary --repo=repo --update

# Get ostree repo log
log variant=default_variant:
    ostree log --repo repo fedora/43/x86_64/{{variant}}

# Get the diff between two ostree commits
diff target origin:
    ostree diff --repo repo --fs-diff {{target}} {{origin}}

# Serve the generated commit for testing
serve:
    # See https://github.com/TheWaWaR/simple-http-server
    simple-http-server --index --ip 192.168.122.1 --port 8000 --silent

# Preparatory steps before starting a compose. Also ensure the ostree repo is initialized
prep:
    #!/bin/bash
    set -euxo pipefail

    mkdir -p repo cache logs
    if [[ ! -f "repo/config" ]]; then
        pushd repo > /dev/null || exit 1
        ostree init --repo . --mode=archive
        popd > /dev/null || exit 1
    fi
    # Set option to reduce fsync for transient builds
    ostree --repo=repo config set 'core.fsync' 'false'

# Clean up everything
clean-all:
    just clean-repo
    just clean-cache

# Only clean the ostree repo
clean-repo:
    rm -rf ./repo

# Only clean the package and repo caches
clean-cache:
    rm -rf ./cache

# Run from inside a container
podman:
    podman run --rm -ti --volume $PWD:/srv:rw --workdir /srv --privileged quay.io/fedora-ostree-desktops/buildroot

# Update the container image
podman-pull:
    podman pull quay.io/fedora-ostree-desktops/buildroot

upload-container variant=default_variant:
    #!/bin/bash
    set -euxo pipefail

    variant={{variant}}
    variant_pretty="Niri-Caelestia"

    if [[ -z ${CI_REGISTRY_USER+x} ]] || [[ -z ${CI_REGISTRY_PASSWORD+x} ]]; then
        echo "Skipping artifact archiving: Not in CI"
        exit 0
    fi
    if [[ "${CI}" != "true" ]]; then
        echo "Skipping artifact archiving: Not in CI"
        exit 0
    fi

    version="$(rpm-ostree compose tree --print-only --repo=repo fedora-${variant}.yaml | jq -r '."automatic-version-prefix"')"

    image="quay.io/fedora-ostree-desktops/${variant}"
    buildid=""
    if [[ -f ".buildid" ]]; then
        buildid="$(< .buildid)"
    else
        buildid="$(date '+%Y%m%d.0')"
        echo "${buildid}" > .buildid
    fi

    git_commit=""
    if [[ -n "${CI_COMMIT_SHORT_SHA}" ]]; then
        git_commit="${CI_COMMIT_SHORT_SHA}"
    else
        git_commit="$(git rev-parse --short HEAD)"
    fi

    skopeo login --username "${CI_REGISTRY_USER}" --password "${CI_REGISTRY_PASSWORD}" quay.io
    skopeo copy --retry-times 3 "oci-archive:fedora-${variant}.ociarchive" "docker://${image}:${version}.${buildid}.${git_commit}"
    skopeo copy --retry-times 3 "docker://${image}:${version}.${buildid}.${git_commit}" "docker://${image}:${version}"

# Make a container image with the artifacts
archive variant=default_variant kind="repo":
    #!/bin/bash
    set -euxo pipefail

    if [[ -z ${CI_REGISTRY_USER+x} ]] || [[ -z ${CI_REGISTRY_PASSWORD+x} ]]; then
        echo "Skipping artifact archiving: Not in CI"
        exit 0
    fi
    if [[ "${CI}" == "true" ]]; then
        rm -rf cache
    fi

    variant={{variant}}
    variant_pretty="Niri-Caelestia"

    kind={{kind}}
    case "${kind}" in
        "repo")
            echo "Archiving repo"
            ;;
        "iso")
            echo "Archiving iso"
            ;;
        "*")
            echo "Unknown kind"
            exit 1
            ;;
    esac

    version="$(rpm-ostree compose tree --print-only --repo=repo fedora-${variant}.yaml | jq -r '."automatic-version-prefix"')"

    if [[ "${kind}" == "repo" ]]; then
        tar --create --file repo.tar.zst --zstd repo
        if [[ "${CI}" == "true" ]]; then
            rm -rf repo
        fi
    fi
    if [[ "${kind}" == "iso" ]]; then
        tar --create --file iso.tar.zst --zstd iso
        if [[ "${CI}" == "true" ]]; then
            rm -rf iso
        fi
    fi

    container="$(buildah from scratch)"
    if [[ "${kind}" == "repo" ]]; then
        buildah copy "${container}" repo.tar.zst /
    fi
    if [[ "${kind}" == "iso" ]]; then
        buildah copy "${container}" iso.tar.zst /
    fi
    buildah config --label "quay.expires-after=2w" "${container}"
    commit="$(buildah commit ${container})"

    image="quay.io/fedora-ostree-desktops/${variant}"
    buildid=""
    if [[ -f ".buildid" ]]; then
        buildid="$(< .buildid)"
    else
        buildid="$(date '+%Y%m%d.0')"
        echo "${buildid}" > .buildid
    fi

    git_commit=""
    if [[ -n "${CI_COMMIT_SHORT_SHA}" ]]; then
        git_commit="${CI_COMMIT_SHORT_SHA}"
    else
        git_commit="$(git rev-parse --short HEAD)"
    fi

    buildah login -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" quay.io
    buildah push "${commit}" "docker://${image}:${version}.${buildid}.${git_commit}.${kind}"
