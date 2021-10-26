### Bước 1:
Download image từ Internet:

wget https://mirror.vinahost.vn/centos/8.4.2105/isos/x86_64/CentOS-8.4.2105-x86_64-boot.iso
### Bước 2:
Upload image lên Openstack:
source /root/admin-openrc
openstack image create "Centos8"  --file CentOS-8.4.2105-x86_64-boot.iso --disk-format iso --container-format bare --public --debug
Kết quả như sau:
![image](https://user-images.githubusercontent.com/44855268/138828498-bcdeace0-aeef-48e1-a1e9-3a1deb6fa332.png)

## Các API và Endpoint:
![image](https://user-images.githubusercontent.com/44855268/138826902-0367d9fe-7702-44a8-abb2-cb830f6706cb.png)
![image](https://user-images.githubusercontent.com/44855268/138828661-b25785b2-904e-40f1-b350-3cf39581c1d2.png)


# Endpoint: http://192.168.40.37:5000/v3 - Biến môi trường OS_AUTH_URL của Keystone
           http://192.168.40.37:9292 - Endpoint của Glance service
           http://192.168.40.37:8776 - Endpoint OpenStack Block Storage volume
           http://192.168.40.37:9696 - Endpoint của Neutron
           http://192.168.40.37:8778 - Endpoint dịch vụ Placement
           http://192.168.40.37:8774 - Endpoint dịch vụ Nova
# API: key_manager API: openstack.key_manager.v1
      dns API: openstack.dns.v2
      neutronclient API: openstack.neutronclient.v2
      compute API: openstack.compute.v2
      identity API: openstack.identity.v3
      image API: openstack.image.v2
      network API: openstack.network.v2
      object_store API: openstack.object_store.v1
      volume API: openstack.volume.v3
