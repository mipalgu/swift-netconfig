import CNetlink
import NetConfigCHelpers
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif
public struct NetConfig {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}
