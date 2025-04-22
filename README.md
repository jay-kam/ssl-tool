# SSL-Tool

## Introduction

This is a small tool for quickly generating SSL self-signed certificates.

## Features

- Generate CA
- Generate a certificate

## How to use

### 1. Generate CA (optional)

```shell
sh gen_ca.sh
```

or generate an unencrypted key

```shell
sh gen_cert.sh --noenc
```

#### 2. Generate a certificate

```shell
sh gen_cert.sh
```

or

```shell
sh gen_cert.sh 10.10.10.10
```

You can specify some options.

- Specify CA

  ```
  sh gen_cert.sh 10.10.10.10 --ca-key /path/to/key_file --ca-cert /path/to/crt_file
  ```
  or

  ```
  export CA_KEY=/path/to/key_file
  export CA_CERT=/path/to/crt_file
  sh gen_cert.sh 10.10.10.10
  ```
- Specify the output file name

  ```
  sh gen_cert.sh 10.10.10.10 --out-name server
  ```
