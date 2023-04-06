import CNetlink
import NetConfigCHelpers
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

/// Net configuration interface.
///
/// This class provides an interface to the netlink
/// socket used to query network interface configuration
/// and statistics.
public class NetConfig {
    /// The underlying netlink message used for communication.
    @usableFromInline var message = NetlinkMessage()
    /// The netlink socket used for communication.
    @usableFromInline let fd = socket(AF_NETLINK, CInt(SOCK_RAW.rawValue), CInt(NETLINK_ROUTE))
    /// The name of the interface.
    public let interfaceName: String
    /// The index of the interface
    @usableFromInline let interfaceIndex: UInt32?
    /// The interface statistics callback.
    var onStatistics: ((String, LinkStatistics) -> Void)?
    /// Return whether the connection is open.
    public var isOpen = false

    /// Return whether data are available for reading .
    @inlinable public var hasDataAvailable: Bool {
        var fds = pollfd(fd: fd, events: CShort(POLLIN), revents: 0)
        return poll(&fds, 1, 0) >= 0 && fds.revents == fds.events
    }

    /// Designated initialiser.
    ///
    /// - Parameter interface: The interface to look at.
    @inlinable
    public init(interface: String = "") {
        interfaceName = interface
        interfaceIndex = interface.isEmpty ? nil : if_nametoindex(interface)
    }

    deinit {
        guard fd != -1 else { return }
#if os(Linux)
        Glibc.close(fd)
#elseif os(macOS)
        Darwin.close(fd)
#endif
    }
}

public extension NetConfig {
    /// Open the net configuration interface and bind
    /// its address.
    @inlinable
    func open() -> Bool {
        guard fd != -1 else { return false }
        return bind_netlink_msg(fd, &message.rawValue)
    }

    /// Close the net configuration interface.
    @inlinable
    func close() {
        guard fd != -1 else { return }
#if os(Linux)
        Glibc.close(fd)
#elseif os(macOS)
        Darwin.close(fd)
#endif
    }

    /// Request interface statistics
    /// - Returns: `true` if the request was successful, `false` otherwise.
    @inlinable
    func requestStatistics() -> Bool {
        guard fd != -1 else { return false }
        return send_netlink_msg(fd, RTM_GETLINK, NLM_F_REQUEST | NLM_F_DUMP) > 0
    }

    /// Call the given callback for any interface statistics received.
    func forEachStatistics(_ callback: @escaping (String, LinkStatistics) -> Void) -> Bool {
        fd != -1 && withUnsafeMutablePointer(to: &message.rawValue) { msgptr in
            let messageLength = recv_netlink_msg(fd, msgptr)
            guard messageLength >= 0 else { return false }

            self.onStatistics = callback
            let rawSelf = Unmanaged.passUnretained(self).toOpaque()
            return parse_netlink_msg(msgptr, messageLength, rawSelf) { ifi, stats, ifptr in
                guard let this = ifptr.map({ Unmanaged<NetConfig>.fromOpaque($0).takeUnretainedValue() }) else { return }
                let index = this.interfaceIndex
                guard let ifi, index == nil || ifi.pointee.ifi_index == Int(index!),
                      let statistics = stats.map(LinkStatistics.init) else { return }
                var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))
                this.onStatistics?(
                    String(cString: if_indextoname(UInt32(ifi.pointee.ifi_index), &buf)),
                    statistics
                )
            }
        }
    }
}
