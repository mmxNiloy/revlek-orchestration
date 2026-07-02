#!/usr/bin/env bash

success=false
set -Eeuo pipefail
sudo -v

file_to_copy=()
created_links=()
created_files=()
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly local_dir="${script_dir}/sites-available"
readonly -a sites=("www.revlek.com" "api.revlek.com" "admin.revlek.com")

echo "Deploying sites..."

verify_nginx_installation() {
    if ! command -v nginx &> /dev/null; then
        echo "Nginx could not be found"
        exit 1
    fi
}

mark_files_to_copy() {
    if [[ ! -d "$local_dir" ]]; then
        echo "Local directory ${local_dir} does not exist"
        exit 1
    fi

    for file_name in "${sites[@]}"; do
        if [ ! -f "${local_dir}/${file_name}" ]; then
            echo "${file_name} site is not available"
            continue
        fi
        file_to_copy+=("${file_name}")
    done

    if ((${#file_to_copy[@]} == 0)); then
        echo "No configuration files found."
        exit 1
    fi
}

copy_files() {
    for file in "${file_to_copy[@]}"; do
        source="${local_dir}/${file}"
        dest="/etc/nginx/sites-available/${file}"

        if [[ ! -e "$dest" ]]; then
            created_files+=("${file}")
        fi

        if sudo cp -f "${source}" "${dest}" &> /dev/null; then
            echo "${file} site copied to ${dest}"
        else
            echo "Failed to copy ${file} site to ${dest}"
            exit 1
        fi
    done
}

make_symlinks() {
    for file in "${file_to_copy[@]}"; do
        source="/etc/nginx/sites-available/${file}"
        dest="/etc/nginx/sites-enabled/${file}"
        
        if [[ ! -e "$dest" ]]; then
            created_links+=("${file}")
        fi

        if sudo ln -sfn "${source}" "${dest}" &> /dev/null; then
            echo "${file} site linked to ${dest}"
        else
            echo "Failed to link ${file} site to ${dest}"
            exit 1
        fi
    done
}

remove_symlinks() {
    for file in "${created_links[@]}"; do
        if sudo rm -f "/etc/nginx/sites-enabled/${file}" &> /dev/null; then
            echo "${file} site unlinked from /etc/nginx/sites-enabled/${file}"
        else
            echo "Failed to unlink ${file} site from /etc/nginx/sites-enabled/${file}"
        fi
    done
}

remove_files() {
    for file in "${created_files[@]}"; do
        if sudo rm -f "/etc/nginx/sites-available/${file}" &> /dev/null; then
            echo "${file} site removed from /etc/nginx/sites-available/${file}"
        else
            echo "Failed to remove ${file} site from /etc/nginx/sites-available/${file}"
        fi
    done
}

cleanup() {
    if $success; then
        return
    fi

    remove_symlinks
    remove_files
}

verify_nginx_configuration() {
    sudo nginx -t
}

reload_nginx() {
    sudo systemctl reload nginx
}

trap cleanup EXIT

verify_nginx_installation
mark_files_to_copy
copy_files
make_symlinks
verify_nginx_configuration
reload_nginx
success=true
trap - EXIT
echo "Sites deployed successfully."