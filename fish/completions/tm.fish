# Running sessions first (most recently used on top). If none match what has
# been typed so far, ~/active_workspaces folder names instead. After `tm rm`,
# running sessions only. See bin/tm.
complete -c tm -f -k -a '(tm --complete (commandline -ct) (commandline -opc)[2..2])'
