//mod lib;
use crate::data_structure::todo_struct::Todo;
pub struct TodoList{
    pub todos:Vec<Todo>
}


impl TodoList{

    pub fn new() -> TodoList{
        TodoList { todos: Vec::new() }
    }

   pub fn add(&mut self, description: String) {
        let todo = Todo::new(description);
        self.todos.push(todo);
    }

    pub fn remove(&mut self, index: usize) {
        if index < self.todos.len() {
            self.todos.remove(index);
        }
    }

    pub fn complete(&mut self, index: usize) {
        if index < self.todos.len() {
            self.todos[index].mark_completed();
        }
    }

   pub  fn list(&self) {
    for i in 0..self.todos.len() {
        let todo = &self.todos[i];
        
        let status;
        if todo.completed {
            status = "✔️";
        } else {
            status = "❌";
        }

        println!("{}: {} [{}]", i + 1, todo.description, status);
    }
}


}

