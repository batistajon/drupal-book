#! /bin/bash

# Script that need to run daily on Becker (usually on DEV).

source $(pwd)/scripts/post-deploy/functions.sh

ENV=$1
DISABLE_CAPTCHA=$2
CREATE_USERS=$3
PRODUCT_SYNC=$4
REINDEX_SEARCH=$5

if [[ $DISABLE_CAPTCHA ]]
then
    echo 'Disabling Captcha in Dev environment...'
    disable_captcha $ENV
fi

if [[ $CREATE_USERS ]]
then
    echo 'Creating test users...'
    create_test_users $ENV
fi

if [[ $PRODUCT_SYNC ]]
then
    echo 'Deleting products queue...'
    delete_products_queue $ENV

    echo 'Syncing products queue...'
    sync_products_queue $ENV

    echo 'Consume products on queue...'
    consume_products_queue $ENV
fi

if [[ $REINDEX_SEARCH ]]
then
    echo 'Reindex Solr...'
    reindex_search_api $ENV
fi
