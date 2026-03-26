#!/usr/bin/env bash

# Check if widget is enabled
SHOW_WIDGET=$(tmux show-option -gv @gruvbox-tmux_show_wbg 2>/dev/null)
if [ "$SHOW_WIDGET" == "0" ]; then
    exit 0
fi

cd "$1" || exit 1

# Gruvbox color definitions
RED="#ea6962"
GREEN="#a9b665"
YELLOW="#d8a657"
BLACK="#1d2021"
BG="#282828"
FG="#d4be98"

RESET="#[fg=${FG},bg=default,nobold,noitalics,nounderscore,nodim]"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
PROVIDER=$(git config remote.origin.url 2>/dev/null | awk -F '@|:' '{print $2}')
PROVIDER_ICON=""

PR_COUNT=0
REVIEW_COUNT=0
ISSUE_COUNT=0
BUG_COUNT=0

PR_STATUS=""
REVIEW_STATUS=""
ISSUE_STATUS=""
BUG_STATUS=""

if [[ -z $BRANCH ]]; then
    exit 0
fi

if [[ $PROVIDER == "github.com" ]]; then
    if ! command -v gh &>/dev/null; then
        exit 1
    fi

    PROVIDER_ICON="$RESET#[fg=${FG}] "
    PR_COUNT=$(gh pr list --json number --jq 'length' 2>/dev/null | bc)
    REVIEW_COUNT=$(gh pr status --json reviewRequests --jq '.needsReview | length' 2>/dev/null | bc)
    RES=$(gh issue list --json "assignees,labels" --assignee @me 2>/dev/null)
    ISSUE_COUNT=$(echo "$RES" | jq 'length' | bc)
    BUG_COUNT=$(echo "$RES" | jq 'map(select(.labels[].name == "bug")) | length' | bc)
    ISSUE_COUNT=$((ISSUE_COUNT - BUG_COUNT))

elif [[ $PROVIDER == "gitlab.com" ]]; then
    if ! command -v glab &>/dev/null; then
        exit 1
    fi

    PROVIDER_ICON="$RESET#[fg=#fc6d26] "
    PR_COUNT=$(glab mr list 2>/dev/null | grep -cE "^\!")
    REVIEW_COUNT=$(glab mr list --reviewer=@me 2>/dev/null | grep -cE "^\!")
    ISSUE_COUNT=$(glab issue list 2>/dev/null | grep -cE "^\#")
else
    exit 0
fi

# Build status strings
if [[ $PR_COUNT -gt 0 ]]; then
    PR_STATUS="#[fg=${GREEN},bg=default,bold] ${RESET}${PR_COUNT} "
fi

if [[ $REVIEW_COUNT -gt 0 ]]; then
    REVIEW_STATUS="#[fg=${YELLOW},bg=default,bold] ${RESET}${REVIEW_COUNT} "
fi

if [[ $ISSUE_COUNT -gt 0 ]]; then
    ISSUE_STATUS="#[fg=${GREEN},bg=default,bold] ${RESET}${ISSUE_COUNT} "
fi

if [[ $BUG_COUNT -gt 0 ]]; then
    BUG_STATUS="#[fg=${RED},bg=default,bold] ${RESET}${BUG_COUNT} "
fi

WB_STATUS="#[fg=${BLACK},bg=default,bold] $RESET$PROVIDER_ICON $RESET$PR_STATUS$REVIEW_STATUS$ISSUE_STATUS$BUG_STATUS"

echo "$WB_STATUS"

# Wait extra time if status-interval is less than 20 seconds to
# avoid overloading GitHub API
INTERVAL=$(tmux display -p '#{status-interval}')
if [[ $INTERVAL -lt 20 ]]; then
    sleep 20
fi
