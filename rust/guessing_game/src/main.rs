// Rust's standard library
use std::io;
use std::cmp::Ordering;

use rand::RngExt;

fn main() {
    println!("   Welcome to Guess the Number!");
    println!("I'm thinking of a number between 1 and 100.");
    println!("You have 8 lives. Good luck!\n");

    // Generate a random secret number between 1 and 100 (inclusive)
    let secret_number = rand::rng().random_range(1..=100);

    // This is how many guesses the player has left
    let mut lives = 9;

    // loop keeps running forever until we use "break" to stop it
    loop {
        println!("Lives remaining: {lives}");
        println!("Enter your guess:");

        // Create an empty String to store what the user types
        let mut guess = String::new();

        // Read a line from the keyboard into our guess variable
        io::stdin()
            .read_line(&mut guess)
            .expect("Failed to read line");

        // trim() removes the newline at the end, then parse() converts the
        // String into a number (u32 = unsigned 32-bit integer, i.e. a whole number >= 0)
        
        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,       // parse succeeded — use the number
            Err(_) => {           // parse failed — tell the user and try again
                println!("Please type a whole number!\n");
                continue;         // jump back to the top of the loop
            }
        };

        // Compare the guess to the secret number
        match guess.cmp(&secret_number) {
            Ordering::Less => {
                println!("Too small! Try higher.\n");
                lives -= 1; // subtract one life
            }
            Ordering::Greater => {
                println!("Too big! Try lower.\n");
                lives -= 1;
            }
            Ordering::Equal => {
                // The player got it right!
                println!("\nCorrect! The number was {secret_number}.");
                println!("You won with {lives} lives left!");
                break; // exit the loop — game over (win)
            }
        }

        // Check if the player has run out of lives
        if lives == 0 {
            println!("\nGame over! You ran out of lives.");
            println!("The secret number was {secret_number}. Better luck next time!");
            break; // exit the loop — game over (lose)
        }
    }
}
