#!/bin/sh

set -e

CHOWN=$(/usr/bin/which chown)
SQUID=$(/usr/bin/which squid)

prepare_folders() {
	echo "Preparing folders..."
	mkdir -p /etc/squid-cert/
	mkdir -p /var/cache/squid/
	mkdir -p /var/log/squid/
	"$CHOWN" -R squid:squid /etc/squid-cert/
	"$CHOWN" -R squid:squid /var/cache/squid/
	"$CHOWN" -R squid:squid /var/log/squid/
}

initialize_cache() {
	echo "Creating cache folder..."
	"$SQUID" -z

	sleep 5
}

create_cert() {
	if [ ! -f /etc/squid-cert/squid.key ] || \
	   [ ! -f /etc/squid-cert/squid.crt ]; then
		echo "Creating certificate..."
		# openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 \
		# 	-extensions v3_ca -keyout /etc/squid-cert/squid.key \
		# 	-out /etc/squid-cert/squid.crt \
		# 	-subj "/CN=$CN/O=$O/OU=$OU/C=$C" -utf8 -nameopt multiline,utf8

                openssl genrsa -out /etc/squid-cert/squid.key 4096
                openssl req -x509 -new -nodes -subj "/CN=$CN/O=$O/OU=$OU/C=$C" \
                    -key /etc/squid-cert/squid.key -sha256 -days 3650 -out /etc/squid-cert/squid.crt
		# openssl x509 -in /etc/squid-cert/private.pem \
		# 	-outform DER -out /etc/squid-cert/CA.der

		# openssl x509 -inform DER -in /etc/squid-cert/CA.der \
		# 	-out /etc/squid-cert/CA.pem
	else
		echo "Certificate found..."
	fi
}

clear_certs_db() {
	echo "Clearing generated certificate db..."
	rm -rfv /var/lib/ssl_db/
	/usr/lib/squid/ssl_crtd -c -s /var/lib/ssl_db
	"$CHOWN" -R squid.squid /var/lib/ssl_db
}

run() {
	echo "Starting squid..."
	prepare_folders
	create_cert
	clear_certs_db
	initialize_cache
	exec "$SQUID" -NYCd 1 -f /etc/squid/squid.conf
}

run
