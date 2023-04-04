//
//  GetLinkRequest.swift
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

/// Swift wrapper around a pointer to a `rtm_genlink_request`.
public struct GetLinkRequest: RawRepresentable {
    /// The underlying request.
    public var rawValue: rtm_genlink_request

    /// Raw value initialiser.
    /// - Parameter rawValue: The raw value to initialise this.
    @inlinable
    public init(rawValue: rtm_genlink_request) {
        self.rawValue = rawValue
    }

    /// Designated initialiser.
    @inlinable
    public init() {
        var request = rtm_genlink_request()
        withUnsafeMutableBytes(of: &request) { _ = $0.initializeMemory(as: UInt8.self, repeating: 0) }
        self.init(rawValue: request)
        length = nlmsg_length(MemoryLayout<rtgenmsg>.size)
        messageType = UInt16(RTM_GETLINK)
        flags = UInt16(NLM_F_REQUEST | NLM_F_DUMP)
        family = UInt8(AF_PACKET)
    }
}

/// Properties
public extension GetLinkRequest {
    /// The type of the request.
    @inlinable var messageType: UInt16 {
        get { rawValue.nlh.nlmsg_type }
        set { rawValue.nlh.nlmsg_type = newValue }
    }

    /// The length of the request in bytes.
    @inlinable var length: UInt32 {
        get { rawValue.nlh.nlmsg_len }
        set { rawValue.nlh.nlmsg_len = newValue }
    }

    /// The flags for the request.
    @inlinable var flags: UInt16 {
        get { rawValue.nlh.nlmsg_flags }
        set { rawValue.nlh.nlmsg_flags = newValue }
    }

    /// The family of the request.
    @inlinable var family: UInt8 {
        get { rawValue.gen.rtgen_family }
        set { rawValue.gen.rtgen_family = newValue }
    }
}

