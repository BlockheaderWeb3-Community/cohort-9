// #############################################
// #  FIBONACCI DUNGEON — SHARED GAME CORE     #
// #  Used by both the CLI and the GUI         #
// #############################################

use std::collections::HashMap;

// =====================================================================
// FLOOR 1 — Build the Tree
// =====================================================================

// A Node is one room in the dungeon.
// It has a value, a left room, a right room, and a result (empty for now).
#[derive(Clone)]
pub struct Node {
    pub value: i64,
    pub left: Option<Box<Node>>,
    pub right: Option<Box<Node>>,
    pub result: Option<i64>,
}

impl Node {
    // Make a sealed chamber (a leaf / dead-end room)
    pub fn sealed(value: i64) -> Node {
        Node {
            value,
            left: None,
            right: None,
            result: None,
        }
    }
}

// Build the full dungeon tree for depth n.
// Room n has two corridors: one to n-1 and one to n-2.
// Rooms 0 and 1 are sealed chambers with no corridors.
pub fn build_fib_tree(n: i64) -> Option<Box<Node>> {
    if n == 0 {
        return Some(Box::new(Node::sealed(0)));
    }
    if n == 1 {
        return Some(Box::new(Node::sealed(1)));
    }

    let left_room = build_fib_tree(n - 1);
    let right_room = build_fib_tree(n - 2);

    Some(Box::new(Node {
        value: n,
        left: left_room,
        right: right_room,
        result: None,
    }))
}

// =====================================================================
// FLOOR 2 — Evaluate the Tree (collect the treasure)
// =====================================================================

// Walk the dungeon in post-order (deepest chambers first).
// Sealed chamber 0 gives 0 gold, chamber 1 gives 1 gold.
// Every other room's treasure = left treasure + right treasure.
pub fn evaluate_tree(node: &mut Node) -> i64 {
    // Base case: sealed chamber
    if node.value == 0 {
        node.result = Some(0);
        return 0;
    }
    if node.value == 1 {
        node.result = Some(1);
        return 1;
    }

    // Regular room: sum the two corridors
    let left_value;
    let right_value;

    match &mut node.left {
        Some(left) => left_value = evaluate_tree(left),
        None => left_value = 0,
    }

    match &mut node.right {
        Some(right) => right_value = evaluate_tree(right),
        None => right_value = 0,
    }

    let total = left_value + right_value;
    node.result = Some(total);
    total
}

// =====================================================================
// FLOOR 3 — Analyze the Tree (count rooms, leaves, depth)
// =====================================================================

// Count every room in the tree
pub fn count_rooms(node: &Node) -> i64 {
    let mut count = 1;

    match &node.left {
        Some(left) => count += count_rooms(left),
        None => {}
    }

    match &node.right {
        Some(right) => count += count_rooms(right),
        None => {}
    }

    count
}

// Count the sealed chambers (leaves — rooms with no children)
pub fn count_leaves(node: &Node) -> i64 {
    if node.left.is_none() && node.right.is_none() {
        return 1;
    }

    let mut count = 0;

    if let Some(left) = &node.left {
        count += count_leaves(left);
    }
    if let Some(right) = &node.right {
        count += count_leaves(right);
    }

    count
}

// Find the height (longest path from entrance to a leaf)
pub fn tree_height(node: &Node) -> i64 {
    if node.left.is_none() && node.right.is_none() {
        return 1;
    }

    let mut left_height = 0;
    let mut right_height = 0;

    if let Some(left) = &node.left {
        left_height = tree_height(left);
    }
    if let Some(right) = &node.right {
        right_height = tree_height(right);
    }

    if left_height >= right_height {
        left_height + 1
    } else {
        right_height + 1
    }
}

// =====================================================================
// FLOOR 4 — The Memory Ward (memoization to make it a DAG)
// =====================================================================

// Same Node but stored in Rc so many parents can share one room.
use std::rc::Rc;

pub struct DagNode {
    pub value: i64,
    pub left: Option<Rc<DagNode>>,
    pub right: Option<Rc<DagNode>>,
}

// Build the dungeon as a DAG using memoization.
// Each unique room value is built once, then reused by all corridors.
pub fn build_fib_dag(n: i64, memo: &mut HashMap<i64, Rc<DagNode>>) -> Rc<DagNode> {
    if let Some(existing) = memo.get(&n) {
        return existing.clone();
    }

    let node;
    if n == 0 {
        node = DagNode { value: 0, left: None, right: None };
    } else if n == 1 {
        node = DagNode { value: 1, left: None, right: None };
    } else {
        let left_room = build_fib_dag(n - 1, memo);
        let right_room = build_fib_dag(n - 2, memo);
        node = DagNode { value: n, left: Some(left_room), right: Some(right_room) };
    }

    let link = Rc::new(node);
    memo.insert(n, link.clone());
    link
}

// Count the unique rooms in the DAG by walking it.
pub fn count_dag_rooms(node: &Rc<DagNode>) -> usize {
    let mut counted = HashMap::new();
    walk_and_count(node, &mut counted)
}

fn walk_and_count(node: &Rc<DagNode>, counted: &mut HashMap<i64, bool>) -> usize {
    let mut total = 0;

    if !counted.contains_key(&node.value) {
        counted.insert(node.value, true);
        total += 1;
    }

    if let Some(left) = &node.left {
        total += walk_and_count(left, counted);
    }
    if let Some(right) = &node.right {
        total += walk_and_count(right, counted);
    }

    total
}

// =====================================================================
// SHARED HELPERS FOR THE CLI AND GUI
// =====================================================================

// All the stats for a tree, packed into one struct for easy display.
#[derive(Clone, Copy, Debug)]
pub struct DungeonStats {
    pub n: i64,
    pub fib: i64,
    pub rooms_unwarded: i64,
    pub leaves: i64,
    pub height: i64,
    pub rooms_warded: i64,
}

// Compute everything for a given depth n in one call.
pub fn compute_stats(n: i64) -> DungeonStats {
    if n < 0 {
        return DungeonStats {
            n,
            fib: 0,
            rooms_unwarded: 0,
            leaves: 0,
            height: 0,
            rooms_warded: 0,
        };
    }

    let mut root = build_fib_tree(n).unwrap();
    let fib = evaluate_tree(&mut root);
    let rooms_unwarded = count_rooms(&root);
    let leaves = count_leaves(&root);
    let height = tree_height(&root);

    let mut memo = HashMap::new();
    let dag = build_fib_dag(n, &mut memo);
    let rooms_warded = count_dag_rooms(&dag) as i64;
    let _ = dag;

    DungeonStats {
        n,
        fib,
        rooms_unwarded,
        leaves,
        height,
        rooms_warded,
    }
}

// Turn the n=6 (or any n) tree into a list of map lines for drawing.
// We build from scratch so the GUI can render it with highlighted duplicates.
pub fn build_map_lines(n: i64, highlight_dups: bool) -> (Vec<String>, i64) {
    let mut root = build_fib_tree(n).unwrap();
    let fib = evaluate_tree(&mut root);

    let mut lines = Vec::new();
    let mut seen_values: Vec<i64> = Vec::new();
    draw_to_lines(&root, String::new(), false, highlight_dups, &mut seen_values, &mut lines);

    (lines, fib)
}

fn draw_to_lines(
    node: &Node,
    prefix: String,
    is_last: bool,
    highlight_dups: bool,
    seen_values: &mut Vec<i64>,
    lines: &mut Vec<String>,
) {
    let branch = if is_last { "└── " } else { "├── " };

    let mut label = String::new();
    if node.left.is_none() && node.right.is_none() {
        label.push_str(&format!("{} (sealed chamber)", node.value));
    } else {
        label.push_str(&format!("fib({}) -> {}", node.value, node.result.unwrap()));
    }

    // Mark duplicates when the ward is NOT active
    if highlight_dups && seen_values.contains(&node.value) {
        label.push_str("  [DUPLICATE]");
    }

    let is_duplicate = highlight_dups && seen_values.contains(&node.value);
    let line = if is_duplicate {
        format!("{}{}{}  ⚠️", prefix, branch, label)
    } else {
        format!("{}{}{}", prefix, branch, label)
    };
    lines.push(line);

    // Remember this value for duplicate detection (first occurrence wins)
    if !seen_values.contains(&node.value) {
        seen_values.push(node.value);
    }

    let child_prefix = format!("{}{}", prefix, if is_last { "    " } else { "│   " });

    if let Some(left) = &node.left {
        let is_left_last = node.right.is_none();
        draw_to_lines(left, child_prefix.clone(), is_left_last, highlight_dups, seen_values, lines);
    }
    if let Some(right) = &node.right {
        draw_to_lines(right, child_prefix, true, highlight_dups, seen_values, lines);
    }
}
