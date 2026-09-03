use std::io;
mod dungeon;

fn main() {
    let mut no = String::new();
    io::stdin()
        .read_line(&mut no)
        .expect("Failed to read line");

    // Convert the input string into a number
    let num: u32 = match no.trim().parse() {
        Ok(num) => num,
        Err(_) => {
            println!("Please type a valid number!");
            return;
        }
    };

    // 1. Build the tree (Part 1) - now backed by the Memory Ward, so
    // shared values only ever get built once (it's a DAG, not a tree).
    let root = dungeon::build_fib_tree(num);

    // Show the branching structure
    dungeon::print_tree(&root);

    // 2. Evaluate the tree (Part 2)
    let fib_result = dungeon::evaluate_tree(&root);

    println!("Fibonacci result at root: {}", fib_result);
    println!("Stored in root.result: {:?}", root.result.borrow());

    // 3. Study the tree (Floor 3)
    let total_rooms = dungeon::count_rooms(&root);
    let sealed_chambers = dungeon::count_sealed_chambers(&root);
    let longest_path = dungeon::longest_path(&root);
    let distinct_rooms = dungeon::count_distinct_rooms(&root);

    println!("Total rooms discovered: {}", total_rooms);
    println!("Sealed chambers found: {}", sealed_chambers);
    println!("Longest path traveled: {}", longest_path);
    println!("Distinct rooms in memory: {}", distinct_rooms);
}
