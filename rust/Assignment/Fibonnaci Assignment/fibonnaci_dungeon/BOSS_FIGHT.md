# 👑 The Boss Fight — Written Trial by the Dungeon Master

*(Part 5 — no blade helps here, only understanding.)*

## 1. Why does the un-warded dungeon explode exponentially, while the warded one grows linearly?

The un-warded dungeon is a **tree**: every recursive call `build_fib_tree(k)` /
`evaluate_tree(k)` creates a brand-new room, even if a room with that exact
value `k` was already built somewhere else in the dungeon. Room `n-2` is not
just *similar to* the left child's right grandchild — it is rebuilt as an
entirely separate object. Floor 3 proved this count precisely:

```
N(n) = 2*F(n+1) - 1  =  O(phi^n),   phi = (1+sqrt(5))/2 ≈ 1.618
```

Each step down costs a constant amount of work but the number of *distinct
calls* still doubles-ish every couple of levels, because the same room value
is reachable by exponentially many different paths from the root (a path is
any sequence of "-1"/"-2" steps summing to `n - k`, and the number of such
paths is itself Fibonacci-shaped). Nothing is shared, so nothing is saved.

The warded dungeon is a **DAG**. The very first time room `k` is requested,
`cast_memory_ward` builds and evaluates it and stores the `Rc<WardedRoom>` in
the `Ward` (a `HashMap<u64, Rc<WardedRoom>>`). Every subsequent request for
room `k` — no matter how many different corridors lead there — finds the
entry already in the map and returns a cheap `Rc::clone` (a pointer-copy plus
a refcount bump) instead of recursing further. Since there are only `n + 1`
*distinct* room values (`0..=n`), the ward is populated exactly `n + 1`
times, and each population does O(1) work beyond the two (already-cached)
recursive lookups. Total work: **O(n)**, confirmed by the demo's table
(`rooms (warded)` column is exactly `n + 1` for `n = 10, 20, 30`).

The exponential blow-up was never inherent to Fibonacci — it was the cost of
refusing to remember an answer you already computed.

## 2. How is the Memory Ward secretly just top-down Dynamic Programming wearing a costume?

Top-down DP (a.k.a. memoized recursion) is exactly: *write the naive
recursive solution, but before recursing, check a cache keyed by the
subproblem's parameters; after computing a result, store it in that cache
before returning.* That is a literal, line-by-line description of
`cast_memory_ward`:

- The **cache** is the `Ward` (`HashMap<u64, Rc<WardedRoom>>`), keyed by
  room value `n` — the subproblem's only parameter.
- The **base cases** (`n == 0`, `n == 1`) are the DP's base cases.
- The **recurrence** `result = left.result + right.result` is the DP's
  transition, identical to `dp[n] = dp[n-1] + dp[n-2]`.
- The **cache check at the top** (`if let Some(existing) = ward.get(&n) {
  return Rc::clone(existing); }`) is precisely "if `dp[n]` is already
  computed, return it."
- The **cache write before returning** (`ward.insert(n, Rc::clone(&room))`)
  is `dp[n] = result`.

The only costume is that instead of storing a plain number in `dp[n]`, we
store a whole `Rc<WardedRoom>` — value, children, and result together — so
the memo table doubles as the DAG's node storage. Shared subtrees in the DAG
*are* memo-table hits; the DAG is just what a call graph looks like once you
draw an edge for every cache hit instead of silently discarding it.

## 3. If you explored the un-warded dungeon level-by-level (breadth-first) instead of depth-by-depth, what would each level represent?

Breadth-first search visits all rooms at distance `d` from the entrance
before any room at distance `d+1`. In this dungeon, "distance from the
entrance" is the number of corridors taken, i.e. the number of `-1`/`-2`
steps subtracted from `n` so far. So **level `d` is exactly the set of all
rooms reachable by paths of length `d`** — every room whose value equals `n`
minus some composition of `d` steps drawn from `{1, 2}`.

Concretely: level 0 is just `{n}` (the entrance). Level 1 is `{n-1, n-2}`
(left corridor, right corridor). Level 2 is the four two-step paths `LL, LR,
RL, RR`, giving values `{n-2, n-3, n-3, n-4}` — note `n-3` already shows up
twice, as two separate un-warded room instances, even this early. In
general, level `d` contains one room instance
for every composition of `d` into parts `1` and `2`, and the room's *value*
at that position is `n` minus the sum of the composition's parts used so far
along that particular path — so distinct paths of the same length `d` can
and do land on the same value.

Put differently: **level `d` is the `d`-th anti-diagonal of the call tree**,
and the multiset of values appearing at level `d` is the un-warded, still
fully-exploded version of "all the ways to spend `d` steps of size 1 or 2" —
the same compositions-of-`d` count (`fib(d+1)`) that Floor 3 used to explain
why Room 5 keeps reappearing. BFS doesn't fix any of the redundancy the
Memory Ward fixes — it just re-slices the same exponential tree by distance
from the root instead of by recursive call order. The ward's linear DAG,
by contrast, would BFS in exactly `n + 1` distinct levels — one per room
value — because merged nodes only get visited (and enqueued) once.

---

**Complexity summary**

| | Rooms built | Work per room | Total time | Total space |
|---|---|---|---|---|
| Cursed (un-warded) | `N(n) = 2F(n+1)-1` | O(1) | **O(phi^n)** | O(n) stack + O(phi^n) if materialized |
| Warded (memoized DAG) | `n + 1` | O(1) amortized | **O(n)** | **O(n)** (ward + DAG nodes) |
