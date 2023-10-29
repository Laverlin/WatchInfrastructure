#!/bin/bash

VERSION=""

function Deploy 
{
    echo "Deploy $VERSION"
    if [ ! -d yas-bot-app ]; then
        mkdir yas-bot-app;
    fi
    sudo rm -rf /shared-data/persist/wwwroot-yas/yas-bot
    curl -L -o yas-bot-app/yasbot.zip https://github.com/Laverlin/yas-bot-webapp/releases/download/$VERSION/build-$VERSION.zip
    sudo unzip yas-bot-app/yasbot.zip -d /shared-data/persist/wwwroot-yas/yas-bot
}

function Usage
{
    echo "Use -v <version> to set the version to deploy"
}

while getopts ":v:" option; do
   case $option in
      v) 
         VERSION=$OPTARG
         Deploy
         exit;;
     \?) 
         Usage
         exit;;
   esac
done

if [ $OPTIND -eq 1 ]; then Usage; fi
