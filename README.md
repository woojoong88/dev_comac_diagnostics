# COMAC Diagnostics Development Kit (CDDK)

CDDK is the diagnostics for VNF containers in COMAC.

This repository is NOT an official ONF repository.

The official CDDK code will be merged into the official ONF repository, hopefully.

CDDK can be used to check whether all VNF containers in COMAC is set correctly or not (i.e., CI/CD).

All scripts are developed by Woojoong Kim from Open Networking Foundation.

Current version (v1.0) is cut on May 23rd, 2019.

## Introduction
COMAC is one of the reference designs for 5G networks, which will be release officially sooner or later.

Now, initial version of CDDK (CDDK v1.0) is ready, which checks SPGW-U and SPGW-C by using TCP Replay.

The current CDDK instantiates the container *traffic* the traffic generator (this is the temporal name).

With the script in the CDDK, the container *traffic* is easily deployed.

For demonstration, the current CDDK includes the script to set SPGW-U and SPGW-C.

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
**Note:** If you don't need to set up SPGW-C and SPGW-U with CDDK, skip this step.

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

## Configuration
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

### config/ngic\_config/static\_arp.cfg
```
...
[sgi]
<IP address of traffic container connected in `brsgi` bridge> <IP address of traffic container connected in `brsgi` bridge> = <MAC address of traffic container connected in `brsgi` bridge>
...
[s1u]
<IP address of traffic container connected in `brs1u` bridge> <IP address of traffic container connected in `brs1u` bridge> = <MAC address of traffic container connected in `brs1u` bridge>
...
```

### How to generate traffic for each LTE interface?
```
root# tcpreplay --pps=200 -i $S11_IFACE tosend-s11.pcap # to generate S11 traffic
root# tcpreplay --pps=2000 -i $S1U_IFACE tosend-s1u.pcap # to generate S1U traffic
root# tcpreplay --pps=2000 -i $SGI_IFACE tosend-sgi.pcap # to generate SGI traffic
```

## Release information
* Version 1.0 - Diagnostics for SPGW-C and SPGW-U with TCP Replay.1

## Generate pcap files to run `TCPReplay`

First, access to traffic container.
Then, input the following command:
```
root# ./rewrite_pcaps.py enb.s1u.ngic spgw.s11.ngic spgw.s1u.ngic spgw.sgi.ngic
```
where
```
enb.s1u.ngic: IP address of traffic container connected in `brs1u` bridge
spgw.s11.ngic: IP address of CP container connected in `brs11` bridge
spgw.s1u.ngic: IP address of DP container connected in `brs1u` bridge
spgw.sgi.ngic: IP address of DP container connected in `brsgi` bridge
```
Note that this step spends 1-2 minutes.

## How to run?
### Overview
There is the sequence to run SPGW side by side *traffic*, which is DP -> CP -> *traffic*.

Before run everything, you need to double-check all configurations.

### How to run DP?
```
dp_container# cd /opt/ngic-rtc
dp_container# ./setup_af_ifaces.sh
dp_container# cd dp
dp_container# ./vdev.sh
```

### How to run CP?
```
cp_container# cd /opt/ngic-rtc/cp
cp_container# ./run.sh
```


### How to generate traffic for each LTE interface?
```
root# tcpreplay --pps=200 -i $S11_IFACE tosend-s11.pcap # to generate S11 traffic
root# tcpreplay --pps=2000 -i $S1U_IFACE tosend-s1u.pcap # to generate S1U traffic
root# tcpreplay --pps=2000 -i $SGI_IFACE tosend-sgi.pcap # to generate SGI traffic
```

## Release information
* Version 1.0 - Diagnostics for SPGW-C and SPGW-U with TCP Replay.
* Version 2.0 - Diagnostics for OpenMME (under development).
