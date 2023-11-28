#!/bin/bash
window_file="$HOME/.cache/hyprpoon_windows_cache.txt"
touch "$window_file"

declare -A window_dict

save_to_cache() {
    > "$window_file"
    for pid in "${!window_dict[@]}"; do
        echo "$pid:${window_dict[$pid]}" >> "$window_file"
    done
}

load_from_cache() {
    declare -gA window_dict
    while IFS=':' read -r pid title; do
        window_dict["$pid"]="$title"
    done < "$window_file"
}

function add_window() {
    load_from_cache
    local window_pid window_title
    window_pid=$(hyprctl activewindow -j | jq '.pid')
    window_title=$(hyprctl activewindow -j | jq '.title')


    if [[ -v window_dict["$window_pid"] ]]; then
        echo "Window already added"
    else
        window_dict["$window_pid"]="$window_title"
        save_to_cache
    fi
}

function add_window_hide() {
    load_from_cache
    local window_pid window_title
    window_pid=$(hyprctl activewindow -j | jq '.pid')
    window_title=$(hyprctl activewindow -j | jq '.title')


    if [[ -v window_dict["$window_pid"] ]]; then
        echo "Window already added"
        echo "Hiding window"
        hyprctl dispatch movetoworkspacesilent 90,pid:"$window_pid"
    else
        window_dict["$window_pid"]="$window_title"
        save_to_cache
        hyprctl dispatch movetoworkspacesilent 90,pid:"$window_pid"
    fi
}

function return_window() {
    load_from_cache
    local selection current_workspace
    selection=$(printf '%s\n' "${window_dict[@]}" | rofi -dmenu)
    echo "$selection"

    current_workspace=$(hyprctl activeworkspace -j | jq '.id')

    if [[ -z "$selection" ]]; then
        return
    fi

    for pid in "${!window_dict[@]}"; do
	    title="${window_dict["$pid"]}"
	    if [[ "$title" == "$selection" ]]; then
		    echo $title
		    echo $pid
		    echo $current_workspace
		    break
	    fi
    done

    hyprctl dispatch movetoworkspacesilent "$current_workspace,pid:$pid"
}

function main() {
    if [ "$1" ]; then
        if [ "$1" == "a" ]; then
            add_window
        fi
        if [ "$1" == "h" ]; then
            add_window_hide
        fi
    else
        return_window
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
