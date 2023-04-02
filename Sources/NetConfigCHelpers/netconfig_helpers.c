#include <stddef.h>
#include "netconfig_helpers.h"

#ifdef __linux__

/// The maximum value for `ifla` attributes.
intptr_t ifla_max = IFLA_MAX;

/// Return the `rtattr` pointer for the given `ifinfomsg` pointer.
///
/// - Parameter ifm: The `ifinfomsg` pointer.
/// - Returns: The `rtattr` pointer.
/// - Note: this wraps the `IFLA_RTA` macro.
struct rtattr *ifla_rta(const struct ifinfomsg *ifm)
{
    return IFLA_RTA(ifm);
}

/// Return `true` if the given `nlmsghdr` pointer is okay.
///
/// - Parameter nlh: The `nlmsghdr` pointer to check.
/// - Parameter len: The length of the message.
/// - Note: this wraps the `NLMSG_OK` macro.
bool nlmsg_ok(const struct nlmsghdr *nlh, intptr_t len)
{
    return nlh && NLMSG_OK(nlh, len);
}

/// Return the message length for the given data length.
///
/// - Parameter length: The length of the data.
/// - Note: this wraps the `NLMSG_LENGTH` macro.
int nlmsg_length(intptr_t length)
{
    return NLMSG_LENGTH(length);
}

/// Return the next `nlmsghdr` pointer.
///
/// - Parameter nlh: The `nlmsghdr` pointer.
/// - Parameter len: The length of the message.
/// - Note: this wraps the `NLMSG_NEXT` macro.
struct nlmsghdr *nlmsg_next(const struct nlmsghdr *nlh, intptr_t *len)
{
    return nlh ? NLMSG_NEXT(nlh, *len) : NULL;
}

/// Return the data of the given `nlmsghdr` pointer.
///
/// - Parameter nlh: The `nlmsghdr` pointer.
/// - Note: this wraps the `NLMSG_DATA` macro.
void *nlmsg_data(const struct nlmsghdr *nlh)
{
    return nlh ? NLMSG_DATA(nlh) : NULL;
}

/// Return `true` if the given `rtattr` pointer is okay.
///
/// - Parameter rta: The `rtattr` pointer to check.
/// - Parameter len: The length of the `rtattr` pointer.
/// - Note: this wraps the `RTA_OK` macro.
bool rta_ok(const struct rtattr *rta, intptr_t len)
{
    return rta && RTA_OK(rta, len);
}

/// Return the next `rtattr` pointer.
///
/// - Parameter rta: The `rtattr` pointer.
/// - Parameter attrlen: The length of the `rtattr` pointer.
/// - Note: this wraps the `RTA_NEXT` macro.
struct rtattr *rta_next(const struct rtattr *rta, intptr_t *attrlen)
{
    return RTA_NEXT(rta, *attrlen);
}

/// Return the length of the given `rtattr` pointer.
///
/// - Parameter rta: The `rtattr` pointer.
/// - Note: this wraps the `RTA_LENGTH` macro.
int rta_length(intptr_t size)
{
    return RTA_LENGTH(size);
}

/// Return the data of the given `rtattr` pointer.
///
/// - Parameter rta: The `rtattr` pointer.
/// - Note: this wraps the `RTA_DATA` macro.
void *rta_data(const struct rtattr *rta)
{
    return rta ? RTA_DATA(rta) : NULL;
}

#endif // __linux__
