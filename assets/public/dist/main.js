'use strict'

const uri = 'ws://' + location.host + '/ws';
const ws = new WebSocket(uri);

const app = Elm.Main.init();

ws.addEventListener("message", function(event) {
    try { 
        let data = JSON.parse(event.data);
        app.ports.rx.send(data);
    } catch(e) { 
        console.error("Could not parse json", data)
    }
});

// Send down to server
app.ports.tx.subscribe(function(message) {
  ws.send(JSON.stringify(message));
});


