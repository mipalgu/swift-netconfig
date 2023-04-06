import CNetlink
import NetConfigCHelpers
import NetConfig
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

let arguments = CommandLine.arguments

guard arguments.count == 2 else {
    print("Usage: \(arguments[0]) <interface_name>")
    exit(1)
}

let interfaceName = arguments[1]
let ifIndex = if_nametoindex(interfaceName)

guard ifIndex != 0 else {
    print("Error: Invalid interface name")
    exit(1)
}

let fd = socket(AF_NETLINK, CInt(SOCK_RAW.rawValue), CInt(NETLINK_ROUTE))

guard fd >= 0 else {
    perror("Failed to create netlink socket")
    exit(1)
}

var message = NetlinkMessage()
guard bind_netlink_msg(fd, &message.rawValue) else {
    perror("Failed to bind netlink socket")
    close(fd)
    exit(1)
}

let sendResult = send_netlink_msg(fd, RTM_GETLINK, NLM_F_REQUEST | NLM_F_DUMP)
guard sendResult >= 0 else {
    perror("Failed to send netlink message")
    close(fd)
    exit(1)
}

withUnsafeMutablePointer(to: &message.rawValue) { msgptr in
    let messageLength = recv_netlink_msg(fd, msgptr)
    guard messageLength >= 0 else {
        perror("Failed to receive netlink message")
        close(fd)
        exit(1)
    }

//    print("Parsing message \(String(describing: msgptr)) of length: \(messageLength)")
    guard parse_netlink_msg(msgptr, messageLength, UnsafeMutableRawPointer(bitPattern: Int(ifIndex)), { ifi, stats, ifptr in
        let ifIndex = Int(bitPattern: ifptr)
        guard let ifi, ifi.pointee.ifi_index == ifIndex,
              let statistics = stats.map(LinkStatistics.init) else { return }
        var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))
        print("Interface: \(String(cString: if_indextoname(UInt32(ifi.pointee.ifi_index), &buf)))")
//        printInterfaceStats(stats: stats)
        print(statistics.description)
    }) else {
        perror("Failed to parse netlink message")
        close(fd)
        exit(1)
    }
}
close(fd)
