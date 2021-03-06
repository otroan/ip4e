---
title: IPv4 Forever (IP4E)
abbrev: IP4E
docname: draft-troan-intarea-ip4e-00
date: 2022-05-09
category: exp

ipr: trust200902
area: Internet
workgroup: Intarea Working Group
keyword: Internet-Draft

stand_alone: yes
pi: [toc, sortrefs, symrefs]

author:
 -
    ins: O. Troan
    name: Ole Trøan
    organization: Cisco Systems Inc.
    email: ot@cisco.com
    street: Philip Pedersens vei 1
    city: Lysaker
    code: 1364
    country: Norway

normative:
  RFC2119:
  RFC791:
  RFC8200:

informative:
  RFC5389:
  I-D.ietf-behave-turn:
  RFC2633:
  RFC7788:


--- abstract
IP4E is an alternative solution to IPv6. A "what if". What if we had followed this path instead of pursuing IPv6? IP4E connects addressing domains by doing recording route in the forwarding direction and source routing in the return direction. A host or the first addressing domain gateway (ADGW) inserts a record route header, each ADGW on the path inserts a new record route entry as the packet traverses addressing domains. When the packet arrives at the final destination, the record route is reversed and copied to a source routing header in the reply packet. The response packet is then source routed back to the sender. Ensuring that the packet will traverse the same set of addressing domains as in the forward direction.

As the solution is stateless an addressing domain may have multiple ADGWs and it will not matter through which ADGW a packet enters.



--- middle

Introduction        {#problems}
============
In the early 90s it was apparent that the current IP protocol {{RFC791}} would run out of addresses. The Internet community after much considerations came up with IPv6 {{RFC8200}} as the solution. The premise for that work was to enable global reachability across the Internet using globally scoped addresses.

In the mean time the IPv4 Internet continued to evolve. Network address translation {{RFC2633}} was created as a mechanism to share one IP address among many hosts. NAT as a mechanism has been exceedingly successful. It does not only alleviate pressure on the IPv4 address space, it also provides additional benefits. For example, NAT provides a demarcation point between end-users and the Internet provider. It allows for permissionless extensions of the network. It effectively provides a split between identifier and locator.

NAT creates it's own set of problems.
NAT (Network Address Translator) allows permissionless extensions of the network, by presenting itself as a host to the upstream network and a router to the downstream network. A NAT is directional. The NAT also allows static addressing on one side, and dynamic shortlived addressing on the other side. In case of a renumbering event all transport connections are dropped. Requiring adaptions in the transport layer. A NAT is also unidirectional in session setup. Sessions can only be set up from the inside to the outside.

NAT or more correctly NAPT has the issue of being stateful in the network. With all the implications of state maintenance and forcing traffic to be symmetrical.

IPv6 set out to restore the end-to-end-ness of IP. It has turned out that the demarcation point between the end-user network and the provider is important in operations. While IPv6 has renumbering built in, that mechanism expects that a transition from old to new prefix is supported over a relatively long time period. While providers for operational reasons are prone to flash renumber a site. IPv6 hosts and networks do not work well with this approach of renumbrering.

Also, while permisionless extensions to an IPv6 network is possible, e.g. using the protocol suite provided by homenet (HNCP {{RFC7788}}. This is not commonly deployed.

While in IPv4 a host would typically have a single IPv4 address per interface. Potentially one with local scope, but global reachability. IPv6 interfaces have multiple addresses, with different properties. The expectation is that for multi-homed sites that do not have provider independent addresses, a host will have one address per provider. Unfortunately in the 25 years since IPv6 was specified, applications and hosts have not adapted to dealing with this complexity.

In summary, address rewriting on site boundaries provides fundamental functionality in todays Internet, and the Internet community needs to adapt its architecture to accommodate that. Instead of trying to coerce the Internet deployments into the old Internet architecture.

The protocol described in this document is a "what if". In the series of alternative futures to a transition from IPv4 to IPv6. What if we instead had chosen a path as described here. What would have happened?

Requirements
============
- No state in the network
- Traffic should not have to be symmetrical (forward and reverse traffic follows the same path)
- Backwards compatible with IPv4
- Scale to indefinite number of hosts and networks

Solution
========
The current Internet consists of private domains using RFC1918 space connected across a core using global addressing. What if we made the network protocol reflect that reality? With the private to global domains connected via stateful gateways.

NAT extends the IP address space by hijacking bits from the transport layer ports. IPv6 extends the IPv4 address space by extending the source and destination addresses to 128 bits. The way of extending the address space proposed here is more flexible, backwards compatible and dynamic.

The address space is extended as a path list. Addressing domains are connected via stateless addressing domain gateways (ADGW). These ADGWs insert or append record route information in the forwarding direction and follow a source route in the reverse direction.

A packet can have both record route and source route options at the same time.

Because of the increased drop probability of IPv4 options {{RFC791}} this proposal uses the IPv6 Extension header Routing Header to encode the record route and source route options. (A reader may argue that extension headers also increase drop probablity, and they are correct of course. The authors claim is that there are more routers checking for 0x45 as the first byte in the IP header than those blocking extension headers.)

While these options can be inserted by the end-host it is expected that the first-hop / last-hop ADGW will insert/remove the options.

IP4E can support multiple levels of private domain, even using overlapping address space. They do not need to be interconnected by a global addressing domain.

Addressing domain gateway behaviour
-----------------------------------

The representation of an IPv4 address in AD#1 in the path list does not have to be in cleartext. E.g the ADGW could XOR the address with a secret key shared among all the ADGWs between the two domains. The only requirement is that any of the ADGWs on a domains edge can transform the address back to it's original form. For all other ADGWs the AD#1 address is a opaque 32-bit tag.

### ADGW behaviour - header insertion

In the case where an ADGW is connecting a RFC1918 domain to the global Internet, replacing a NAT.
Hosts are unchanged, and send the packets to the ADGW, acting as a default router.

The ADGW has an interface in the RFC1918 domain (AD-INT) and an interface in the global addressing domain (AD-EXT). When receiving a packet on the AD-INT interface, a recourd route extension header (RREH) is inserted in the packet and the original source address (from the RFC1918 domain) is added as the first entry in the RREH. The source address in the packet is then replaced with the ADGW's address on the interface connecting to AD-EXT. The packet is then forwarded normally using destination based forwarding using the destination address.

When a packet is received in the other direction, on the interface connecting to the AD-EXT domain. The packet is destined to the ADGW's address on the AD-EXT interface. The packet contains a source routing header. The packet's destination address is rewritten with the address from the source routing header.



Interactions with DNS
---------------------
Something akin to the A6 object?

As long as the IP4e AD has a route towards the global Internet, a host can use DNS as normal, resolve an A record and construct a normal IP packet. The ADGW will insert a record route in the packet with the internal host's address, and itself as a source address. With the global address in the destination address of the packet.

It's perfectly possible to represent a whole path in DNS. I.e a host in a RFC1918 domain sitting behind a global address would be represented as a path-list of {a.b.c.d, 192.168.0.1}.
One could also imagine coming up with some solution where an IP4E path list was represented as IPv6 addresses. Either in DNS or perhaps also as IPv6 packets to the host / application. Where the last ADGW would translate the IP4 packet to an IPv6 packet.

Routing
-------

Ideas to explore
-----------------
Encode the path list in an IPv6 address.

IPv6 extends the network address space

RFC791 {{RFC791}} has 


IP4e record route header
------------------------
The Type TBD Routing header has the following format:

~~~~~~~~~~

    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  Next Header  |  Hdr Ext Len  | Routing Type=N| Segments Left |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Address[1]                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Address[2]                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    .                               .                               .
    .                               .                               .
    .                               .                               .
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Address[n]                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

~~~~~~~~~~

IP4e source route header
------------------------
The Type TBD Routing header has the following format:

~~~~~~~~~~

    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  Next Header  |  Hdr Ext Len  | Routing Type=N| Segments Left |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Address[1]                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Address[2]                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    .                               .                               .
    .                               .                               .
    .                               .                               .
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Address[n]                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

~~~~~~~~~~

Security Considerations
=======================


--- back
