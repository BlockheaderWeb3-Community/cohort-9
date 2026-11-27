pub struct Todo {
    pub description: String,
    pub completed: bool,
}
impl Todo {
    pub fn new(description: String) -> Todo {
        Todo {
            description,
            completed: false,
        }
    }

    pub fn mark_completed(&mut self) {
        self.completed = true;
    }
}
