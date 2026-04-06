# Claude Agent Context

This repository is a learning resource for Bluespec, a hardware description language
with a Haskell-like syntax and a formal foundation in guarded atomic actions (Term
Rewriting Systems).

## Chapter Structure

- **Chapter 1** (`Chapter1.md`) — Complete. Sets the stage: chips as distributed systems,
  coherence problems, atomic actions, Bluespec's TRS foundation.
- **Chapter 2** (`Chapter2.md`) — In progress. Covers Bluespec's message-passing
  primitives (Registers, Wires, FIFOs) and begins motivating the type system.
- **Chapter 3** — Not yet written. Will introduce Haskell to students.
- **Chapter 4** (`chapter4.ipynb`) — Complete as a notebook. Parser combinators without
  monads; builds a full calculator parser. Plan at `chapter4/PLAN.md`.

## Chapter 4 — Status

The notebook `chapter4.ipynb` is complete and executes cleanly. It covers:

- `ParseResult`/`Parser` types, `item`, `satisfy`, `char`, `digit`
- `<|>` (choice), `many`/`some`, `natural`
- `andThen`, `yield`, `chain`, and the full calculator grammar
- Closes with motivation for Chapter 5 (monads)

**Note:** The Functor/Applicative/Monad section and do-notation rewrite are deferred
to Chapter 5 per the revised plan.

## Running Notebooks

IHaskell is installed via Stack. Jupyter is installed via pip3 into
`~/Library/Python/3.9/bin/`. The IHaskell kernel must be registered **without**
the `--stack` flag:

```bash
export PATH="$PATH:$HOME/Library/Python/3.9/bin"
stack exec -- ihaskell install   # no --stack flag here
```

To execute a notebook in-place:

```bash
export PATH="$PATH:$HOME/Library/Python/3.9/bin"
jupyter nbconvert --to notebook --execute chapter4.ipynb --output chapter4.ipynb
```

### Known GHC 9.10.3 aarch64 bug

GHC 9.10.3 has an RTS bug (`ARR_WORDS object entered!`) triggered when custom
data types are defined in a kernel session and then certain standard library
functions are imported and used. Confirmed bad: all of `Data.Char`, `Data.List.sort`,
`Data.List.nub`. Confirmed fine: `Data.List.isPrefixOf`, `isInfixOf`, `intercalate`,
and pure Prelude. The pattern is inconsistent — do not try to reason about which
imports are safe. **Safe rule: no `import` statements in notebooks at all.** Implement
any helpers from first principles (e.g. `c >= '0' && c <= '9'` instead of `isDigit`).

**Code files:** `chapter4/Parser.hs` and `chapter4/Calculator.hs` (standalone GHCi/ghc versions)
**Notebook:** `chapter4.ipynb`

## Writing Style

Match the tone of existing chapters: conversational, first-person, uses analogies freely,
honest about gaps and uncertainties. Does not shy away from technical depth but always
grounds abstractions in concrete examples first.
