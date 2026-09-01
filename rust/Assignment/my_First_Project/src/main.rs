use std::io;
use rand::RngExt;
use std::cmp::Ordering;

fn main() {
    // println!("Hello, world!");
    // println!("Guess the number!");
    // let number = rand::rng().random_range(1..=100);

    // println!("Please input your guess.");

    // let mut guess = String::new();

    // io::stdin()
    //     .read_line(&mut guess)
    //     .expect("Failed to read line");

    // // println!("You guessed: {}", guess);
    // // println!("You guessed: {guess}");
    // let guess: u32 = guess.trim().parse().expect("Please type a number!");

    // println!("You guessed: {}", guess);

    // match guess.cmp(&number){
    //     Ordering::Less => println!("Too small"),
    //     Ordering::Greater => println!("Too big"),
    //     Ordering::Equal => println!("You win"),
    // }

    println!("We're playing a little Hangman game, you have 5 attempts to save him!!!");

    println! ("Guess the number!");

    let fixed_number = rand::rng().random_range(1..=100);


    let max_guess = 5;
    let mut guessed_number = 0;


    loop{

        guessed_number += 1;
        println!("Input your guess to save him,  {guessed_number} attempt(s) out of {max_guess} attempts");

        let mut guess = String::new();
        
        io:: stdin()
            .read_line(&mut guess)
            .expect("Failed to read line");

        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => {
                println!("Please input a number!!!");
                continue;
            }
        };

        println!("You guessed {guess}");

        match guess.cmp(&fixed_number) {
            Ordering::Less => println!("Too small, try again"),
            Ordering::Greater => println!("Too big, try again"),
            Ordering::Equal => {
                println!{"You win, you saved him!!!Hoorayyy!!!"};
                break;
            }
        }

        if guessed_number >= max_guess {
            println!("You lost, he is dead!!!");
            break;
        }

    }
}
