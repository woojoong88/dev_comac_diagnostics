# COMAC VNFs Diagnostics Kit (CVDK)

CVDK is the diagnostics for VNF containers in COMAC.

This repository is NOT an official ONF repository.

The official CVDK code will be merged into the official ONF repository, hopefully.

CVDK can be used to check whether all VNF containers in COMAC is set correctly or not (i.e., CI/CD).

All scripts are developed by Woojoong Kim from Open Networking Foundation.

Current version (v1.0) is cut on May 23rd, 2019.

## Introduction
COMAC is one of the reference designs for 5G networks, which will be release officially sooner or later.

Now, initial version of CVDK (CVDK v1.0) is ready, which checks SPGW-U and SPGW-C by using TCP Replay.

The current CVDK instantiates the container *traffic* the traffic generator (this is the temporal name).

With the script in the CVDK, the container *traffic* is easily deployed.

For demonstration, the current CVDK includes the script to set SPGW-U and SPGW-C.

## Specification
* OS: Ubuntu 18.04 (fin to test)
* CPU: Intel CPU (More than Haswell CPU microarchitecture), at least 20 cores (due to the SPGW-C/U images)
* Memory: 32GB (due to the SPGW-C/U images)
* Disk: around 10GB (due to the SPGW-C/U images)

## Setup environment (for demonstration)
0. (Optional) Make a disk storage when using CloudLab
```
PM$ ./cloudlab-disk-setup.sh
```

1. Install Docker and other prerequisites
```
PM$ ./set_env.sh
```
**Note:** If you don't need to set up Docker or any other stuffs, skip this step.

2. Pull/run SPGW-C/U images and make bridges for S1U, SPGW, SGi, S11 interfaces
```
PM$ ./get_ngic_images.sh
```
**Note:** If you don't need to set up SPGW-C and SPGW-U with CVDK, skip this step.

3. Pull/run traffic generator image
```
PM$ ./get_traffic_images
```
**Note:** If you skip *2* the above step, you need some manual steps.

You initially pull and run images with below commands:
```
PM$ docker pull woojoong/omec-traffic-gen:v1-debug
PM$ docker run -t -d --name traffic --cap-add NET_ADMIN woojoong/omec-traffic-gen:v1-debug bash
```
Then, need to connect the container *traffic* into appropriate network/bridges.

* For SPGW-C test, *traffic* need to connect S11 network.
* For SPGW-U test, *traffic* need to connect both S1U and SGi networks.

Everything depands on your own environment. 

Of course, if you set up everything through 1 -> 2 -> 3, then no need the above manual steps.

## Information (for demonstration)
### Network information
* brspgw: 192.168.104.0/24
* brs11: 192.168.103.0/24
* brs1u: 192.168.105.0/24
* brsgi: 192.168.106.0/24

### How to access each container?
* DP container
```
PM$ docker exec -it dp bash
```

* CP container
```
PM$ docker exec -it cp bash
```

* Traffic generator container
```
PM$ docker exec -it traffic bash
```

### How to get IP address for each interface in each container?
1. Access each container
2. Input `ifconfig` command

## SPGW-C/U configuration (for demonstration)
### config/ngic\_config/interface.cfg in this repository
```
21: dp_comm_ip = <IP address of DP container connected in `brspgw` bridge>
...
23: cp_comm_ip = <IP address of CP container connected in `brspgw` bridge>
```

### config/ngic\_config/cp\_config.cfg in this repository
```
1: S11_SGW_IP=<IP address of CP container connected in `brs11` bridge>
2: S11_MME_IP=<IP address of traffic container connected in `brs11` bridge>
3: S1U_SGW_IP=<IP address of DP container connected in `brs1u` bridge>
```

### config/ngic\_config/dp\_config.cfg in this repository
```
1: S1U_IP=<IP address of DP container connected in `brs1u` bridge>
...
5: SGI_IP=<IP address of DP container connected in `brsgi` bridge>
...
8: SGI_GW_IP=<IP address of traffic container connected in `brsgi` bridge>
```

### config/ngic\_config/static\_arp.cfg in this repository
```
...
[sgi]
<IP address of traffic container connected in `brsgi` bridge> <IP address of traffic container connected in `brsgi` bridge> = <MAC address of traffic container connected in `brsgi` bridge>
...
[s1u]
<IP address of traffic container connected in `brs1u` bridge> <IP address of traffic container connected in `brs1u` bridge> = <MAC address of traffic container connected in `brs1u` bridge>
...
```

## Generate pcap files to run `TCPReplay`

First, access to traffic container.
Then, input the following command:
```
root# ./rewrite_pcaps.py traffic.s1u.ngic spgw.s11.ngic spgw.s1u.ngic spgw.sgi.ngic
```
where
```
traffic.s1u.ngic: IP address of traffic container connected in `brs1u` bridge
spgw.s11.ngic: IP address of CP container connected in `brs11` bridge
spgw.s1u.ngic: IP address of DP container connected in `brs1u` bridge
spgw.sgi.ngic: IP address of DP container connected in `brsgi` bridge
```
Note that this step spends 1-2 minutes.

## How to run?
### Overview
There is the sequence to run SPGW side by side *traffic*, which is DP -> CP -> *traffic*.

Before run everything, you need to double-check all configurations.

### How to run DP? (for demonstration)
```
dp_container# cd /opt/ngic-rtc
dp_container# ./setup_af_ifaces.sh
dp_container# cd dp
dp_container# ./vdev.sh
```

### How to run CP? (for demonstration)
```
cp_container# cd /opt/ngic-rtc/cp
cp_container# ./run.sh
```


### How to generate traffic for each LTE interface?
```
traffic_container# tcpreplay --pps=200 -i $S11_IFACE tosend-s11.pcap # to generate S11 traffic
traffic_container# tcpreplay --pps=2000 -i $S1U_IFACE tosend-s1u.pcap # to generate S1U traffic
traffic_container# tcpreplay --pps=2000 -i $SGI_IFACE tosend-sgi.pcap # to generate SGI traffic
```
where
* $S11\_IFACE means the network interface name (e.g., eth1) for S11 network in *traffic*
* $S1U\_IFACE means the network interface name (e.g., eth1) for S1U network in *traffic*
* $SGI\_IFACE means the network interface name (e.g., eth1) for SGI network in *traffic*

## Diagnostics
### For S11 network
After run *tcpreplay* for S11, SPGW-C is good if you can see below outputs:

1. Output in *traffic*
```
processing file: tosend-s11.pcap
Actual: 2000 packets (429000 bytes) sent in 10.09 seconds.              Rated: 42517.3 bps, 0.32 Mbps, 198.22 pps
Statistics for network device: eth1
        Attempted packets:         2000
        Successful packets:        2000
        Failed packets:            0
        Retried packets (ENOBUFS): 0
        Retried packets (EAGAIN):  0
```

2. Output in SPGW-C
```
...
  106     2000     1000      193       70     1000        0        0        0        0        0        0        0        0        0
  107     2000     1000        0        0     1000        0        0        0        0        0        0        0        0        0
  108     2000     1000        0        0     1000        0        0        0        0        0        0        0        0        0
...
```
The second, third, and sixth column values should be around 2000, 1000, and 1000, respectively.

Note that you can see so many error messages below:
```
main.c::control_plane()::Error
        case SPGWC:
        process_modify_bearer_request GTP_MODIFY_BEARER_REQ: (64) GTPV2C_CAUSE_CONTEXT_NOT_FOUND
main.c::control_plane()::Error
        case SPGWC:
        process_modify_bearer_request GTP_MODIFY_BEARER_REQ: (64) GTPV2C_CAUSE_CONTEXT_NOT_FOUND
```
You can ignore it only for the diagnostics.

### For S1U network

After run *tcpreplay* command for S1U and SGi networks, SPGW-U is good if you can see below outputs:

1. Output in *traffic*
```
processing file: tosend-s1u.pcap
Actual: 6600 packets (9124100 bytes) sent in 3.39 seconds.              Rated: 2691475.0 bps, 20.53 Mbps, 1946.90 pps
Statistics for network device: eth2
        Attempted packets:         6600
        Successful packets:        6600
        Failed packets:            0
        Retried packets (ENOBUFS): 0
        Retried packets (EAGAIN):  0
```

2. Output in SPGW-U
```
##NGCORE_SHRINK(RTC)
                  UPLINK                            ||                 DOWNLINK
IfMisPKTS    IfPKTS     UL-RX     UL-TX    UL-DFF   || IfMisPKTS    IfPKTS     DL-RX     DL-TX    DL-DFF
        0         0         0         0         0   ||         0         0         0         0         0
        0      6609      6600         0      6600   ||         0         0         0         0         0
        0      6611      6600         0      6600   ||         0         0         0         0         0
        0      6611      6600         0      6600   ||         0         0         0         0         0
        0      6611      6600         0      6600   ||         0         0         0         0         0
```
Note that UL-RX and UL-DFF should be the same number of packets which *traffic* sent (see output in *traffic*; you can see "Successful packets").

In this example, UL-RX and UL-DFF are 6600, while "Successful packets" is also 6600 in *traffic* output.

### For SGi network

After run *tcpreplay* command for S1U and SGi networks, SPGW-U is good if you can see below outputs:

1. Output in *traffic*
```
processing file: tosend-sgi.pcap
Actual: 6765 packets (9114910 bytes) sent in 3.47 seconds.              Rated: 2626775.2 bps, 20.04 Mbps, 1949.57 pps
Statistics for network device: eth3
        Attempted packets:         6765
        Successful packets:        6765
        Failed packets:            0
        Retried packets (ENOBUFS): 0
        Retried packets (EAGAIN):  0
```

2. Output in SPGW-U
```
##NGCORE_SHRINK(RTC)
                  UPLINK                            ||                 DOWNLINK
IfMisPKTS    IfPKTS     UL-RX     UL-TX    UL-DFF   || IfMisPKTS    IfPKTS     DL-RX     DL-TX    DL-DFF
        0         0         0         0         0   ||         0         0         0         0         0
        0      6609      6600         0      6600   ||         0         0         0         0         0
        0      6611      6600         0      6600   ||         0         0         0         0         0
        0      6611      6600         0      6600   ||         0         0         0         0         0
        0      6611      6600         0      6600   ||         0         0         0         0         0
        0      6611      6600         0      6600   ||         0         0         0         0         0
        0      6611      6600         0      6600   ||         0         8         0         0         0
        0      6611      6600         0      6600   ||         0      6765         0         0         0
        0      6611      6600         0      6600   ||         0      6765         0         0         0
        0      6611      6600         0      6600   ||         0      6765         0         0         0
        0      6611      6600         0      6600   ||         0      6765         0         0         0
        0      6611      6600         0      6600   ||         0      6765         0         0         0
        0      6611      6600         0      6600   ||         0      6765         0         0         0
        0      6611      6600         0      6600   ||         0      6765         0         0         0
        0      6611      6600         0      6600   ||         0      6765         0         0         0
```
Note that IFPKTS in Downlink should be the same number of packets which *traffic* sent (see output in *traffic*; you can see "Successful packets").

In this example, those are 6765.

## How to clean up? (for demonstration)
```
PM$ ./reset.sh
```

## Release information
* Version 1.0 - Diagnostics for SPGW-C and SPGW-U with TCP Replay.
* Version 2.0 - Diagnostics for OpenMME (under development).
