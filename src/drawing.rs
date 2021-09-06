use crate::room::Msg;
use crate::word::Word;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

#[derive(Serialize, Clone, Debug)]
pub struct DrawingModel {
    pub artist: Uuid,
    pub word: Word,
    pub seconds_left: i32,
    pub frames: Vec<u8>,
}

impl DrawingModel {
    pub fn new(word: &str, artist: &Uuid) -> Self {
        let word = Word::new(word);
        Self {
            seconds_left: 180,
            artist: artist.to_owned(),
            word: word.clone(),
            frames: vec![],
        }
    }
}
