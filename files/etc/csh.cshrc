# $FreeBSD: src/etc/csh.cshrc,v 1.3 1999/08/27 23:23:40 peter Exp $
#
# System-wide .cshrc file for csh(1).

setenv CLICOLOR yes
setenv MAKEOBJDIRPREFIX /tmp

if ($?prompt) then
        # An interactive shell -- set some stuff up
        set filec
        set history = 100
        set savehist = 100
        set mail = (/var/mail/$USER)
        if ( $?tcsh ) then
                bindkey "^W" backward-delete-word
                bindkey -k up history-search-backward
                bindkey -k down history-search-forward
        endif

        [ -x /usr/games/fortune ] && /usr/games/fortune freebsd-tips
        set prompt = '%n@%m:%~%# '
        set autolist

endif

