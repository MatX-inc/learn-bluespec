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
- **Chapter 4** — Not yet written. Plan is at `chapter4/PLAN.md`.

## Chapter 4 — What Needs to Be Done

Write `Chapter4.md` and the accompanying code in `chapter4/`. Full plan is in
`chapter4/PLAN.md`. Summary:

- Build a minimal parser combinator library from scratch in Haskell
- Implement Functor, Applicative, Monad instances on the `Parser` type
- Parse simple calculator expressions (`+`, `-`, `*`, `/`, parentheses, integers)
- Show the calculator parser built twice: raw `>>=` style and do notation style
- Close with an explicit bridge to Bluespec's `Action`/`ActionValue#` monad

**Code files:** `chapter4/Parser.hs` and `chapter4/Calculator.hs`
**Tutorial file:** `Chapter4.md`

## Writing Style

Match the tone of existing chapters: conversational, first-person, uses analogies freely,
honest about gaps and uncertainties. Does not shy away from technical depth but always
grounds abstractions in concrete examples first.
