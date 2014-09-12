#Agenda

 * Motivation
   * Größere HA-LB Installationen
   * Viele Netze, Getrennte Routing Domains
   * Container Virtualisiertung vs Voll-Virt.
     * niedriege Latenzen
   * Fancy new Kernel-Shit
   * Weil wir es können

 * Technologie Overview
   * HA
   * LB
   * IPVS
   * iproute2
   * Namespaces
   * CGroups
   * Capabilities
   * LXC

 * Ziel: Vorstellung wie sieht unsere Umgebung aus

 * LB
   * Was ist HA?
   * Was ist ein LB?
   * Was ist IP-Balancing?
   * Technologien
     * VRRP
     * IPVS
     * Übung Simple LB

 * Netzwerkinterfaces unter Linux
   * ifconfig war gestern iproute2
   * brctl war gestern
     * ubung/beispiel
    * vconfig war gestern
     * ubung/beispiel
    * tap/veth/macvlan mit iproute2

 * Namespaces für Subsysteme
   * IPC
   * UTS
   * PID
   * Mount
   * Net
   * User
   * Übungen
     * unshare
       * UTS / host
       * PID
       * ip netns $PID
       * veth / macvlan

 * cgroups

 * Was ist LXC? netns und cgroups
   * chroot
   * plus Namespaces
   * plus CGroups
   * plus Capabilities
   * Vollcontainer vs. Application Container
   * Übungen lxc-create

 * IPVS & Namespaces => funkt super
   * Idee Applikation Container für jeden LB
     * trennt Routing und Broadcast-Domains
   * Practice
   * Script-Set

#Slides

ToDo

