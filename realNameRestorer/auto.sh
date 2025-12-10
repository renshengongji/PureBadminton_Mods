#!/bin/bash

sourceFile="./characters.json"
cacheFile="./.gameLoc"
remoteFile="https://raw.githubusercontent.com/renshengongji/PureBadminton_Mods/refs/heads/main/realNameRestorer/characters.json"

if [ ! -f "$sourceFile" ]; then
    echo "Attempting to download 'characters.json' from GitHub..."
    
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$sourceFile" "$remoteFile"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$sourceFile" "$remoteFile"
    else
        echo "Error: Neither curl nor wget found. Cannot download file"
        exit 1
    fi

    if [ $? -eq 0 ] && [ -f "$sourceFile" ]; then
        echo "Download successful"
    else
        echo "Error: Download failed."
        exit 1
    fi
fi

selectedGame=""

if [ -f "$cacheFile" ]; then
    if [ ! -d "$cachedPath/Pure Badminton_Data" ]; then
        rm "$cacheFile"
        echo "Cached game path is invalid. Please re-run the script."
        exit 1
    fi
    cachedPath=$(cat "$cacheFile")
    if [ -d "$cachedPath" ] && [ -d "$cachedPath/Pure Badminton_Data" ]; then
        echo "Found cached game path: $cachedPath"
        read -p "Do you want to install to this location? (Y/n) " response
        if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
            selectedGame="$cachedPath"
        fi
    fi
fi

if [ -z "$selectedGame" ]; then
    echo "Enter a folder path (e.g., /Users/name/Games) to search"
    echo "or type empty to search common system locations"
    read -p "Start Path: " userPath

    searchPaths=()

    if [ -z "$userPath" ]; then
        echo "Starting Global Search..."
        if [ -d "/Applications" ]; then searchPaths+=("/Applications"); fi
        if [ -d "/Users" ]; then searchPaths+=("/Users"); fi
        if [ -d "/Volumes" ]; then searchPaths+=("/Volumes"); fi
        if [ -d "/home" ]; then searchPaths+=("/home"); fi
        if [ -d "/mnt" ]; then searchPaths+=("/mnt"); fi
        if [ -d "/media" ]; then searchPaths+=("/media"); fi
        if [ -d "$HOME/.local/share/Steam" ]; then searchPaths+=("$HOME/.local/share/Steam"); fi
        if [ -d "$HOME/.steam" ]; then searchPaths+=("$HOME/.steam"); fi
        if [ -d "$HOME/Library/Application Support/Steam" ]; then searchPaths+=("$HOME/Library/Application Support/Steam"); fi
    else
        userPath=${userPath%/}
        if [ -d "$userPath" ]; then
            searchPaths+=("$userPath")
            echo "Searching: $userPath ..."
        else
            echo "Error: The path does not exist."
            exit 1
        fi
    fi

    spinner() {
        local pid=$1
        local delay=0.1
        local spinstr='|/-\'
        while kill -0 "$pid" 2>/dev/null; do
            local temp=${spinstr#?}
            printf " [%c] Searching...  " "$spinstr"
            local spinstr=$temp${spinstr%"$temp"}
            sleep $delay
            printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
        done
        printf "    Done!            \n"
    }

    results=$(mktemp)
    (
        find "${searchPaths[@]}" -type d -name "Pure Badminton*" 2>/dev/null | while read -r dir; do
            if [ -d "$dir/Pure Badminton_Data" ]; then
                echo "$dir" >> "$results"
            fi
        done
    ) &

    pid=$!
    spinner $pid

    candidates=()
    while IFS= read -r line; do
        candidates+=("$line")
    done < "$results"
    rm "$results"

    count=${#candidates[@]}

    if [ "$count" -eq 0 ]; then
        echo "Error: No valid game folder found"
        exit 1
    elif [ "$count" -eq 1 ]; then
        selectedGame="${candidates[0]}"
        echo "Found game: $selectedGame"
    else
        echo "Found games:"
        i=1
        for dir in "${candidates[@]}"; do
            echo "[$i] $dir"
            ((i++))
        done
        
        while true; do
            read -p "Enter index (1-$count): " selection
            if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$count" ]; then
                idx=$((selection-1))
                selectedGame="${candidates[$idx]}"
                break
            else
                echo "Invalid index."
            fi
        done
    fi

    echo "$selectedGame" > "$cacheFile"
fi

dir="$selectedGame/Pure Badminton_Data/mods"

mkdir -p "$dir"
cp -f "$sourceFile" "$dir/"

echo ""
echo "========================================"
echo "Installation Successful!"
echo "File copied to: $dir"
echo "========================================"
