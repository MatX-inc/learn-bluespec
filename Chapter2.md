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