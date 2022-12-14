#!/bin/bash

REPO_REMOTE=origin

while getopts fpr: ch; do
	case $ch in
	p)	REPO_PUSH=1;;
	r)	REPO_REMOTE=$OPTARG;;
	f)	REPO_PUSH_FORCE=1;;
	*)	exit 2;;
	esac
done
shift $(( OPTIND - 1 ))

tmpdir=$(mktemp -d chartXXXXXX)
trap 'rm -rf $tmpdir' EXIT

for chart in charts/*; do
	[[ -d $chart ]] || continue
	helm package -d "$tmpdir" "$chart"
done

published=0
for chart in "$tmpdir"/*; do
	basename="${chart##*/}"
	if ! [[ -f repo/$basename ]]; then
		echo "publishing $basename"
		cp "$chart" "repo/$basename"
		(( published++ ))
	else
		echo "ignoring $basename (already exists)"
	fi
done

if [[ $published -gt 0 ]]; then
	helm repo index repo

	git -C repo add .
	git -C repo commit -m "Published new charts"
fi

if [[ $REPO_PUSH -eq 1 && ( $REPO_PUSH_FORCE -eq 1 || $published -gt 0 ) ]]; then
	git -C repo push -f "$REPO_REMOTE" HEAD
fi
