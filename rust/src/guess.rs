// use std ::io;

use std::io;
use rand::{Rng, RngExt};

fn main() {
   // THis is for the random number generation
    let mut rng = rand::rng();
    let secret_number = rng.random_range(1..=20);
    
    loop{
        println!("Input your guess(Hint : between 1 to 20)");
        let mut guess = String::new();
        io::stdin()
        .read_line(&mut guess)
        .expect("Failed to read line");

        // Convert the input string into a number
        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => {
                println!("Please type a valid number!");
                continue; 
            }
        };

        if guess < secret_number {
            println!("Too small! Try again.(lol)"); 
            
            
        } else if guess > secret_number {
            println!("Too big! Try again. :)"); 
            // Loop automatically repeats here
            
        } else {
            println!("You win! ");
            break; 
        }
    
   

    }   
    
}