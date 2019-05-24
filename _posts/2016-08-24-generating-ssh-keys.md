---
layout: post
title: "Generating SSH keys for Azure Linux VMs"
categories: Linux
excerpt: "How to generate SSH keys for logging into Azure Linux VMs."
---
When creating new Azure Linux virtual machines, it is recommended you use SSH keys to connect to the VM rather than a username/password combination. Creating these keys is simple using Bash. 

Bash is native in Linux and Mac OS X but clients are available on Windows as well. [Git for Windows](https://git-scm.com/) comes with the Git Bash client. Otherwise if you are running Windows 10 with the Anniversary Update, you can use the [Windows Ubuntu Bash client](https://docs.microsoft.com/en-us/windows/wsl/about). This demo was done using Git Bash but the steps should be the same in other Bash clients.

From the Bash command prompt, run ssh-keygen with type ‘rsa’. You will be prompted for a file name and a passphrase which you can leave blank if you want. This will create the public and private RSA files.

```
ssh-keygen -t rsa
```

![Generated Key](/assets/images/generating-ssh-keys-1.jpg)

In the example above, two files were created:

- **mynewkey_rsa** - this is the private key you use when connecting to the VM
- **mynewkey_rsa.pub** - this is the public key you will use when creating the VM

The file you want when creating the VM is the public key. To display the contents of this file, you can enter the following in the bash prompt:

```
cat mynewkey_rsa.pub
```

![Generated Key](/assets/images/generating-ssh-keys-2.jpg)

This will display the contents of the public key file which you can copy and then paste into the SSH section

![Creating a new VM](/assets/images/generating-ssh-keys-3.jpg)

Once the VM is created, you should be able to ssh to it in your Bash shell by using your private key and the username/IP address of the VM you created.

```
ssh -i mynewkey_rsa myadminuser@13.92.100.189
```

![A successful login](/assets/images/generating-ssh-keys-4.jpg)

If you have an instance that you connect to on a regular basis, you can create an [ssh config](http://man.openbsd.org/ssh_config.5) file to store the settings for that VM. To do this, create a file called *config* in your *.ssh* directory (found in your home directory), or edit it if it already exists. This file can have multiple entries. To add an entry for your new VM, give it a name (it can be anything but should be easy to remember) and then set the host name, username, and identity file (which you should probably move into the *.ssh* directory). For example:

```
Host myvm
HostName 13.92.100.189
User myadminuser
IdentityFile ~/.ssh/mynewkey_rsa
```

With this in place, you can now connect to your VM using the following command:

```
ssh myvm
```

This article shows how easy it is to get up and running using SSH to connect to Azure Linux VMs. Be safe, be secure, use ssh.
