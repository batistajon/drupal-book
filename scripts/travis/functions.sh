#!/bin/bash

err() {
  printf " [error] %s\n\n" "$*" >&2
  exit 1
}

is_draft() {
    local GITHUB_TOKEN=$1
    local TRAVIS_PULL_REQUEST=$2

    IS_DRAFT=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/batistajon/drupal-book/pulls/${TRAVIS_PULL_REQUEST}" | jq '.draft')
    # IS_DRAFT=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/colibrigroup/CMS-Drupal-ECOM/pulls/${TRAVIS_PULL_REQUEST}" | jq '.draft')

    if $IS_DRAFT
    then
        err "The PR ${TRAVIS_PULL_REQUEST} is a Draft and still in development."
    fi
}