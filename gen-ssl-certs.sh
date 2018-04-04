#!/bin/bash
 set -x
#Required
DOMAIN=$1
COMMONNAME=$DOMAIN
 
#Change to your company details
COUNTRY=VE
STATE=DC
LOCALITY=Caracas
organization=teravisiontech.com
organizationalunit=IT-DEVOPS
EMAIL=soporte@teravisiontech.com
PATHSSL="ssl-$(date +%Y%d)"
 
#Optional
PASSWORD=dummyPASSWORD





if ! [ -d "${PATHSSL}" ]
then
   mkdir -p "${PATHSSL}"

else 
   echo "Generando SSL Certs"
fi
### SSL OPTIONS
cat << EOF > $PATHSSL/dns.txt
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF


if [ -z "$DOMAIN" ]
then
    echo "Argument not present."
    echo "Useage $0 [common name]"
 
    exit 99
fi
 
echo "Generating key request for $DOMAIN"
 
#Generate a key
openssl genrsa -des3 -passout pass:$PASSWORD -out $DOMAIN.key 2048 -noout
 
#Remove passphrase from the key. Comment the line out to keep the passphrase
echo "Removing passphrase from key"
openssl rsa -in $DOMAIN.key -passin pass:$PASSWORD -out $DOMAIN.key
 
#Create the request
echo "Creating CSR"
openssl req -new -key $DOMAIN.key -out $DOMAIN.csr -passin pass:$PASSWORD  \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$organization/OU=$organizationalunit/CN=$COMMONNAME/EMAILAddress=$EMAIL" 
 
openssl x509 -req -days 365 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt -extfile  $PATHSSL/dns.txt


mv $DOMAIN.csr $DOMAIN.key $DOMAIN.crt "${PATHSSL}"
echo "---------------------------"
echo "-----Below is your CERTIFICATES-----"
echo "---------------------------"
echo

echo "---------------------------"
echo "----- your CSR-----"
echo "---------------------------"
echo
cat ${PATHSSL}/$DOMAIN.csr

echo
echo "---------------------------"
echo "----- your Key-----"
echo "---------------------------"
echo

cat ${PATHSSL}/$DOMAIN.key

echo
echo "---------------------------"
echo "----- your CERT-----"
echo "---------------------------"
echo

cat ${PATHSSL}/$DOMAIN.crt

echo "Copy it?"

read -r -p "Are you Sure? [y/N]" RESPONSE
if [[ -z "${RESPONSE}" ]]; then
   printf '%s\n' "No input entered "
   exit 1
else
   printf "You entered %s " "${RESPONSE} ,"
fi


case "${RESPONSE}" in
    [yY][eE][sS]|[yY])
        echo "Where do you want to copy it? "
        echo "root perms are neccesary.."
        read -r -p "Path like... /etc/apache2/ssl: " PATHTO
        if [ ! -d  ${PATHTO} ]
        then 
        echo "NO existe o no tiene permiso en ${PATHTO}"
        else
        echo "Copyng to ${PATHTO} "
        cp ${PATHSSL}/{$DOMAIN.csr,$DOMAIN.key,$DOMAIN.crt} ${PATHTO}
        ls -la ${PATHTO}/$DOMAIN*
        fi
        ;;
    [nN])
        echo "Do not Copy , certs on $PATHSSL"
        ls -la ${PATHSSL}/$DOMAIN*
        exit
        ;;
    *)
        echo "Select one please"
        ;;
esac

