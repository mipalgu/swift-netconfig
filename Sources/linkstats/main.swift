import CNetlink
import NetConfigCHelpers
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

func parseRtattr(tb: inout [UnsafeMutablePointer<rtattr>?], max: Int, rta rtaPtr: UnsafeMutablePointer<rtattr>, len: inout Int) {
    var rta = rtaPtr
    let zeroPtr: UnsafeMutablePointer<rtattr>? = nil
    tb = Array(repeating: zeroPtr, count: max + 1)
    
    while rta_ok(rta, len) {
        if rta.pointee.rta_type <= max {
            tb[Int(rta.pointee.rta_type)] = rta
        }
        rta = rta_next(rta, &len)
    }
}

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

var local = sockaddr_nl()
local.nl_family = UInt16(AF_NETLINK)
local.nl_pid = UInt32(getpid())

var iov = iovec(iov_base: &local, iov_len: MemoryLayout<sockaddr_nl>.size)
var msg = msghdr(msg_name: &local, msg_namelen: UInt32(MemoryLayout<sockaddr_nl>.size), msg_iov: &iov, msg_iovlen: 1, msg_control: nil, msg_controllen: 0, msg_flags: 0)

let bindResult = withUnsafeBytes(of: &local) {
    bind(fd, $0.assumingMemoryBound(to: sockaddr.self).baseAddress, socklen_t(MemoryLayout<sockaddr_nl>.size))
}
guard bindResult >= 0 else {
    perror("Failed to bind netlink socket")
    close(fd)
    exit(1)
}

var req: (nlh: nlmsghdr, gen: rtgenmsg) = (nlmsghdr(), rtgenmsg())

req.nlh.nlmsg_len = UInt32(nlmsg_length(MemoryLayout<rtgenmsg>.size))
req.nlh.nlmsg_type = UInt16(RTM_GETLINK)
req.nlh.nlmsg_flags = UInt16(NLM_F_REQUEST | NLM_F_DUMP)
req.gen.rtgen_family = UInt8(AF_PACKET)

let sendResult = send(fd, &req, Int(req.nlh.nlmsg_len), 0)

guard sendResult >= 0 else {
    perror("Failed to send netlink message")
    close(fd)
    exit(1)
}

var buf = [UInt8](repeating: 0, count: 8192)
withUnsafeMutableBytes(of: &buf) {
    let msg_len = recvmsg(fd, &msg, 0)
    
    guard msg_len >= 0 else {
        perror("Failed to receive netlink message")
        close(fd)
        exit(1)
    }
    
    var h = $0.assumingMemoryBound(to: nlmsghdr.self).baseAddress!
    var msg_len_remaining = msg_len
   
    if !nlmsg_ok(h, msg_len_remaining) {
        print("Error: Invalid netlink message")
    }
    while nlmsg_ok(h, msg_len_remaining) {
        if h.pointee.nlmsg_type == NLMSG_DONE {
            break
        }
        
        if h.pointee.nlmsg_type == UInt16(RTM_NEWLINK) {
            let ifi = nlmsg_data(h).assumingMemoryBound(to: ifinfomsg.self)
            var tb = [UnsafeMutablePointer<rtattr>?]()
            var len = Int(h.pointee.nlmsg_len) - Int(nlmsg_length(MemoryLayout<ifinfomsg>.size))
            
            parseRtattr(tb: &tb, max: ifla_max, rta: ifla_rta(ifi), len: &len)
            
            if Int(ifi.pointee.ifi_index) == ifIndex, let stats = tb[IFLA_STATS] {
                let ifName = String(cString: if_indextoname(UInt32(ifIndex), &buf))
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

close(fd)
