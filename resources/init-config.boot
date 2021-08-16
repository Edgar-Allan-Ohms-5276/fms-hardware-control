firewall {
    all-ping enable
    broadcast-ping disable
    ipv6-receive-redirects disable
    ipv6-src-route disable
    ip-src-route disable
    log-martians enable
    name TEAM_TO_FMS {
        description "Allowed routes for team VLANs to FMS"
        default-action reject
        enable-default-log
        rule 10 {
            action accept
            log disable
            description "Allowed to connect to FMS"
            destination {
                address 10.0.100.5
            }
        }
    }
    name FMS_TO_TEAM {
        description "Allowed routes for team VLANs from FMS"
        default-action reject
        enable-default-log
        rule 10 {
            action accept
            log disable
            description "Allowed to connect from FMS"
            source {
                address 10.0.100.5
            }
        }
    }
    name TEAM_ROUTER {
        description "Disable router endpoint on VLANs"
        default-action drop
    }
    name WAN_IN {
        default-action drop
        description "WAN to internal"
        rule 10 {
            action accept
            state {
                established enable
                related enable
            }
            description "Allow established/related"
        }
        rule 20 {
            action drop
            state {
                invalid enable
            }
            description "Drop invalid state"
        }
    }
    name WAN_LOCAL {
        default-action drop
        description "WAN to router"
        rule 10 {
            action accept
            state {
                established enable
                related enable
            }
            description "Allow established/related"
        }
        rule 20 {
            action drop
            state {
                invalid enable
            }
            description "Drop invalid state"
        }
    }
    receive-redirects disable
    send-redirects enable
    source-validation disable
    syn-cookies enable
}
interfaces {
    ethernet eth0 {
        address 10.0.100.254/24
        address 192.168.1.1/24
        duplex auto
        speed auto
        vif 11 {
            address 10.0.111.254/24
            description "RED1"
            firewall {
                in {
                    name TEAM_TO_FMS
                }
                out {
                    name FMS_TO_TEAM
                }
                local {
                    name TEAM_ROUTER
                }
            }
        }
        vif 12 {
            address 10.0.112.254/24
            description "RED2"
            firewall {
                in {
                    name TEAM_TO_FMS
                }
                out {
                    name FMS_TO_TEAM
                }
                local {
                    name TEAM_ROUTER
                }
            }
        }
        vif 13 {
            address 10.0.113.254/24
            description "RED3"
            firewall {
                in {
                    name TEAM_TO_FMS
                }
                out {
                    name FMS_TO_TEAM
                }
                local {
                    name TEAM_ROUTER
                }
            }
        }
        vif 21 {
            address 10.0.121.254/24
            description "BLUE1"
            firewall {
                in {
                    name TEAM_TO_FMS
                }
                out {
                    name FMS_TO_TEAM
                }
                local {
                    name TEAM_ROUTER
                }
            }
        }
        vif 22 {
            address 10.0.122.254/24
            description "BLUE2"
            firewall {
                in {
                    name TEAM_TO_FMS
                }
                out {
                    name FMS_TO_TEAM
                }
                local {
                    name TEAM_ROUTER
                }
            }
        }
        vif 23 {
            address 10.0.123.254/24
            description "BLUE3"
            firewall {
                in {
                    name TEAM_TO_FMS
                }
                out {
                    name FMS_TO_TEAM
                }
                local {
                    name TEAM_ROUTER
                }
            }
        }
        vif 50 {
            address 10.0.150.254/24
            description "Sensors and Lights"
        }
        vif 60 {
            address 10.0.160.254/24
            description "Administration"
        }
    }
    ethernet eth1 {
        disable
        duplex auto
        speed auto
    }
    ethernet eth2 {
        disable
        duplex auto
        speed auto
    }
    ethernet eth3 {
        disable
        duplex auto
        speed auto
    }
    ethernet eth4 {
        speed auto
        duplex auto
        address dhcp
        description Internet
        poe {
            output off
        }
        firewall {
            in {
                name WAN_IN
            }
            local {
                name WAN_LOCAL
            }
        }
    }
    loopback lo {
    }
    switch switch0 {
        mtu 1500
    }
}
service {
    dhcp-server {
        disabled false
        hostfile-update disable
        shared-network-name LAN-ADM {
            authoritative enable
            subnet 10.0.160.0/24 {
                default-router 10.0.160.254
                dns-server 10.0.160.254
                lease 86400
                start 10.0.160.50 {
                    stop 10.0.160.150
                }
            }
        }
        shared-network-name LAN-SAL {
            authoritative enable
            subnet 10.0.150.0/24 {
                default-router 10.0.150.254
                lease 86400
                start 10.0.150.50 {
                    stop 10.0.150.150
                }
            }
        }
        shared-network-name LAN-HARD {
            authoritative enable
            subnet 10.0.100.0/24 {
                default-router 10.0.100.254
                dns-server 10.0.100.254
                lease 86400
                start 10.0.100.50 {
                    stop 10.0.100.150
                }
            }
        }
        shared-network-name RED1 {
            authoritative enable
            subnet 10.0.111.0/24 {
                default-router 10.0.111.254
                lease 86400
                start 10.0.111.50 {
                    stop 10.0.111.150
                }
            }
        }
        shared-network-name RED2 {
            authoritative enable
            subnet 10.0.112.0/24 {
                default-router 10.0.112.254
                lease 86400
                start 10.0.112.50 {
                    stop 10.0.112.150
                }
            }
        }
        shared-network-name RED3 {
            authoritative enable
            subnet 10.0.113.0/24 {
                default-router 10.0.113.254
                lease 86400
                start 10.0.113.50 {
                    stop 10.0.113.150
                }
            }
        }
        shared-network-name BLUE1 {
            authoritative enable
            subnet 10.0.121.0/24 {
                default-router 10.0.121.254
                lease 86400
                start 10.0.121.50 {
                    stop 10.0.121.150
                }
            }
        }
        shared-network-name BLUE2 {
            authoritative enable
            subnet 10.0.122.0/24 {
                default-router 10.0.122.254
                lease 86400
                start 10.0.122.50 {
                    stop 10.0.122.150
                }
            }
        }
        shared-network-name BLUE3 {
            authoritative enable
            subnet 10.0.123.0/24 {
                default-router 10.0.123.254
                lease 86400
                start 10.0.123.50 {
                    stop 10.0.123.150
                }
            }
        }
        static-arp disable
        use-dnsmasq disable
    }
    dns {
        forwarding {
            listen-on eth0
            listen-on eth0.60
            cache-size 150
            listen-on eth0
        }
    }
    gui {
        http-port 80
        https-port 443
        older-ciphers enable
    }
    nat {
        rule 5010 {
            outbound-interface eth4
            type masquerade
            description "masquerade for WAN"
        }
    }
    ssh {
        port 22
        protocol-version v2
    }
}
system {
    host-name nevermore-router
    login {
        user nevermore {
            authentication {
                plaintext-password "$DESIRED_PASSWORD"
            }
            level admin
        }
        user ubnt {
            authentication {
                plaintext-password "$DESIRED_PASSWORD"
            }
            level admin
        }
    }
    ntp {
        server 0.ubnt.pool.ntp.org {
        }
        server 1.ubnt.pool.ntp.org {
        }
        server 2.ubnt.pool.ntp.org {
        }
        server 3.ubnt.pool.ntp.org {
        }
    }
    static-host-mapping {
        host-name fms.nevermore {
            alias fms.nevermore
            alias ref.nevermore
            alias fta.nevermore
            inet 10.0.100.5
        }
        host-name router.nevermore {
            alias router.nevermore
            inet 10.0.100.254
            inet 192.168.1.1
        }
    }
    syslog {
        global {
            facility all {
                level notice
            }
            facility protocols {
                level debug
            }
        }
    }
    time-zone UTC
}

/* Warning: Do not remove the following line. */
/* === vyatta-config-version: "config-management@1:conntrack@1:cron@1:dhcp-relay@1:dhcp-server@4:firewall@5:ipsec@5:nat@3:qos@1:quagga@2:suspend@1:system@4:ubnt-pptp@1:ubnt-udapi-server@1:ubnt-unms@1:ubnt-util@1:vrrp@1:webgui@1:webproxy@1:zone-policy@1" === */
/* Release version: v1.10.7.5127989.181001.1227 */
