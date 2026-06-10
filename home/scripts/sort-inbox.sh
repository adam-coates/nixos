#!/bin/bash

menu() {
    local prompt="$1" outvar="$2" selected_outvar="$3"
    shift 3
    local options=("$@")
    local count=${#options[@]}
    local cur=0
    local esc=$(echo -en "\e")
    local selected=()
    for ((i=0; i<count; i++)); do
        selected[i]=0
    done

    printf "$prompt\n"
    while true; do
        for ((i=0; i<count; i++)); do
            if [ "$i" -eq "$cur" ]; then
                if [ "${selected[i]}" -eq 1 ]; then
                    echo -e " > \e[32m${options[i]}\e[0m (keep)"
                elif [ "${selected[i]}" -eq 2 ]; then
                    echo -e " > \e[31m${options[i]}\e[0m (delete)"
                else
                    echo -e " > \e[7m${options[i]}\e[0m"
                fi
            else
                if [ "${selected[i]}" -eq 1 ]; then
                    echo -e "   \e[32m${options[i]}\e[0m (keep)"
                elif [ "${selected[i]}" -eq 2 ]; then
                    echo -e "   \e[31m${options[i]}\e[0m (delete)"
                else
                    echo "   ${options[i]}"
                fi
            fi
        done

        IFS= read -rsn1 key

        if [[ $key == $esc ]]; then
            read -rsn2 -t 0.1 key
            if [[ $key == '[A' ]]; then
                ((cur--)); ((cur < 0)) && cur=$((count - 1))
            elif [[ $key == '[B' ]]; then
                ((cur++)); ((cur >= count)) && cur=0
            fi
        elif [[ $key == "k" ]]; then
            selected[cur]=1
        elif [[ $key == "d" ]]; then
            selected[cur]=2
        elif [[ $key == "p" ]]; then
            local selected_note="${options[$cur]}"
            local note_path="$notes_dir/$selected_note"

            tput sc

            echo -e "\nPreviewing note: $selected_note\n"
            bat --paging=never --line-range :100 --color=always "$note_path"

            echo -e "\nPress any key to continue..."
            read -rsn1

            tput rc
            tput ed

        elif [[ $key == "" ]]; then
            break
        fi
        echo -en "\e[${count}A"
    done

    printf -v "$outvar" "${options[$cur]}"
    eval "$selected_outvar=(${selected[@]})"
}

extract_tag() {
    local file="$1"
    local tag=$(awk -F': *' '/location:/{print $2; exit}' "$file" | sed -e 's/^ *- *//' -e 's/^ *//;s/ *$//')
    echo "$tag"
}

find_folder() {
    local tag="$1"
    local folder=$(find "$HOME/notes" -type d -iname "* $tag" 2>/dev/null | head -n 1)
    echo "$folder"
}

notes_dir="$HOME/notes/00 - Inbox"
notes=("$notes_dir"/*)
note_names=()

if [ ! -e "${notes[0]}" ]; then
    echo "No files in Inbox."
    exit 0
fi

for note in "${notes[@]}"; do
    note_names+=("$(basename "$note")")
done

selected_note=""
declare -a actions
menu "Select a note to keep (k), delete (d), or preview (p). Press ENTER when done:" selected_note actions "${note_names[@]}"

confirm=""
menu "Confirm your choices (ok to apply, cancel to discard):" confirm _ "ok" "cancel"

if [[ $confirm == "ok" ]]; then
    for ((i=0; i<${#actions[@]}; i++)); do
        note_file="${notes[i]}"
        if [[ ${actions[i]} -eq 1 ]]; then
            tag=$(extract_tag "$note_file")
            if [ -n "$tag" ]; then
                folder=$(find_folder "$tag")
                if [ -n "$folder" ]; then
                    mv "$note_file" "$folder"
                    echo "Moved '${note_names[i]}' to '$folder'"
                else
                    echo "location: '$tag' not found. Skipping '${note_names[i]}'."
                fi
            else
                echo "No location found in '${note_names[i]}'. Skipping."
            fi
        elif [[ ${actions[i]} -eq 2 ]]; then
            rm -f "${note_file}"
            echo "Deleted '${note_names[i]}'"
        fi
    done
else
    echo "No changes made."
fi
