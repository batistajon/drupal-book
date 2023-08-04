#!/bin/bash

source $(dirname "$0")/test_fn.sh

# if is_draft "ola"
# then
#     echo false
# else
#     echo true
# fi


JIRA_TICKET_NUMBER=$(get_jira_ticket_number "feature/BIT-5529-functions")
echo $JIRA_TICKET_NUMBER