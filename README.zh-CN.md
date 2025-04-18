# SSL-Tool

## Introduction

这是一个快速生成SSL自签名证书的小工具。

## Features

- 生成CA
- 生成证书

## How to use

### 1. 生成CA（可跳过）

```shell
sh gen_ca.sh
```

或直接使用明文，生成不加密的key

```shell
sh gen_cert.sh --noenc
```

#### 2. 生成证书

```shell
sh gen_cert.sh
```

或

```shell
sh gen_cert.sh 10.10.10.10
```

指定输出文件名

```shell
sh gen_cert.sh 10.10.10.10 --out-name server
```
