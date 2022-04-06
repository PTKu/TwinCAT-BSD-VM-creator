# TwinCAT-BSD-VM-creator
the script creates VirtualBox Virtual Machine from Twincat BSD image provided by [Beckhoff Automation](https://www.beckhoff.com/en-en/products/ipc/software-and-tools/operating-systems/c9900-s60x-cxxxxx-0185.html). You can find lots of useful information in the [documentation](https://download.beckhoff.com/download/Document/ipc/embedded-pc/embedded-pc-cx/TwinCAT_BSD_en.pdf).

## Using the batch file

Download TwinCAT BSD image from Beckhoff automation website;
Extract the zip file in the same directory where the script is located.
the image file will be xxxx.iso
open the script and modify the line 3 the "TCBSD-x64-12-40411.iso" to match your image name

SET sourcefilename="new image name.iso"

## Using PowerShell script

Run `Create-TcBsdVM.ps1` where the first parameter is the virtual machine name and the second is the TCBSD image file that you will need to download and unzip the working folder.

The script will also verify the `VirtualBox` installation at the location `Program Files\Oracle\VirtualBox` on the same drive where the working folder is located. If you have the VirtualBox installed in some other location, provide the path to that folder at the third positional parameter of the script.

The virtual machine folder will be created in the working folder.

Usage

~~~PowerShell
PS C:\YOUR_FOLDER\.\Create-TcBsdVM.ps1 MyLovelyTcBSD TCBSD-x64-12-40411.iso
~~~

# Setting up the network interface

If VMs network defaults to `NAT`, you may not be able to connect to the PLC. Therefore you should set the virtual network either to `Host-Only Adapter` if you are working with the PLC only from the host computer; or `Bridged Adpater` to set up a physical connection to the outside network.

![Host only](assets/pics/host-only.png)
![Bridged](assets/pics/bridged.png)

# Solving route creation issue

If you are having issues creating route to your VM, the reason could be that you are trying to create unsecured ADS connection. Unencrypted ADS connections are dissabled by default. To fix this issue, either use an encrypted route or update the rules in your VM's firewall. To do this, connect to your VM through WinSCP.

![WinSCP connection](assets/pics/winscp.png) 

To start WinSCP with root rights, edit connection settings and click on Advanced. Update entry for SFTP server with entry `doas /usr/libexec/sftp-server` and click OK and SAVE. 
 
![SFTP](assets/pics/sftp.png) 

Finally to update firewall rules, navigate to file `/etc/pf.conf` and add entry `pass in quick proto tcp to port 48898 synproxy state`. Save file and reboot your VM.




