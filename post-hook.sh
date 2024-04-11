#!/bin/bash

FILE=Chart.yaml
FILE_PATH=helm/crossplane/"$FILE"

if [[ "$1" != "chart" ]]; then
	echo "Skipping post-hook for $1"
	exit 0
fi

VER=${5##v}
echo "Patching $FILE with upstream versions info"

yq ".appVersion = \"$VER\"" -i "$FILE_PATH"
yq ".upstreamChartVersion = \"$VER\"" -i "$FILE_PATH"
