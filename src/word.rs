use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::string::ToString;
use uuid::Uuid;

#[derive(Serialize, Clone, Debug)]
pub struct Word {
    val: String,
    letters: Vec<Option<char>>,
}

impl Word {
    pub fn new(val: &str) -> Self {
        Self {
            val: val.to_owned(),
            letters: val.chars().map(|_| None).collect(),
        }
    }

    pub fn letters(&self) -> Vec<Option<char>> {
        self.letters.clone()
    }

    pub fn reveal(&mut self, count: i32) {
        let mut count = count;
        self.letters = self
            .letters
            .iter()
            .enumerate()
            .map(|(index, c)| {
                if c.is_none() && count > 0 {
                    count -= 1;
                    self.val.chars().nth(index).clone()
                } else {
                    c.clone()
                }
            })
            .collect();
    }
}

impl ToString for Word {
    fn to_string(&self) -> String {
        self.val.clone()
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn reveal_init() {
        let word = Word::new("hey");
        let got = word.letters();
        let want = vec![None, None, None];

        assert_eq!(got, want);
    }

    #[test]
    fn reveal_some() {
        let mut word = Word::new("hey");
        word.reveal(1);
        let got = word.letters();
        let want = vec![Some('h'), None, None];

        assert_eq!(got, want);
    }

    #[test]
    fn reveal_more() {
        let mut word = Word::new("hey");
        word.reveal(3);
        let got = word.letters();
        let want = vec![Some('h'), Some('e'), Some('y')];

        assert_eq!(got, want);
    }
}
