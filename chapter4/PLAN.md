# Chapter 4 Plan: Building a Parser Combinator in Haskell

## Goal

Before students write Bluespec Haskell, they need experience with regular Haskell in a
forgiving environment (good compiler errors, good tooling). Chapter 4 builds a minimal but
fully functional parser combinator from scratch, culminating in a calculator expression
parser. The monad pattern encountered here directly foreshadows Bluespec's `Action` monad.

## Assumptions

- Students have passing familiarity with Haskell functions and types (covered in Chapter 3).
- No prior knowledge of parser combinators or monads.

## Code Layout (`./chapter4/`)

- `Parser.hs` — the `Parser` type, typeclass instances (Functor, Applicative, Monad),
  primitive parsers (`item`, `satisfy`, `char`, `digit`, `natural`), and combinators
  (`<|>`, `many`, `some`).
- `Calculator.hs` — the calculator parser built twice: once without do notation (raw `>>=`
  and `>>` chains), once with do notation. Includes a `main` that demos both.

`Calculator.hs` imports from `Parser.hs` — explicit module separation is intentional and
worth calling out in the text.

## Chapter Sections

### 1. Why Parser Combinators?
Brief motivation. Higher-order functions and types working together in a concrete,
runnable project. Foreshadow the connection to Bluespec's `Action` monad.

### 2. The Parser Type
Define `Parser a` as a `newtype` wrapping `String -> Maybe (a, String)`. Explain what the
type means: takes remaining input, returns either failure (`Nothing`) or a parsed value
plus unconsumed input. Introduce `runParser` as the unwrapper.

### 3. Primitive Parsers
`item`, `satisfy`, `char`, `digit`, `natural` (multi-digit integers). Small, concrete,
immediately testable in GHCi.

### 4. Functor → Applicative → Monad
Implement in order — GHC requires it (Monad has Applicative as a superclass, Applicative
has Functor). Don't treat this as a detour; explain *why* the ordering is forced and what
each instance buys us. For Monad, implement `>>=` and `>>`. This is the minimum needed for
do notation.

### 5. Combinators
`<|>` (choice/alternation), `many`, `some`. Note: `many` applied to a parser that never
fails will loop forever — call this out explicitly.

### 6. Small Do/Raw Comparison
Before the full calculator, show the mechanical equivalence of do notation vs raw `>>=`
on a tiny 2-parser sequence. Make the "desugaring" obvious before the complexity ramps up.

### 7. The Calculator Grammar
State the grammar as BNF before writing any code:

```
expr   ::= term (('+' | '-') term)*
term   ::= factor (('*' | '/') factor)*
factor ::= natural | '(' expr ')'
```

Parentheses are included deliberately — they force a recursive parser structure that
illustrates why combinators are powerful. This mirrors the formal specification mindset
used in Bluespec design.

### 8. Building the Parser — Raw Style
Implement `expr`, `term`, `factor` using explicit `>>=` and `>>` chains. No do notation.
It should feel slightly painful to read. That contrast is the point.

### 9. Building the Parser — Do Notation
Same logic, same structure, dramatically more readable. Students should feel the relief.

### 10. The Bridge to Bluespec
Explicit callout: `Parser a` is structurally identical to `ActionValue#(a)`. Parsers
consume input sequentially; actions sequence atomically. The monad is the design pattern
for "computation that threads some implicit state." This is what Bluespec's do blocks are
doing inside rules.
