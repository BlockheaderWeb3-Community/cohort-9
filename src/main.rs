use std::cmp::Ordering;
use std::io;

use rand::Rng;

fn main() {
    println!("I have chosen a number between 1 and 100.");
    println!("You have 7 attempts to guess it.");
// Generate a random number between 1 and 100
    let secret_number = rand::thread_rng().gen_range(1..=100);

    //create a loop that allows the user to guess up to 7 times
    for attempt in 1..=7 {
        println!();
        println!("Attempt {attempt} of 7");
        println!("Guess a number:");

        //create a mutable variable to store the user's guess

        let mut guess = String::new();

        //read the user's guess from standard input

        io::stdin()
            .read_line(&mut guess)
            .expect("Failed to read line");

            //convert the user's guess to a number and handle any errors that may occur

        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => {
                println!("Invalid guess! Please guess a number.");
                continue;
            }
        };

        //print the user's guess to the console

        println!("You guessed: {guess}");

        //compare the user's guess to the secret number and print a message indicating whether the guess was too low, too high, or correct

        match guess.cmp(&secret_number) {
            Ordering::Less => {
                println!("Too small!");
            }

            // Handle the case where the guess is greater than the secret number

            Ordering::Greater => {
                println!("Too big!");
            }

            // Handle the case where the guess is equal to the secret number

            Ordering::Equal => {
                println!();
                println!("Congratulations!");
                println!("You guessed the correct number!");
                println!("You guessed the number in {attempt} attempt(s).");
                return;
            }
        }
    }

    // If the user has used all 7 attempts, print a message indicating that the game is over and reveal the secret number

    println!();
    println!("Your guessing is over!");
    println!("You used all 7 attempts.");
    println!("The secret number was: {secret_number}");
}
