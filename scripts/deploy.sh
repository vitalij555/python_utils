#!/usr/bin/env bash


function increment_version() {
    local version=$1
    local increment_type=$2

    local -a version_parts
    IFS='.' read -ra version_parts <<< "$version"

    if [[ $increment_type == "major" ]]; then
        version_parts[0]=$((version_parts[0] + 1))
        version_parts[1]=0
    elif [[ $increment_type == "minor" ]]; then
        version_parts[1]=$((version_parts[1] + 1))
    fi

    # Join the version parts back together and return the result
    local new_version="${version_parts[*]}"
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

    current_version=$(<"$version_file")

    local new_version
    new_version=$(increment_version "$current_version" "$increment_type")
    echo "$new_version" > "$version_file"
    docker build -t "my-service:$new_version" ../../
    local registry_url="localhost:5000"
    docker tag "my-service:$new_version" "$registry_url/my-service:$new_version"
    docker push "$registry_url/my-service:$new_version"


    git add "$version_file"
    git commit -m "Bump version to $new_version"
    git tag "version-$new_version"
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
