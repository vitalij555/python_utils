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
    local current_version_number=${current_version#*:}
    local latest_tag_version=$(git describe --tags --match "${service_name}-version-*" --abbrev=0 2>/dev/null | sed "s/${service_name}-version-//")
    local registry_url="192.168.49.2:32615"
    local image_exists=$(docker image inspect "$registry_url/${service_name}:${latest_tag_version}" > /dev/null 2>&1 && echo "yes" || echo "no")

    echo "Latest tag detected: ${latest_tag_version}"


    if [[ "${current_version_number}" != "${latest_tag_version}" || "${image_exists}" == "no" ]]; then
        # There have been commits since the last tag, or the image does not exist in the registry
        local new_version
        new_version=$(increment_version "$current_version" "$increment_type")

        # Extract only the version number part for Docker tagging
        local new_version_number=${new_version#*:}

        echo "$new_version" > "$VERSION_FILE"
        docker build -t "${service_name}:${new_version_number}" .

        docker tag "${service_name}:${new_version_number}" "$registry_url/${service_name}:${new_version_number}"
        docker push "$registry_url/${service_name}:${new_version_number}"

        # Only add, commit, tag, and push if a new version was actually created
        if [[ "${current_version_number}" != "${latest_tag_version}" ]]; then
            git add "$VERSION_FILE"
            git commit -m "Bump version to ${service_name}:${new_version_number}"
            git tag "${service_name}-version-${new_version_number}"
            git push origin master --tags
        fi
    else
        # No new commits since the last tag and the image exists in the registry
        echo "No new commits since the last version tag and the image exists in the registry. Skipping build and push."
    fi
}

#private
function show_help() {
    echo "Usage: $0 [--help] [-i increment_type]"
    echo "Options:"
    echo "   -i    Type of version increment (major or minor)"
    echo "   --help, -h    Show help"
}

# here we preven this code to be run via "source"
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
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
fi
