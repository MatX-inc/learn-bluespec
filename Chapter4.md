# Building a Parser, Building Intuition

I want to take a detour before we write any more Bluespec. Not because it isn't
time for Bluespec, but because there's a pattern buried in Bluespec's design that
I think is best understood in a friendlier environment first. That pattern is the
*monad*, and the friendlier environment is plain Haskell.

Don't let the word scare you. By the end of this chapter, you'll have built a
working calculator parser from scratch — and the monad will be the thing that
made it readable. After that, Bluespec's `Action` and `ActionValue#` types will
feel like old friends.

All the code for this chapter lives in `chapter4/`. Two files: `Parser.hs` and
`Calculator.hs`. To build and run:

```
cd chapter4
make run
```

## What Is a Parser, Really?

Before we write a line of Haskell, let's build an intuition for what parsing
even *is*.

Imagine you're reading a sentence word by word, left to right. You haven't read
the whole thing yet — you've read some prefix, and the rest is still waiting.
At any moment you can ask: what have I recognized so far, and what's still left
to read? A parser is exactly that process, formalized. It consumes input from
left to right, and at each step it has two things: the structure it has
recognized, and the input it hasn't touched yet.

Consider parsing the string `"123+45"` as a number followed by something else.
A number parser would chew through `"123"`, recognize the integer 123, and hand
back `"+45"` as the unconsumed remainder. That remainder is then available for
the *next* parser to work on. This is how parsers chain: not by passing the
whole string around explicitly, but by each one taking what it needs and leaving
the rest.

### What about wrong turns?

Here's where it gets interesting. Parsers don't always know in advance which
branch of a grammar applies. Consider parsing either a number or an opening
parenthesis — you don't know which one you'll find until you look. If you try
the number parser and the input starts with `'('`, the number parser fails. At
that point you need to *backtrack* — pretend the failed attempt never happened
and try the other option on the original, untouched input.

In traditional compiler implementations, this backtracking uses an explicit
stack. The parser pushes its current position onto the stack before trying a
branch, and pops it if the branch fails. You're not wrong to reach for that
image — it's the right mental model.

In our combinator parser, the call stack *is* the stack. We never actually
consume input in Haskell's sense; we just pass a `String` down the call chain.
If a branch fails, the string we passed in never changed — we just return
`Nothing` and the caller tries something else with the same string it started
with. The backtracking is implicit in the function call structure. This is one
of the pleasant things about functional languages: you get backtracking for
free because strings are immutable and there's nothing to undo.

## Why Parser Combinators?

A parser takes a string and tries to extract structure from it. A *parser combinator*
library is one where parsers are just ordinary values — you can pass them to functions,
return them from functions, and compose them together like Lego bricks.

This makes them a perfect vehicle for learning Haskell's type system. You get
higher-order functions, custom typeclasses, and a real payoff at the end:
a calculator that handles operator precedence and parentheses correctly. It's
small enough to hold in your head and just interesting enough that you'll care
whether it works.

## The Parser Type

Everything starts here:

```haskell
newtype Parser a = Parser { runParser :: String -> Maybe (a, String) }
```

The type `Parser a` encodes exactly what we just described. It's a function that
takes a `String` (the remaining input — the part not yet consumed) and returns
either:

- `Nothing` — the parse failed, or
- `Just (x, rest)` — it succeeded. `x` is the structure that was recognized
  (a character, an integer, an expression — whatever type `a` is), and `rest`
  is everything the parser didn't touch, ready to be handed to the next parser.

Think of `x` as "what I understood" and `rest` as "what I left for you." Every
parser in this chapter produces exactly one of those pairs on success.

The `newtype` wrapper is just bookkeeping — it lets us attach typeclass instances
to `Parser` without confusing Haskell into thinking every function from
`String -> Maybe (a, String)` is a parser. `runParser` unwraps it when we need
the raw function.

That's the whole representation. Everything else is built on top.

## Primitive Parsers

Let's build the simplest possible parsers first.

```haskell
item :: Parser Char
item = Parser $ \input ->
  case input of
    []     -> Nothing
    (c:cs) -> Just (c, cs)
```

`item` consumes exactly one character, or fails on empty input. That's it.

From `item` we can build `satisfy`, which consumes one character but only if it
passes a test:

```haskell
satisfy :: (Char -> Bool) -> Parser Char
satisfy p = do
  c <- item
  if p c then return c else Parser $ \_ -> Nothing
```

Hold on — there's a `do` block here, but we haven't explained how `do` notation
works for `Parser` yet. I'm sneaking it in early because the definition reads
naturally, and I'll explain the machinery in the next section. For now, just read
it as: "consume a character; if the predicate holds, keep it; otherwise fail."

With `satisfy` in hand, `char` and `digit` are one-liners:

```haskell
char :: Char -> Parser Char
char c = satisfy (== c)

digit :: Parser Char
digit = satisfy isDigit
```

And a parser for non-negative integers:

```haskell
natural :: Parser Int
natural = do
  ds <- some digit
  return (read ds)
```

`some` means "one or more" — we'll define it shortly. `read ds` converts the list
of digit characters into an `Int`. Try these in GHCi:

```
ghci> runParser (char 'a') "abc"
Just ('a',"bc")

ghci> runParser digit "42xyz"
Just ('4',"2xyz")

ghci> runParser natural "123abc"
Just (123,"abc")

ghci> runParser natural "abc"
Nothing
```

The unconsumed tail is always handed back. That's how the parsers thread together.

## Functor → Applicative → Monad

Here's the thing about Haskell: you can't just slap `do` notation on any type
you like. `do` notation desugars into calls to `>>=` and `>>`, which are defined
by the `Monad` typeclass. And `Monad` requires `Applicative` as a prerequisite,
which in turn requires `Functor`. You have to implement them in order — GHC
enforces it.

This might feel like bureaucracy, but each layer adds something real.

### Functor — transforming results

```haskell
instance Functor Parser where
  fmap f p = Parser $ \input -> do
    (x, rest) <- runParser p input
    return (f x, rest)
```

`fmap f p` runs the parser `p`, and if it succeeds, applies `f` to the result.
The `do` block here is `Maybe`'s do notation — we're just threading the `Maybe`
that `runParser` returns. What `Functor` buys us: we can transform what a parser
*produces* without touching the parsing logic itself.

### Applicative — combining parsers

```haskell
instance Applicative Parser where
  pure x  = Parser $ \input -> Just (x, input)
  pf <*> px = Parser $ \input -> do
    (f, rest1) <- runParser pf input
    (x, rest2) <- runParser px rest1
    return (f x, rest2)
```

`pure x` is a parser that always succeeds and returns `x` without consuming any
input. Useful for injecting a value at the end of a sequence.

`pf <*> px` runs `pf` to get a function, then runs `px` on the remaining input
to get an argument, then applies the function. Notice how `rest1` is fed into the
second `runParser` — the parsers are chained on the unconsumed input. That
threading of remaining input is the central idea.

### Monad — sequential parsing with choices

```haskell
instance Monad Parser where
  return = pure
  p >>= f = Parser $ \input -> do
    (x, rest) <- runParser p input
    runParser (f x) rest
```

`>>=` (pronounced "bind") is where things get interesting. It runs parser `p`;
if that succeeds with value `x`, it feeds `x` to `f` to get the *next* parser,
and runs that on `rest`. The key insight: `f` can *decide what to parse next*
based on what was just parsed. That makes parsing context-sensitive.

`Functor` lets you transform. `Applicative` lets you sequence. `Monad` lets you
*branch* based on what you've already seen. For our calculator that's overkill —
the grammar isn't context-sensitive — but the `do` notation it unlocks is worth
having.

## The Choice Combinator

One thing the three typeclasses above don't give us is the ability to *try
alternatives*. For that we define `<|>` ourselves:

```haskell
(<|>) :: Parser a -> Parser a -> Parser a
p <|> q = Parser $ \input ->
  case runParser p input of
    Nothing -> runParser q input
    result  -> result
```

Try `p` first. If it fails (`Nothing`), try `q` on the same input. If `p`
succeeds, use that result — `q` never runs. This is the "committed choice" of
parser combinators: no backtracking once a character has been consumed.

## Repetition: `many` and `some`

```haskell
many :: Parser a -> Parser [a]
many p = some p <|> return []

some :: Parser a -> Parser [a]
some p = do
  x  <- p
  xs <- many p
  return (x : xs)
```

`some p` tries to parse at least one occurrence. `many p` tries for one or more,
but happily returns the empty list if `p` fails immediately.

**Warning:** if `p` always succeeds (for example, `many (return ())`) this will
loop forever. `many` has no way to know you're not making progress.

With `many` and `some` defined, `natural` compiles fine:

```haskell
natural = do
  ds <- some digit
  return (read ds)
```

## Do Notation vs Raw `>>=` — A Small Example

Before we build the full calculator, let me show you what `do` notation actually
*is*. It's syntactic sugar — the compiler mechanically rewrites it. Here's a
small two-parser sequence both ways:

**Do notation:**
```haskell
twoDigits :: Parser (Char, Char)
twoDigits = do
  a <- digit
  b <- digit
  return (a, b)
```

**Raw `>>=`:**
```haskell
twoDigits :: Parser (Char, Char)
twoDigits = digit >>= \a -> digit >>= \b -> return (a, b)
```

These are identical. The compiler turns the first into the second. The `<-`
arrow in a `do` block is just `>>=` with the lambda written to the right rather
than inline. For two parsers it's fine either way. For ten parsers in a chain,
the raw style becomes a right-leaning pyramid of lambdas. That's the problem `do`
notation solves.

## The Calculator Grammar

Before writing any parser code, let's state what we're parsing:

```
expr   ::= term   (('+' | '-') term)*
term   ::= factor (('*' | '/') factor)*
factor ::= natural | '(' expr ')'
```

The layered structure — expr calls term, term calls factor, factor calls expr —
is what gives us the right operator precedence for free. Multiplication binds
tighter than addition because `term` is parsed as a unit before `expr` ever sees
it. Parentheses force re-entry at `expr` level, which resets the precedence
hierarchy. This mirrors the kind of formal grammar specification you'd write in
a Bluespec design document.

We also need helpers to parse the operators themselves:

```haskell
addOp :: Parser (Int -> Int -> Int)
addOp = (char '+' >> return (+)) <|> (char '-' >> return (-))

mulOp :: Parser (Int -> Int -> Int)
mulOp = (char '*' >> return (*)) <|> (char '/' >> return div)
```

These parsers don't return a number — they return a *function*. That's
higher-order programming doing real work: we parse a symbol and produce the
operation it represents, to be applied later.

We also need something to parse a left-associative chain of (op, operand) pairs:

```haskell
chain :: Parser (Int -> Int -> Int) -> Parser Int -> Int -> Parser Int
chain op p acc =
  (do f <- op
      x <- p
      chain op p (f acc x))
  <|> return acc
```

`chain` takes an operator parser, an operand parser, and an accumulator. It
tries to consume one more `(op, operand)` pair, folds it into `acc`, and
recurses. When no more operators are available, it returns the accumulated
result. Left-associativity emerges from the accumulator pattern: `1-2-3` becomes
`(1-2)-3 = -4`, not `1-(2-3) = 2`.

## Building the Parser — Raw Style

Here's the full calculator using explicit `>>=` and `>>`. No do notation.

```haskell
chainRaw :: Parser (Int -> Int -> Int) -> Parser Int -> Int -> Parser Int
chainRaw op p acc =
  (op >>= \f -> p >>= \x -> chainRaw op p (f acc x))
  <|> return acc

factorRaw :: Parser Int
factorRaw =
  natural <|>
  (char '(' >> exprRaw >>= \e -> char ')' >> return e)

termRaw :: Parser Int
termRaw = factorRaw >>= chainRaw mulOp factorRaw

exprRaw :: Parser Int
exprRaw = termRaw >>= chainRaw addOp termRaw
```

It's not unreadable, but `factorRaw` is starting to feel like you're solving a
puzzle. The `>>` and `>>=` arrows are doing a lot, the parentheses are load-bearing,
and you have to hold the threading in your head. Now look at the same logic in
do notation.

## Building the Parser — Do Notation Style

```haskell
factor :: Parser Int
factor = natural <|> do
  _ <- char '('
  e <- expr
  _ <- char ')'
  return e

term :: Parser Int
term = do
  f <- factor
  chain mulOp factor f

expr :: Parser Int
expr = do
  t <- term
  chain addOp term t
```

The structure is identical. The logic is the same. But now each line reads as a
sentence: "parse an opening paren, parse an expression, parse a closing paren,
return the expression." The do notation doesn't add power — the monad already
gave us that — it adds *legibility*.

Running it:

```
Expression          do-style      raw style
----------------------------------------------
1+2*3               7             7
10-4/2              8             8
(1+2)*3             9             9
42                  42            42
2*(3+4*(5-1))       38            38
```

Both styles agree on every test case. They're the same parser.

## The Bridge to Bluespec

Here's why I made you build all this.

`Parser a` is structurally identical to Bluespec's `ActionValue#(a)`:

| Haskell           | Bluespec                  |
|-------------------|---------------------------|
| `Parser a`        | `ActionValue#(a)`         |
| `Action` (no val) | `Action`                  |
| `do` block        | rule body / action block  |
| `>>=`             | `<-` in an action         |
| `return x`        | `return x`                |
| "consumes input"  | "modifies hardware state" |

A `Parser` threads an implicit string through a sequence of steps. An `Action`
in Bluespec threads an implicit hardware state through a sequence of atomic
operations. The `do` block you write in a Bluespec rule is doing the same
structural thing as the `do` block in our `expr` parser: chaining operations
that each hand off their "remaining context" to the next step.

The monad is the design pattern for *computation that threads some implicit
state*. Parsers thread remaining input. Actions thread hardware state.
`ActionValue#(a)` is Bluespec's way of saying "an action that, when it fires,
produces a value of type `a`" — exactly what `Parser a` says about consuming
input.

When you write a Bluespec rule that looks like:

```bluespec
rule doSomething;
  let x <- fifo.first;
  fifo.deq;
  reg <= x + 1;
endrule
```

the `<-` is `>>=`. The rule body is a `do` block. The monad is doing the
bookkeeping. You now know what that means.
