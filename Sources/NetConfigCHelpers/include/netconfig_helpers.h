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


/// The maximum value for `ifla` attributes.
extern intptr_t ifla_max;

/// Return the `rtattr` pointer for the given `ifinfomsg` pointer.
///
/// - Parameter ifm: The `ifinfomsg` pointer.
/// - Returns: The `rtattr` pointer.
/// - Note: this wraps the `IFLA_RTA` macro.
struct rtattr *ifla_rta(const struct ifinfomsg *ifm);

/// A netlink `rtgen` message.
struct netlink_rtgen_message
{
    struct nlmsghdr nlh;
    struct rtgenmsg gen;
};

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
int nlmsg_length(intptr_t length);

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

#endif // __linux__
#endif // NETCONFIG_HELPERS_H