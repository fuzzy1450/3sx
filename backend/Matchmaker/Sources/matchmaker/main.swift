import NIO
import NIOExtras

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let coordinator = MatchmakingCoordinator(loop: group.next())

defer {
    try! group.syncShutdownGracefully()
}

let tcpBootstrap = ServerBootstrap(group: group)
    .serverChannelOption(.backlog, value: 256)
    .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
    .childChannelInitializer { channel in
        channel.pipeline.addHandler(ByteToMessageHandler(LineBasedFrameDecoder()))
            .flatMap {
                channel.pipeline.addHandler(TCPHandler(coordinator: coordinator))
            }
    }
    .childChannelOption(.socketOption(.so_reuseaddr), value: 1)

let tcpPort = 9000

let tcpChannel = try tcpBootstrap
    .bind(host: "0.0.0.0", port: tcpPort)
    .wait()

print("TCP listening on \(tcpPort)")

let udpBootstrap = DatagramBootstrap(group: group)
    .channelOption(.socketOption(.so_reuseaddr), value: 1)
    .channelInitializer { channel in
        channel.pipeline.addHandler(UDPHandler(coordinator: coordinator))
    }

let udpPort = 9001

let udpChannel = try udpBootstrap
    .bind(host: "0.0.0.0", port: udpPort)
    .wait()

print("UDP listening on \(udpPort)")

try tcpChannel.closeFuture.wait()
try udpChannel.closeFuture.wait()
