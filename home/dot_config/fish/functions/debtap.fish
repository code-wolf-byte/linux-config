function debtap
    # debtap's fakeroot heredoc runs under $SHELL; fish's stricter glob
    # errors on unmatched wildcards break the tar/zstd step. Force bash.
    SHELL=/bin/bash command debtap $argv
end
