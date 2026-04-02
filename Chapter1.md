# Setting the Stage For Bluespec
The core insight of Bluespec is that chips are essentially distributed systems
like bank or business databases except much tinier. Banks and business
have many geographically distinct branches that independently perform their
own operations and must periodically sync accounts and records. Likewise,
chips have many different functional units that operate independently and
must periodically converge on an agreed upon shared state.

Really bad things can happen when distributed systems fail to coordinate
their operations correctly. Next, we consider such an example:

## Potentially Unsafe Emergent Behavior in Distributed Systems

Consider a bank with 13 branches, each maintaining a local copy of account balances. You have $1,000 in your account, and you can walk into any branch and withdraw it.
What's stopping you from visiting all 13 branches in sequence and withdrawing $1,000 from each?
As far as each branch is aware when you walk in, your balance is $1,000. If branches don't coordinate, you could walk away with $13,000. This class of bug is called a double-spend (or, by analogy to memory safety, a double-free) error. Systems like banks simply cannot tolerate it.
This is an instance of a coherence problem — a class of problems that arise whenever multiple nodes in a distributed system each hold a local view of shared state, and those views can diverge.

## Solutions To Divergent Behavior

There are entire branches of mathematics dedicated to modeling computation and
how comptuations can evolve over time. Within these mathematical frameworks,
we can do such things as:

1. Define systems of equations that let us represent different parts
   of our distributed system such as account balances at each bank branch. 
2. We can define what it means to withdraw money, deposit money, and get
   the currently available balance.
3. We can also define invariants that must hold such as the balance of an account 
   when queried at time `t` at any given branch must always evaluate to the sum of the deposits minus the sum of the withdrawls up to time `t`
4. Use axioms provided by the framework to derive transformations that allow
   us to prove our invariants hold or don't across time

We're not going to go into the mechanics of how these things are done, but suffice
it to say it can be done. The name of the fields that emerged to solve these
problems are collectively referred to as logic systems, calculi(when talking about
computability more broadly) and process calculi when time is involved.

Process calculi that deal with distrubted systems often employ message passing
to enable communication between processes and atomic actions to reason about
transitions between process states in a system. One such process calculus that
did this was called Temporal Logic of Actions, upon which Bluespec is based.


# Footnotes - A Possible Solution to Bank Consensus:


A natural fix for `withdraw` is to require that before any branch commits a withdrawal, it must consult a **majority** of all branches — specifically, more than half:

$$\text{quorum} = \lfloor 13/2 \rfloor + 1 = 7$$

If at least 7 out of 13 branches agree on the current balance *and* the new balance, the withdrawal is safe to commit. Because no two majorities can be disjoint, any two quorums must share at least one branch — guaranteeing that the most recent committed transaction is always represented.

## What About the Other Operations?

We've handled `withdraw`. Two operations remain: `get_balance` and `deposit`.

**`get_balance`:** For a balance read to be up-to-date, the responding branch must have *witnessed* — directly or indirectly — every prior `withdraw` and `deposit`. Requiring a read quorum (again, a majority) guarantees that at least one branch in that quorum saw the most recent write.

**`deposit`:** Like `withdraw`, a deposit modifies shared state. It must also go through a write quorum to be safe.

## How Information Propagates

Any time a quorum is achieved, the agreed-upon value — the **consensus value** — must be adopted by all other available nodes. This is the mechanism by which writes propagate through the system: a majority agrees, and then the minority catches up. 

This simple invariant is surprisingly powerful. It is the seed of algorithms like **Paxos** and **Raft**. From what I understand, you can actually model Paxos in TLA+.
As I mentioned before, TLA+ inspired Bluespec.