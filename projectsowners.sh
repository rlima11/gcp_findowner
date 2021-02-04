#!/bin/bash

if [ $# -eq 0 ]; then
    echo "No folder ID provided"
    exit 1
fi

folders=()
#add first folder
folders+=($1)

getProjectsinFolder(){
    cat temp_gcp_random12345678910.json |  jq -r --arg id "$1" '.[] | select(.parent.id==$id)| .name'
}

getProjectOwner(){
    echo -e "\t Project: $1, owners:"
    gcloud projects get-iam-policy $1 --format="json"| jq -r '.bindings[] | select(.role=="roles/owner") | .members[]'
}

checkSubfolders() {
    gcloud alpha resource-manager folders list --folder=$1 --format="value(name)"
}

folderLoop(){
    for folder in $(checkSubfolders $1); do
        echo -e "\t Sub Folder: $folder"
        folders+=($folder)
        folderLoop $folder
    done
}

name=`gcloud alpha resource-manager folders describe $1 --format="value(displayName)"` 
echo "### Lopping folder id $1, name $name..."

folderLoop $1

echo "### Dumping all projects to a temp file"
gcloud projects list --format="json" > temp_gcp_random12345678910.json

echo "### Getting all projects that are under scoped folders"

for id in "${folders[@]}"; do
    for project in $(getProjectsinFolder $id); do
        getProjectOwner $project
    done
done

echo "## done - removing temp file"
rm temp_gcp_random12345678910.json
