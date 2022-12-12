function connect(r) {
    let sock = ngx.socket.tcp();
    let ok, err = sock.connect("127.0.0.1", 8443);
    if (!ok) {
        ngx.say("failed to connect to upstream: ", err);
        return;
    }
    ngx.say("successfully connected to upstream!");
    sock.send("G");
    sock.close();
}
  
export default {connect}
