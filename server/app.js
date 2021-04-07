const express = require('express')
const app = require('express')();
const server = require('http').createServer(app);
const io = require('socket.io')(server);
const path = require('path');

const history = {}

io.on('connection', (socket) => {
    socket.on('join', room => {
        console.log(`Someone joined ${room}`)
        socket.join(room);
        socket.emit('history', history[room] ? history[room] : []);
    });
    socket.on('message', (room, message) => {
        historize(room, message);
        io.in(room).emit('message', message);
    });
    socket.on('disconnect', () => console.log('user disconnected'));
});

function historize(room, message) {
    let roomHistory = history[room] || [];
    roomHistory.push(message);
    history[room] = roomHistory;
}

let publicDirPath = path.join(__dirname + "/../", 'public');
app.use(express.static(publicDirPath));
app.get('/', (req, res) => {
    res.sendFile(path.join(publicDirPath, "index.html"))
}).get('/mob/*', (req, res) => {
    res.sendFile(path.join(publicDirPath, "index.html"))
})

const port = process.env.PORT || 3000
server.listen(port, () => {
    console.log(`Live at http://0.0.0.0:${port}`)
});
