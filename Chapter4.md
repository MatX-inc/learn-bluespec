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
`NoParse` and the caller tries something else with the same string it started
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
data ParseResult a
  = NoParse
  | ParseOk { consumed :: a, remaining :: String }

data Parser a = Parser { runParser :: String -> ParseResult a }
```

We have two types. `ParseResult a` is what a parser hands back — either
`NoParse` (failure, nothing was recognized) or `ParseOk` with two named fields:
`consumed` is the structure that was recognized (a character, an integer, an
expression — whatever `a` is), and `remaining` is everything the parser didn't
touch, ready to be handed to the next parser. Think of it as the parser's
outgoing message: "here's what I understood, here's what I left for you."

`Parser a` wraps a function from an input string to a `ParseResult`. The `data`
wrapper is bookkeeping — it lets us attach typeclass instances to `Parser`
without Haskell confusing it with every other function of the same shape.
`runParser` unwraps it when we need the raw function.

That's the whole representation. Everything else is built on top.

> **Aside:** In real Haskell codebases you'll often see `newtype` used instead
> of `data` when there's a single constructor wrapping a single field. `newtype`
> carries a compiler guarantee that the wrapper is erased at runtime — zero
> overhead. For our purposes `data` works identically; the distinction only
> matters when you care about performance or laziness. Worth knowing when you
> encounter it.

## Primitive Parsers

Let's build the simplest possible parsers first.

```haskell
item :: Parser Char
item = Parser $ \input ->
  case input of
    []     -> NoParse
    (c:cs) -> ParseOk { consumed = c, remaining = cs }
```

Inside `item` we define an anonymous function that takes the input string.
That string is matched on two cases: the empty list `[]`, in which case we
return `NoParse` (nothing to consume, so the parse fails); and the non-empty
list, where Haskell's pattern syntax `(c:cs)` simultaneously destructures it
into the first character `c` and the rest of the string `cs`. We then wrap
those into a `ParseOk`: `c` is what we consumed, `cs` is what remains.

`item` is the only parser that directly touches the input string. Everything
else is built on top of it.

From `item` we can build `satisfy`, which consumes one character but only if it
passes a test:

```haskell
satisfy :: (Char -> Bool) -> Parser Char
satisfy p = do
  c <- item
  if p c then return c else Parser $ \_ -> NoParse
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
ParseOk {consumed = 'a', remaining = "bc"}

ghci> runParser digit "42xyz"
ParseOk {consumed = '4', remaining = "2xyz"}

ghci> runParser natural "123abc"
ParseOk {consumed = 123, remaining = "abc"}

ghci> runParser natural "abc"
NoParse
```

The field names make it easy to see what happened: `consumed` is what the
parser recognized, `remaining` is what it left for whoever comes next.
When the parse fails there's nothing to show — just `NoParse`.
That's how parsers chain — each one picks up where the last one stopped.

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
  fmap f p = Parser $ \input ->
    case runParser p input of
      NoParse                                  -> NoParse
      ParseOk { consumed = x, remaining = r } -> ParseOk { consumed = f x, remaining = r }
```

`fmap f p` runs `p` and inspects the result. If it's `NoParse`, failure
passes straight through. If it's `ParseOk`, `f` is applied to `consumed`
and `remaining` is left untouched. What `Functor` buys us: we can transform
what a parser *produces* without touching the parsing logic itself.

### Applicative — combining parsers

```haskell
instance Applicative Parser where
  pure x = Parser $ \input -> ParseOk { consumed = x, remaining = input }
  pf <*> px = Parser $ \input ->
    case runParser pf input of
      NoParse                                  -> NoParse
      ParseOk { consumed = f, remaining = r1 } ->
        case runParser px r1 of
          NoParse                                  -> NoParse
          ParseOk { consumed = x, remaining = r2 } -> ParseOk { consumed = f x, remaining = r2 }
```

`pure x` is a parser that always succeeds, returning `x` as `consumed` without
touching the input — `remaining` is the full input unchanged. Useful for
injecting a plain value at the end of a sequence.

`pf <*> px` runs `pf` first. If it fails, we're done — `NoParse` propagates
immediately. If it succeeds, we take its `remaining` and feed it into `px`.
If that also succeeds, we apply `f` (what `pf` consumed) to `x` (what `px`
consumed) and hand back the final `remaining`. Each `NoParse` branch makes
failure propagation explicit — there's no invisible machinery doing it for us.

### Monad — sequential parsing with choices

```haskell
instance Monad Parser where
  return = pure
  p >>= f = Parser $ \input ->
    case runParser p input of
      NoParse                                  -> NoParse
      ParseOk { consumed = x, remaining = r } -> runParser (f x) r
```

`>>=` (pronounced "bind") runs `p`, and if it fails, stops immediately with
`NoParse`. If it succeeds, `consumed` is handed to `f` to produce the *next*
parser, which then runs on `remaining`. What was recognized becomes the input
to the next decision; what was left over becomes the input to the next parser.
The key insight: `f` can decide what to parse next based on what was just
recognized. That's what makes `do` notation so natural for parsers — each `<-`
line is one `>>=`, passing its result forward.

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
    NoParse -> runParser q input
    result  -> result
```

Try `p` first. If it fails (`NoParse`), try `q` on the same input. If `p`
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
