#!/bin/bash

redmica_version=$1
database=$2
redmine_dir=$3

mkdir -p $redmine_dir
cd $redmine_dir
pwd
echo https://github.com/redmica/redmica/archive/$redmica_version.tar.gz
wget -O redmine.tar.gz "https://github.com/redmica/redmica/archive/${redmica_version}.tar.gz"
tar -xf redmine.tar.gz --strip-components=1

cp -r $GITHUB_WORKSPACE ./plugins
cp ./plugins/redmica_ui_extension/.github/templates/database-$database.yml config/database.yml

ls

apt-get update;
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    bzr \
    git \
    mercurial \
    openssh-client \
    subversion \
    build-essential \
    mariadb-client \
    ghostscript \
    gsfonts \
    imagemagick \
    shared-mime-info \
    default-libmysqlclient-dev \
    freetds-dev \
    gcc \
    libpq-dev \
    libsqlite3-dev \
    make \
    patch;

# Setup playwright for E2E test
apt-get update && apt-get install -y ca-certificates curl gnupg
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update && apt-get install nodejs -y
npm install playwright
npx playwright install chromium
npx playwright install-deps

# PDFのサムネイル作成テストを成功させるため
sed -i 's/^.*policy.*coder.*none.*PDF.*//' /etc/ImageMagick-6/policy.xml

# DB側のログを表示しないため(additional_environment.rbでログを標準出力に出している)
rm -f ./config/additional_environment.rb

# Gemfileの修正
# 参考リンク: https://github.com/agileware-jp/redmine-plugin-orb/pull/70
# https://www.redmine.org/issues/40802
if grep -q "require 'blankslate'" lib/redmine/views/builders/structure.rb
then
  echo 'gem "blankslate"' >> Gemfile
fi

bundle install --with test development
bundle update
bundle exec rake db:create db:migrate RAILS_ENV=test

# 利用しているRedmineのバージョンなどを確認
RAILS_ENV=test ruby bin/about