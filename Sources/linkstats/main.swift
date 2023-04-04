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
let bindResult = withUnsafeBytes(of: &message.rawValue.local) {
    bind(fd, $0.assumingMemoryBound(to: sockaddr.self).baseAddress, socklen_t(MemoryLayout<sockaddr_nl>.size))
}
guard bindResult >= 0 else {
    perror("Failed to bind netlink socket")
    close(fd)
    exit(1)
}

var request = GetLinkRequest()
let len = Int(request.length)
let sendResult = send(fd, &request.rawValue, len, 0)

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

    withUnsafeMutablePointer(to: &msgptr.pointee.nlh) {
        var h = $0
        var msg_len_remaining = Int(messageLength)

        if !nlmsg_ok(h, msg_len_remaining) {
            print("Error: Invalid netlink message")
        }
        while nlmsg_ok(h, msg_len_remaining) {
            if h.pointee.nlmsg_type == NLMSG_DONE {
                break
            }

            if h.pointee.nlmsg_type == UInt16(RTM_NEWLINK) {
                let ifi = nlmsg_data(h).assumingMemoryBound(to: ifinfomsg.self)
                var tb = [UnsafeMutablePointer<rtattr>?](repeating: nil, count: ifla_max)
                let len = Int(h.pointee.nlmsg_len) - Int(nlmsg_length(MemoryLayout<ifinfomsg>.size))

                parseRtattr(&tb, ifla_max, ifla_rta(ifi), len)

                if Int(ifi.pointee.ifi_index) == ifIndex, let stats = tb[IFLA_STATS] {
                    let ifName = String(cString: if_indextoname(UInt32(ifIndex), &msgptr.pointee.buffer))
                    stats.withMemoryRebound(to: rtnl_link_stats.self, capacity: 1) {
                        print("Interface: \(ifName)")
                        printInterfaceStats(stats: $0)
                        print("\n")
                    }
                    break
                } else {
                    if Int(ifi.pointee.ifi_index) != ifIndex {
                        print("Unexpected interface index \(ifi.pointee.ifi_index) (expected \(ifIndex))")
                    } else if tb[IFLA_STATS] == nil {
                        print("No stats for interface \(interfaceName)")
                    }
                }
            } else {
                print("Unexpected message type \(h.pointee.nlmsg_type) (expected \(RTM_NEWLINK))")
            }

            h = nlmsg_next(h, &msg_len_remaining)
        }

        if h.pointee.nlmsg_type != NLMSG_DONE {
            perror("Expected \(NLMSG_DONE) but got \(h.pointee.nlmsg_type)")
        }
    }
}

close(fd)
