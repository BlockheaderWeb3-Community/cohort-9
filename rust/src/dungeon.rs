use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;

pub struct Node {
    pub value: u32,
    pub left: Option<Rc<Node>>,
    pub right: Option<Rc<Node>>,
    // RefCell lets us write into `result` later even though the node may
    // now be shared (owned jointly by more than one parent, via Rc) -
    // normally Rust won't let you mutate something you don't uniquely own.
    pub result: RefCell<Option<u32>>,
}

// The Memory Ward: remembers "value -> the room we already built for it",
// so the same value never gets built twice.
type Memory = HashMap<u32, Rc<Node>>;

pub fn build_fib_tree(n: u32) -> Rc<Node> {
    let mut memory: Memory = HashMap::new();
    build_room(n, &mut memory)
}

fn build_room(n: u32, memory: &mut Memory) -> Rc<Node> {
    // "Have we already built this room?" If so, hand back that exact
    // room instead of building a new one. This is the whole trick: it
    // turns the structure from a tree (every value rebuilt from scratch)
    // into a DAG (many corridors can point at the very same room).
    if let Some(existing) = memory.get(&n) {
        return Rc::clone(existing);
    }

    let node = Rc::new(if n == 0 || n == 1 {
        Node {
            value: n,
            left: None,
            right: None,
            result: RefCell::new(None),
        }
    } else {
        let left = build_room(n - 1, memory);
        let right = build_room(n - 2, memory);
        Node {
            value: n,
            left: Some(left),
            right: Some(right),
            result: RefCell::new(None),
        }
    });

    // Remember this room before we hand it back, so the next request
    // for the same value finds it here.
    memory.insert(n, Rc::clone(&node));
    node
}

pub fn print_tree(node: &Node) {
    println!("{}", node.value);
    print_children(node, String::new());
}

// Draws each node's children with tree-style connectors (├──, └──, │)
// so the branching structure is visible, not just a flat list of values.
//
// A node from build_fib_tree always has both children or neither one
// (it never has just one), so we don't need to work out "is this the
// last child" dynamically: left is always drawn first with "├── ", and
// right is always drawn last with "└── ".
//
// Note: this walks every corridor, even ones that lead to a room it has
// already drawn elsewhere - so a shared room can legitimately appear
// more than once in the printout. That's expected: the diagram is
// showing the paths taken, not just the distinct rooms that exist.
fn print_children(node: &Node, prefix: String) {
    if let Some(left) = &node.left {
        println!("{}├── {}", prefix, left.value);
        print_children(left, format!("{}│   ", prefix));
    }

    if let Some(right) = &node.right {
        println!("{}└── {}", prefix, right.value);
        print_children(right, format!("{}    ", prefix));
    }
}

pub fn evaluate_tree(node: &Node) -> u32 {
    // Already worked out this room's answer? Reuse it. Because rooms are
    // now shared, this is what stops evaluation from redoing the same
    // work through every corridor that leads here - each distinct room
    // only ever gets computed once.
    if let Some(cached) = *node.result.borrow() {
        return cached;
    }

    // 1. Base cases: Fib(0) is 0, Fib(1) is 1
    let total = if node.value == 0 || node.value == 1 {
        node.value
    } else {
        // 2. Compute left child
        let left_val = match &node.left {
            Some(left_child) => evaluate_tree(left_child),
            None => 0,
        };

        // 3. Compute right child
        let right_val = match &node.right {
            Some(right_child) => evaluate_tree(right_child),
            None => 0,
        };

        // 4. Combine results
        left_val + right_val
    };

    // 5. Write the answer to this room's plaque so it's found instantly
    // next time (by us or by whoever else reaches this same room).
    *node.result.borrow_mut() = Some(total);

    total
}

// Floor 3: study the built tree and report back what it looks like.

// Counts every corridor walked (not every distinct room - see
// count_distinct_rooms for that) by adding 1 for each room visited,
// including repeat visits to a shared room via a different path. This
// always comes out to 2*F(n+1) - 1, a known identity for the naive
// recursive Fibonacci call tree.
pub fn count_rooms(node: &Node) -> u32 {
    let mut total = 1; // this room itself

    if let Some(left) = &node.left {
        total += count_rooms(left);
    }

    if let Some(right) = &node.right {
        total += count_rooms(right);
    }

    total
}

// Counts the "sealed chambers" - the base-case rooms where value is 0
// or 1. These are the leaves of the tree, where recursion stops and no
// more doors lead onward. Like count_rooms, this counts every visit,
// not just distinct rooms.
pub fn count_sealed_chambers(node: &Node) -> u32 {
    if node.value == 0 || node.value == 1 {
        return 1;
    }

    let mut total = 0;

    if let Some(left) = &node.left {
        total += count_sealed_chambers(left);
    }

    if let Some(right) = &node.right {
        total += count_sealed_chambers(right);
    }

    total
}

// Finds the longest path from this room down to a sealed chamber,
// measured in doors (edges) crossed. For fib(5) this is 4.
pub fn longest_path(node: &Node) -> u32 {
    if node.value == 0 || node.value == 1 {
        return 0;
    }

    let left_depth = match &node.left {
        Some(left) => longest_path(left),
        None => 0,
    };

    let right_depth = match &node.right {
        Some(right) => longest_path(right),
        None => 0,
    };

    1 + left_depth.max(right_depth)
}

// The Memory Ward's payoff: counts only the physically distinct rooms
// that exist (not every corridor that leads to one). Since every value
// from 0 up to n gets built at most once, this is always exactly n + 1 -
// linear, instead of count_rooms' exponential 2*F(n+1) - 1.
pub fn count_distinct_rooms(node: &Node) -> usize {
    let mut seen = HashSet::new();
    mark_seen(node, &mut seen);
    seen.len()
}

fn mark_seen(node: &Node, seen: &mut HashSet<u32>) {
    // insert() returns false if the value was already in the set - i.e.
    // we've reached this exact room through a different corridor before.
    // No need to walk its children again; they were already counted.
    if !seen.insert(node.value) {
        return;
    }

    if let Some(left) = &node.left {
        mark_seen(left, seen);
    }

    if let Some(right) = &node.right {
        mark_seen(right, seen);
    }
}
