#! /bin/bash
#
# Script to manage Becker Admin Script functions.

ENVS='dev stg prod'

# Display error and exit.
# Arguments:
#   Error message
err() {
  printf " [error] %s\n\n" "$*" >&2
  exit 1
}

info() {
  printf " [info] %s\n\n" "$*" >&2
}

# Escape all character form a command
# in order to pass to acli whitout error.
# Arguments:
#   Command to escape
escape_char () {
  printf "%q" "$1"
}

acli_drush () {
  local env=$1; shift
  validate_env "$env"

  case "$env" in
    dev) local ATGE_SSH_HOST='staging-36686.prod.hosting.acquia.com';;
    stg) local ATGE_SSH_HOST='staging-36686.prod.hosting.acquia.com';;
    prod) local ATGE_SSH_HOST='web-36682.prod.hosting.acquia.com';;
    *) err "Environment is not valid.";;
  esac

  local ATGE_SSH_USER="atgeacebecker.$env"
  local ATGE_SSH_DOCROOT="/var/www/html/atgeacebecker.$env/docroot"
  local SSH_DOCROOT="ssh -t $ATGE_SSH_USER@$ATGE_SSH_HOST cd $ATGE_SSH_DOCROOT && "

  local command=$*
  if ! result=$($SSH_DOCROOT "drush $command")
  then
    err "Error while running command: $command $result"
  fi

  printf '%s\n' "$result"
}

# Validate if the given environment is existent
# compared with the global var ENVS.
# Arguments:
#   Environment name
validate_env () {
  local env=$1

  if [[ -z "$env" || $ENVS != *"$env"* ]]; then
    err "Existing environment required, $env provided."
  fi
}

# Dissable old orders
# Arguments:
#   <String> Environment name
disable_old_orders () {
  local env=$1; shift
  validate_env "$env"

  acli_drush "$env" cron:disable bkr_oldorders_cron
  acli_drush "$env" cron:disable ultimate_cron_queue_order_queue_processor
  info "Old Orders disabled successfully!"
}

# Dissable Captcha
# Arguments:
#   <String> Environment name
disable_captcha () {
  local env=$1; shift
  validate_env "$env"

  acli_drush "$env" config:set captcha.captcha_point.user_login_form status 0 --input-format=yml -y
  acli_drush "$env" config:set captcha.captcha_point.user_register_form status 0 --input-format=yml -y
  info "Captcha disabled successfully!"
}

get_test_users () {
  echo "'test_pds_bke_230816@csr.com', 'beckerqa.auto@outlook.com', 'admin@admin.com', 'administrator@administrator.com', 'csr@csr.com', 'content_admin@content_admin.com', 'content_editor@content_editor.com', 'behatadmin@becker.com', 'behatcsr@becker.com'"
}

get_users_email_list () {
  local env=$1
  validate_env "$env"

  acli_drush "$env" sql:query '"SELECT GROUP_CONCAT(mail) FROM users_field_data WHERE mail IN ('$(get_test_users)')"'
}

get_array_users () {
  get_test_users | tr ',' ' ' | xargs
}

create_test_users () {
  local ENV=$1
  validate_env "$ENV"

  local ARRAY_MAILS=$(get_array_users)

  for mail in ${ARRAY_MAILS[@]}
  do
    if [[ $(get_users_email_list $ENV) =~ $mail ]]
    then
        echo "User $mail is already created."
    else
        echo "User $mail not Found. Creating new user..."
        if [[ "$mail" == "beckerqa.auto@outlook.com" ]]; then
            acli_drush "$ENV" ucrt "beckerqa.auto@outlook.com" --password=Auto@123 --mail="beckerqa.auto@outlook.com"
            acli_drush "$ENV" user-add-role "csr" "beckerqa.auto@outlook.com"
        elif [[ "$mail" == "admin@admin.com" ]]; then
            acli_drush "$ENV" ucrt "admin@admin.com" --password=Auto@123 --mail="admin@admin.com"
            acli_drush "$ENV" user-add-role "administrator" "admin@admin.com"
        elif [[ "$mail" == "behatadmin@becker.com" ]]; then
            # Create Behat admin user.
            acli_drush "$ENV" ucrt "behatadmin@becker.com" --password="BehatAdmin@123" --mail="behatadmin@becker.com"
            acli_drush "$ENV" user-add-role "administrator" "behatadmin@becker.com"
        elif [[ "$mail" == "behatcsr@becker.com" ]]; then
            # Create Behat admin user.
            acli_drush "$ENV" ucrt "behatcsr@becker.com" --password="Behatcsr@123" --mail="behatcsr@becker.com"
            acli_drush "$ENV" user-add-role "csr" "behatcsr@becker.com"
        else
            # regex to extract role from email domain
            ROLE=$(echo $mail | awk -F@ '{print $2}' | awk -F.com '{print $1}')
            # Creating users automaycaly based on roles
            acli_drush "$ENV" ucrt "$mail" --password=Becker@123 --mail="$mail"
            acli_drush "$ENV" user-add-role "$ROLE" "$mail"
            echo "User $mail is has been created as an $ROLE."
        fi
    fi
  done
}

delete_products_queue () {
  local env=$1; shift
  validate_env "$env"

  acli_drush "$ENV" queue:delete atge_product_import
  acli_drush "$ENV" queue:delete order_queue_processor
  info "Products Queue deleted successfully!"
}

sync_products_queue () {
  local env=$1; shift
  validate_env "$env"

  acli_drush "$ENV" php:eval '"atge_product_product_import_queue();"'
  info "Products Queue synchronized successfully!"
}

consume_products_queue () {
  local env=$1; shift
  validate_env "$env"

  acli_drush "$ENV" queue:run atge_product_import -v
  info "Products Queue consumed successfully!"
}

clear_search_api () {
  local env=$1; shift
  validate_env "$env"

  acli_drush "$ENV" search-api-clear acquia_search_index
  info "Search API was cleared successfully!"
}

reindex_search_api () {
  local env=$1; shift
  validate_env "$env"

  acli_drush "$ENV" search-api-index acquia_search_index --batch-size=50
  info "Search API re-indexed successfully!"
}

clear_drupal_cache () {
  local env=$1; shift
  validate_env "$env"

  acli_drush "$env" 'cr'
}

# clear_acquia_cache () {

# }

# clear_cloudflare_cache () {

# }