#!/bin/bash

info() {
  printf " [info] %s\n\n" "$*" >&2
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
    local EXPRESSION=$1
    echo "$EXPRESSION"
    local JIRA_TICKET=$(echo "$EXPRESSION" | grep -o '[A-Z]\+-[0-9]\+' )
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

tag_merge_process_issue() {
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
                    "add": "merge-process-issue"
                }
            ]
        }
    }' |
    jq '.'
}

leave_pr_comment() {
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

leave_merge_comment() {
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
                            "text": "Jira Automation Message: Ticket *Merged* with wrong status. Please change the Ticket status to *Code Review* to log work hours and then change it to *Code Merged* status",
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

    info "Wrong Status! Jira Status need to be Code Review -- 10050. Current status: ${TICKET_STATUS}"

    tag_pr_process_issue $JIRA_TICKET
    leave_pr_comment $JIRA_TICKET
}

warn_assignee_merge_pull_request() {
    local JIRA_TICKET=$1

    info "Wrong Status! Jira Status need to be Code Review -- 10050. Current status: ${TICKET_STATUS}"

    tag_merge_process_issue $JIRA_TICKET
    leave_merge_comment $JIRA_TICKET
}

move_merged_ticket() {
    local JIRA_TICKET=$1

    curl --request POST \
    --url "https://beckeredu.atlassian.net/rest/api/3/issue/${JIRA_TICKET}/transitions" \
    --user $JIRA_USER_NAME:$JIRA_API_TOKEN \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data '{
        "transition": {
            "id": "181"
        }
    }' |
    jq '.'

    successful_merge_comment $JIRA_TICKET
}

successful_merge_comment() {
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
                            "text": "Jira Automation Message: Status Correct! Ticket changed to Code Merge status by automation.",
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

# Main function that validates the PR.
validate_pull_request() {
    if ! is_pull_request
    then
        info "The trigger is not a Pull Request. It's a ${TRAVIS_EVENT_TYPE} one";
        return
    fi

    if is_draft
    then
        info "The PR ${TRAVIS_PULL_REQUEST} is a Draft and still in development."
        return
    fi

    local JIRA_TICKET_NUMBER=$(get_jira_ticket_number $TRAVIS_PULL_REQUEST_BRANCH)
    local TICKET_STATUS=$(get_ticket_current_status $JIRA_TICKET_NUMBER)

    if ! validate_status $TICKET_STATUS
    then
        warn_assignee_pull_request $JIRA_TICKET_NUMBER
        return
    fi

    info "Status Correct! Jira Status need to be Code Review -- 10050. Current status: ${TICKET_STATUS}"
    return
}

validate_merged_pull_request () {
    echo "Commit message: ${TRAVIS_COMMIT_MESSAGE}"

    local JIRA_TICKET_NUMBER=$(get_jira_ticket_number $TRAVIS_COMMIT_MESSAGE)
    echo "jira: ${JIRA_TICKET_NUMBER}"

    local TICKET_STATUS=$(get_ticket_current_status $JIRA_TICKET_NUMBER)

    if ! validate_status $TICKET_STATUS
    then
        warn_assignee_merge_pull_request $JIRA_TICKET_NUMBER
        return
    fi

    info "Status Correct! Jira Status need to be Code Review -- 10050. Current status: ${TICKET_STATUS}"
    move_merged_ticket $JIRA_TICKET_NUMBER
    return
}