#!/bin/bash

is_draft() {
    local IS_DRAFT=$1

    if [[ ! $IS_DRAFT = "ola" ]]
    then
        return 1
    fi

    return 0
}

get_jira_ticket_number() {
    local TRAVIS_PULL_REQUEST_BRANCH=$1
    local JIRA_TICKET=$(echo "$TRAVIS_PULL_REQUEST_BRANCH" | grep -o '[A-Z]\+-[0-9]\+' )
    echo "${JIRA_TICKET}"
}