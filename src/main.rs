use futures::{SinkExt, StreamExt, TryFutureExt};
use serde::Serialize;
use std::collections::HashMap;
use std::thread;
use tokio::sync::mpsc::{self, UnboundedSender};
use tokio_stream::wrappers::UnboundedReceiverStream;
use uuid::Uuid;
use warp::ws::WebSocket;
use warp::Filter;
use xtra::prelude::*;
use xtra::spawn::Tokio;

mod dev_server;
mod room;
mod word;
use room::Msg;

// Main
#[tokio::main]
async fn main() {
    pretty_env_logger::init();

    thread::spawn(|| {
        dev_server::watch();
    });

    let room = Room::new().create(None).spawn(&mut Tokio::Global);
    let room = warp::any().map(move || room.clone());

    let chat = warp::path("ws")
        .and(warp::ws())
        .and(room)
        .map(|ws: warp::ws::Ws, room| ws.on_upgrade(move |socket| user_connected(socket, room)));

    let index = warp::any().and(warp::fs::file("assets/public/index.html"));
    let dist = warp::path("dist").and(warp::fs::dir("assets/public/dist"));

    let routes = dist.or(chat).or(index);

    println!("Listening on 3030");
    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}

// Room
struct Room {
    users: HashMap<Uuid, UnboundedSender<String>>,
    room: room::Room,
}
impl Actor for Room {}
impl Room {
    fn new() -> Self {
        Self {
            users: HashMap::new(),
            room: room::Room::new(),
        }
    }
}

#[derive(Serialize)]
struct Response<'a, T: Serialize> {
    me: &'a Uuid,
    payload: &'a T,
}

// GotUserMessage
struct RoomUpdate(Uuid, Msg);
impl Message for RoomUpdate {
    type Result = ();
}
#[async_trait::async_trait]
impl Handler<RoomUpdate> for Room {
    async fn handle(&mut self, msg: RoomUpdate, _ctx: &mut Context<Self>) {
        self.room.update(msg.0, msg.1);
        for (user, tx) in self.users.iter() {
            dbg!(&self.room);
            tx.send(
                serde_json::to_string(&Response {
                    me: user,
                    payload: &self.room,
                })
                .unwrap(),
            )
            .unwrap();
        }
    }
}

// GotUserMessage
struct GotUserMessage(Uuid, String);
impl Message for GotUserMessage {
    type Result = ();
}
#[async_trait::async_trait]
impl Handler<GotUserMessage> for Room {
    async fn handle(&mut self, msg: GotUserMessage, ctx: &mut Context<Self>) {
        if let Ok(inner_msg) = serde_json::from_str::<room::Msg>(&msg.1) {
            ctx.notify(RoomUpdate(msg.0, inner_msg));
        } else {
            println!("Ignoring unknown message {}", &msg.1);
        }
    }
}

// Join
struct Join(Uuid, UnboundedSender<String>);
impl Message for Join {
    type Result = ();
}
#[async_trait::async_trait]
impl Handler<Join> for Room {
    async fn handle(&mut self, msg: Join, ctx: &mut Context<Self>) {
        self.users.insert(msg.0, msg.1);
        ctx.notify(RoomUpdate(msg.0, Msg::GotJoin));
    }
}

// Leave
struct Leave(Uuid);
impl Message for Leave {
    type Result = ();
}
#[async_trait::async_trait]
impl Handler<Leave> for Room {
    async fn handle(&mut self, msg: Leave, ctx: &mut Context<Self>) {
        self.users.remove(&msg.0);
        ctx.notify(RoomUpdate(msg.0, Msg::GotLeave));
    }
}

async fn user_connected(ws: WebSocket, room: xtra::Address<Room>) {
    let (mut user_ws_tx, mut user_ws_rx) = ws.split();
    let (tx, rx) = mpsc::unbounded_channel();
    let mut rx = UnboundedReceiverStream::new(rx);

    let id = Uuid::new_v4();
    room.send(Join(id, tx))
        .await
        .expect("Could not join the room");

    // Pipe mesesages back up to the user
    tokio::task::spawn(async move {
        while let Some(value) = rx.next().await {
            let message = warp::ws::Message::text(value);
            user_ws_tx
                .send(message)
                .unwrap_or_else(|e| {
                    eprintln!("websocket send error: {}", e);
                })
                .await;
        }
    });

    // Receive messages
    while let Some(result) = user_ws_rx.next().await {
        let msg = match result {
            Ok(msg) => msg,
            Err(_) => {
                break;
            }
        };

        // Send in to actor
        if let Ok(s) = msg.to_str() {
            room.send(GotUserMessage(id, s.to_string()))
                .await
                .expect("Could not receive message");
        };
    }

    room.send(Leave(id))
        .await
        .expect("Could not leave the room");
}
