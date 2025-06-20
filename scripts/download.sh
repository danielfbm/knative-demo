#!/bin/bash


# Source the common library
source "$(dirname "$0")/library.sh"

file=$1
add_registy=${2:-true}

function download () {
    image=$1
    if [ "$add_registy" = "true" ]; then
        image="build-harbor.alauda.cn/$image"
    else
        full_image=$image
    fi


    # Replace non-filesystem friendly characters with underscores
    image_report=$(echo "$full_image" | sed 's/[^a-zA-Z0-9_-]/_/g')

    say "Copying image $full_image..."
    skopeo copy docker://$full_image docker-archive:./images/$image_report.tar.gz --override-os=linux --override-arch=amd64
}

say "Reading file $file..."

if [ ! -f "$file" ]; then
    say_error "File not found: $file"
    exit 1
fi

for  i in $(yq '.[]' $file ); do

    download $i
done