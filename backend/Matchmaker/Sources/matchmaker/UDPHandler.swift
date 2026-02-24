import NIO

final class UDPHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>

    private let coordinator: MatchmakingCoordinator

    init(coordinator: MatchmakingCoordinator) {
        self.coordinator = coordinator
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let envelope = unwrapInboundIn(data)
        var buffer = envelope.data

        guard let id = buffer.readString(length: 7) else {
            return
        }

        _ = coordinator.noteUDPEndpoint(envelope.remoteAddress, for: id)
    }
}
