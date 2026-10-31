# Running sessions first (most recently used on top). If none match what has
# been typed so far, ~/active_workspaces folder names instead. See bin/tm.
complete -c tm -f -k -a '(tm --complete (commandline -ct))'
