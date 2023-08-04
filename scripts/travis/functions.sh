#!/bin/bash

info() {
  printf " [info] %s\n\n" "$*" >&2
  return 1
}

is_pull_request() {
    if [[ ! $TRAVIS_EVENT_TYPE = "pull_request" ]]
    then
        return 1
    fi

    return 0
}

is_draft() {
    local IS_DRAFT=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/batistajon/drupal-book/pulls/${TRAVIS_PULL_REQUEST}" | jq '.draft')
    # IS_DRAFT=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/colibrigroup/CMS-Drupal-ECOM/pulls/${TRAVIS_PULL_REQUEST}" | jq '.draft')

    if ! $IS_DRAFT
    then
        return 1
    fi

    return 0
}

get_jira_ticket_number() {
    local JIRA_TICKET=$(echo "$TRAVIS_PULL_REQUEST_BRANCH" | grep -o '[A-Z]\+-[0-9]\+' )
    echo "${JIRA_TICKET}"
}

get_ticket_current_status() {
    local JIRA_TICKET=$1
    local CURRENT_STATUS=$(curl -u $JIRA_USER_NAME:$JIRA_API_TOKEN -X GET -H "Content-Type: application/json" "https://beckeredu.atlassian.net/rest/api/3/issue/${JIRA_TICKET}" | jq '.fields.status.id' | grep -o '[0-9]\+')
    echo "${CURRENT_STATUS}"
}

validate_status() {
    local TICKET_STATUS=$1

    if [[ ! $TICKET_STATUS = "10050" ]]
    then
        return 1
    fi

    return 0
}

tag_pr_process_issue() {
    local JIRA_TICKET=$1

    curl --request PUT \
    --url "https://beckeredu.atlassian.net/rest/api/3/issue/${JIRA_TICKET}" \
    --user $JIRA_USER_NAME:$JIRA_API_TOKEN \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data '{
        "update": {
            "labels": [
                {
                    "add": "pr-process-issue"
                }
            ]
        }
    }' |
    jq '.'
}

leave_comment() {
    local JIRA_TICKET=$1

    curl --request POST \
    --url "https://beckeredu.atlassian.net/rest/api/3/issue/${JIRA_TICKET}/comment" \
    --user $JIRA_USER_NAME:$JIRA_API_TOKEN \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data '{
        "body": {
            "content": [
                {
                    "content": [
                        {
                            "text": "Jira Automation Message: Pull Request opened with wrong status. Please change the Ticket to Code Review to log work hours.",
                            "type": "text"
                        }
                    ],
                    "type": "paragraph"
                }
            ],
            "type": "doc",
            "version": 1
        }
    }' |
    jq '.'
}

warn_assignee_pull_request() {
    local JIRA_TICKET=$1

    tag_pr_process_issue $JIRA_TICKET
    leave_comment $JIRA_TICKET
    info "Wrong Status! Jira Status need to be Code Review -- 10050. Current status: ${TICKET_STATUS}"
}


# Main function that validates the PR.
validate_pull_request() {
    if
    then
        info "The trigger is not a Pull Request. It's a ${TRAVIS_EVENT_TYPE} one";
    fi

    if ! is_draft
    then
        info "The PR ${TRAVIS_PULL_REQUEST} is a Draft and still in development."
    fi

    local JIRA_TICKET_NUMBER=$(get_jira_ticket_number $TRAVIS_PULL_REQUEST_BRANCH)
    local TICKET_STATUS=$(get_ticket_current_status $JIRA_TICKET_NUMBER)

    if ! validate_status $TICKET_STATUS
    then
        warn_assignee_pull_request $JIRA_TICKET_NUMBER
    fi

    # info "Status Correct! Jira Status need to be Code Review -- 10050. Current status: ${TICKET_STATUS}"
}