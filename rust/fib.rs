use std::collections::HashMap;

fn fib_naive(n: u64, calls: &mut u64) -> u64 {
    *calls += 1;
    if n <= 1 {
        return n;
    }
    fib_naive(n - 1, calls) + fib_naive(n - 2, calls)
}

fn fib_memo(n: u64, memo: &mut HashMap<u64, u128>, calls: &mut u64) -> u128 {
    *calls += 1;
    if let Some(&val) = memo.get(&n) {
        return val;
    }
    if n <= 1 {
        return n as u128;
    }
    let result = fib_memo(n - 1, memo, calls) + fib_memo(n - 2, memo, calls);
    memo.insert(n, result);
    result
}

fn fib_iter(n: u64) -> u128 {
    let (mut a, mut b): (u128, u128) = (0, 1);
    for _ in 0..n {
        let temp = a + b;
        a = b;
        b = temp;
    }
    a
}

fn fib_pair(n: u64) -> (u128, u128) {
    if n == 0 {
        return (0, 1);
    }
    let (a, b) = fib_pair(n / 2);
    let c = a * (2 * b - a);
    let d = a * a + b * b;
    if n % 2 == 0 {
        (c, d)
    } else {
        (d, c + d)
    }
}

fn fib_fast(n: u64) -> u128 {
    fib_pair(n).0
}

fn main() {
    let known: [(u64, u128); 9] = [(0,0),(1,1),(2,1),(3,2),(4,3),(5,5),(10,55),(20,6765),(30,832040)];

    println!("=== FLOOR 1: naive recursion ===");
    for (n, expected) in known.iter() {
        let mut calls: u64 = 0;
        let result = fib_naive(*n, &mut calls) as u128;
        let status = if result == *expected { "OK".to_string() } else { format!("FAIL (got {}, expected {})", result, expected) };
        println!("  fib_naive({}) = {}  [{}]  calls={}", n, result, status, calls);
    }

    println!("\n=== FLOOR 2: memoized recursion ===");
    for (n, expected) in known.iter() {
        let mut memo: HashMap<u64, u128> = HashMap::new();
        let mut calls: u64 = 0;
        let result = fib_memo(*n, &mut memo, &mut calls);
        let status = if result == *expected { "OK".to_string() } else { format!("FAIL (got {}, expected {})", result, expected) };
        println!("  fib_memo({}) = {}  [{}]  calls={}", n, result, status, calls);
    }

    println!("\n=== FLOOR 3: iterative ===");
    for (n, expected) in known.iter() {
        let result = fib_iter(*n);
        let status = if result == *expected { "OK".to_string() } else { format!("FAIL (got {}, expected {})", result, expected) };
        println!("  fib_iter({}) = {}  [{}]", n, result, status);
    }

    println!("\n=== FLOOR 4 (BOSS): fast doubling ===");
    for (n, expected) in known.iter() {
        let result = fib_fast(*n);
        let status = if result == *expected { "OK".to_string() } else { format!("FAIL (got {}, expected {})", result, expected) };
        println!("  fib_fast({}) = {}  [{}]", n, result, status);
    }

    let big_n: u64 = 150;
    println!("\n=== BOSS at n={} ===", big_n);
    println!("  fib_fast({}) = {}", big_n, fib_fast(big_n));
}
