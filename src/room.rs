use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use uuid::Uuid;

#[derive(Serialize, Clone, Debug)]
pub struct Room {
    users: HashSet<Uuid>,
    magic_number: i32,
}

impl Room {
    pub fn new() -> Self {
        Self {
            users: HashSet::new(),
            magic_number: 42,
        }
    }

    pub fn update(&mut self, user: Uuid, msg: Msg) -> Effect {
        match msg {
            Msg::GotJoin(id) => {
                self.users.insert(id);
                Effect::SendRoomState(user, self.clone())
            }
            Msg::GotLeave(id) => {
                self.users.remove(&id);
                Effect::Nothing
            }
        }
    }
}

#[derive(Deserialize)]
pub enum Msg {
    GotJoin(Uuid),
    GotLeave(Uuid),
}

#[derive(Serialize)]
pub enum Effect {
    SendRoomState(Uuid, Room),
    Nothing,
}
