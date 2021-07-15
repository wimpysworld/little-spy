#!/usr/bin/env bash

PROJECT="${HOME}/Development/wimpysworld/little-spy"
VERSION=$(grep VERSION "${PROJECT}/code/autoload/Project.gd" | cut -d'"' -f2)
FULLNAME=$(grep NAME "${PROJECT}/code/autoload/Project.gd" | cut -d'"' -f2)
SAFENAME=$(grep NAME "${PROJECT}/code/autoload/Project.gd" | cut -d'"' -f2 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

function mkapk() {
    local IN="${1}/${SAFENAME}.apk"
    local OUT="${PROJECT}/builds/${2}.apk"
    echo "Making ${OUT}..."
    cp "${IN}" "${OUT}"
}

function mkdmg() {
    # Reference
    # https://stackoverflow.com/questions/286419/how-to-build-a-dmg-mac-os-x-file-on-a-non-mac-platform
    local IN="${1}/${SAFENAME}.zip"
    local UNCOMPRESSED="${PROJECT}/builds/${2}-uncompressed.dmg"
    local COMPRESSED="${PROJECT}/builds/${2}.dmg"

    if [ -e /usr/local/bin/dmg ]; then
        echo "Making ${COMPRESSED}..."
    else
        echo "Making ${UNCOMPRESSED}..."
    fi
    rm -rf "/tmp/${SAFENAME}" 2> /dev/null
    mkdir -p "/tmp/${SAFENAME}"
    unzip -q "${IN}" -d "/tmp/${SAFENAME}"
    local APPNAME=$(ls -1 "/tmp/${SAFENAME}/" | head -n1)
    local EXENAME=$(echo "${APPNAME}" | cut -d'.' -f1)
    # Make sure the executable bit is set.
    chmod +x "/tmp/${SAFENAME}/${APPNAME}/Contents/MacOS/${EXENAME}"
    genisoimage -quiet -D -V "${FULLNAME} ${VERSION}" -no-pad -r -apple -o "${UNCOMPRESSED}" "/tmp/${SAFENAME}/${APPNAME}"
    if [ -e /usr/local/bin/dmg ]; then
        dmg "${UNCOMPRESSED}" "${COMPRESSED}" > /dev/null 2>&1
    fi
    rm -rf "/tmp/${SAFENAME}" 2> /dev/null
}

function mktar() {
    local IN="${1}"
    local OUT="${PROJECT}/builds/${2}.tar.xz"
    echo "Making ${OUT}..."
    rm "${OUT}" 2>/dev/null
    tar --directory="${1}" --xz --create --file "${OUT}" .
}

function mkzip() {
    local IN="${1}/"
    local OUT="${PROJECT}/builds/${2}.zip"
    echo "Making ${OUT}..."
    rm "${OUT}" 2>/dev/null
    zip --quiet --junk-paths --recurse-paths "${OUT}" "${IN}"
}

for BUILD in ${PROJECT}/builds/*; do
    if [ -d "${BUILD}" ]; then
        PLATFORM=$(basename ${BUILD})
        ARCHIVE="${SAFENAME}-${VERSION}-${PLATFORM}"
        if [[ $PLATFORM == *"android"* ]]; then
            mkapk "${BUILD}" "${ARCHIVE}"
        elif [[ $PLATFORM == *"linux"* ]]; then
            mktar "${BUILD}" "${ARCHIVE}"
        elif [[ $PLATFORM == *"macos"* ]]; then
            mkdmg "${BUILD}" "${ARCHIVE}"
        else
            mkzip "${BUILD}" "${ARCHIVE}"
        fi
    fi
done
