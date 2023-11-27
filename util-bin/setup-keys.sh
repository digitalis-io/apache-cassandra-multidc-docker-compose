#!/bin/bash

set -x

CLUSTER_NAME=axonops-localdev
PASSWORD=axonops123

SSL_DIR=$PWD/../docker/ssl
TEST_RESOURCES_DIR=$PWD/../src/test/resources

echo $SSL_DIR

rm -rf "$SSL_DIR/$CLUSTER_NAME"
rm -f "$PWD/../src/test/resources/${CLUSTER_NAME}_truststore.jks"
mkdir -p "$SSL_DIR/$CLUSTER_NAME" && cd "$SSL_DIR/$CLUSTER_NAME"

if [ ! -f ca.key ]; then
  # Create root CA
  tmpFile=$(mktemp /tmp/ca.XXXXXX)

  cat > $tmpFile <<-END
  [ req ]
  distinguished_name        = req_distinguished_name
  prompt		      = no
  output_password	    = myPass
  default_bits		= 2048

  [ req_distinguished_name ]
  C			    = IE
  O			    = localdev
  OU			  = localcluster
  CN			  = rootCa
END
  openssl req \
      -config $tmpFile \
      -new -x509 -nodes \
      -keyout ca.key \
      -out ca.crt \
      -days 3650

  rm -f $tmpFile
fi

  keytool -genkeypair \
    -keyalg RSA \
    -alias "${CLUSTER_NAME}" \
    -keystore "${CLUSTER_NAME}_keystore.jks" \
    -storepass "${PASSWORD}" \
    -keypass "${PASSWORD}" \
    -validity 3650 \
    -keysize 2048 \
    -dname "CN=${CLUSTER_NAME}, OU=localcluster, O=localdev, L=Dublin, ST=Dublin, C=IE"

  keytool -importkeystore \
    -srckeystore "${CLUSTER_NAME}_keystore.jks" \
    -destkeystore "${CLUSTER_NAME}_keystore.jks" \
    -deststoretype pkcs12 \
    -deststorepass "${PASSWORD}" \
    -srcstorepass "${PASSWORD}"

  keytool -certreq \
    -alias "${CLUSTER_NAME}" \
    -keystore "${CLUSTER_NAME}_keystore.jks" \
    -file "${CLUSTER_NAME}.csr" \
    -storepass "${PASSWORD}" \
    -keypass "${PASSWORD}" \
    -dname "CN=${CLUSTER_NAME}, OU=localcluster, O=localdev, L=Dublin, ST=Dublin, C=IE"

  openssl x509 \
    -req \
    -CA ca.crt \
    -CAkey ca.key \
    -in "${CLUSTER_NAME}.csr" \
    -out "${CLUSTER_NAME}.crt" \
    -days 3650 \
    -CAcreateserial

  # Verify
  openssl verify -CAfile ca.crt "${CLUSTER_NAME}.crt"

  # import rootCA into each of the nodes
  keytool -importcert \
    -keystore "${CLUSTER_NAME}_keystore.jks" \
    -alias rootCa \
    -file ca.crt \
    -noprompt \
    -storepass "${PASSWORD}" \
    -keypass "${PASSWORD}"

  # verify again
  keytool -list -keystore "${CLUSTER_NAME}_keystore.jks" -storepass "${PASSWORD}"

  # Import node's signed certificate into node keystore for each node
  keytool -importcert \
    -alias "${CLUSTER_NAME}" \
    -keystore "${CLUSTER_NAME}_keystore.jks" \
    -file "${CLUSTER_NAME}.crt" \
    -noprompt \
    -storepass "${PASSWORD}" \
    -keypass "${PASSWORD}"


keytool -importcert \
    -keystore "${CLUSTER_NAME}_truststore.jks" \
    -alias rootCa \
    -file ca.crt \
    -noprompt \
    -storepass "${PASSWORD}" \
    -keypass "${PASSWORD}"

# Needs to exist in both filenames
cp ca.crt ca.cer

cp "${SSL_DIR}/$CLUSTER_NAME/${CLUSTER_NAME}_truststore.jks" "${TEST_RESOURCES_DIR}/${CLUSTER_NAME}_truststore.jks"