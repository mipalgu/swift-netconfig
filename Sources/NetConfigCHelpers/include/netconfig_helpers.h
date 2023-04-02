#ifndef NETCONFIG_HELPERS_H
#define NETCONFIG_HELPERS_H

#include <arpa/inet.h>
#include <net/if.h>
#include <sys/socket.h>
#ifdef __linux__
#include <linux/rtnetlink.h>
#endif
#include <stdbool.h>

#ifdef __linux__

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
bool nlmsg_ok(const struct nlmsghdr *nlh, int len);

/// Return the length of the given `nlmsghdr` pointer.
///
/// - Parameter nlh: The `nlmsghdr` pointer.
/// - Note: this wraps the `NLMSG_LENGTH` macro.
int nlmsg_length(const struct nlmsghdr *nlh);

/// Return the next `nlmsghdr` pointer.
///
/// - Parameter nlh: The `nlmsghdr` pointer.
/// - Parameter len: The length of the message.
/// - Note: this wraps the `NLMSG_NEXT` macro.
struct nlmsghdr *nlmsg_next(const struct nlmsghdr *nlh, int *len);

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
bool rta_ok(const struct rtattr *rta, int len);

/// Return the length of the given `rtattr` pointer.
///
/// - Parameter rta: The `rtattr` pointer.
/// - Note: this wraps the `RTA_LENGTH` macro.
int rta_length(const struct rtattr *rta);

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
struct rtattr *rta_next(const struct rtattr *rta, int *attrlen);

#endif // __linux__
#endif // NETCONFIG_HELPERS_H