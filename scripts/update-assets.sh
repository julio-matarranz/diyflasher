#!/bin/bash
TOKEN_HEADER="authorization: Bearer ${2}"
cat $1/github-assets/VERSIONS | while read -r tag; do
    VERSION=$(printf $tag | jq -sRr 'gsub("[\\n\\t\\r]"; "")')
    echo $VERSION    
    RELEASE=$(curl --header "${TOKEN_HEADER}" -s https://api.github.com/repos/BitMaker-hub/NerdMiner_v2/releases/tags/$(printf $tag | jq -sRr 'gsub("[\\n\\t\\r]"; "") | @uri'))
    COMMIT_SHA=$(echo $RELEASE | jq -r '.target_commitish')
    COMMIT_SHA_FILE="$1/github-assets/${VERSION}/commit_sha"
    if test -f "${COMMIT_SHA_FILE}" && grep -q "${COMMIT_SHA}" "${COMMIT_SHA_FILE}"; then
        continue
    fi
    rm -f "$1/github-assets/${VERSION}/assets"
    echo "${COMMIT_SHA}" > "${COMMIT_SHA_FILE}"
    echo $RELEASE | jq -r 'try .assets[] | [.name, .browser_download_url] | @csv' | while IFS="," read -r name url; do
        NAME=$(printf $name | jq -sRr 'gsub("[\\n\\t\\r\"]"; "")')
        echo $NAME
        curl --header "${TOKEN_HEADER}" -L --create-dirs --output $1/github-assets/${VERSION}/${NAME} $(printf $url | jq -sRr 'gsub("[\\n\\t\\r\"]"; "")')
        echo ${NAME} >>$1/github-assets/${VERSION}/assets
    done
done
