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

    pub fn update(&mut self, user: Uuid, msg: Msg) -> Option<(Uuid, Effect)> {
        match msg {
            Msg::GotJoin => {
                self.users.insert(user);

                Some((
                    user,
                    Effect::JoinPayload {
                        room: self.clone(),
                        me: user,
                    },
                ))
            }
            Msg::GotLeave => {
                self.users.remove(&user);

                None
            }
        }
    }
}

#[derive(Deserialize)]
pub enum Msg {
    GotJoin,
    GotLeave,
}

#[derive(Serialize)]
#[serde(tag = "type")]
pub enum Effect {
    JoinPayload { room: Room, me: Uuid },
}
