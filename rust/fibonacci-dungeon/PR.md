# 🔢 Fibonacci Dungeon — Recursive Descent Quest

A complete implementation of the **Recursive Descent / Fibonacci Dungeon** challenge, written in Rust. It builds the Fibonacci recursion tree from scratch, evaluates it via post-order traversal, analyzes its exponential growth, then "breaks the curse" with memoization (turning the tree into a DAG) — ending with the written boss-fight essay.

## What's included

**`rust/fibonacci-dungeon/`** — a single Rust crate with a shared core + two app binaries:

- **`src/lib.rs`** — shared game engine used by both apps
- **`src/main.rs`** — CLI binary (`fibonacci_dungeon`)
- **`src/gui.rs`** — desktop GUI binary (`fibonacci_dungeon_gui`) built with **egui/eframe**

## The 5 floors (+ bonus)

| Floor | Task | XP |
|-------|------|----|
| **1** | `build_fib_tree(n)` — builds the recursion tree (rooms 0/1 are sealed leaves) | 300 |
| **2** | `evaluate_tree(node)` — post-order traversal collects treasure = `fib(n)` | 200 |
| **3** | Cartographer's survey — rooms / leaves / height + O(φⁿ) scroll | 200 |
| **4** | The Memory Ward — memoized DAG: each room built once (`Rc` + `HashMap`) | 200 |
| **5** | Boss fight essay — why memoization is top-down DP | 100 |
| **Bonus** | Indented dungeon map for n=6 | 150 |
| **Total** | | **1150 XP — Legendary Architect** |

## Key results

- `fib(30)` computed correctly without Binet's formula or loops
- Un-warded tree for n=30: **2,692,537 rooms** (exponential)
- Warded DAG for n=30: **31 rooms** (linear, O(n))
- ~86,000× reduction in room count

## The GUI

Interactive desktop app with three tabs:

- **🗺️ Map** — live dungeon tree with a "Curse" toggle that highlights duplicate rooms before the Memory Ward is cast
- **📊 Floors** — full survey + before/after ward comparison (adjustable depth n = 0–20)
- **📜 Boss** — the written trial essay

## Running it

```bash
cd rust/fibonacci-dungeon
cargo run --bin fibonacci_dungeon        # CLI (fast)
cargo run --bin fibonacci_dungeon_gui    # GUI (needs egui deps)
```

## Complexity notes

- **Cursed (un-warded):** O(φⁿ) rooms, O(2ⁿ) time
- **Warded (memoized):** O(n) rooms, O(n) time, O(n) space

No memoization decorators or libraries were used — the Memory Ward is implemented by hand.
