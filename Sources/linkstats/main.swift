import CNetlink
import NetConfigCHelpers
import NetConfig
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

func printInterfaceStats(stats: UnsafeMutablePointer<rtnl_link_stats>) {
    print("rx_packets: \(stats.pointee.rx_packets)")
    print("tx_packets: \(stats.pointee.tx_packets)")
    print("rx_bytes: \(stats.pointee.rx_bytes)")
    print("tx_bytes: \(stats.pointee.tx_bytes)")
    print("rx_errors: \(stats.pointee.rx_errors)")
    print("tx_errors: \(stats.pointee.tx_errors)")
    print("rx_dropped: \(stats.pointee.rx_dropped)")
    print("tx_dropped: \(stats.pointee.tx_dropped)")
    print("multicast: \(stats.pointee.multicast)")
    print("collisions: \(stats.pointee.collisions)")
    print("rx_length_errors: \(stats.pointee.rx_length_errors)")
    print("rx_over_errors: \(stats.pointee.rx_over_errors)")
    print("rx_crc_errors: \(stats.pointee.rx_crc_errors)")
    print("rx_frame_errors: \(stats.pointee.rx_frame_errors)")
    print("rx_fifo_errors: \(stats.pointee.rx_fifo_errors)")
    print("rx_missed_errors: \(stats.pointee.rx_missed_errors)")
    print("tx_aborted_errors: \(stats.pointee.tx_aborted_errors)")
    print("tx_carrier_errors: \(stats.pointee.tx_carrier_errors)")
    print("tx_fifo_errors: \(stats.pointee.tx_fifo_errors)")
    print("tx_heartbeat_errors: \(stats.pointee.tx_heartbeat_errors)")
    print("tx_window_errors: \(stats.pointee.tx_window_errors)")
}

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
        guard let ifi, let stats else {
            print("Got \(String(describing: ifi)), \(String(describing: stats))")
            return
        }
        let ifIndex = Int(bitPattern: ifptr)
        guard ifi.pointee.ifi_index == ifIndex else {
            return
        }
        var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))
        print("Interface: \(String(cString: if_indextoname(UInt32(ifi.pointee.ifi_index), &buf)))")
        printInterfaceStats(stats: stats)
    }) else {
        perror("Failed to parse netlink message")
        close(fd)
        exit(1)
    }
}
close(fd)
