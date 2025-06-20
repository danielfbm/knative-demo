#!/bin/bash


# Source the common library
source "$(dirname "$0")/library.sh"

file=$1
add_registy=${2:-true}

function scan () {
    image=$1
    if [ "$add_registy" = "true" ]; then
        image="build-harbor.alauda.cn/$image"
    else
        full_image=$image
    fi


    # Replace non-filesystem friendly characters with underscores
    image_report=$(echo "$image" | sed 's/[^a-zA-Z0-9._-]/_/g')

    say "Scanning image $full_image..."
    trivy image --scanners vuln --exit-code 0 $full_image | tee $image_report.log
}

say "Reading file $file..."

if [ ! -f "$file" ]; then
    say_error "File not found: $file"
    exit 1
fi

for  i in $(yq '.[]' $file ); do

    scan $i
done