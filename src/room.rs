use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

#[derive(Serialize, Clone, Debug)]
pub struct Room {
    users: HashMap<Uuid, String>,
    machine: Machine,
    magic_number: i32,
}

#[derive(Serialize, Clone, Debug)]
pub enum Machine {
    Joining,
    SelectingWord {
        active_user: Uuid,
    },
    Drawing {
        active_user: Uuid,
        word: String,
        seconds_left: i32,
    },
    EndOfTurn {
        active_user: Uuid,
    },
}

impl Room {
    pub fn new() -> Self {
        Self {
            users: HashMap::new(),
            machine: Machine::Joining,
            magic_number: 42,
        }
    }

    fn broadcast(&mut self, effect: Effect) -> Option<(Vec<Uuid>, Effect)> {
        Some((self.users.keys().cloned().collect(), effect))
    }

    pub fn update(&mut self, user: Uuid, msg: Msg) -> Option<(Vec<Uuid>, Effect)> {
        match (msg, &self.machine) {
            (Msg::GotJoin, _) => {
                self.users.insert(user, "".into());

                Some((
                    vec![user],
                    Effect::JoinPayload {
                        room: self.clone(),
                        me: user,
                    },
                ))
            }

            (Msg::SetName { id, name }, _) => {
                self.users.insert(id, name);

                Some((
                    vec![user],
                    Effect::JoinPayload {
                        room: self.clone(),
                        me: user,
                    },
                ))
            }
            (Msg::GotLeave, _) => {
                self.users.remove(&user);

                None
            }
            // Playing Flow
            (Msg::WordSelected { word }, Machine::SelectingWord { active_user }) => {
                self.machine = Machine::Drawing {
                    seconds_left: 180,
                    word: word.clone(),
                    active_user,
                };

                self.broadcast(Effect::WordSelected {
                    letters: word.chars().map(|_| None).collect(),
                })
            }

            (Msg::WordSelected { word }, Machine::SelectingWord { active_user }) => {
                self.machine = Machine::Drawing {
                    seconds_left: 180,
                    word: word.clone(),
                    active_user,
                };

                self.broadcast(Effect::WordSelected {
                    letters: word.chars().map(|_| None).collect(),
                })
            }

            (
                Msg::Tick,
                Machine::Drawing {
                    seconds_left,
                    word,
                    active_user,
                },
            ) => {
                if seconds_left > 0 {
                    let seconds_left = seconds_left - 1;
                    self.machine = Machine::Drawing {
                        seconds_left,
                        word,
                        active_user,
                    };
                    self.broadcast(Effect::SecondsLeft { seconds_left })
                } else {
                    self.machine = Machine::EndOfTurn { active_user };
                    self.broadcast(Effect::TurnEnded { new_scores: false })
                }
            }
            (Msg::Tick, Machine::EndOfTurn { .. }) => {
                // Select new user, start their turn
                if let Some((new_user, _)) = self.users.iter().take(1).next() {
                    self.machine = Machine::SelectingWord {
                        active_user: *new_user,
                    };
                    self.broadcast(Effect::TurnStarted { user: *new_user })
                } else {
                    None
                }
            }
            _ => None,
        }
    }
}

#[derive(Deserialize)]
#[serde(tag = "type")]
pub enum Msg {
    // Joining flow
    GotJoin,
    GotLeave,
    SetName { id: Uuid, name: String },
    // Playing flow
    WordSelected { word: String },
    GotCanvasFrames { frames: Vec<u8> },
    GotGuess { guess: String },
    Tick,
}

#[derive(Serialize)]
#[serde(tag = "type")]
pub enum Effect {
    // Joining Flow
    JoinPayload {
        room: Room,
        me: Uuid,
    },
    // Playing flow
    TurnStarted {
        user: Uuid,
    },
    WordSelected {
        letters: Vec<Option<char>>,
    },
    PublishCanvasFrames {
        frames: Vec<u8>,
    },
    LettersRevealed {
        letters: Vec<Option<char>>,
    },
    GuessResult {
        correct: bool,
        user: Uuid,
        guess: String,
    },
    TurnEnded {
        new_scores: bool,
    },
    SecondsLeft {
        seconds_left: i32,
    },
}
