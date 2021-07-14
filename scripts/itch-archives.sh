#!/usr/bin/env bash

PROJECT="${HOME}/Development/Oval-Tutu/little-spy"
VERSION=$(grep VERSION "${PROJECT}/code/autoload/Project.gd" | cut -d'"' -f2)
FULLNAME=$(grep NAME "${PROJECT}/code/autoload/Project.gd" | cut -d'"' -f2)
SAFENAME=$(grep NAME "${PROJECT}/code/autoload/Project.gd" | cut -d'"' -f2 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

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
        if [[ $PLATFORM == *"linux"* ]]; then
            mktar "${BUILD}" "${ARCHIVE}"
        else
            mkzip "${BUILD}" "${ARCHIVE}"
        fi
    fi
done
