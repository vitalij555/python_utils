#!/usr/bin/env bash

function increment_version() {
    local version=$1
    local increment_type=$2

    # Extract only the version number part after the colon
    local version_number=${version#*:}

    local -a version_parts
    IFS='.' read -ra version_parts <<< "$version_number"

    if [[ $increment_type == "major" ]]; then
        version_parts[0]=$((version_parts[0] + 1))
        version_parts[1]=0
    elif [[ $increment_type == "minor" ]]; then
        version_parts[1]=$((version_parts[1] + 1))
    fi

    # Reconstruct the service name and version
    local service_name=${version%%:*}
    local new_version="${service_name}:${version_parts[*]}"
    echo "${new_version// /.}"
}


function deploy_to_registry() {
    local VERSION_FILE="./version"
    local increment_type=$1  # major or minor
    local current_version

    if [[ ! -f "${VERSION_FILE}" ]]; then
      echo "Error: version file does not exist. Currently looking for it here: ${VERSION_FILE}" >&2
      return 1
    fi

    current_version=$(<"$VERSION_FILE")
    local service_name=${current_version%%:*}
    local new_version
    new_version=$(increment_version "$current_version" "$increment_type")

    # Extract only the version number part for Docker tagging
    local new_version_number=${new_version#*:}

    echo "$new_version" > "$VERSION_FILE"
    docker build -t "${service_name}:${new_version_number}" ../../
    local registry_url="localhost:5000"
    docker tag "${service_name}:${new_version_number}" "$registry_url/${service_name}:${new_version_number}"
    docker push "$registry_url/${service_name}:${new_version_number}"

    git add "$VERSION_FILE"
    git commit -m "Bump version to ${service_name}:${new_version_number}"
    git tag "${service_name}-version-${new_version_number}"
    git push origin master --tags
}

#private
function show_help() {
    echo "Usage: $0 [--help] [-i increment_type]"
    echo "Options:"
    echo "   -i    Type of version increment (major or minor)"
    echo "   --help, -h    Show help"
}

while :; do
    case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -i)
        if [ "$2" ]; then
            increment_type=$2
            shift
        else
            echo "Error: -i requires a non-empty option argument."
            show_help
            exit 1
        fi
        ;;
    *)
        break
        ;;
    esac
    shift
done

if [ -z "$increment_type" ]; then
    echo "Error: Increment type is required"
    show_help
    exit 1
fi

deploy_to_registry "$increment_type"
