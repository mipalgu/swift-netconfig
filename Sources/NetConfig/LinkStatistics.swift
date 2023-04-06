import CNetlink
import NetConfigCHelpers
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

/// Swift wrapper around a pointer to a `rtnl_link_stats`.
public struct LinkStatistics {
    /// Pointer to the underlying `rtnl_link_stats` struct.
    public let linkStats: UnsafeMutablePointer<rtnl_link_stats>

    /// Creates a new `LinkStatistics` from a pointer to a `rtnl_link_stats`.
    public init(_ ptr: UnsafeMutablePointer<rtnl_link_stats>) {
        self.linkStats = ptr
    }
}

// MARK: - Properties
public extension LinkStatistics {
    /// The number of bytes received.
    @inlinable var rxBytes: Int { Int(linkStats.pointee.rx_bytes) }
    /// The number of packets received.
    @inlinable var rxPackets: Int { Int(linkStats.pointee.rx_packets) }
    /// The number of errors while receiving.
    @inlinable var rxErrors: Int { Int(linkStats.pointee.rx_errors) }
    /// The number of dropped packets while receiving.
    @inlinable var rxDropped: Int { Int(linkStats.pointee.rx_dropped) }
    /// The number of multicast packets on the interface.
    @inlinable var rxMulticast: Int { Int(linkStats.pointee.multicast) }
    /// The number of receive CRC errors.
    @inlinable var rxCrcErrors: Int { Int(linkStats.pointee.rx_crc_errors) }
    /// The number of length errors while receiving.
    @inlinable var rxLengthErrors: Int { Int(linkStats.pointee.rx_length_errors) }
    /// The number of overrun errors while receiving.
    @inlinable var rxOverErrors: Int { Int(linkStats.pointee.rx_over_errors) }
    /// The number of frame alignment errors while receiving.
    @inlinable var rxFramesErrors: Int { Int(linkStats.pointee.rx_frame_errors) }
    /// The number of FIFO overrun errors while receiving.
    @inlinable var rxFifoErrors: Int { Int(linkStats.pointee.rx_fifo_errors) }
    /// The number of missed packets while receiving.
    @inlinable var rxMissedErrors: Int { Int(linkStats.pointee.rx_missed_errors) }
    /// The number of bytes transmitted.
    @inlinable var txBytes: Int { Int(linkStats.pointee.tx_bytes) }
    /// The number of packets transmitted.
    @inlinable var txPackets: Int { Int(linkStats.pointee.tx_packets) }
    /// The number of errors while transmitting.
    @inlinable var txErrors: Int { Int(linkStats.pointee.tx_errors) }
    /// The number of dropped packets while transmitting.
    @inlinable var txDropped: Int { Int(linkStats.pointee.tx_dropped) }
    /// The number of collisions while transmitting.
    @inlinable var txCollisions: Int { Int(linkStats.pointee.collisions) }
    /// The number of transmit aborted errors.
    @inlinable var txAbortedErrors: Int { Int(linkStats.pointee.tx_aborted_errors) }
    /// The number of carrier errors.
    @inlinable var txCarrierErrors: Int { Int(linkStats.pointee.tx_carrier_errors) }
    /// The number of FIFO errors while transmitting.
    @inlinable var txFifoErrors: Int { Int(linkStats.pointee.tx_fifo_errors) }
    /// The number of heartbeat errors.
    @inlinable var txHeartbeatErrors: Int { Int(linkStats.pointee.tx_heartbeat_errors) }
    /// The number of transmit window errors.
    @inlinable var txWindowErrors: Int { Int(linkStats.pointee.tx_window_errors) }

    /// The total number of errors while receiving.
    @inlinable var rxTotalErrors: Int {
        rxErrors + rxCrcErrors + rxLengthErrors + rxOverErrors + rxFramesErrors + rxFifoErrors + rxMissedErrors
    }
    /// The total number of errors while transmitting.
    @inlinable var txTotalErrors: Int {
        txErrors + txAbortedErrors + txCarrierErrors + txFifoErrors + txHeartbeatErrors + txWindowErrors
    }
    /// The overall total number of errors.
    @inlinable var totalErrors: Int { rxTotalErrors + txTotalErrors }

    /// Statistics pretty-printed as a String.
    @inlinable var statistics: String {
        """
            rxBytes: \(rxBytes),
            rxPackets: \(rxPackets),
            rxErrors: \(rxErrors),
            rxDropped: \(rxDropped),
            rxMulticast: \(rxMulticast),
            rxCrcErrors: \(rxCrcErrors),
            rxLengthErrors: \(rxLengthErrors),
            rxOverErrors: \(rxOverErrors),
            rxFramesErrors: \(rxFramesErrors),
            rxFifoErrors: \(rxFifoErrors),
            rxMissedErrors: \(rxMissedErrors),
            txBytes: \(txBytes),
            txPackets: \(txPackets),
            txErrors: \(txErrors),
            txDropped: \(txDropped),
            txCollisions: \(txCollisions),
            txAbortedErrors: \(txAbortedErrors),
            txCarrierErrors: \(txCarrierErrors),
            txFifoErrors: \(txFifoErrors),
            txHeartbeatErrors: \(txHeartbeatErrors),
            txWindowErrors: \(txWindowErrors),
            rxTotalErrors: \(rxTotalErrors),
            txTotalErrors: \(txTotalErrors),
            totalErrors: \(totalErrors)
        """
    }
}

// MARK: - CustomStringConvertible
extension LinkStatistics: CustomStringConvertible {
    /// A textual representation of this instance.
    @inlinable public var description: String { statistics }
}

extension LinkStatistics: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    @inlinable public var debugDescription: String {
        """
        LinkStatistics(
        \(statistics)
        )
        """
    }
}

// MARK: - Equatable
extension LinkStatistics: Equatable {
    /// Returns a Boolean value indicating whether two instances
    /// reference the same underlying struct.
    @inlinable public static func === (lhs: LinkStatistics, rhs: LinkStatistics) -> Bool {
        lhs.linkStats == rhs.linkStats
    }

    /// Returns a Boolean value indicating whether two instances
    /// are equal.
    @inlinable public static func == (lhs: LinkStatistics, rhs: LinkStatistics) -> Bool {
        memcmp(lhs.linkStats, rhs.linkStats, MemoryLayout<rtnl_link_stats>.size) == 0
    }
}
