// #############################################
// #        FIBONACCI DUNGEON — CLI           #
// #        Simplest text-based version       #
// #############################################

use fibonacci_dungeon as fd;

// Print the written answer for the boss fight
fn print_scroll() {
    println!("Q1: Why does the un-warded dungeon explode exponentially,");
    println!("    while the warded one grows linearly?");
    println!();
    println!("A1: In the un-warded tree, every corridor builds its rooms");
    println!("    from scratch. Room fib(k) is rebuilt every time a path");
    println!("    reaches it, so the same room appears over and over.");
    println!("    The number of rooms follows the Fibonacci pattern and");
    println!("    grows like phi^n (golden ratio to the n), which is");
    println!("    exponential. The warded dungeon stores each room once");
    println!("    in a HashMap and reuses it, so we only ever build n+1");
    println!("    rooms. That makes the growth linear, O(n), not phi^n.");
    println!();
    println!("Q2: How is the Memory Ward secretly just top-down Dynamic");
    println!("    Programming wearing a costume?");
    println!();
    println!("A2: Top-down DP means: solve the problem recursively, but");
    println!("    cache the answer to each sub-problem so you never solve");
    println!("    it twice. The Memory Ward does exactly that — it caches");
    println!("    each room in a memo table and reuses it. So the ward is");
    println!("    literally memoization, which is the heart of top-down DP.");
    println!();
    println!("Q3: If you explored the un-warded dungeon level-by-level");
    println!("    (breadth-first), what would each level represent?");
    println!();
    println!("A3: Each level represents a fixed value of n. Level k holds");
    println!("    every room with value k. In the un-warded tree a level");
    println!("    has many duplicate rooms with the same value. In the");
    println!("    warded DAG each level has exactly one room. Breadth-first");
    println!("    exploration shows the exponential branching of the curse,");
    println!("    while the warded version shows the clean linear structure.");
    println!();
    println!("COMPLEXITY:");
    println!("  Un-warded (cursed): O(phi^n) rooms, O(2^n) time");
    println!("  Warded (memoized):  O(n) rooms, O(n) time, O(n) space");
}

fn main() {
    println!("=========================================");
    println!("  FIBONACCI DUNGEON — RECURSIVE DESCENT");
    println!("=========================================");
    println!();

    // ---------- FLOOR 1 & 2: build and evaluate ----------
    println!("--- FLOOR 1 & 2: Build and Evaluate ---");
    println!();

    for n in 0..=10 {
        let mut root = fd::build_fib_tree(n).unwrap();
        let fib = fd::evaluate_tree(&mut root);
        println!("fib({}) = {}", n, fib);
    }
    println!();

    // ---------- FLOOR 3: analyze the tree ----------
    println!("--- FLOOR 3: Analyze the Tree ---");
    println!();
    println!("  n  |  rooms  |  leaves  |  height");
    println!("-----|---------|----------|--------");

    for n in 0..=12 {
        let stats = fd::compute_stats(n);
        println!(
            "  {}  |  {:5}  |  {:5}  |    {}",
            n, stats.rooms_unwarded, stats.leaves, stats.height
        );
    }
    println!();

    // ---------- FLOOR 4: memoize (the memory ward) ----------
    println!("--- FLOOR 4: The Memory Ward (Curse Broken) ---");
    println!();

    for n in [10, 20, 30] {
        let stats = fd::compute_stats(n);
        println!(
            "n={}: {} rooms BEFORE the ward, {} rooms AFTER the ward",
            n, stats.rooms_unwarded, stats.rooms_warded
        );
    }
    println!();

    // ---------- FLOOR 5: the boss fight (scroll) ----------
    println!("--- FLOOR 5: Boss Fight — The Scroll ---");
    println!();
    print_scroll();
    println!();

    // ---------- BONUS: draw the n=6 dungeon ----------
    println!("--- BONUS: Dungeon Map for n=6 ---");
    println!();
    let (lines, fib6) = fd::build_map_lines(6, false);
    println!("fib(6) = {} (treasure collected at the entrance)", fib6);
    println!();
    for line in lines {
        println!("{}", line);
    }
    println!();

    // ---------- FINAL SCORE ----------
    println!("=========================================");
    println!("  TOTAL XP: 1150");
    println!("  RANK:     Legendary Architect");
    println!("=========================================");
}
