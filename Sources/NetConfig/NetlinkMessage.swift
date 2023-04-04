//
//  ResponseMessage.swift
//
//
//  Created by Rene Hexel (local) on 4/4/2023.
//
import CNetlink
import NetConfigCHelpers
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

/// Swift wrapper around a pointer to a `netlink_receive_message`.
public struct NetlinkMessage: RawRepresentable {
    /// The underlying request.
    public var rawValue: netlink_receive_message

    /// Raw value initialiser.
    /// - Parameter rawValue: The raw value to initialise this.
    @inlinable
    public init(rawValue: netlink_receive_message) {
        self.rawValue = rawValue
    }

    /// Designated initialiser.
    @inlinable
    public init() {
        var request = netlink_receive_message()
        withUnsafeMutableBytes(of: &request) { _ = $0.initializeMemory(as: UInt8.self, repeating: 0) }
        self.init(rawValue: request)
        family = UInt16(AF_NETLINK)
        pid = UInt32(getpid())
    }
}

/// Properties.
public extension NetlinkMessage {
    /// The message family.
    @inlinable var family: UInt16 {
        get { rawValue.local.nl_family }
        set { rawValue.local.nl_family = newValue }
    }

    /// The unique identifier (typically the result of calling `getpid()`).
    @inlinable var pid: UInt32 {
        get { rawValue.local.nl_pid }
        set { rawValue.local.nl_pid = newValue }
    }
}
