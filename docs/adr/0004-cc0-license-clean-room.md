# CC0-1.0 license, clean-room discipline toward GPL code

aim-mode is licensed CC0-1.0 (Creative Commons public-domain dedication),
not the elisp-conventional GPL. Nothing legally forces GPL on us: requiring
built-in GPL libraries and running inside GNU Emacs constrains only the
combined runtime work, and CC0 is FSF-listed as GPL-compatible, so the
combination remains lawful and MELPA-acceptable. We chose maximal freedom
for downstream users over the strategic benefit GPL would have given us.

The price, binding on every future contribution: **code is never copied
from GPL projects** — not from evil, not from Emacs internals, not from any
GPL package. Studying their source for architecture and ideas is fine (and
ADR 0003 is built on exactly that); reproducing their code is a violation.

## Consequences

- Every Kernel mechanism evil already solved must be reimplemented from
  the idea, not ported from the code.
- Known caveats of CC0 accepted: no patent grant, and OSI declined to
  approve it — both immaterial for this project.
- CC-BY / CC-BY-SA were not options: Creative Commons itself discourages
  its attribution licenses for software.
