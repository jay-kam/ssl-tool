#!/bin/bash
set -e

parse_arg() {
    case "$1" in
        *=*)
            # Remove everything after first equal sign.
            opt="${1%%=*}"
            # Remove everything before first equal sign.
            optarg="${1#*=}"
            if [ ! "$optarg" ] && [ ! "${OPTIONAL-}" ]; then
                echoerr "$opt requires an argument"
                echoerr "Run with --help to see usage."
                exit 1
            fi
            echo "$optarg"
            return
            ;;
    esac

    case "${2-}" in
        "" | -*)
            if [ ! "${OPTIONAL-}" ]; then
                echoerr "$1 requires an argument"
                echoerr "Run with --help to see usage."
                exit 1
            fi
            ;;
        *)
            echo "$2"
            return
            ;;
    esac
}

humanpath() {
    sed "s# $HOME# ~#g; s#'$HOME#'\$HOME#g; s#\"$HOME#\"\$HOME#g"
}

echoh() {
    echo "$@" | humanpath
}

echoerr() {
    echoh "$@" >&2
}

usage() {
    arg0="$0"
    cat <<EOF
Generate certificate for a server using OpenSSL.

Usage:
    $arg0 [OPTIONS] <server_name1> <server_name2> ...

OPTIONS:
    --view-cert
        View the certificate details after generation.
    --days <DAYS>
        Specify the number of days for which the certificate is valid. [env: DAYS=]
    --ca-key <CA_KEY>
        Specify the CA private key file name. [env: CA_KEY=]
    --ca-cert <CA_CERT>
        Specify the CA certificate file name. [env: CA_CERT=]
    --download-demo-ca
        Download the demo CA certificate and key released on github.
    --common-name <COMMON_NAME>
        Specify the common name for the certificate. [env: COMMON_NAME=]
    --organization <ORGANIZATION>
        Specify the organization name for the certificate. [env: ORGANIZATION=]
    --unit <ORGANIZATIONAL_UNIT>
        Specify the organizational unit name for the certificate. [env: ORGANIZATIONAL_UNIT=]
    -o, --out-name <OUT_NAME>
        Specify the output file name for the certificate and key. [env: OUT_NAME=]
        
EOF
}

ARGS=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h | --h | -help | --help)
            usage
            exit 0
            ;;
        --view-cert)
            VIEW_CERT=1
            ;;
        --days)
            DAYS="$(parse_arg "$@")"
            shift
            ;;
        --days=*)
            DAYS="$(parse_arg "$@")"
            ;;
        --ca-key)
            CA_KEY="$(parse_arg "$@")"
            shift
            ;;
        --ca-key=*)
            CA_KEY="$(parse_arg "$@")"
            ;;
        --ca-cert)
            CA_CERT="$(parse_arg "$@")"
            shift
            ;;
        --ca-cert=*)
            CA_CERT="$(parse_arg "$@")"
            ;;
        --download-demo-ca)
            DOWNLOAD_DEMO_CA=1
            ;;
        --common-name)
            COMMON_NAME="$(parse_arg "$@")"
            shift
            ;;
        --common-name=*)
            COMMON_NAME="$(parse_arg "$@")"
            ;;
        --organization)
            ORGANIZATION="$(parse_arg "$@")"
            shift
            ;;
        --organization=*)
            ORGANIZATION="$(parse_arg "$@")"
            ;;
        --unit)
            ORGANIZATIONAL_UNIT="$(parse_arg "$@")"
            shift
            ;;
        --unit=*)
            ORGANIZATIONAL_UNIT="$(parse_arg "$@")"
            ;;
        -o | --out-name)
            OUT_NAME="$(parse_arg "$@")"
            shift
            ;;
        -o=* | --out-name=*)
            OUT_NAME="$(parse_arg "$@")"
            ;;
        --)
            shift
            ARGS+=("$@")
            break
            ;;
        -*)
            echoerr "Unknown flag $1"
            echoerr "Run with --help to see usage."
            exit 1
            ;;
        *)
            ARGS+=("$1")
            ;;
    esac
    shift
done

# Set default values of CA_KEY and CA_CERT
if [ -z "$CA_KEY" ]; then
    CA_KEY=ca.key
fi
if [ -z "$CA_CERT" ]; then
    CA_CERT=ca.crt
fi

if [ -n "$DOWNLOAD_DEMO_CA" ]; then
    if [ -f "$CA_KEY" ] || [ -f "$CA_CERT" ]; then
        echoerr "File \"$CA_KEY\" or \"$CA_CERT\" already exists. Please remove them or specify different names."
        exit 1
    fi
    curl -#fL https://github.com/jay-kam/ssl-tool/releases/download/v0.0.0/ca.crt -o $CA_CERT
    curl -#fL https://github.com/jay-kam/ssl-tool/releases/download/v0.0.0/ca.key -o $CA_KEY
    openssl rsa -passin pass:1024 -in $CA_KEY -out $CA_KEY
fi

# Input domain name or IP address
if [ ${#ARGS} -ne 0 ]; then
    SERVER_NAME=("${ARGS[@]}")
elif [ -n "$SERVER_NAME" ]; then
    SERVER_NAME=($SERVER_NAME)
else
    while true; do
        read -p "Enter Domain name or IP address: " -a SERVER_NAME
        if (( ${#SERVER_NAME[@]} > 0 )); then
            break
        fi
    done
fi

# Concatenate cn, o, and ou into subject string
if [ -n "$COMMON_NAME" ]; then
    SUBJ="/CN=$COMMON_NAME"
else
    SUBJ="/CN=$SERVER_NAME"
fi
if [ -n "$ORGANIZATION" ]; then
    SUBJ+="/O=$ORGANIZATION"
fi
if [ -n "$ORGANIZATIONAL_UNIT" ]; then
    SUBJ+="/OU=$ORGANIZATIONAL_UNIT"
fi

# Concatenate all domain names and IP addresses into subjectAltName string
SubjectAltName=()
for name in "${SERVER_NAME[@]}"; do
    if [[ $name =~ ^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}$ ]]; then
        SubjectAltName+=("IP:$name")
    else
        SubjectAltName+=("DNS:$name")
    fi
done
SubjectAltName=$(printf ",%s" "${SubjectAltName[@]}")
SubjectAltName="${SubjectAltName:1}"

# Set output file name
if [ -z "$OUT_NAME" ]; then
    if (( ${#SERVER_NAME[@]} == 1 )); then
        OUT_NAME="${SERVER_NAME[0]}"
    else
        OUT_NAME=$(printf "+%s" "${SERVER_NAME[@]}")
        OUT_NAME="${OUT_NAME:1}"
    fi
fi

# Generate CA private key and certificate if not provided
if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CERT" ]; then
    openssl req -x509 \
        -noenc \
        -days ${DAYS:-3650} \
        -subj "$SUBJ" \
        -newkey rsa:2048 \
        -extensions v3_ca \
        -keyout $CA_KEY \
        -out $CA_CERT
fi

# Generate server private key
openssl genrsa -out "$OUT_NAME.key" 2048

#  Generate CSR for server certificate
openssl req -new \
    -key "$OUT_NAME.key" \
    -subj "$SUBJ"  \
    -addext "subjectAltName=$SubjectAltName"  \
    -out "$OUT_NAME.csr"

# Generate server certificate
openssl x509 -req -sha256 \
    -in "$OUT_NAME.csr" \
    -days ${DAYS:-3650} \
    -CA $CA_CERT \
    -CAkey $CA_KEY \
    -CAcreateserial \
    -copy_extensions copyall \
    -out "$OUT_NAME.crt"

echo "Server certificate generation is done!"

if [ -n "${VIEW_CERT-}" ]; then
    openssl x509 -in "$OUT_NAME.crt" -text -noout
fi
