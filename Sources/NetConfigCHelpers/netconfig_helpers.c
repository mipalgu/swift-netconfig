#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
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
uint32_t nlmsg_length(intptr_t length)
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

/// Parse the rtattr responses into a table indexed by type.
///
/// - Parameters:
///   - tb: The table to parse the `rta` list into.
///   - count: The number of entries the table can hold.
///   - rta: The list of attributes.
///   - len: Message length without the header.
void parseRtattr(struct rtattr *tb[], size_t count, struct rtattr *rta, size_t len)
{
    memset(tb, 0, sizeof(struct rtattr *) * count);

    while (RTA_OK(rta, len))         // while not end of the message
    {
        if (rta->rta_type < count)
        {
            tb[rta->rta_type] = rta; // read attribute
        }
        rta = RTA_NEXT(rta,len);
    }
}

/// Bind a netlink message.
/// - Parameters:
///   - fd: The socket to bind.
///   - msg: The message containing the bind address.
bool bind_netlink_msg(int fd, struct netlink_receive_message *msg)
{
    memset(&msg->local, 0, sizeof(msg->local));

    msg->local.nl_family = AF_NETLINK;
    msg->local.nl_pid = getpid();

    return bind(fd, (struct sockaddr *)&msg->local, sizeof(msg->local)) >= 0;
}

/// Send a netlink request message.
/// - Parameters:
///   - fd: The socket to send the message to.
///   - type: The type of message to send, e.g. `RTM_GETLINK`
///   - flags: The flags for the request, e.g. `NLM_F_REQUEST | NLM_F_DUMP`
ssize_t send_netlink_msg(int fd, intptr_t type, int32_t flags)
{
    struct netlink_rtgen_message req;

    memset(&req, 0, sizeof(req));
    req.nlh.nlmsg_len = NLMSG_LENGTH(sizeof(struct rtgenmsg));
    req.nlh.nlmsg_type = RTM_GETLINK;
    req.nlh.nlmsg_flags = NLM_F_REQUEST | NLM_F_DUMP;
    req.gen.rtgen_family = AF_PACKET;

    return send(fd, &req, req.nlh.nlmsg_len, 0);
}

/// Receive a netlink response message.
/// - Parameters:
///   - fd: The socket to receive the message on.
///   - msg: The message to receive.
ssize_t recv_netlink_msg(int fd, struct netlink_receive_message *msg)
{
    msg->iov.iov_base = msg->buf;
    msg->iov.iov_len = sizeof(msg->buf);

    msg->hdr.msg_name = &msg->local;
    msg->hdr.msg_namelen = sizeof(msg->local);
    msg->hdr.msg_iov = &msg->iov;
    msg->hdr.msg_iovlen = 1;

    return recvmsg(fd, &msg->hdr, 0);
}

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
bool parse_netlink_msg(struct netlink_receive_message *msg, ssize_t msg_len, void *user_data, void (*on_if_info)(struct ifinfomsg *, struct rtnl_link_stats *, void *))
{
    struct nlmsghdr *nlh;

    for (nlh = (struct nlmsghdr *)msg->buffer; NLMSG_OK(nlh, msg_len); nlh = NLMSG_NEXT(nlh, msg->iov.iov_len))
    {
        switch (nlh->nlmsg_type)
        {
            case NLMSG_DONE: return true;
            case NLMSG_ERROR: return false;

            case RTM_NEWLINK:
            case RTM_DELLINK:
            case RTM_GETLINK:
            {
                struct ifinfomsg *ifm = (struct ifinfomsg *)NLMSG_DATA(nlh);
                struct rtattr *rta[IFLA_MAX + 1];
                int len = nlh->nlmsg_len - NLMSG_LENGTH(sizeof(*ifm));
                parseRtattr(rta, IFLA_MAX, IFLA_RTA(ifm), len);

                if (rta[IFLA_STATS])
                    on_if_info(ifm, (struct rtnl_link_stats *)RTA_DATA(rta[IFLA_STATS]), user_data);
            }
            break;

            default:
                fprintf(stderr, "Skipped message type %d\n", (int)nlh->nlmsg_type);
        }
    }

    return true;
}

#endif // __linux__
