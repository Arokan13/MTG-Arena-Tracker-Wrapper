#!/bin/bash

#Custom Variables
NotificationTitle="MTG-Arena Tracker-Wrapper"
TIMEOUT=15

#Paths
STEAM_LIB_DIR=
STL_BIN=
GUI_BIN=

kdialog() { command env -u LD_LIBRARY_PATH -u LD_PRELOAD kdialog "$@"; }
zenity() { command env -u LD_LIBRARY_PATH -u LD_PRELOAD zenity "$@"; }

getSteamLibraryList() {
    #Trying to find Steam's List of Directories + Preparing Menu List
    STEAM_LIB_FILE="$(find ~/.steam/root/ ~/.var/app/com.valvesoftware.steam/data/ -name "libraryfolders.vdf" -print -quit 2>/dev/null)"
    STEAM_LIB_LIST=(); STEAM_LIB_MENU=();
    while IFS= read -r path; do
        STEAM_LIB_LIST+=("$path")
        STEAM_LIB_MENU+=("$path")
        STEAM_LIB_MENU+=("$path")
    done < <(cat "$STEAM_LIB_FILE" | grep path | awk -F\" '{print $4}')
}

getSteamLibraryDir() {
#Trying to find MTG-Client. Prompt if none is found.
getSteamLibraryList
    export STEAM_LIB_DIR="$(find "${STEAM_LIB_LIST[@]}" -type d -wholename "*common/MTGA" -print -quit 2>/dev/null | sed 's|/steamapps.*||g')"

if [ -z "$STEAM_LIB_DIR" ]; then
    if [ ${#STEAM_LIB_LIST[@]} -gt 1 ]; then
        if command -v kdialog &>/dev/null; then
            STEAM_LIB_DIR="$(kdialog --title "Choose Directory" --menu "Choose Directory" "${STEAM_LIB_MENU[@]}")"
        elif command -v zenity &>/dev/null; then
            STEAM_LIB_DIR="$(zenity --title "Choose Directory" --list --column="Select" "${STEAM_LIB_LIST[@]}")"
        fi
    elif [ ${#STEAM_LIB_LIST[@]} -eq 1 ]; then
            STEAM_LIB_DIR="${STEAM_LIB_LIST[0]}"
    fi
fi
    echo "$STEAM_LIB_DIR"
    sed -i "s|^STEAM_LIB_DIR=.*|STEAM_LIB_DIR=\"$STEAM_LIB_DIR\"|" "$0"
}

installSTL() {
#Trying to find 17Lands. Prompt install if not found.
    STL_BIN="$(whereis seventeenlands | awk 'NR==1{$1=""; print substr($0,2)}')"
if [ -z "$STL_BIN" ]; then
    #Install Python if not installed
    if ! command -v pipx &> /dev/null; then
        if command -v kdialog &>/dev/null; then
            kdialog --title "17 Lands missing!" --yesno "It appears 17 lands is not installed.\nWould you like to (along with python (required)?" \
            --yes-label "Yes" --no-label "No" --cancel-label "Ask again later"
        elif command -v zenity &>/dev/null; then
            zenity --question --title="17 Lands missing!" --text="It appears 17 lands is not installed.\nWould you like to (along with python (required)?" \
            --ok-label="Yes" --cancel-label="No"
        fi
    fi

    if [ $? -eq 0 ]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y pipx
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y pipx
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm python-pipx
        fi

        pipx ensurepath
        pipx install seventeenlands
        export STL_BIN="$(whereis seventeenlands | awk 'NR==1{$1=""; print substr($0,2)}')"

    elif [ $? -eq 1 ]; then
        sed -i "s|^STL_BIN=.*|STL_BIN=\"none\"|" "$0"
    fi

    if [ -f "$STL_BIN" ] && [ ! -f "$HOME/.mtga_follower.ini" ]; then
        xdg-open "https://www.17lands.com/account"
        if command -v kdialog &>/dev/null; then
            TOKEN="$(kdialog --title "Token Needed" --inputbox "Copy the \"Client token\" and paste it here!")"
        elif command -v zenity &>/dev/null; then
            TOKEN="$(zenity --entry --title="Token Needed" --text="Copy the \"Client token\" and paste it here!")"
        fi
    [ -n "$TOKEN" ] && echo -e "[client]\ntoken = $TOKEN" > "$HOME/.mtga_follower.ini"
    fi
    echo "$STL_BIN"
    sed -i "s|^STL_BIN=.*|STL_BIN=\"$STL_BIN\"|" "$0"
fi
}

getGUI_BIN() {
    if command -v kdialog &>/dev/null; then
        kdialog --title "Second Tracker" --yesnocancel "You can have the wrapper run a Graphical Tracker alongside/instead of 17 Lands.\nDo you want to?" \
        --yes-label "Choose Path" --no-label "No" --cancel-label "Ask again later"
    elif command -v zenity &>/dev/null; then
        zenity --question --title="17 Lands missing!" --text="You can have the wrapper run a Graphical Tracker alongside/instead of 17 Lands.\nDo you want to?" \
        --ok-label="Choose Path" --cancel-label="No"
    fi

    if [ $? -eq 0 ]; then
        if command -v kdialog &>/dev/null; then
            GUI_BIN="$(kdialog --title "Choose Path to second Tracker" --getopenfilename)"
        elif command -v zenity &>/dev/null; then
            GUI_BIN="$(zenity --title="Choose Path to second Tracker" --file-selection)"
        fi

        if [ "${GUI_BIN##*.}" = "exe" ]; then
            if command -v kdialog &>/dev/null; then
                kdialog --title "Protonhax required" --yesno "Windows Programs should be run with Proton via Protonhax to run two programs in the same Prefix.\nWould you like to install it?"
            elif command -v zenity &>/dev/null; then
                zenity --question --title="Protonhax required" --text="Windows Programs should be run with Proton via Protonhax to run two programs in the same Prefix.\nWould you like to install it?"
            fi

            if [ $? -eq 0 ]; then
                curl -sL "https://github.com/jcnils/protonhax/archive/refs/heads/main.tar.gz" | tar -xz
                mv ./protonhax-main/protonhax "${GUI_BIN%/*}/protonhax"
                chmod 755 "${GUI_BIN%/*}/protonhax"
                rm -r ./protonhax-main/protonhax
            else GUI_BIN=""
            fi
        fi

        echo "$GUI_BIN"
        sed -i "s|^GUI_BIN=.*|GUI_BIN=\"$GUI_BIN\"|" "$0"
    elif [ $? -eq 1 ]; then
        sed -i "s|^GUI_BIN=.*|GUI_BIN=none|" "$0"
    fi
}

initProtonhax() {
PHAX="${GUI_BIN%/*}/protonhax"
while [ -z "$("$PHAX" ls)" ]; do sleep 1; done \
&& "$PHAX" run \
    $("$PHAX" ls | awk 'NR==1{print $1}') \
    env -u LD_LIBRARY_PATH -u LD_PRELOAD \
    "$GUI_BIN" 2>&1 &
    echo "GUI_PID=$!" >> /tmp/MTG-TW-PID.log
}

# Cleanup
cleanup() {
    source /tmp/MTG-TW-PID.log
    [ -n "$STL_PID" ] && kill "$STL_PID" 2>/dev/null
    [ -n "$GUI_PID" ] && kill "$GUI_PID" 2>/dev/null
    [ -n "$SRN_PID" ] && kill "$SRN_PID" 2>/dev/null
    rm -f /tmp/MTG-TW-PID.log 2>/dev/null
    exit 0
}
trap cleanup EXIT INT TERM

# Notification Function
send_rank_notification() {
    local line="$1"

    local msg
    msg=$(echo "$line" | awk -F"[{}]" '{print $2}' | awk -F", " '
    {
        for (i=1; i<=NF; i++) {
            split($i, a, ": ");
            gsub(/\047/, "", a[1]);
            gsub(/\047/, "", a[2]);
            val[a[1]] = a[2];
        }

        # Constructed
        c_class = val["constructedClass"];
        c_lvl   = val["constructedLevel"] + 0;
        c_step  = val["constructedStep"] + 0;
        c_won   = val["constructedMatchesWon"] + 0;
        c_lost  = val["constructedMatchesLost"] + 0;
        if (c_won == c_lost) c_won = c_won + 0.1;
        c_total = c_won + c_lost;
        c_wrate  = c_won / c_total;

        #Pip Math Constructed
        c_left  = (c_class == "mythic" ) ? 0 : \
                  (c_class == "diamond" ) ? 24 : \
                  (c_class == "platinum" ) ? 48 : \
                  (c_class == "gold" ) ? 72 : \
                  (c_class == "silver" ) ? 96 : 120;
        c_left  = (c_left - 6*(4-c_lvl) - c_step);
        c_gr_ha = int(c_left / 24);
        c_gr_so = int(c_left / 6 - c_gr_ha);
        c_gr_re = (c_left - c_gr_so - c_gr_ha);

        c_pr_ap = (  c_wrate - (1-c_wrate)  ) * (c_gr_re / c_left) \
                + (  c_wrate - (1-c_wrate)^2) * (c_gr_so / c_left) \
                + (  c_wrate                ) * (c_gr_ha / c_left);
        c_pr_up = (2*c_wrate - (1-c_wrate)  ) * (c_gr_re / c_left) \
                + (2*c_wrate - (1-c_wrate)^2) * (c_gr_so / c_left) \
                + (2*c_wrate                ) * (c_gr_ha / c_left);

        c_gtm   = (c_left == 0) ? "Mythic" \
                : (c_pr_ap > 0 && c_left <= 48) \
                    ? sprintf("%d Games to Mythic", int(c_left / c_pr_up)) \
                : (c_pr_ap > 0 && c_left > 48) \
                    ? sprintf("%d Games to Mythic", int(48 / c_pr_ap + (c_left - 48) / c_pr_up)) \
                : (c_pr_up > 0 && c_left <=48) \
                    ? "Never Mythic" \
                : (c_pr_up > 0 && c_left > 48) \
                    ? sprintf("%d Games to Plat", int((c_left - 48 ) / c_pr_up)) \
                : "Never even Plat";


        c_wrate = (c_total > 0) ? sprintf("%.2f%%", (c_won * 100) / c_total) : "0.00%";
        c_out  = sprintf("Con: %s:%d:%d - %s - %s", c_class, c_lvl, c_step, c_wrate, c_gtm);


        # Limited
        l_class = val["limitedClass"];
        l_lvl   = val["limitedLevel"] + 0;
        l_step  = val["limitedStep"] + 0;
        l_won   = val["limitedMatchesWon"] + 0;
        l_lost  = val["limitedMatchesLost"] + 0;
        if (l_won == l_lost) l_won = l_won + 0.1;
        l_total = l_won + l_lost;
        l_wrate  = l_won / l_total;

        #Pip Math Limited
        l_left  = (l_class == "mythic" ) ? 0 : \
                  (l_class == "diamond" ) ? 20 : \
                  (l_class == "platinum" ) ? 40 : \
                  (l_class == "gold" ) ? 64 : \
                  (l_class == "silver" ) ? 88 : 112;
        l_left  = (l_left <= 40) ? \
                  (l_left - 5*(4-l_lvl) - l_step) \
                : (l_left - 6*(4-l_lvl) - l_step);
        l_gr_ha = (l_left <= 40) ? \
                  int(l_left / 20) \
                : int((l_left-40) / 24 + 2);
        l_gr_so = (l_left <= 40) ? \
                  int(l_left / 5 - l_gr_ha) \
                : int((l_left-40) / 6 + 8 - l_gr_ha);
        l_gr_re = (l_left - l_gr_so - l_gr_ha);

        l_pr_ap = (  l_wrate - (1-l_wrate)  ) * (l_gr_re / l_left) \
                + (  l_wrate - (1-l_wrate)^2) * (l_gr_so / l_left) \
                + (  l_wrate                ) * (l_gr_ha / l_left);
        l_pr_up = (2*l_wrate - (1-l_wrate)  ) * (l_gr_re / l_left) \
                + (2*l_wrate - (1-l_wrate)^2) * (l_gr_so / l_left) \
                + (2*l_wrate                ) * (l_gr_ha / l_left);

        l_gtm   = (l_left == 0) ? "Mythic" \
                : (l_pr_ap > 0 && l_left <= 40) \
                    ? sprintf("%d Games to Mythic", int(l_left / l_pr_up)) \
                : (l_pr_ap > 0 && l_left > 40) \
                    ? sprintf("%d Games to Mythic", int(40 / l_pr_ap + (l_left - 40) / l_pr_up)) \
                : (l_pr_up > 0 && l_left <=40) \
                    ? "Never Mythic" \
                : (l_pr_up > 0 && l_left > 40) \
                    ? sprintf("%d Games to Plat", int((l_left - 40 ) / l_pr_up)) \
                : "Never even Plat";


        l_wrate = (l_total > 0) ? sprintf("%.2f%%", (l_won * 100) / l_total) : "0.00%";
        l_out  = sprintf("Lim: %s:%d:%d - %s - %s", l_class, l_lvl, l_step, l_wrate, l_gtm);

        print c_out "\n" l_out;
    }')
    if command -v notify-send &>/dev/null; then
        notify-send -a "$NotificationTitle" -t "$((TIMEOUT * 1000))" "" "$msg"
    elif command -v kdialog &>/dev/null; then
        kdialog --title "$NotificationTitle" --passivepopup "$msg" "$TIMEOUT"
    elif command -v zenity &>/dev/null; then
        zenity --notification --text="$NotificationTitle: $msg"
    fi
}

# Install
[ -z "$STEAM_LIB_DIR" ] && getSteamLibraryDir
[ -z "$STL_BIN" ] && installSTL
[ -z "$GUI_BIN" ] && getGUI_BIN

# Initialize GUI-Tracker
if [ -f "$GUI_BIN" ]; then
    if [ "${GUI_BIN##*.}" = "exe" ]; then
            prhx="${GUI_BIN%/*}/protonhax init"
            initProtonhax 2>&1 &
    else    env -u LD_LIBRARY_PATH -u LD_PRELOAD \
            "$GUI_BIN" 2>&1 &
            echo "GUI_PID=$!" >> /tmp/MTG-TW-PID.log
    fi
fi

# Initialize 17Lands
if [ -f "$STL_BIN" ]; then
pipx upgrade seventeenlands #1-2s extra
PLAYER_LOG="$(find "$STEAM_LIB_DIR" -wholename "*/MTGA/Player.log" -print -quit 2>/dev/null)"
"$STL_BIN" -l "$PLAYER_LOG" >> "/tmp/17lands.log" 2>&1 &
echo "STL_PID=$!" >> /tmp/MTG-TW-PID.log
fi

# Background Read
tail -F -n 0 "/tmp/17lands.log" 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" == *"Parsed rank info"* ]]; then
        send_rank_notification "$line"
    fi
done &
echo "SRN_PID=$!" >> /tmp/MTG-TW-PID.log


# MTGA `%command%`
$prhx "$@"
