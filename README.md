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

Specify the output file name:

```shell
sh gen_cert.sh 10.10.10.10 --out-name server
```
