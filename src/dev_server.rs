use notify::{watcher, RecursiveMode, Watcher};
use std::process::Command;
use std::sync::mpsc::channel;
use std::time::Duration;

pub fn watch() {
    let (tx, rx) = channel();
    let mut watcher = watcher(tx, Duration::from_secs(10)).unwrap();

    watcher
        .watch("assets/src", RecursiveMode::Recursive)
        .unwrap();

    Command::new("open")
        .arg("http://localhost:3030")
        .spawn()
        .expect("could not open browser");

    loop {
        match rx.recv() {
            Ok(_) => {
                Command::new("yarn")
                    .current_dir("assets")
                    .arg("run")
                    .arg("build")
                    .spawn()
                    .expect("could not build");
            }
            Err(e) => println!("watch error: {:?}", e),
        }
    }
}
