#!/bin/sh

set -eu

package_name=$1

package_id=$(curl -sSf --header "PRIVATE-TOKEN: ${GITLAB_PROJECT_TOKEN}" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages?sort=desc&per_page=1" | jq ".[] | select(.version == \"${BUILD_VERSION}\") | .id")
package_file_id=$(curl -sSf --header "PRIVATE-TOKEN: ${GITLAB_PROJECT_TOKEN}" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/${package_id}/package_files" | jq ".[] | select(.file_name == \"$package_name\") | .id")
echo "https://gitlab.archlinux.org/archlinux/archlinux-docker/-/package_files/${package_file_id}/download"
