#!/bin/bash
SERVER_IP=$1
yum install -y wget unzip openssl
mkdir /etc/sslkeys/
cat << EOF > /etc/sslkeys/ssl.conf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = US
ST = NC
L =  R
O = Percona
CN = *
[v3_req]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:TRUE
subjectAltName = @alt_names
[alt_names]
IP = $SERVER_IP
EOF

cd /etc/sslkeys/
openssl req -config ssl.conf -x509 -days 365 -batch -nodes -newkey rsa:2048 -keyout vault.key -out vault.crt
cat vault.key vault.crt > vault.pem
cd 

wget https://releases.hashicorp.com/vault/1.1.2/vault_1.1.2_linux_amd64.zip
unzip vault_1.1.2_linux_amd64.zip
mv vault /usr/bin/
mkdir /etc/vault
mkdir /vault-data
mkdir -p /var/log/vault

cat << EOF > /etc/systemd/system/vault.service
[Unit]
Description=vault service
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/config.hcl
 
[Service]
EnvironmentFile=-/etc/sysconfig/vault
Environment=GOMAXPROCS=2
Restart=on-failure
ExecStart=/usr/bin/vault server -config=/etc/vault/config.hcl
StandardOutput=/var/log/vault/output.log
StandardError=/var/log/vault/error.log
LimitMEMLOCK=infinity
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
 
[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/vault/config.hcl
listener "tcp" {
address = "0.0.0.0:8200"
tls_cert_file="/etc/sslkeys/vault.crt"
tls_key_file="/etc/sslkeys/vault.key"
}
storage "file" {
path = "/var/lib/vault"
}
EOF
sudo systemctl start vault.service
sudo systemctl enable vault.service


cat << EOF >> /etc/profile
export VAULT_ADDR=https://$SERVER_IP:8200
export VAULT_CACERT=/etc/sslkeys/vault.crt
EOF
export VAULT_ADDR=https://$SERVER_IP:8200
export VAULT_CACERT=/etc/sslkeys/vault.crt
vault operator init > /etc/vault/init.file
for key in $(cat /etc/vault/init.file | grep 'Unseal Key' | awk '{print $4}'); do vault operator unseal $key; done

vault login $(cat /etc/vault/init.file | grep 'Initial Root Token' | awk '{print $4}')
vault secrets enable -path=secret/ kv

echo "*************************"
echo "Done"
echo "*************************"
echo ""
echo "Please refer to init files at /etc/vault/init.file"
