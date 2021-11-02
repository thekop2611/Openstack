### Tạo KVM bằng câu lệnh
## Bước 1: Check phần cứng có hỗ trợ ảo hoá

    - Chạy câu lệnh sau:
    
    cat /proc/cpuinfo
    
  ![image](https://user-images.githubusercontent.com/44855268/139798874-2197a6eb-c3ef-44f7-93a8-3be0edadba19.png)
    
    Trường flag có vmx là đạt yêu cầu
    
    - Kiểm tra các module KVM đã được enable
    
    lsmod | grep kvm
    
  ![image](https://user-images.githubusercontent.com/44855268/139799080-677407e1-76a4-4f20-8309-08742940327a.png)

## Bước 2: Cài đặt các package cần thiết

    yum -y install qemu-kvm libvirt virt-install bridge-utils
    
    yum install virt-manager 
    
## Bước 3: Tạo network bridge
    
    nmcli connection add type bridge autoconnect yes con-name br0 ifname br0
    
    nmcli connection modify br0 ipv4.addresses 10.0.0.30/24 ipv4.method manual
    
    nmcli connection modify br0 ipv4.gateway 10.0.0.1
    
    nmcli connection modify br0 ipv4.dns 10.0.0.1
    
    nmcli connection add type bridge-slave autoconnect yes con-name eth0 ifname eth0 master br0
    
  ![image](https://user-images.githubusercontent.com/44855268/139800803-538034c9-96d9-4927-b857-1220f63e186d.png)

 ## Bước 4: Tạo VM bằng câu lệnh
 
    cd /tmp
    
    wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
    
    virt-install --name=testkvm --vcpus=1 --memory=1024 --cdrom=/tmp/cirros-0.3.4-x86_64-disk.img --disk size=5 --os-variant=cirros0.3.4 --network bridge=br0 --graphics none --console pty,target_type=serial
    
    - Kiểm tra VM đã được tạo và running
    
    virsh list
    
  ![image](https://user-images.githubusercontent.com/44855268/139801033-5ffdf96b-3f04-4388-94c1-9fac86d25019.png)
    
## Bước 5: Kiểm tra file XML của VM
 
    virsh edit testkvm
    
  ![image](https://user-images.githubusercontent.com/44855268/139801849-21cef19e-a080-493b-ba6b-0385ab2691d9.png)

## Bước 6: Connect đến VM

    virsh console Server1
    
    ![image](https://user-images.githubusercontent.com/44855268/139803104-104cd314-38f4-4d17-8f2d-a007fa19c115.png)

    

 
    
    
    
    
    
    
