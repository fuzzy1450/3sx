import NIO

final class MatchmakingCoordinator: @unchecked Sendable {
    private let loop: EventLoop
    private var players: [Player.ID: Player] = [:]
    private var waiting: [Player.ID] = []

    init(loop: EventLoop) {
        self.loop = loop
    }

    func registerPlayer(tcpChannel: Channel) -> EventLoopFuture<Void> {
        loop.submit { [self] in
            let id = generateID()
            players[id] = Player(id: id, tcpChannel: tcpChannel)
            return id
        }
        .flatMap { [self] id in
            sendTCPMessage(id, through: tcpChannel)
        }
    }

    func removePlayer(boundTo tcpChannel: Channel) -> EventLoopFuture<Void> {
        loop.submit { [self] in
            guard let (id, _) = players.first(where: { $0.value.tcpChannel === tcpChannel }) else {
                return
            }

            players.removeValue(forKey: id)
            waiting.removeAll { $0 == id }
        }
    }

    func noteUDPEndpoint(_ endpoint: SocketAddress, for playerID: Player.ID) -> EventLoopFuture<Void> {
        loop.submit { [self] () -> (Player, Player)? in
            guard var player = players[playerID] else {
                return nil
            }

            // No need to do anything if the endpoint is already known
            guard player.udpEndpoint == nil else {
                return nil
            }

            player.udpEndpoint = endpoint
            players[playerID] = player
            waiting.append(playerID)

            if waiting.count >= 2 {
                let aID = waiting.removeFirst()
                let bID = waiting.removeFirst()

                guard let a = players[aID], let b = players[bID] else {
                    return nil
                }

                return (a, b)
            }

            return nil
        }
        .flatMap { [self] match in
            guard let (a, b) = match else {
                return loop.makeSucceededVoidFuture()
            }

            let aEndpoint = "\(a.udpEndpoint!.ipAddress!):\(a.udpEndpoint!.port!)"
            let bEndpoint = "\(b.udpEndpoint!.ipAddress!):\(b.udpEndpoint!.port!)"

            let f1 = sendTCPMessage(bEndpoint, through: a.tcpChannel)
            let f2 = sendTCPMessage(aEndpoint, through: b.tcpChannel)
            return f1.and(f2).map { _ in }
        }
    }

    func nextMatch() -> (String, String)? {
        while waiting.count >= 2 {
            let a = waiting.removeFirst()
            let b = waiting.removeFirst()
            guard players[a] != nil else { continue }
            guard players[b] != nil else { continue }
            return (a, b)
        }
        
        return nil
    }

    private func sendTCPMessage(_ message: String, through channel: Channel) -> EventLoopFuture<Void> {
        channel.eventLoop.flatSubmit {
            var buf = channel.allocator.buffer(capacity: 64)
            buf.writeString(message + "\n")
            return channel.writeAndFlush(buf)
        }
    }

    private func generateID() -> Player.ID {
        let alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
        var id: [Character] = []

        for _ in 0..<7 {
            id.append(alphabet.randomElement()!)
        }

        return String(id)
    }
}
