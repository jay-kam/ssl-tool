# SSL工具

## 简介

这是一个快速生成SSL自签名证书的小工具。

## 功能

- 生成自用CA
- 生成ssl证书

## 用法

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

选项设置:

- 指定CA

  ```shell
  sh gen_cert.sh 10.10.10.10 --ca-key /path/to/key_file --ca-cert /path/to/crt_file
  ```
  或

  ```shell
  export CA_KEY=/path/to/key_file
  export CA_CERT=/path/to/crt_file
  sh gen_cert.sh 10.10.10.10
  ```
- 指定输出文件名

  ```shell
  sh gen_cert.sh 10.10.10.10 --out-name server
  ```

- 更多选项，请查看 `--help`

  ```shell
  sh gen_cert.sh --help
  ```

