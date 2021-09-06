use crate::drawing::DrawingModel;
use crate::word::Word;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

#[derive(Serialize, Clone, Debug)]
pub struct Room {
    users: HashMap<Uuid, String>,
    machine: Machine,
}

#[derive(Serialize, Clone, Debug)]
pub enum Machine {
    Joining,
    SelectingWord { artist: Uuid },
    Drawing(DrawingModel),
    EndOfTurn { artist: Uuid },
}

impl Room {
    pub fn new() -> Self {
        Self {
            users: HashMap::new(),
            machine: Machine::Joining,
        }
    }

    pub fn update(&mut self, user: Uuid, msg: Msg) {
        match msg {
            Msg::GotJoin => {
                self.users.insert(user, "".into());
            }

            Msg::SetName { id, name } => {
                self.users.insert(id, name);
            }
            Msg::GotLeave => {
                self.users.remove(&user);
            }
            // Playing Flow
            Msg::WordSelected { word } => {
                let drawing = DrawingModel::new(&word, &user);
                self.machine = Machine::Drawing(drawing);
            }
            // Counting down and moving on to new turn
            Msg::Tick => match self.machine {
                Machine::Drawing(ref mut drawing) => {
                    if drawing.seconds_left > 0 {
                        drawing.seconds_left -= 1;

                        if drawing.seconds_left % 10 == 10 {
                            drawing.word.reveal(1);
                        }
                    } else {
                        if let Some((new_user, _)) = self.users.iter().take(1).next() {
                            self.machine = Machine::SelectingWord { artist: *new_user };
                        } else {
                            panic!("atd");
                        }
                    }
                }
                _ => (),
            },
            // (Msg::GotCanvasFrames { frames }, Machine::Drawing(mut drawing)) => {
            //     drawing.frames.extend(frames);
            // }
            _ => (),
        };
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
    Tick,
    GotGuess { guess: String },
}
