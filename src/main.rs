use std::io;
use rand::thread_rng;
use rand::Rng;
use std::cmp::Ordering;


fn main() {
    let secret_number = thread_rng().gen_range(1..=100);
    println!("Hint: Secret number is between 1 - 100");
    println!("Guess the number! ");

    println!("Enter number of trials: ");

    let mut trial_input = String::new();

    io::stdin().read_line(& mut trial_input).expect("Enter a number");
    let max_trials: u32 = trial_input.trim().parse().expect("Enter a number");

    for attempt in 1..=max_trials{
        println!("Attempt {}/{}: Please input your guess", attempt, max_trials);
        let mut guess = String::new();

        io::stdin()
        .read_line(&mut guess)
        .expect("failed to read line");

    
        let guess: u32 = match guess.trim().parse(){
            Ok(num) => num,
            Err(_) => {
                println!("lease enter a valid number");
                continue
            }
        };

        

        match guess.cmp(&secret_number){
            Ordering::Equal =>{ 
                println!("You win");
                return;
            },
            Ordering::Greater => println!("Too big"),
            Ordering::Less => println!("Too small"),
        }
    }

    println!("Out of trials! The secret number was: {}", secret_number);

}
