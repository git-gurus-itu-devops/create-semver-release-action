#!/bin/bash

GH_TOKEN="$1"
COMMIT_SHA="$2"

export GH_TOKEN=$GH_TOKEN

echo 'Authenticating...'

LATEST_TAG=$(
	gh release list \
		--repo ${GITHUB_REPOSITORY} \
		--exclude-drafts \
		--exclude-pre-releases \
		--limit 1 \
		--json tagName \
		--jq '.[].tagName'
)
LATEST_TAG=${LATEST_TAG:1}

echo "Latest tag: $LATEST_TAG"

declare -A VERSIONS=(
	[major]=$(echo $LATEST_TAG | cut -d '.' -f 1)
	[minor]=$(echo $LATEST_TAG | cut -d '.' -f 2)
	[patch]=$(echo $LATEST_TAG | cut -d '.' -f 3)
)

labels=$(
	gh pr list \
		--repo ${GITHUB_REPOSITORY} \
		--search "${COMMIT_SHA}" \
		--state merged \
		--json labels \
		--jq '.[].labels.[] | .name'
)

echo "Labels: $labels"

for label in $labels; do
	case $label in major | minor | patch)
		((VERSIONS[$label]++))
		NEXT_VERSION="v${VERSIONS[major]}.${VERSIONS[minor]}.${VERSIONS[patch]}"
		;;
	esac
done

if [[ -z "$NEXT_VERSION" ]]; then
	echo "Pull Request does not contain any SemVer compliant labels; cannot determine next tag. Aborting"
	exit 1
elif [[ -n "$NEXT_VERSION" ]]; then
	echo "Next version: $NEXT_VERSION"
fi

gh release create "$NEXT_VERSION" \
	--repo ${GITHUB_REPOSITORY} \
	--generate-notes

echo "release_tag=$NEXT_VERSION" >>$GITHUB_OUTPUT
