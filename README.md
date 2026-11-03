Description
A Wrapper for Steam that lets you run 17lands' python client in the background to read rank, winrate and approximated games left to play to mythic and show the data as notification when the client is started and a game or match finished.
You can also run a second GUI-based tracker alongside or instead of 17 lands, although the notification function is tied to 17lands.
Settings are gathered either automatically or via gui-prompting with kdialog/zenity.
No pre-installation of 17lands necessary - the script will handle that for you.

How to use
make the script executable via: chmod +x /path/to/MTG-Arena-Tracker-Wrapper.sh
add to Launch Options: /path/to/MTG-Arena-Tracker-Wrapper.sh %command%
