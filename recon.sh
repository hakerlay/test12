#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Please specify a domains file."
    echo "Usage: $0 domains_file.txt"
    exit
fi

domains_file="$1"
total_file="all_external_subdomains.txt"

# Execute all external tools in parallel for more complete subdomains results
# and save all the results in a single file.
external_sources() {
    local amass_file="amass_output.txt"
    local subfinder_file="subfinder_output.txt"
    local assetfinder_file="assetfinder_output.txt"
    local sublister_file="sublister_output.txt"
    local domain="$1"
    touch "$amass_file" "$subfinder_file" "$sublister_file" "$assetfinder_file"
    amass enum --passive -d "$domain" -o "$amass_file" >/dev/null &
    subfinder -silent -d "$domain" -o "$subfinder_file" >/dev/null &
    assetfinder -subs-only "$domain" > "$assetfinder_file" &
    sublist3r -d "$domain" -o "$sublister_file" >/dev/null &
    wait
    cat "$amass_file" "$subfinder_file" "$sublister_file" "$assetfinder_file" > "$total_file"
    rm -f "$amass_file" "$subfinder_file" "$sublister_file" "$assetfinder_file"
}

while IFS= read -r domain; do
  if [ -n "$domain" ]; then
     fixed_domain=${domain//$'\r'/}
     external_sources "$fixed_domain"
     findomain -t "$fixed_domain" --import-subdomains "$total_file" -o -m -q --http-status -i --pscan --iport 1 --lport 65535 -s screenshots --mtimeout --threads 50 --unlock
     rm -f "$total_file"
  fi
done < "$domains_file"
