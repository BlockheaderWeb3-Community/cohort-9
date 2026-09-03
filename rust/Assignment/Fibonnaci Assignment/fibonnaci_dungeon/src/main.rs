//! 🌲 The Fibonacci Dungeon — A Recursive Descent Quest
//!
//! Run with `cargo run` to walk all four floors plus the bonus vault.
//! The written Boss Fight trial (Part 5) lives in BOSS_FIGHT.md.
//!
//! Everything lives in this one file on purpose — the dungeon is small
//! enough that splitting it into modules just adds ceremony.

use std::collections::{HashMap, HashSet};
use std::rc::Rc;

// ---------------------------------------------------------------------
// Floor 1 — The Spawning Chamber (Part 1: build the recursive tree)
// ---------------------------------------------------------------------

/// A single room in the dungeon.
struct Node {
    value: u64,
    left: Option<Box<Node>>,
    right: Option<Box<Node>>,
    result: Option<u64>,
}

impl Node {
    fn leaf(value: u64) -> Self {
        Node { value, left: None, right: None, result: None }
    }
}

/// Recursively spawns the dungeon for depth `n`. Rooms 0 and 1 are sealed
/// chambers (leaves, dead ends). Every other room `n` opens a left corridor
/// to room `n-1` and a right corridor to room `n-2`.
fn build_fib_tree(n: u64) -> Node {
    if n == 0 || n == 1 {
        return Node::leaf(n);
    }
    let left = build_fib_tree(n - 1);
    let right = build_fib_tree(n - 2);
    Node { value: n, left: Some(Box::new(left)), right: Some(Box::new(right)), result: None }
}

// ---------------------------------------------------------------------
// Floor 2 — The Descent (Part 2: post-order evaluation)
// ---------------------------------------------------------------------

/// Walks the dungeon post-order (both corridors before the room itself),
/// filling in `result` at every room. Returns the treasure collected in
/// `node`. Rule of the dungeon: no Binet's-formula shortcuts — this is a
/// genuine traversal, so the gold really is earned by walking the rooms.
fn evaluate_tree(node: &mut Node) -> u64 {
    let treasure = match (node.left.as_deref_mut(), node.right.as_deref_mut()) {
        (None, None) => if node.value == 0 { 0 } else { 1 },
        (Some(left), Some(right)) => evaluate_tree(left) + evaluate_tree(right),
        _ => unreachable!("a room always has zero or two corridors"),
    };
    node.result = Some(treasure);
    treasure
}

// ---------------------------------------------------------------------
// Floor 3 — The Cartographer's Trial (Part 3: structural analysis)
// ---------------------------------------------------------------------

/// Survey report: (total rooms, sealed chambers, dungeon depth/height).
fn analyze_tree(node: &Node) -> (u64, u64, u64) {
    match (node.left.as_deref(), node.right.as_deref()) {
        (None, None) => (1, 1, 0),
        (Some(left), Some(right)) => {
            let (lt, ll, ld) = analyze_tree(left);
            let (rt, rl, rd) = analyze_tree(right);
            (1 + lt + rt, ll + rl, 1 + ld.max(rd))
        }
        _ => unreachable!("a room always has zero or two corridors"),
    }
}

/// Standard Fibonacci, F(0)=0, F(1)=1, computed iteratively. Structural
/// bookkeeping for the survey, not the dungeon's treasure (that stays
/// banned from closed-form shortcuts on Floor 2).
fn fib(n: u64) -> u64 {
    let (mut a, mut b) = (0u64, 1u64);
    for _ in 0..n {
        let next = a + b;
        a = b;
        b = next;
    }
    a
}

fn predicted_total_rooms(n: u64) -> u64 {
    2 * fib(n + 1) - 1
}

fn predicted_sealed_chambers(n: u64) -> u64 {
    fib(n + 1)
}

fn predicted_depth(n: u64) -> u64 {
    if n == 0 { 0 } else { n - 1 }
}

/// Counts how many rooms carry `target`'s value anywhere in the dungeon —
/// used to demonstrate the redundancy the Memory Ward fixes.
fn count_value_occurrences(node: &Node, target: u64) -> u64 {
    let here = u64::from(node.value == target);
    let l = node.left.as_deref().map_or(0, |l| count_value_occurrences(l, target));
    let r = node.right.as_deref().map_or(0, |r| count_value_occurrences(r, target));
    here + l + r
}

const SCROLL: &str = r#"
📜 The Cartographer's Scroll — Room-Count Derivation
=====================================================

Let N(n) be the number of rooms in the dungeon of depth n (sealed and open
together). Rooms 0 and 1 are single sealed chambers:

    N(0) = 1
    N(1) = 1

Every other room n opens exactly two corridors, to rooms n-1 and n-2, plus
itself:

    N(n) = 1 + N(n-1) + N(n-2)      for n >= 2

Because every room has either 0 or 2 corridors (never 1), the dungeon is a
*full* binary tree. In any full binary tree, internal nodes I and leaves L
satisfy I = L - 1, so total nodes N = I + L = 2L - 1.

The leaves are exactly the sealed chambers reached by the recursion, and by
induction their count follows the ordinary Fibonacci recurrence
L(n) = L(n-1) + L(n-2) with L(0) = L(1) = 1, which gives:

    L(n) = F(n+1)        (F = standard Fibonacci, F(0)=0, F(1)=1)

Therefore:

    N(n) = 2*F(n+1) - 1

Dungeon depth (height) H(n): the left corridor (n-1) is always at least as
deep as the right (n-2), so H(n) = 1 + H(n-1), with H(0) = H(1) = 0, giving:

    H(n) = n - 1     for n >= 1,   H(0) = 0

Why O(phi^n)? Binet's formula gives F(n) = (phi^n - psi^n) / sqrt(5), where
phi = (1+sqrt(5))/2 ~ 1.618 is the golden ratio and |psi| < 1, so
F(n) = Theta(phi^n). Since N(n) = 2*F(n+1) - 1, the room count — and thus
the number of recursive calls build_fib_tree/evaluate_tree make — grows at
exactly the same golden-ratio rate as the treasure value itself: O(phi^n).
"#;

// ---------------------------------------------------------------------
// Floor 4 — The Memory Ward (Part 4: memoize the tree into a DAG)
// ---------------------------------------------------------------------

/// A warded room. Two different corridors are allowed to point at the
/// same `Rc<WardedRoom>` — that's what turns the tree into a DAG.
struct WardedRoom {
    value: u64,
    left: Option<Rc<WardedRoom>>,
    right: Option<Rc<WardedRoom>>,
    result: u64,
}

/// The ward: a spellbook mapping a room's value to the one true instance
/// of that room, built the first time it's needed.
type Ward = HashMap<u64, Rc<WardedRoom>>;

/// Casts the Memory Ward: builds AND evaluates room `n` at most once ever.
/// Any later corridor that would lead to a room already in the ward links
/// back to that original `Rc` instead of reconstructing it from scratch.
/// This is our own spell — a plain `HashMap` cache, no memoization crate.
fn cast_memory_ward(n: u64, ward: &mut Ward) -> Rc<WardedRoom> {
    if let Some(existing) = ward.get(&n) {
        return Rc::clone(existing);
    }
    let room = if n == 0 || n == 1 {
        Rc::new(WardedRoom { value: n, left: None, right: None, result: if n == 0 { 0 } else { 1 } })
    } else {
        let left = cast_memory_ward(n - 1, ward);
        let right = cast_memory_ward(n - 2, ward);
        let result = left.result + right.result;
        Rc::new(WardedRoom { value: n, left: Some(left), right: Some(right), result })
    };
    ward.insert(n, Rc::clone(&room));
    room
}

/// Proves the tree really became a DAG: walks from `root` and returns every
/// room reachable by more than one corridor, checked by `Rc` pointer
/// identity (the literal same room in memory, not just an equal value).
fn find_shared_rooms(root: &Rc<WardedRoom>) -> Vec<u64> {
    let mut seen_ptrs: Vec<*const WardedRoom> = Vec::new();
    let mut shared = Vec::new();
    let mut stack = vec![Rc::clone(root)];
    while let Some(room) = stack.pop() {
        let ptr = Rc::as_ptr(&room);
        if seen_ptrs.contains(&ptr) {
            continue;
        }
        seen_ptrs.push(ptr);
        // >2 because `room` itself plus the ward's own cache entry are
        // always at least 1 each; a genuinely shared room has parents too.
        if Rc::strong_count(&room) > 2 {
            shared.push(room.value);
        }
        if let Some(left) = &room.left {
            stack.push(Rc::clone(left));
        }
        if let Some(right) = &room.right {
            stack.push(Rc::clone(right));
        }
    }
    shared.sort_unstable();
    shared.dedup();
    shared
}

/// Counts rooms in the *un-warded* (cursed) dungeon by genuine recursive
/// descent, without materializing a full `Node` tree in memory, so it stays
/// cheap enough to run out to n=30 while still paying the real exponential
/// call cost.
fn count_cursed_rooms(n: u64) -> u64 {
    if n == 0 || n == 1 {
        return 1;
    }
    1 + count_cursed_rooms(n - 1) + count_cursed_rooms(n - 2)
}

// ---------------------------------------------------------------------
// Bonus Vault — map n=6, gold-highlighting duplicates, plus Graphviz
// ---------------------------------------------------------------------

/// Prints an indented-text map of the dungeon (depth-first, root first).
/// The first room to carry a given value prints plain; every later room
/// carrying a value already seen is marked gold — exactly the rooms the
/// Memory Ward will collapse into one shared node.
fn print_map(node: &Node, prefix: &str, is_last: bool, is_root: bool, seen: &mut HashSet<u64>) {
    let branch = if is_root { "" } else if is_last { "└── " } else { "├── " };
    let duplicate = !seen.insert(node.value);
    let tag = if duplicate { " 🟡 GOLD (duplicate — would be shared after the ward)" } else { "" };
    println!("{prefix}{branch}Room {}{tag}", node.value);

    let new_prefix = if is_root {
        String::new()
    } else if is_last {
        format!("{prefix}    ")
    } else {
        format!("{prefix}│   ")
    };

    let children: Vec<&Node> = [node.left.as_deref(), node.right.as_deref()].into_iter().flatten().collect();
    let last_index = children.len().saturating_sub(1);
    for (i, child) in children.iter().enumerate() {
        print_map(child, &new_prefix, i == last_index, false, seen);
    }
}

/// Emits a Graphviz `.dot` description of the dungeon, coloring duplicate
/// rooms (by the same first-seen rule as `print_map`) gold.
fn to_graphviz(root: &Node) -> String {
    let mut out = String::from("digraph FibonacciDungeon {\n  node [shape=circle, fontname=\"monospace\"];\n");
    let mut seen = HashSet::new();
    let mut counter = 0u64;
    write_graphviz(root, &mut out, &mut seen, &mut counter);
    out.push_str("}\n");
    out
}

fn write_graphviz(node: &Node, out: &mut String, seen: &mut HashSet<u64>, counter: &mut u64) -> u64 {
    let id = *counter;
    *counter += 1;
    let duplicate = !seen.insert(node.value);
    let style = if duplicate { "style=filled, fillcolor=gold" } else { "style=filled, fillcolor=white" };
    out.push_str(&format!("  n{id} [label=\"{}\", {style}];\n", node.value));

    if let Some(left) = node.left.as_deref() {
        let lid = write_graphviz(left, out, seen, counter);
        out.push_str(&format!("  n{id} -> n{lid} [label=\"L\"];\n"));
    }
    if let Some(right) = node.right.as_deref() {
        let rid = write_graphviz(right, out, seen, counter);
        out.push_str(&format!("  n{id} -> n{rid} [label=\"R\"];\n"));
    }
    id
}

// ---------------------------------------------------------------------
// Orchestration
// ---------------------------------------------------------------------

fn main() {
    floor1_and_2();
    floor3();
    floor4();
    bonus_vault_demo();
}

fn floor1_and_2() {
    println!("🌲 FLOOR 1 — The Spawning Chamber");
    println!("=================================");
    let n = 10;
    let mut root = build_fib_tree(n);
    println!("Built the dungeon for depth n={n}. Entrance room value: {}", root.value);

    println!("\n⚔️  FLOOR 2 — The Descent");
    println!("=========================");
    let treasure = evaluate_tree(&mut root);
    let expected = fib(n);
    println!("Treasure collected walking back to the entrance: {treasure} gold");
    println!("fib({n}) via the textbook recurrence: {expected}");
    assert_eq!(treasure, expected, "the dungeon lied about its gold");
    println!("✅ root.result matches fib({n}) exactly — no shortcuts taken.");
}

fn floor3() {
    println!("\n🧭 FLOOR 3 — The Cartographer's Trial");
    println!("======================================");
    println!(
        "{:>3} | {:>10} {:>10} | {:>10} {:>10} | {:>8} {:>8}",
        "n", "rooms", "(predicted)", "sealed", "(predicted)", "depth", "(pred.)"
    );
    for n in [5, 10, 15, 20] {
        let root = build_fib_tree(n);
        let (rooms, sealed, depth) = analyze_tree(&root);
        println!(
            "{:>3} | {:>10} {:>10} | {:>10} {:>10} | {:>8} {:>8}",
            n, rooms, predicted_total_rooms(n), sealed, predicted_sealed_chambers(n), depth, predicted_depth(n)
        );
        assert_eq!(rooms, predicted_total_rooms(n));
        assert_eq!(sealed, predicted_sealed_chambers(n));
        assert_eq!(depth, predicted_depth(n));
    }

    println!("\nBoss taunt check — how many times does Room 5 get rebuilt?");
    for n in [8, 10, 12, 14] {
        let root = build_fib_tree(n);
        let count = count_value_occurrences(&root, 5);
        println!("  depth n={n:>2}: Room 5 appears {count:>3} times");
    }

    println!("{SCROLL}");
}

fn floor4() {
    println!("\n🔮 FLOOR 4 — The Memory Ward");
    println!("=============================");
    println!("{:>4} | {:>16} | {:>16}", "n", "rooms (cursed)", "rooms (warded)");
    for n in [10u64, 20, 30] {
        let cursed = count_cursed_rooms(n);
        let mut ward: Ward = Ward::new();
        let warded_root = cast_memory_ward(n, &mut ward);
        let warded = ward.len();
        println!("{:>4} | {:>16} | {:>16}", n, cursed, warded);
        assert_eq!(warded_root.result, fib(n), "the ward computed the wrong treasure");
        assert_eq!(warded as u64, n + 1, "the ward should hold exactly n+1 distinct rooms");
    }
    println!(
        "\nCursed growth is O(phi^n) — exponential, matching Floor 3's N(n) = 2*F(n+1)-1.\n\
Warded growth is O(n) — linear, since each distinct room value 0..=n is\n\
built and evaluated exactly once, so |ward| = n + 1 for n >= 2."
    );

    let mut small_ward: Ward = Ward::new();
    let small_root = cast_memory_ward(6, &mut small_ward);
    let shared = find_shared_rooms(&small_root);
    println!(
        "\nProof it's a real DAG (n=6): rooms reached by more than one corridor\n\
(same Rc, not just an equal value): {shared:?}"
    );
}

fn bonus_vault_demo() {
    println!("\n💎 BONUS VAULT — Dungeon Map for n=6");
    println!("======================================");
    let root = build_fib_tree(6);
    let mut seen = HashSet::new();
    print_map(&root, "", true, true, &mut seen);

    println!("\nGraphviz export (paste into https://dreampuf.github.io/GraphvizOnline/ or `dot`):\n");
    println!("{}", to_graphviz(&root));
}

// ---------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn floor1_leaves_are_sealed_with_no_corridors() {
        let zero = build_fib_tree(0);
        assert_eq!(zero.value, 0);
        assert!(zero.left.is_none() && zero.right.is_none());

        let one = build_fib_tree(1);
        assert_eq!(one.value, 1);
        assert!(one.left.is_none() && one.right.is_none());
    }

    #[test]
    fn floor2_treasure_matches_fib_for_many_n() {
        for n in 0..=25 {
            let mut root = build_fib_tree(n);
            let treasure = evaluate_tree(&mut root);
            assert_eq!(treasure, fib(n), "mismatch at n={n}");
            assert_eq!(root.result, Some(treasure));
        }
    }

    #[test]
    fn floor3_survey_matches_formulas() {
        for n in 0..=20 {
            let root = build_fib_tree(n);
            let (rooms, sealed, depth) = analyze_tree(&root);
            assert_eq!(rooms, predicted_total_rooms(n), "rooms mismatch at n={n}");
            assert_eq!(sealed, predicted_sealed_chambers(n), "sealed mismatch at n={n}");
            assert_eq!(depth, predicted_depth(n), "depth mismatch at n={n}");
        }
    }

    #[test]
    fn floor4_ward_is_correct_and_linear() {
        for n in [0u64, 1, 2, 5, 10, 20, 30] {
            let mut ward: Ward = Ward::new();
            let root = cast_memory_ward(n, &mut ward);
            assert_eq!(root.result, fib(n), "ward gave wrong treasure at n={n}");
            // For n<=1 the requested room *is* the base case, so recursion
            // never touches the other base value and the ward holds just
            // that one room. From n=2 on, reaching room n always requires
            // walking down to both 0 and 1, so every value in 0..=n gets
            // cached exactly once: |ward| = n + 1.
            let expected = if n <= 1 { 1 } else { n + 1 };
            assert_eq!(ward.len() as u64, expected, "unexpected ward size at n={n}");
        }
    }

    #[test]
    fn bonus_vault_flags_every_repeated_value_as_duplicate() {
        let root = build_fib_tree(6);
        let mut seen = HashSet::new();
        let mut first_seen = HashSet::new();
        let mut stack = vec![&root];
        while let Some(node) = stack.pop() {
            if !first_seen.insert(node.value) {
                seen.insert(node.value);
            }
            if let Some(r) = node.right.as_deref() {
                stack.push(r);
            }
            if let Some(l) = node.left.as_deref() {
                stack.push(l);
            }
        }
        for v in 0..=4 {
            assert!(seen.contains(&v), "value {v} should repeat in an n=6 dungeon");
        }
    }
}
