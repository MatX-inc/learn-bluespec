# Chapters 4–6 Plan: Parser Combinators → Monads → Idiomatic Haskell

## Format

All three chapters are **IHaskell Jupyter notebooks** (`.ipynb`). They render
on GitHub and let students run code inline without a separate GHCi session.
Setup requires `stack` + IHaskell; a setup guide and help channel are provided
separately.

## Code Layout

- `chapter4/Parser4.hs` — parser implementation for Chapter 4 (no monads)
- `chapter5/Parser5.hs` — parser implementation for Chapter 5 (with Monad)
- `chapter6/Parser6.hs` — idiomatic final version
- `chapterN/Calculator.hs` — calculator built on each chapter's parser

Each chapter's notebook imports from its own `.hs` file so notebook cells
stay focused on concepts, not boilerplate.

---

## Chapter 4 — Parser Combinators Without Monads

**Goal:** Build a working parser by explicit pattern matching and threading.
No `>>=`, no `do`, no anonymous functions, no `$`. Every step named, every
field named. Students should feel the verbosity — that's the point.

### Principles
- No `$` operator
- No anonymous functions (`\x -> ...`)
- Named field construction everywhere (`ParseOk { consumed = x, remaining = r }`)
- No `do` notation
- No `>>=` or `>>`

### Sections

1. **What is a parser?**
   Left-to-right consumption, the `(recognized, remainder)` pair, how parsers
   chain by handing off the unconsumed tail. Wrong turns and backtracking —
   the explicit-stack mental model, and why immutable strings give us
   backtracking for free.

2. **The types**
   `ParseResult` with `NoParse` and `ParseOk { consumed, remaining }`.
   `Parser` as a `data` wrapper around a function. Explain record field
   extraction explicitly — `runParser p` is just pulling the function out
   of the wrapper. `newtype` aside deferred to Chapter 6.

3. **`item` — the only primitive**
   The one parser that directly touches the input string. Walk through the
   pattern match step by step.

4. **Building bigger parsers from small ones**
   This is function composition. Hit that point explicitly before writing
   any more parsers. Small parsers combined into larger ones, all the way up.

5. **`satisfy` — parsing with a condition**
   Motivate it first: sometimes you only want to consume a character if it
   meets a test (is it a digit? a letter?). Implement using explicit pattern
   matching on the result of `item`, not `do` notation.

6. **`char`, `digit`, `natural`**
   Each one built from the last. Emphasize the compositional chain.

7. **`<|>` — choice**
   Try one parser, fall back to another. Explicit case match, no magic.

8. **`many` and `some`**
   Repetition. Warn about infinite loops explicitly.

9. **The calculator — explicit threading**
   Build `expr`/`term`/`factor` by explicitly passing `remaining` from one
   result into the next parser by name. It's verbose. That's intentional.
   Students should feel why something better is needed.

---

## Chapter 5 — Introducing the Monad as a Sequencer

**Goal:** Name the pattern from Chapter 4. The explicit threading of `remaining`
into each next parser is a pattern — it has a name, and we can encode it once
and reuse it. That encoding is the Monad. Introduce `>>=` and `>>` as the
tools; defer `do` notation until the very end of the chapter as a reveal.

### Principles
- Introduce `Functor` and `Applicative` as required steppingstones to `Monad`,
  but keep explanations brief — they're prerequisites, not the destination
- Explain `Monad` as: "sequence two parsers, automatically threading `remaining`"
- Build everything with `>>=` and `>>` first
- `do` notation arrives at the end as syntactic sugar — show the mechanical
  desugaring, then rewrite the calculator in `do` style
- Still no `$`, still named fields, still no anonymous functions until `>>=`
  makes lambdas unavoidable

### Sections

1. **The problem with Chapter 4**
   Show a multi-step parse from Chapter 4. Count how many times `remaining`
   appears. This is the noise we want to eliminate.

2. **The pattern has a name**
   The threading of state from one step to the next is a Monad. Introduce
   `>>=` as "run this parser, take what it consumed, produce the next parser,
   run that on the remaining input."

3. **Functor and Applicative — required groundwork**
   GHC requires them. Implement them, explain what each adds, move on.
   Show `NoParse` propagation explicitly in each instance.

4. **The Monad instance**
   Implement `>>=`. Walk through how it eliminates the explicit `remaining`
   threading from Chapter 4.

5. **Rewriting the primitives with `>>=`**
   `satisfy`, `char`, `digit`, `natural` — rewritten using `>>=` and `>>`.

6. **The calculator with `>>=`**
   Same calculator as Chapter 4, now using explicit `>>=` chains. Still
   slightly painful to read — but less noisy than Chapter 4.

7. **`do` notation — the reveal**
   Show the mechanical desugaring. Rewrite the calculator in `do` style.
   Students should feel the relief.

8. **Bridge to Bluespec**
   `Parser a` ↔ `ActionValue#(a)`. The table. The Bluespec rule example.

---

## Chapter 6 — Idiomatic Haskell

**Goal:** Take Chapter 5 and rewrite it the way an experienced Haskell
programmer would actually write it. Introduce `$`, anonymous functions,
`newtype`, and drop named field construction. Students now understand what
the idioms are *doing* because they've built the verbose version themselves.

### Principles
- Introduce `$` and explain why it exists
- Anonymous functions (`\x -> ...`) used freely
- `newtype` instead of `data` for `Parser` — revisit the aside from Chapter 4
- Named field construction dropped in favor of positional or pattern style
- Point out each transformation from Chapter 5 and explain the idiom

### Sections

1. **`$` — avoiding parentheses**
2. **Anonymous functions**
3. **`newtype` — the zero-cost wrapper**
4. **Dropping named fields**
5. **The full idiomatic rewrite side-by-side with Chapter 5**
