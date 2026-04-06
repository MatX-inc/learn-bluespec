# Learn Bluespec

Verilog engineers learning Haskell. Haskell engineers learning hardware.
Everybody emerges with superpowers. No exceptions.

## What is this?

A guided introduction to [Bluespec](https://github.com/B-Lang-org/bsc), a
hardware description language built on two big ideas:

1. Chips are tiny distributed systems, and distributed systems(of any size) need **atomic actions**
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
| [Chapter 4](chapter4.ipynb) | Complete | Parser combinators in Haskell — building a calculator parser from scratch |

## Running the notebooks

Chapters 4 and beyond are [IHaskell](https://github.com/gibiansky/IHaskell) Jupyter
notebooks. You can read them on GitHub without any setup. To run them interactively:

### Dependencies

- [Stack](https://docs.haskellstack.org/en/stable/) — Haskell build tool
- IHaskell — install via Stack (see the IHaskell README for one-time setup)
- Jupyter — `pip3 install jupyter nbconvert`

### Register the kernel (once)

```bash
export PATH="$PATH:$HOME/Library/Python/3.9/bin"   # or wherever pip3 installed jupyter
stack exec -- ihaskell install
```

### Open a notebook

```bash
export PATH="$PATH:$HOME/Library/Python/3.9/bin"
jupyter notebook chapter4.ipynb
```

### Execute a notebook non-interactively

```bash
export PATH="$PATH:$HOME/Library/Python/3.9/bin"
jupyter nbconvert --to notebook --execute chapter4.ipynb --output chapter4.ipynb
```

> **Note:** If `ihaskell install` was previously run with a `--stack` flag, re-run it
> without that flag — the flag prevents the kernel from starting under `nbconvert`.

## Prerequisites

No single background is assumed. You should have *one* of:

- Experience with a hardware description language (Verilog, VHDL, SystemVerilog)
- Experience with a typed functional language (Haskell, OCaml, Scala, Elm)
- Curiosity stubborn enough to compensate for either
