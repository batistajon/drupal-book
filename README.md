# Drupal Book Sample

It's a brand new D10 instalation which reproduces in a simple way the Quotes feature we discussed before.

I'm using Lando as Dev tool, so to launch this env, make sure you have [Lando](https://docs.lando.dev/) and [Docker](https://docs.docker.com/engine/install/) installed.

To do it I created a View which search Quotes (Paragraphs) fields in Articles content type, and then I created a module - Manage Quotes - that treat the pre-render view's result.

I've deployed the result on http://54.89.212.175/. You can see the Search Quotes feature by accessing http://54.89.212.175/search-quotes.

If you want to launch it locally, please follow the instructions bellow.

## Local instructions:
- Clone the Repo
```shell
git clone git@github.com:batistajon/drupal-book.git
```
- Start Lando environment
```shell
cd drupal-book && lando start
```
- Import the DB with simple content
```shell
lando db-import drupal10.2023-07-03-1688385901.sql.gz
```
- Just in case run a config import 
```shell
lando drush cim -y
```
- Finally clear the caches
```shell
lando drush cr
```

- Access the local by [Local](https://drupal-book.lndo.site/search-quotes)