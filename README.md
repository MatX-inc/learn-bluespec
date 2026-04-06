# Learn Bluespec

Verilog engineers learning Haskell. Haskell engineers learning hardware.
Everybody emerges with superpowers. No exceptions.

## What is this?

A guided introduction to [Bluespec](https://github.com/B-Lang-org/bsc), a
hardware description language built on two big ideas:

1. Chips are distributed systems, and distributed systems need **atomic actions**
   to stay correct.
2. The right language for describing those actions is one with a serious type
   system — which is why Bluespec is built on Haskell.

If you know Verilog, you already think in hardware. This guide will give you the
language to express what you already know at a higher level. If you know Haskell,
you already think in types and abstractions. This guide will give you the hardware
intuitions to make those abstractions mean something on silicon. Either way, you
are closer than you think.

## Chapters

| Chapter | Status | Topic |
|---------|--------|-------|
| [Chapter 1](Chapter1.md) | Complete | Chips as distributed systems, coherence problems, atomic actions, Bluespec's TRS foundation |
| [Chapter 2](Chapter2.md) | In progress | Bluespec's message-passing primitives; circuit design as functional programming |
| Chapter 3 | Not started | Introduction to Haskell |
| [Chapter 4](Chapter4.md) | Complete | Parser combinators in Haskell; the monad bridge to Bluespec's `Action` type |

## Running the code

Chapter 4 has runnable Haskell. You'll need GHC installed.

```
cd chapter4
make run
```

## Prerequisites

No single background is assumed. You should have *one* of:

- Experience with a hardware description language (Verilog, VHDL, SystemVerilog)
- Experience with a typed functional language (Haskell, OCaml, Scala, Elm)
- Curiosity stubborn enough to compensate for either
