use crate::word::Word;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

#[derive(Serialize, Clone, Debug)]
pub struct Room {
    users: HashMap<Uuid, User>,
    machine: Machine,
    turn_offset: usize,
}

#[derive(Serialize, Clone, Debug)]
pub struct User {
    name: String,
    points: i32,
}

impl User {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            points: 0,
        }
    }
}

#[derive(Serialize, Clone, Debug)]
#[serde(tag = "type")]
pub enum Machine {
    Joining { user_count: usize },
    SelectingWord { artist: Uuid },
    Drawing(DrawingModel),
}

#[derive(Serialize, Clone, Debug)]
pub struct DrawingModel {
    pub artist: Uuid,
    pub word: Word,
    pub seconds_left: i32,
    pub frames: Vec<u8>,
    pub guesses: Vec<Guess>,
}

impl DrawingModel {
    pub fn new(word: &str, artist: &Uuid) -> Self {
        let word = Word::new(word);
        Self {
            seconds_left: 180,
            artist: artist.to_owned(),
            word: word.clone(),
            frames: vec![],
            guesses: vec![],
        }
    }

    pub fn guess(&mut self, val: &str, user: &Uuid) {
        let correct = val == self.word.to_string();
        let guess = Guess::new(val, correct, user);
        self.guesses.push(guess);
    }
}

#[derive(Serialize, Clone, Debug)]
pub struct Guess {
    pub val: String,
    pub correct: bool,
    pub user: Uuid,
}

impl Guess {
    pub fn new(val: &str, correct: bool, user: &Uuid) -> Self {
        Self {
            val: val.to_owned(),
            correct,
            user: user.to_owned(),
        }
    }
}

impl Room {
    pub fn new() -> Self {
        Self {
            users: HashMap::new(),
            machine: Machine::Joining { user_count: 0 },
            turn_offset: 0,
        }
    }

    pub fn update(&mut self, user: Uuid, msg: Msg) {
        match msg {
            Msg::GotJoin => {
                self.users.insert(user, User::new(""));
            }

            Msg::SetName { id, name } => {
                self.users.insert(id, User::new(&name));
                self.machine = Machine::SelectingWord { artist: id.clone() };
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
                        self.turn_offset += 1;
                        if let Some((new_user, _)) = self
                            .users
                            .iter()
                            .cycle()
                            .skip(self.turn_offset)
                            .take(1)
                            .next()
                        {
                            self.machine = Machine::SelectingWord { artist: *new_user };
                        } else {
                            println!("Could not find next user");
                        }
                    }
                }
                _ => (),
            },
            Msg::GotCanvasFrames { frames } => match self.machine {
                Machine::Drawing(ref mut drawing) => {
                    drawing.frames.extend(frames);
                }
                _ => (),
            },
            Msg::GotGuess { guess } => match self.machine {
                Machine::Drawing(ref mut drawing) => {
                    drawing.guess(&guess, &user);
                }
                _ => (),
            },
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
