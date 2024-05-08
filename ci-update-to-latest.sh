#!/bin/bash

BIN_NAME=$(basename "$0")
function help() {
	echo "Usage: $BIN_NAME REPO_DIR [REPO_NAME]"
	echo
	echo "  REPO_DIR: the directory of the repository to update"
	echo "  REPO_NAME: the name of the repository to push the changes to, in GitHub's 'owner/repo' format (autodetected)"
	echo
	echo "  Requires a config file named 'subtree-cfg.ini' with at least one config section with the following structure:"
	echo "    [CONFIG_SECTION_NAME]"
	echo "    REMOTE_URL=X: the URL of the upstream repository"
	echo "    REMOTE_DIR=X: the directory in the upstream repository to extract"
	echo "    DOWN_DIR=X: the directory in the current repository to put the subtree in"
	echo "    SQUASH=true: whether to squash the commits (optional, defaults to false)"
	echo "    SKIP_ANNOTATE=true: whether to skip annotating the commits (optional, defaults to false)"
	echo "    TAGS_FILTER='helm-.*': filter discovered upstream charts only to the ones matching this extended grep expression (optional, default: '.*')"
}

if [[ $# -eq 1 && ($1 == "-h" || $1 == "--help") ]]; then
	help
	exit 0
fi

if [[ $# -ne 1 && $# -ne 2 ]]; then
	help
	exit 1
fi

REPO_DIR=$1
if [[ $# -eq 2 ]]; then
	REPO_NAME=$2
fi

if [[ ! -d "$REPO_DIR" ]]; then
	echo "Repository directory $REPO_DIR not found"
	exit 2
fi

declare -r SUBTREE_SCRIPT="git-subtree-update.sh"
start_dir=$(pwd)
if [[ ! -x "$start_dir/$SUBTREE_SCRIPT" ]]; then
	echo "Subtree script $start_dir/$SUBTREE_SCRIPT not found"
	exit 3
fi

cd "$REPO_DIR" || exit 1

declare -r CFG_FILE_NAME="subtree-cfg.ini"
# parse config options
if [[ ! -f "$CFG_FILE_NAME" ]]; then
	echo "Config file $CFG_FILE_NAME not found"
	exit 4
fi

configs=""
while read line; do
	if [[ $line =~ ^"["(.+)"]"$ ]]; then
		arrname=${BASH_REMATCH[1]}
		declare -A "$arrname"
		configs="$configs $arrname"
	elif [[ $line =~ ^([_[:alpha:]][_[:alnum:]]*)"="(.*) ]]; then
		declare "${arrname}"["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
	fi
done <"$CFG_FILE_NAME"

git checkout -b upstream-sync
SOURCE_ALTERED=false
for CONFIG_NAME in $configs; do
	echo "Processing config section: $CONFIG_NAME"

	declare -n cfg="$CONFIG_NAME"
	REMOTE_URL=${cfg["REMOTE_URL"]}
	REMOTE_DIR=${cfg["REMOTE_DIR"]}
	DOWN_DIR=${cfg["DOWN_DIR"]}
	if [[ -n "${cfg["SQUASH"]}" && "${cfg["SQUASH"],,}" == "true" ]]; then
		OPTS=("-s")
	fi
	if [[ -n "${cfg["SKIP_ANNOTATE"]}" && "${cfg["SKIP_ANNOTATE"],,}" == "true" ]]; then
		OPTS+=("-u")
	fi
	if [[ -n "${cfg["TAGS_FILTER"]}" ]]; then
		TAGS_FILTER=${cfg["TAGS_FILTER"]}
	else
		TAGS_FILTER=".*"
	fi

	UPSTREAM_NAME="upstream-${CONFIG_NAME}"
	set +e
	remote_log=$(git remote show "$UPSTREAM_NAME")
	remote_status=$?
	remote_ok=false
	if [[ $remote_status -eq 0 ]]; then
		remote_url=$(echo "$remote_log" | awk '/Fetch URL/ {print $3}')
		if [[ "$remote_url" != "$REMOTE_URL" ]]; then
			echo "Remote URL mismatch: $remote_url != $REMOTE_URL"
			echo "Please remove or rename your remote, so that the name '$REMOTE_URL' is not used."
			exit 1
		fi
		remote_ok=true
		echo "Detected correct remote with upstream URL: $remote_url"
	fi

	set -e
	if [[ "$remote_ok" = false ]]; then
		echo "Adding remote $UPSTREAM_NAME"
		git remote add "$UPSTREAM_NAME" "$REMOTE_URL"
	fi

	# detect latest tags
	git fetch "$UPSTREAM_NAME" --tags --force
	latest_upstream_tag=$(git tag --sort=-creatordate | grep "$(git ls-remote --tags "$UPSTREAM_NAME" | cut -f3 -d"/")" | grep -E "$TAGS_FILTER" | head -n 1)
	echo "Latest upstream tag matching filter \"$TAGS_FILTER\" in upstream \"$UPSTREAM_NAME\": $latest_upstream_tag"

	git fetch "$UPSTREAM_NAME" 'refs/notes/*:refs/notes/*'
	latest_merged_tag=$(git log | awk -F'[ =]' "/upstream sync: URL='.+' SYNC_REF='(.+)' REMOTE_DIR='${REMOTE_DIR//\//\\/}' DOWN_DIR='${DOWN_DIR//\//\\/}'/ {if(lastLine == \"Notes:\"){gsub(/'/, \"\", \$0); print \$10;exit}};{lastLine = \$0}")
	if [[ -z "$latest_merged_tag" ]]; then
		latest_merged_tag=$(git tag --sort=creatordate | grep "$(git ls-remote --tags "$UPSTREAM_NAME" | cut -f3 -d"/")" | head -n 1)
		echo "Could not detect the last merged tag for local directory '$DOWN_DIR'. Assuming first existing tag: $latest_merged_tag." >&2
	fi
	echo "Latest merged tag: $latest_merged_tag"

	if [[ "$latest_upstream_tag" == "$latest_merged_tag" ]]; then
		echo "Latest detected upstream tag $latest_upstream_tag is the same as the last merged tag $latest_merged_tag, skipping"
		continue
	fi

	if [[ -x "pre-hook.sh" ]]; then
		echo "Running pre-hook.sh"
		./pre-hook.sh "$CONFIG_NAME" "$REMOTE_URL" "$REMOTE_DIR" "$DOWN_DIR" "$latest_upstream_tag" "$latest_merged_tag"
	fi

	# run the script with the latest tag
	last_commit=$(git rev-parse --short HEAD)
	echo "Running git-subtree-update.sh with the $latest_upstream_tag tag"
	set +e
	"$start_dir"/git-subtree-update.sh \
		-n "$CONFIG_NAME" \
		-r "$REMOTE_URL" \
		-t "$latest_upstream_tag" \
		-d "$REMOTE_DIR" \
		-l "$DOWN_DIR" \
		-m "$latest_merged_tag" \
		-g \
		"${OPTS[@]}"
	set -e

	new_last_commit=$(git rev-parse --short HEAD)
	if git diff-index --quiet HEAD -- && [[ "$last_commit" == "$new_last_commit" ]]; then
		echo "No changes detected for config $CONFIG_NAME, continuing."
		continue
	fi

	SOURCE_ALTERED=true

	if [[ -x "post-hook.sh" ]]; then
		echo "Running post-hook.sh"
		./post-hook.sh "$CONFIG_NAME" "$REMOTE_URL" "$REMOTE_DIR" "$DOWN_DIR" "$latest_upstream_tag" "$latest_merged_tag"
	fi

	if git status --short | grep -E "^( M| D|UU|\?\?) "; then
		echo "Conflicts or hook created changes detected, forcing merge commit."
		git add -A
		git commit --no-verify -m "Merge '$DOWN_DIR' from tag '$latest_upstream_tag'"
	fi
	git notes add -f -m "upstream sync: URL='$REMOTE_URL' SYNC_REF='$latest_upstream_tag' REMOTE_DIR='$REMOTE_DIR' DOWN_DIR='$DOWN_DIR'"
done

if [[ $SOURCE_ALTERED = false ]]; then
	echo "No changes detected, exiting."
	exit 0
fi

PR_TITLE="subtree-utils: automated update from $latest_merged_tag to tag $latest_upstream_tag"
search_res=$(gh pr list -R "$REPO_NAME" --search "author:app/github-actions $PR_TITLE" --json title | jq '. == []')
if [[ "$search_res" == "false" ]]; then
	echo "PR already exists, exiting."
	exit 0
fi

echo "Creating PR on GitHub"
set +e
git push origin --delete upstream-sync
set -e
git push --set-upstream origin upstream-sync
git push origin 'refs/notes/*'
if [[ -z "$REPO_NAME" ]]; then
	REPO_NAME=$(gh repo view --json nameWithOwner -q ".nameWithOwner")
	echo "Detected repository name: $REPO_NAME"
else
	echo "Using repository name: $REPO_NAME"
fi
gh pr create --title "$PR_TITLE" \
	--body "This PR updates the chart using git subtree to the latest tag in the upstream repository." \
	--base main \
	--head upstream-sync \
	-R "$REPO_NAME"

cd "$start_dir"
echo "Done"
