import CNetlink
import NetConfigCHelpers
import NetConfig
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

let arguments = CommandLine.arguments
let netconfig = NetConfig(interface: arguments.count == 2 ? arguments[1] : "")
guard netconfig.open() else {
    perror("Failed to create netlink socket")
    exit(EXIT_FAILURE)
}

guard netconfig.requestStatistics() else {
    perror("Failed to send netlink message")
    netconfig.close()
    exit(EXIT_FAILURE)
}

guard netconfig.forEachStatistics({
    print("Interface: \($0)")
    print($1.description)
}) else {
    perror("Failed to receive netlink message")
    netconfig.close()
    exit(EXIT_FAILURE)
}
