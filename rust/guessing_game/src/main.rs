use std::io;
use rand::RngExt;
use std::cmp::Ordering;

fn main() {
    println!("Guess the number!");

    let mut rng = rand::rng();
    let secret_number = rng.random_range(1..=100);

    println!("Please input your guess.");

    let mut guess = String::new();

    io::stdin()
        .read_line(&mut guess)
        .expect("Failed to read line");

    let guess: u32 = guess
        .trim()
        .parse()
        .expect("Please type a number!");

    println!("You guessed: {guess}");

    match guess.cmp(&secret_number) {
        Ordering::Less => println!("Too small!"),
        Ordering::Greater => println!("Too big!"),
        Ordering::Equal => println!("You win!"),
    }

    println!("The secret number was: {secret_number}");
}