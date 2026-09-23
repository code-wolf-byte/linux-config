source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH $HOME/.lmstudio/bin
# End of LM Studio CLI section

# Added by Hermes Agent setup
set -gx PATH $HOME/.local/bin $PATH
# End of Hermes Agent section

# pkgfile: use the filtered pacman.conf (ogc repo has no .files db)
function pkgfile
    command pkgfile -C /etc/pkgfile.pacman.conf $argv
end
