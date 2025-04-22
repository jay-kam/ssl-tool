#!/bin/bash
set -e

usage() {
    arg0="$0"
    cat <<EOF
Generate CA.

Usage:
    $arg0 [OPTIONS] 

OPTIONS:
    --view-cert
        View the certificate details after generation.
    --noenc
        Don't encrypt the generated key.
    --days <DAYS>
        Specify the number of days for which the certificate is valid. [env: DAYS=]
    --common-name <COMMON_NAME>
        Specify the common name for the CA. [env: COMMON_NAME=]
    --organization <ORGANIZATION>
        Specify the organization name for the CA. [env: ORGANIZATION=]
    --unit <ORGANIZATIONAL_UNIT>
        Specify the organizational unit name for the CA. [env: ORGANIZATIONAL_UNIT=]
    -o, --out-name <OUT_NAME>
        Specify the output file name for the certificate and key. [env: OUT_NAME=]

EOF
}

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

main() {
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
            --noenc)
                ENC_OPT="-noenc"
                ;;
            --days)
                DAYS="$(parse_arg "$@")"
                shift
                ;;
            --days=*)
                DAYS="$(parse_arg "$@")"
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
                echoerr "Unknown option: $1"
                echoerr "Run with --help to see usage."
                exit 1
                ;;
            *)
                ARGS+=("$1")
                ;;
        esac
        shift
    done

    # Concatenate cn, o, and ou into subject string
    if [ -n "$COMMON_NAME" ]; then
        SUBJ="/CN=$COMMON_NAME"
    else
        SUBJ="/CN=AI"
    fi
    if [ -n "$ORGANIZATION" ]; then
        SUBJ+="/O=$ORGANIZATION"
    fi
    if [ -n "$ORGANIZATIONAL_UNIT" ]; then
        SUBJ+="/OU=$ORGANIZATIONAL_UNIT"
    fi
    if [ -z "$OUT_NAME" ]; then
        OUT_NAME="ca"
    fi

    # Generate CA key and certificate
    openssl req -x509 \
        $ENC_OPT \
        -newkey rsa:2048 \
        -extensions v3_ca \
        -days ${DAYS:-3650} \
        -subj "$SUBJ" \
        -keyout $OUT_NAME.key \
        -out $OUT_NAME.crt

    if [ -n "${VIEW_CERT-}" ]; then
        openssl x509 -in "$OUT_NAME.crt" -text -noout
    fi
}

main "$@"
