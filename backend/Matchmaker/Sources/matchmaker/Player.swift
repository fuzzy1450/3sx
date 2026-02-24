import Foundation
import NIO

struct Player {
    typealias ID = String

    let id: ID
    let tcpChannel: Channel
    var udpEndpoint: SocketAddress?
}
