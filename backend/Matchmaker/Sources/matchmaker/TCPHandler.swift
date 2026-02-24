import Foundation
import NIO

final class TCPHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    private let coordinator: MatchmakingCoordinator

    init(coordinator: MatchmakingCoordinator) {
        self.coordinator = coordinator
    }

    func channelActive(context: ChannelHandlerContext) {
        _ = coordinator.registerPlayer(tcpChannel: context.channel)
    }

    func channelInactive(context: ChannelHandlerContext) {
        _ = coordinator.removePlayer(boundTo: context.channel)
    }
}
