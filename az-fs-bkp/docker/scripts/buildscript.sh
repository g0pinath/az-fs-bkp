
apt-get update

apt-get install ca-certificates curl apt-transport-https lsb-release gnupg gpg unzip -y
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null 
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-get update
apt-get install azure-cli

apt-get update
apt-get install unzip wget curl  software-properties-common -y
wget https://releases.hashicorp.com/terraform/0.12.13/terraform_0.12.13_linux_amd64.zip
unzip terraform_0.12.13_linux_amd64.zip
mv terraform /usr/local/bin/

# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
dpkg -i packages-microsoft-prod.deb

# Update the list of products
apt-get update

# Enable the "universe" repositories
add-apt-repository universe
#INSTALL GIT
apt install git -y
#INSTALL kubectl
apt-get update &&  apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |  apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" |  tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
#install ansible
apt-add-repository ppa:ansible/ansible
apt-get update
apt install ansible -y
# Install PowerShell
apt-get install -y powershell

