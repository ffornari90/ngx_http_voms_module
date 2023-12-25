function connect(r) {
    r.log("vivo");
    var sock = new TCPSocket("127.0.0.1", 8443);
    if (!sock.status) {
        r.log("failed to connect to upstream: ");
        r.return(500);
    }
    r.log("successfully connected to upstream!");
    sock.writeable.write("G");
    sock.close();
    r.return(200);
}
  
export default {connect}