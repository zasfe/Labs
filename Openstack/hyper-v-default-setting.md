# Hyper-V Config
## https://adamtheautomator.com/nested-virtualization/

```powershell
## Create a new virtual switch with the new vNAT and the type is Internal.
## This command also automatically creates a virtual network adapter with the name "vEthernet (vNAT)"
PS(관리자)> New-VMSwitch -SwitchName vNAT -SwitchType Internal

## Assign an IP address and subnet to the "vEthernet (vNAT)" network adapter.
PS(관리자)>New-NetIPAddress -IPAddress 192.168.200.1 -PrefixLength 25 -InterfaceAlias "vEthernet (vNAT)"

# Create a new NAT object called vNATNetwork in Windows for the virtual switch's internal IP address
PS(관리자)>New-NetNat -Name vNATNetwork -InternalIPInterfaceAddressPrefix 192.168.200.0/25 -Verbose

# Enable the VM's virtualization extensions
## https://docs.microsoft.com/ko-kr/virtualization/hyper-v-on-windows/user-guide/nested-virtualization
## Set-VMProcessor -VMName <VMName> -ExposeVirtualizationExtensions $true
## ex) VMname is CentOS7_packstack
PS(관리자)>Set-VMProcessor -VMName CentOS7_packstack -ExposeVirtualizationExtensions $true
```


# Step:0 VM default Setting - CentOS7
## https://docs.microsoft.com/ko-kr/azure/virtual-machines/linux/create-upload-centos

```bash
echo "NETWORKING=yes" | sudo tee --append /etc/sysconfig/network
echo "HOSTNAME=localhost.localdomain" | sudo tee --append /etc/sysconfig/network

echo "DEVICE=eth0" > /etc/sysconfig/network-scripts/ifcfg-eth0
echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "BOOTPROTO=dhcp" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "USERCTL=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "PEERDNS=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "IPV6INIT=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules

systemctl stop firewalld.service
systemctl stop iptables.service
systemctl stop ip6tables.service
systemctl disable firewalld.service
systemctl disable iptables.service
systemctl disable ip6tables.service
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network

setenforce 0
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config

yum clean all
yum -y update

# blk_update_request: i/o error, dev fd0, sector 0
echo "blacklist floppy" | sudo tee /etc/modprobe.d/blacklist-floppy.conf
rmmod floppy
dracut -f -v

```
