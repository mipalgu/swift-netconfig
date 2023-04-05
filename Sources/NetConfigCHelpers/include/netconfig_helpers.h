#ifndef NETCONFIG_HELPERS_H
#define NETCONFIG_HELPERS_H

#include <arpa/inet.h>
#include <net/if.h>
#include <sys/socket.h>
#ifdef __linux__
#include <linux/rtnetlink.h>
#endif
#include <stdbool.h>
#include <stdint.h>

#ifdef __linux__

/// Structure containing an `nlmsghdr`
/// followed by a `rtgenmsg`.
///
///
struct rtm_genlink_request
{
    /// The `nlmsghdr` header.
    struct nlmsghdr nlh;
    /// The `rtgenmsg` header.
    struct rtgenmsg gen;
};

/// The maximum value for `ifla` attributes.
extern intptr_t ifla_max;

/// Return the `rtattr` pointer for the given `ifinfomsg` pointer.
///
/// - Parameter ifm: The `ifinfomsg` pointer.
/// - Returns: The `rtattr` pointer.
/// - Note: this wraps the `IFLA_RTA` macro.
struct rtattr *ifla_rta(const struct ifinfomsg *ifm);

/// A netlink `rtgen` request message.
struct netlink_rtgen_message
{
    struct nlmsghdr nlh;
    struct rtgenmsg gen;
};

/// receive message infrastructure and buffer.
struct netlink_receive_message
{
    /// The local netlink socket address.
    struct sockaddr_nl local;

    /// The I/O vector.
    struct iovec iov;

    /// The message header.
    struct msghdr hdr;

    /// The receive buffer.
    union {
        struct nlmsghdr nlh;
        char buf[8192];
        char buffer[1];
    };
};

/// Receive a netlink response message.
/// - Parameters:
///   - fd: The socket to receive the message on.
///   - msg: The message to receive.
ssize_t recv_netlink_msg(int fd, struct netlink_receive_message *msg);

/// Parse the received message.
///
/// This function calls the corresponding callbacks for
/// `RT_NEWLINK` and related `ifinfomsg` messages.
/// - Parameters:
///   - msg: The received message.
///   - msg_len: The length as reported by `recv_netlink_msg()`
///   - user_data: a pointer passed to the callback.
///   - on_if_info: callback for `RTM_NEWLINK`, `RTM_DELLINK`, and `RTM_GETLINK` messages.
/// - Returns: `true` on success or `false` on error.
bool parse_netlink_msg(struct netlink_receive_message *msg, ssize_t msg_len, void *user_data, void (*on_if_info)(struct ifinfomsg *, struct rtnl_link_stats *, void *));

/// Return `true` if the given `nlmsghdr` pointer is okay.
///
/// - Parameter nlh: The `nlmsghdr` pointer to check.
/// - Parameter len: The length of the message.
/// - Note: this wraps the `NLMSG_OK` macro.
bool nlmsg_ok(const struct nlmsghdr *nlh, intptr_t len);

/// Return the message length of the given data length
///
/// - Parameter length: The length of the data.
/// - Note: this wraps the `NLMSG_LENGTH` macro.
uint32_t nlmsg_length(intptr_t length);

/// Return the next `nlmsghdr` pointer.
///
/// - Parameter nlh: The `nlmsghdr` pointer.
/// - Parameter len: The length of the message.
/// - Note: this wraps the `NLMSG_NEXT` macro.
struct nlmsghdr *nlmsg_next(const struct nlmsghdr *nlh, intptr_t *len);

/// Return the data of the given `nlmsghdr` pointer.
///
/// - Parameter nlh: The `nlmsghdr` pointer.
/// - Note: this wraps the `NLMSG_DATA` macro.
void *nlmsg_data(const struct nlmsghdr *nlh);

/// Return `true` if the given `rtattr` pointer is okay.
///
/// - Parameter rta: The `rtattr` pointer to check.
/// - Parameter len: The length of the `rtattr` pointer.
/// - Note: this wraps the `RTA_OK` macro.
bool rta_ok(const struct rtattr *rta, intptr_t len);

/// Return the `rtattr` length for the given size.
///
/// - Parameter size: The size of the data.
/// - Note: this wraps the `RTA_LENGTH` macro.
int rta_length(intptr_t size);

/// Return the data of the given `rtattr` pointer.
///
/// - Parameter rta: The `rtattr` pointer.
/// - Note: this wraps the `RTA_DATA` macro.
void *rta_data(const struct rtattr *rta);

/// Return the next `rtattr` pointer.
///
/// - Parameter rta: The `rtattr` pointer.
/// - Parameter attrlen: The length of the `rtattr` pointer.
/// - Note: this wraps the `RTA_NEXT` macro.
struct rtattr *rta_next(const struct rtattr *rta, intptr_t *attrlen);

/// Parse the rtattr responses into a table indexed by type.
///
/// - Parameters:
///   - tb: The table to parse the `rta` list into.
///   - count: The number of entries the table can hold.
///   - rta: The list of attributes.
///   - len: Message length without the header.
void parseRtattr(struct rtattr *tb[], size_t count, struct rtattr *rta, size_t len);

#endif // __linux__
#endif // NETCONFIG_HELPERS_H
