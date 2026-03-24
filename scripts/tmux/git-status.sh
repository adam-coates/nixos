#!/usr/bin/env bash

# Check if git status display is enabled
SHOW_GIT=$(tmux show-option -gv @gruvbox-tmux_show_git 2>/dev/null)
if [ "$SHOW_GIT" == "0" ]; then
    exit 0
fi

cd "$1" || exit 1

# Gruvbox color definitions
RED="#ea6962"
GREEN="#a9b665"
YELLOW="#d8a657"
BLUE="#7daea3"
MAGENTA="#d3869b"
BLACK="#1d2021"
BG="#282828"
FG="#d4be98"

RESET="#[fg=default,bg=default,nobold,noitalics,nounderscore,nodim]"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

SYNC_MODE=0
NEED_PUSH=0

# Truncate long branch names
if [[ ${#BRANCH} -gt 25 ]]; then
    BRANCH="${BRANCH:0:25}…"
fi

STATUS_CHANGED=""
STATUS_INSERTIONS=""
STATUS_DELETIONS=""
STATUS_UNTRACKED=""

CHANGED_COUNT=0
INSERTIONS_COUNT=0
DELETIONS_COUNT=0

# Check for any changes (staged or unstaged)
HAS_CHANGES=0
if ! git diff-index --quiet HEAD 2>/dev/null; then
    HAS_CHANGES=1
fi

# Get diff statistics comparing to HEAD (includes both staged and unstaged)
if [[ $HAS_CHANGES -eq 1 ]]; then
    #DIFF_COUNTS=($(git diff HEAD --numstat 2>/dev/null | awk '{changed+=1; ins+=($1+0); del+=($2+0)} END {printf("%d %d %d", changed+0, ins+0, del+0)}'))
    #CHANGED_COUNT=$(echo "${DIFF_COUNTS[0]:-0}" | bc)
    #INSERTIONS_COUNT=$(echo "${DIFF_COUNTS[1]:-0}" | bc)
    #DELETIONS_COUNT=$(echo "${DIFF_COUNTS[2]:-0}" | bc)
    read CHANGED_COUNT INSERTIONS_COUNT DELETIONS_COUNT <<<"$(
        git diff HEAD --numstat 2>/dev/null |
            awk '{changed+=1; ins+=($1+0); del+=($2+0)} END {print changed+0, ins+0, del+0}'
    )"

    SYNC_MODE=1
fi

# Count untracked files
UNTRACKED_COUNT=$(git ls-files --other --directory --exclude-standard 2>/dev/null | wc -l | bc)

# Build status strings
if [[ $CHANGED_COUNT -gt 0 ]]; then
    STATUS_CHANGED="${RESET}#[fg=${YELLOW},bg=default,bold] ${CHANGED_COUNT} "
fi

if [[ $INSERTIONS_COUNT -gt 0 ]]; then
    STATUS_INSERTIONS="${RESET}#[fg=${GREEN},bg=default,bold] ${INSERTIONS_COUNT} "
fi

if [[ $DELETIONS_COUNT -gt 0 ]]; then
    STATUS_DELETIONS="${RESET}#[fg=${RED},bg=default,bold] ${DELETIONS_COUNT} "
fi

if [[ $UNTRACKED_COUNT -gt 0 ]]; then
    STATUS_UNTRACKED="${RESET}#[fg=${BLACK},bg=default,bold] ${UNTRACKED_COUNT} "
fi

# Determine repository sync status
if [[ $SYNC_MODE -eq 0 ]]; then
    NEED_PUSH=$(git log @{push}.. 2>/dev/null | wc -l | bc)
    if [[ $NEED_PUSH -gt 0 ]]; then
        SYNC_MODE=2
    else
        if [[ -f .git/FETCH_HEAD ]]; then
            LAST_FETCH=$(stat -c %Y .git/FETCH_HEAD 2>/dev/null || stat -f %m .git/FETCH_HEAD 2>/dev/null || echo 0)
            NOW=$(date +%s | bc)
            # if 5 minutes have passed since the last fetch
            if [[ $((NOW - LAST_FETCH)) -gt 300 ]]; then
                git fetch --atomic origin --negotiation-tip=HEAD 2>/dev/null &
            fi
        fi

        # Check if the remote branch is ahead of the local branch
        REMOTE_DIFF="$(git diff --numstat "${BRANCH}" "origin/${BRANCH}" 2>/dev/null)"
        if [[ -n $REMOTE_DIFF ]]; then
            SYNC_MODE=3
        fi
    fi
fi

# Set the status indicator based on the sync mode
case "$SYNC_MODE" in
1)
    REMOTE_STATUS="$RESET#[bg=default,fg=${RED},bold] 󱓎"
    ;;
2)
    REMOTE_STATUS="$RESET#[bg=default,fg=${RED},bold] 󰛃"
    ;;
3)
    REMOTE_STATUS="$RESET#[bg=default,fg=${MAGENTA},bold] 󰛀"
    ;;
*)
    REMOTE_STATUS="$RESET#[bg=default,fg=${GREEN},bold] "
    ;;
esac

if [[ -n $BRANCH ]]; then
    echo "$REMOTE_STATUS $RESET$BRANCH $STATUS_CHANGED$STATUS_INSERTIONS$STATUS_DELETIONS$STATUS_UNTRACKED"
fi
