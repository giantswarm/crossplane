#!/bin/bash -e

BIN_NAME=$(basename "$0")
declare -r ANNOTATE="(upstream-split) "
declare -r OPTSTRING=":hn:r:t:d:l:m:sagu"

function help() {
	echo "Usage: $BIN_NAME -n CONFIG_NAME -r REMOTE_URL -t REMOTE_REF -m LAST_MERGED_TAG -d REMOTE_DIR -l LOCAL_DIR [-a] [-g] [-s]"
	echo
	echo "  Update a subtree in a local repository's LOCAL_DIR from a REMOTE_URL repository."
	echo
	echo "  Options:"
	echo "    -n CONFIG_NAME: the name of the sync. This is aribtrary string, but keep it the same for all runs for the same subtree."
	echo "    -r REMOTE_URL: the URL of the upstream repository"
	echo "    -t REMOTE_REF: the tag in the upstream repository to sync to"
	echo "    -m LAST_MERGED_TAG: the last upstream tag that was already merged to this repository"
	echo "    -d REMOTE_DIR: the directory in the upstream repository to sync from"
	echo "    -l LOCAL_DIR: the directory in the local repository to sync to"
	echo "    -a force 'add' as subtree operation (optional, defaults to auto-detect)"
	echo "    -g force 'merge' as subtree operation (optional, defaults to auto-detect)"
	echo "    -s include 'squash' in subtree operation"
	echo "    -u don't annotate the commits in artificial history"
	echo
}

function parse_config() {
	set +e
	TEMP=$(getopt -o "$OPTSTRING" -n "$BIN_NAME" -- "$@")
	if [[ $? -ne 0 ]]; then
		printf "Error: wrong argument.\n" >&2
		help
		exit 1
	fi
	set -e

	eval set -- "$TEMP"
	unset TEMP

	FORCE_OPT=""
	SQUASH_OPT=""
	while true; do
		case "$1" in
		'-n')
			CONFIG_NAME=$2
			shift 2
			continue
			;;
		'-r')
			REMOTE_URL=$2
			shift 2
			continue
			;;
		'-t')
			REMOTE_REF=$2
			shift 2
			continue
			;;
		'-d')
			REMOTE_DIR=$2
			shift 2
			continue
			;;
		'-l')
			DOWN_DIR=$2
			shift 2
			continue
			;;
		'-m')
			LAST_MERGED_TAG=$2
			shift 2
			continue
			;;
		'-a')
			FORCE_OPT="add"
			shift 1
			continue
			;;
		'-g')
			FORCE_OPT="merge"
			shift 1
			continue
			;;
		'-s')
			SQUASH_OPT=1
			shift 1
			continue
			;;
		'-u')
			DONT_ANNOTATE=1
			shift 1
			continue
			;;
		'-h')
			help
			exit 0
			;;
		'--')
			shift
			break
			;;
		*)
			echo 'Internal error.' >&2
			exit 1
			;;
		esac
	done

	if [[ -z "$CONFIG_NAME" ]]; then
		echo "Error: CONFIG_NAME is required" >&2
		help
		exit 1
	fi
	if [[ -z "$REMOTE_URL" ]]; then
		echo "Error: REMOTE_URL is required" >&2
		help
		exit 1
	fi
	if [[ -z "$REMOTE_REF" ]]; then
		echo "Error: REMOTE_REF is required" >&2
		help
		exit 1
	fi
	if [[ -z "$REMOTE_DIR" ]]; then
		echo "Error: REMOTE_DIR is required" >&2
		help
		exit 1
	fi
	if [[ -z "$DOWN_DIR" ]]; then
		echo "Error: DOWN_DIR is required" >&2
		help
		exit 1
	fi
	if [[ -z "$LAST_MERGED_TAG" ]]; then
		echo "Error: LAST_MERGED_TAG is required" >&2
		help
		exit 1
	fi
}

function fetch_and_split() {
	local upstream_name=$1
	local upstream_ref=$2
	local split_branch_name=$3
	local split_tag_name=$4
	local remote_dir=$5

	local current_branch
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	# fetch upstream and the configured tag
	git tag -d "$split_tag_name" || true
	git fetch -n "$upstream_name" "$upstream_ref:refs/tags/$split_tag_name"
	git checkout "$split_tag_name"

	SPLIT_CMD=(git subtree split --prefix="$remote_dir" -b "$split_branch_name")
	# split it
	git branch -D "$split_branch_name" || true
	if [[ -z "$DONT_ANNOTATE" ]]; then
		SPLIT_CMD+=(--annotate="$ANNOTATE")
	fi
	"${SPLIT_CMD[@]}"

	# return to original branch
	git checkout "$current_branch"
}

parse_config "$@"
echo "Processing config: $CONFIG_NAME"

SPLIT_BRANCH_NAME="upstream-split-${CONFIG_NAME}"
SPLIT_TAG_NAME="subtree-split-tag-${CONFIG_NAME}"
OLD_SPLIT_BRANCH_NAME="old-upstream-split-${CONFIG_NAME}"
OLD_SPLIT_TAG_NAME="old-subtree-split-tag-${CONFIG_NAME}"

current_branch=$(git rev-parse --abbrev-ref HEAD)

# dir name in the git logs always ends with a slash, so make sure we can grep it
if ! [[ "$DOWN_DIR" == */ ]]; then
	DOWN_DIR="$DOWN_DIR/"
fi

UPSTREAM_NAME="upstream-${CONFIG_NAME}"
# check if upstream exists and add it if not
git remote | grep "$UPSTREAM_NAME" || git remote add "$UPSTREAM_NAME" "$REMOTE_URL"

fetch_and_split "$UPSTREAM_NAME" "$REMOTE_REF" "$SPLIT_BRANCH_NAME" "$SPLIT_TAG_NAME" "$REMOTE_DIR"
fetch_and_split "$UPSTREAM_NAME" "$LAST_MERGED_TAG" "$OLD_SPLIT_BRANCH_NAME" "$OLD_SPLIT_TAG_NAME" "$REMOTE_DIR"

# decide merge vs add
if [[ -z "$FORCE_OPT" ]]; then
	if git log -q | grep "Add '$DOWN_DIR' from commit" >/dev/null; then
		op="merge"
	else
		op="add"
	fi
else
	op="$FORCE_OPT"
fi

set +e
NOTES_CMD=(git notes add -f -m "\"upstream sync: URL='$REMOTE_URL' SYNC_REF='$REMOTE_REF' REMOTE_DIR='$REMOTE_DIR' DOWN_DIR='$DOWN_DIR'\"")
SUBTREE_CMD=(git subtree "$op" "--prefix=$DOWN_DIR" -m "Merge '$DOWN_DIR' from tag '$REMOTE_REF'" "$SPLIT_BRANCH_NAME")
# merge it
if [[ -n "$SQUASH_OPT" ]]; then
	SUBTREE_CMD+=("--squash")
fi
"${SUBTREE_CMD[@]}"
EX=$?
if [[ "$EX" -ne 0 ]]; then
	echo "***"
	echo "A problem (merge conflict?) was detected when running 'git subtree $op --prefix=$DOWN_DIR $SPLIT_BRANCH_NAME'."
	echo "When you're done resolving it, do a commit using the follwowing commands:"
	echo
	echo "git commit -m \"Merge '$DOWN_DIR' from tag '$REMOTE_REF'\""
	echo "${NOTES_CMD[@]}"
	exit "$EX"
fi
set -e
"${NOTES_CMD[@]}"

echo "Config $CONFIG_NAME done"
