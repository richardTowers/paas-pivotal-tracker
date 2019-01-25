#!/usr/bin/env bash

set -eu # 🇪🇺

if [ -z "${PIVOTAL_TRACKER_TOKEN:-}" ]; then
  >&2 echo "PIVOTAL_TRACKER_TOKEN must be set"
  exit 1
fi

max_pagination_limit=500
filter='2018q3'

headers="$(curl --silent --include --header "X-TrackerToken: $PIVOTAL_TRACKER_TOKEN" "https://www.pivotaltracker.com/services/v5/projects/1275640/stories?filter=$filter&limit=0")"
pagination_count="$(sed -n 's/x-tracker-pagination-total: \([0-9]*\)/\1/p' <<< "$headers" | tr -d '')"

if (( "$pagination_count" > "$max_pagination_limit" )); then
  >&2 echo "Query ($filter) returned more results ($pagination_count) than the maximum page size ($max_pagination_limit). Giving up."
  exit 1
fi

stories="$(curl --silent --header "X-TrackerToken: $PIVOTAL_TRACKER_TOKEN" "https://www.pivotaltracker.com/services/v5/projects/1275640/stories?filter=$filter&limit=$max_pagination_limit")"

echo '"State","Epic lablel","Story Name","URL"'
jq -r "map([.current_state, (.labels[].name | select(. | test(\"$filter\"))), .name, .url])[] | @csv" <<< "$stories" | sort

