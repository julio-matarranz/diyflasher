#!/bin/bash
export WORKSPACE="$1"
TOKEN_HEADER="authorization: Bearer ${2}"
curl --header "${TOKEN_HEADER}" -s https://api.github.com/repos/BitMaker-hub/NerdMiner_v2/tags --create-dirs --output "${WORKSPACE}/github-assets/tags.json"
jq -rc '.[:2][] | select (.name | contains("nerdminer-prerelease") or contains("nerdminer-release")) | .name' "${WORKSPACE}/github-assets/tags.json" > "${WORKSPACE}/github-assets/VERSIONS"
cat "${WORKSPACE}/github-assets/VERSIONS" | while read -r tag; do
    VERSION=$(printf $tag | jq -sRr 'gsub("[\\n\\t\\r]"; "")')
    echo $VERSION    
    RELEASE=$(curl --header "${TOKEN_HEADER}" -s https://api.github.com/repos/BitMaker-hub/NerdMiner_v2/releases/tags/$(printf $tag | jq -sRr 'gsub("[\\n\\t\\r]"; "") | @uri'))
    COMMIT_SHA=$(echo $RELEASE | jq -r '.target_commitish')
    COMMIT_SHA_FILE="${WORKSPACE}/github-assets/${VERSION}/commit_sha"
    if test -f "${COMMIT_SHA_FILE}" && grep -q "${COMMIT_SHA}" "${COMMIT_SHA_FILE}"; then
        continue
    fi
    rm -f "${WORKSPACE}/github-assets/${VERSION}/assets"
    echo "${COMMIT_SHA}" > "${COMMIT_SHA_FILE}"
    echo $RELEASE | jq -r 'try .assets[] | [.name, .browser_download_url] | @csv' | while IFS="," read -r name url; do
        NAME=$(printf $name | jq -sRr 'gsub("[\\n\\t\\r\"]"; "")')
        echo $NAME
        curl --header "${TOKEN_HEADER}" -L --create-dirs --output ${WORKSPACE}/github-assets/${VERSION}/${NAME} $(printf $url | jq -sRr 'gsub("[\\n\\t\\r\"]"; "")')
        echo ${NAME} >> "${WORKSPACE}/github-assets/${VERSION}/assets"
    done
done
find "${WORKSPACE}/github-assets/" -mindepth 1 -maxdepth 1 -type d -exec sh -c 'cat $WORKSPACE/github-assets/VERSIONS | tr -d "[:space:]" |  grep -si $(basename $0) || rm -rf $0' {} \;
rm -rf "${WORKSPACE}/github-assets/tags.json"