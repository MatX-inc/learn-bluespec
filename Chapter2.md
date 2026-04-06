# What Bluespec Does

As I mentioned earlier, two important considerations emerge when 
reasoning about distributed systems, namely, message passing and 
atomic actions. When I talk about atomicity, I mean that interactions
with a system are restricted such that an interaction either fully took
place or didn't take place at all. Atomicity is extremely important,
more on this later.

Message passing is simply propagating information. Bluespec takes
message passing very seriously and has two fundamental primitives
for message passing, Register and Wires. They are a bit different from
what you might consider a Register or Wire in Verilog. They have
extremely formal mathematical definitions which 
[this paper](https://adam.chlipala.net/papers/KoikaPLDI20/KoikaPLDI20.pdf)
touches on.

You don't need to worry about the mathematical definition of Reg and Wire.
You'll build an intuition for them as you get more exposure to Bluespec.

Bluespec also provides for latency absorbing message passing with FIFOs.

I think there's probably a connection to be made between message passing
in Rust between threads using `mpsc` and message passing in Bluespec using
FIFOs - but I haven't thought through this too deeply.

# Bluespec Haskell and Its Type System

So far, we've dealt with the fact that Bluespec allows you to run 
concurrent processes that update atomically and can communicate via
message passing, but we've said nothing of how we actually describe
and eventually create these processes.

We could describe these processes in english. Consider:

```
A line at the DMV holds people

Process 1:
  Any time a new person arrives, and the line isn't full, have person join the back of the line

Process 2:
  Any time there is a person at the front of the line, give them a car
  registration tag and de-queue them from the line.
```

TODO: talk about / motivate rigor of type system but divorce from 
bluespec's scheduling and message passing semantics which benefits from
but is not couple to the type system.

---

# Rough notes — to be expanded

**Circuit design is functional programming.** If you've been writing Verilog,
you've been doing functional programming all along — you just didn't have that
framing available to you.

Think about what combinational logic actually is. You have inputs, you have
outputs, and you have a transformation between them. A wire doesn't "remember"
anything — it carries a value that is a pure function of its inputs right now.
Feed the same inputs, get the same outputs, always. That is the definition of a
pure function. Verilog engineers reason about this constantly; they just
describe it with a different vocabulary.

Where Verilog and Haskell diverge is in how much of that reasoning the language
lets you *express*. Verilog's great strength is that it maps closely to the
physical artifact — wires, gates, flip-flops. That closeness is genuinely
useful. It means a Verilog engineer always has a mental model of what silicon
their code corresponds to, which is not a skill to undervalue. The tradeoff is
that Verilog's abstraction tools are limited. Parameterization is clunky,
type-level guarantees are minimal, and reusing logic across different contexts
often means copy-pasting and hoping nothing diverges.

Haskell gives you a much richer set of abstraction tools: parametric types,
typeclasses, compile-time invariants, higher-order functions. Two different
hardware languages have taken this idea seriously, but in meaningfully different
ways, and it's worth understanding the distinction.

Clash is the more direct approach. It identifies a synthesizable subset of
Haskell — circuits are modeled as functions over infinite lists of values
sampled at each clock tick — and compiles that subset straight to hardware.
The semantics live entirely in Haskell. If you can write it in that fragment
of the language, Clash can turn it into gates.

Bluespec is something different. It uses Haskell as a host language for what
is essentially a DSL. You build up a graph of primitives using types and
monads that Haskell's type system constrains and checks — but the full meaning
of those primitives isn't defined in Haskell. The atomic-action semantics, the
scheduling, the rule-firing logic: those live in the Bluespec compiler toolchain
itself. Haskell enforces the structure; the compiler supplies the interpretation.
This is why you can write Bluespec that looks like Haskell and type-checks like
Haskell, but does things that have no equivalent in ordinary Haskell execution.

All of this leads us to a couple interesting conclusions:
1. The Haskell engineer can ramp onto Bluespec quickly because they
already think in the abstractions Bluespec is built from.
2. A Verilog engineer can ramp onto Bluespec too — which is exactly what this guide
is for — because they already understand the hardware intuitions that tell you whether the abstractions are producing *good* hardware.

Both sides have something the other is still building. That's a 
good position to be in.