//use rust_todo::todo_struct::Todo;
//use rust_todo::todolist_struct::TodoList;
// this should be methods that should be called on the Todo struct

//mod lib;
use rust_todo::data_structure::todolist_struct::TodoList;
use std::io::{self, Write};
fn main() {
    let mut todo_list = TodoList::new();

    loop {
        println!("\n1. Add Todo");
        println!("2. Remove Todo");
        println!("3. Complete Todo");
        println!("4. List Todos");
        println!("5. Exit");

        print!("Choose an option: ");

        io::stdout().flush().unwrap();

        let mut input = String::new();

        io::stdin().read_line(&mut input).unwrap();
        let choice: u32 = input.trim().parse().unwrap_or(0);

        match choice {
            1 => {
                print!("Enter todo description: ");
                io::stdout().flush().unwrap();
                let mut description = String::new();
                io::stdin().read_line(&mut description).unwrap();
                todo_list.add(description.trim().to_string());
                println!("Todo added!");
            }

            2 => {
                todo_list.list();
                print!("Enter the index of the todo to remove: ");
                io::stdout().flush().unwrap();
                let mut index = String::new();
                io::stdin().read_line(&mut index).unwrap();
                let index: usize = index.trim().parse().unwrap_or(0) - 1;
                todo_list.remove(index);
                println!("Todo removed!");
            }
            3 => {
                todo_list.list();
                print!("Enter the index of the todo to complete: ");
                io::stdout().flush().unwrap();
                let mut index = String::new();
                io::stdin().read_line(&mut index).unwrap();
                let index: usize = index.trim().parse().unwrap_or(0) - 1;
                todo_list.complete(index);
                println!("Todo marked as completed!");
            }
            4 => {
                todo_list.list();
            }
            5 => {
                println!("Goodbye!");
                break;
            }
            _ => println!("Invalid option, please try again."),
        }
    }
}
