import CNetlink
import NetConfigCHelpers
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif
public class NetConfig {
    /// The underlying netlink message used for communication.
    var message = NetlinkMessage()
    /// The netlink socket used for communication.
    let fd = socket(AF_NETLINK, CInt(SOCK_RAW.rawValue), CInt(NETLINK_ROUTE))
    /// The name of the interface.
    let interfaceName: String
    /// The index of the interface
    let interfaceIndex: UInt32?
    /// Return whether the connection is open.
    var isOpen = false

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
        close(fd)
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
}
