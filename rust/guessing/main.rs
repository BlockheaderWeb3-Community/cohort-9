use std::io;
use std::cmp::Ordering;
use rand::RngExt; // Updated for rand 0.10.x

fn main() {
    let secret_number = rand::rng().random_range(1..=100);

    let mut attempts = 0;
    let max_attempts = 5;

    println!("Welcome to the Random Guessing Game!");
    println!("I have picked a secret number between 1 and 100.");
    println!("You have {max_attempts} attempts!");

    loop {
        if attempts >= max_attempts {
            println!("\nGame Over! The secret number was {secret_number}.");
            break;
        }

        println!("\nAttempt {}/{}", attempts + 1, max_attempts);
        println!("Please input your guess:");

        let mut guess = String::new();

        io::stdin()
            .read_line(&mut guess)
            .expect("Failed to read line");

        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => {
                println!("Please type a valid number!");
                continue;
            }
        };

        attempts += 1;

        match guess.cmp(&secret_number) {
            Ordering::Less => println!("Too small!"),
            Ordering::Greater => println!("Too big!"),
            Ordering::Equal => {
                println!("You win! You guessed it in {attempts} attempts!");
                break;
            }
        }
    }
}