To generate existing SSH keys follow these steps:


1. Generate New SSH Keys
Switch to the rahuldineshk user and generate a new SSH key pair:
ssh-keygen -t rsa -b 4096 -f /home/rahuldineshk/.ssh/id_rsa

When prompted:
Press Enter to accept the default file location (/home/rahuldineshk/.ssh/id_rsa).
Optionally, set a passphrase for added security (or press Enter to leave it empty).
This will create two files:
/home/rahuldineshk/.ssh/id_rsa (private key)
/home/rahuldineshk/.ssh/id_rsa.pub (public key)

2. Copy the Public Key to the Root User
Append the new public key to the root user's authorized_keys file:
cat /home/rahuldineshk/.ssh/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys

If needed
Ensure the correct permissions for the root user's .ssh directory and authorized_keys file:
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys

3. Test the SSH Connection
From the rahuldineshk user, test the SSH connection to the root user:
ssh root@localhost

If everything is set up correctly, you should be able to log in as root without being prompted for a password.


---
Remove any Existing SSH Keys
rm -f /home/rahuldineshk/.ssh/id_rsa /home/rahuldineshk/.ssh/id_rsa.pub
This removes both the private (id_rsa) and public (id_rsa.pub) keys.

Clear the authorized_keys file to remove any previously authorized keys:
> /root/.ssh/authorized_keys
This empties the file but keeps it intact.
---
