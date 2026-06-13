# Keybindings

Generated from the State keymaps by `just docs` — do not edit by hand.
Command names are shown without the `aim-` prefix.

## Normal State

| Key | Command |
|-----|---------|
| `!` | filter |
| `"` | use-register |
| `$` | line-end |
| `%` | matching-pair |
| `&` | ex-repeat-substitute |
| `'` | goto-marker-line |
| `(` | backward-sentence |
| `)` | forward-sentence |
| `*` | search-symbol-forward |
| `+` | next-line-non-blank |
| `,` | repeat-find-reverse |
| `-` | previous-line-non-blank |
| `.` | repeat |
| `/` | search-forward |
| `0` | line-beginning |
| `:` | ex |
| `;` | repeat-find |
| `<` | shift-left |
| `=` | reindent |
| `>` | shift-right |
| `?` | search-backward |
| `@` | execute-macro |
| `A` | append-line |
| `B` | backward-bigword-begin |
| `C` | change-line-rest |
| `C-a` | increment |
| `C-d` | scroll-down |
| `C-r` | redo |
| `C-u` | scroll-up |
| `C-v` | visual-block |
| `D` | kill-line-rest |
| `E` | forward-bigword-end |
| `F` | find-char-backward |
| `G` | goto-line |
| `H` | window-top |
| `I` | insert-line |
| `J` | join-lines |
| `L` | window-bottom |
| `M` | window-middle |
| `N` | search-previous |
| `O` | open-above |
| `P` | paste-before |
| `R` | replace-state |
| `S` | substitute-line |
| `T` | find-char-to-backward |
| `V` | visual-line |
| `W` | forward-bigword-begin |
| `Y` | copy-line |
| `Z Q` | quit-no-write |
| `Z Z` | write-quit |
| `[ [` | backward-section |
| `[ ]` | backward-section-end |
| `] [` | forward-section-end |
| `] ]` | forward-section |
| `^` | first-non-blank |
| `_` | current-line-non-blank |
| ``` | goto-marker |
| `a` | append |
| `b` | backward-word-begin |
| `c` | change |
| `d` | delete |
| `e` | forward-word-end |
| `f` | find-char |
| `g &` | ex-repeat-substitute-buffer |
| `g C-x` | decrement |
| `g J` | join-lines-no-space |
| `g P` | paste-before-advance |
| `g U` | upcase |
| `g _` | last-non-blank |
| `g g` | goto-first-line |
| `g i` | insert-at-last-edit |
| `g j` | next-visual-line |
| `g k` | previous-visual-line |
| `g p` | paste-after-advance |
| `g q` | reformat |
| `g u` | downcase |
| `g v` | visual-restore |
| `g w` | reformat-keep |
| `g ~` | swap-case |
| `h` | backward-char |
| `i` | insert |
| `j` | next-line |
| `k` | previous-line |
| `l` | forward-char |
| `m` | set-marker |
| `n` | search-next |
| `o` | open-below |
| `p` | paste-after |
| `q` | record-macro |
| `r` | replace-char |
| `s` | substitute-char |
| `t` | find-char-to |
| `u` | undo |
| `v` | visual-char |
| `w` | forward-word-begin |
| `x` | delete-char |
| `y` | yank |
| `{` | backward-paragraph |
| `|` | goto-column |
| `}` | forward-paragraph |
| `~` | invert-char-case |

## Visual State

| Key | Command |
|-----|---------|
| `!` | filter |
| `"` | use-register |
| `$` | line-end |
| `%` | matching-pair |
| `'` | goto-marker-line |
| `(` | backward-sentence |
| `)` | forward-sentence |
| `*` | search-symbol-forward |
| `+` | next-line-non-blank |
| `,` | repeat-find-reverse |
| `-` | previous-line-non-blank |
| `0` | line-beginning |
| `:` | ex |
| `;` | repeat-find |
| `<` | shift-left |
| `<escape>` | visual-exit |
| `=` | reindent |
| `>` | shift-right |
| `A` | visual-append |
| `B` | backward-bigword-begin |
| `C-d` | scroll-down |
| `C-u` | scroll-up |
| `C-v` | visual-block |
| `E` | forward-bigword-end |
| `ESC` | visual-exit |
| `F` | find-char-backward |
| `G` | goto-line |
| `H` | window-top |
| `I` | visual-insert |
| `L` | window-bottom |
| `M` | window-middle |
| `N` | search-previous |
| `T` | find-char-to-backward |
| `U` | upcase |
| `V` | visual-line |
| `W` | forward-bigword-begin |
| `[ [` | backward-section |
| `[ ]` | backward-section-end |
| `] [` | forward-section-end |
| `] ]` | forward-section |
| `^` | first-non-blank |
| `_` | current-line-non-blank |
| ``` | goto-marker |
| `a` | visual-object |
| `b` | backward-word-begin |
| `c` | visual-change |
| `d` | delete |
| `e` | forward-word-end |
| `f` | find-char |
| `g _` | last-non-blank |
| `g g` | goto-first-line |
| `g j` | next-visual-line |
| `g k` | previous-visual-line |
| `g q` | reformat |
| `g w` | reformat-keep |
| `h` | backward-char |
| `i` | visual-object |
| `j` | next-line |
| `k` | previous-line |
| `l` | forward-char |
| `n` | search-next |
| `o` | visual-exchange |
| `p` | visual-paste |
| `s` | visual-change |
| `t` | find-char-to |
| `u` | downcase |
| `v` | visual-char |
| `w` | forward-word-begin |
| `x` | delete |
| `y` | yank |
| `{` | backward-paragraph |
| `|` | goto-column |
| `}` | forward-paragraph |
| `~` | swap-case |

## Operator-pending State (motions + text objects)

| Key | Command |
|-----|---------|
| `$` | line-end |
| `%` | matching-pair |
| `'` | goto-marker-line |
| `(` | backward-sentence |
| `)` | forward-sentence |
| `*` | search-symbol-forward |
| `+` | next-line-non-blank |
| `,` | repeat-find-reverse |
| `-` | previous-line-non-blank |
| `0` | line-beginning |
| `;` | repeat-find |
| `<escape>` | keyboard-quit |
| `B` | backward-bigword-begin |
| `C-d` | scroll-down |
| `C-u` | scroll-up |
| `E` | forward-bigword-end |
| `ESC` | keyboard-quit |
| `F` | find-char-backward |
| `G` | goto-line |
| `H` | window-top |
| `L` | window-bottom |
| `M` | window-middle |
| `N` | search-previous |
| `T` | find-char-to-backward |
| `W` | forward-bigword-begin |
| `[ [` | backward-section |
| `[ ]` | backward-section-end |
| `] [` | forward-section-end |
| `] ]` | forward-section |
| `^` | first-non-blank |
| `_` | current-line-non-blank |
| ``` | goto-marker |
| `a "` | outer-double-quote |
| `a '` | outer-single-quote |
| `a (` | outer-paren |
| `a )` | outer-paren |
| `a <` | outer-angle |
| `a >` | outer-angle |
| `a B` | outer-brace |
| `a W` | outer-bigword |
| `a [` | outer-bracket |
| `a ]` | outer-bracket |
| `a `` | outer-back-quote |
| `a b` | outer-paren |
| `a p` | outer-paragraph |
| `a s` | outer-sentence |
| `a t` | outer-tag |
| `a w` | outer-word |
| `a {` | outer-brace |
| `a }` | outer-brace |
| `b` | backward-word-begin |
| `e` | forward-word-end |
| `f` | find-char |
| `g _` | last-non-blank |
| `g g` | goto-first-line |
| `g j` | next-visual-line |
| `g k` | previous-visual-line |
| `h` | backward-char |
| `i "` | inner-double-quote |
| `i '` | inner-single-quote |
| `i (` | inner-paren |
| `i )` | inner-paren |
| `i <` | inner-angle |
| `i >` | inner-angle |
| `i B` | inner-brace |
| `i W` | inner-bigword |
| `i [` | inner-bracket |
| `i ]` | inner-bracket |
| `i `` | inner-back-quote |
| `i b` | inner-paren |
| `i p` | inner-paragraph |
| `i s` | inner-sentence |
| `i t` | inner-tag |
| `i w` | inner-word |
| `i {` | inner-brace |
| `i }` | inner-brace |
| `j` | next-line |
| `k` | previous-line |
| `l` | forward-char |
| `n` | search-next |
| `t` | find-char-to |
| `w` | forward-word-begin |
| `{` | backward-paragraph |
| `|` | goto-column |
| `}` | forward-paragraph |

## Insert State

| Key | Command |
|-----|---------|
| `<escape>` | normal-state |
| `ESC` | normal-state |

## Replace State

| Key | Command |
|-----|---------|
| `<escape>` | normal-state |
| `DEL` | replace-backspace |
| `ESC` | normal-state |
