# Seedbox 一键安装脚本

这是一个用于 Debian / Ubuntu 服务器的 Seedbox 安装脚本，可以快速安装和配置 qBittorrent、autobrr、Vertex、autoremove-torrents，并执行基础系统调优。

## 功能

- 一键安装 qBittorrent-nox
- 可选安装 autoremove-torrents
- 可选安装 autobrr
- 可选安装 Vertex
- 自动创建运行用户
- 自动生成 systemd 服务
- 自动配置 qBittorrent WebUI 用户名、密码、端口、缓存
- 自动配置部分网络、磁盘和系统参数
- 提供一键卸载脚本

## 系统要求

- Debian 10 / 11 / 12 / 13
- Ubuntu 20.04 / 22.04 / 23.x
- 需要 root 权限
- 需要 `wget`

如果系统没有 `wget`，请先安装：

```bash
apt update && apt install -y wget
```

## 一键安装

使用 `wget` 直接运行安装脚本：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/install.sh)
```

不带参数运行时，会显示菜单：

```text
1. 一键安装
2. 一键卸载
3. Help
0. Exit
```

## 一键卸载

使用 `wget` 直接运行卸载脚本：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/uninstall.sh)
```

也可以直接用安装脚本卸载：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/install.sh) -U
```

卸载会停止并删除脚本创建的服务和程序入口。用户配置和下载数据默认保留，脚本会询问是否删除。

注意：卸载不会自动回滚系统依赖包、内核包或 sysctl 系统调优参数。

## 参数说明

### 安装脚本 `install.sh`

| 参数 | 说明 |
| --- | --- |
| `-u <username>` | 设置运行用户 |
| `-p <password>` | 设置 WebUI 密码 |
| `-c <MiB>` | 设置 qBittorrent 缓存大小，单位 MiB |
| `-q <version>` | 安装 qBittorrent，并指定 qBittorrent 版本 |
| `-l <version>` | 指定 libtorrent 版本 |
| `-r` | 安装 autoremove-torrents |
| `-b` | 安装 autobrr |
| `-v` | 安装 Vertex |
| `-o` | 手动指定端口 |
| `-U` | 一键卸载 |
| `-y` | 卸载时自动确认 |
| `-h` | 查看帮助 |

也支持长参数：

| 参数 | 说明 |
| --- | --- |
| `--install` | 进入一键安装模式 |
| `--uninstall` | 进入一键卸载模式 |
| `--yes` | 卸载时自动确认 |

### 卸载脚本 `uninstall.sh`

| 参数 | 说明 |
| --- | --- |
| `-y` | 自动确认卸载 |
| `-h` | 查看帮助 |

## 支持版本

### qBittorrent

```text
4.3.9
4.4.5
4.5.5
4.6.7
5.0.3
5.1.0
5.2.1
```

### libtorrent

```text
v1.2.15
v1.2.18
v1.2.19
v1.2.20
v2.0.5
v2.0.8
v2.0.9
v2.0.10
v2.0.11
v2.0.13
```

## 使用样例

### 只安装 qBittorrent

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/install.sh) -u admin -p adminadmin -c 4096 -q 4.3.9 -l v1.2.15
```

### 安装 qBittorrent、Vertex

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/install.sh) -u admin -p adminadmin -c 4096 -q 4.3.9 -l v1.2.15 -v
```

### 安装 qBittorrent、autobrr、Vertex、autoremove-torrents

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/install.sh) -u admin -p adminadmin -c 4096 -q 4.3.9 -l v1.2.15 -b -v -r
```

### 安装时手动指定端口

请把 `-o` 放在需要安装的组件参数后面，例如:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/install.sh) -u admin -p adminadmin -c 4096 -q 4.3.9 -l v1.2.15 -v -o
```

脚本会依次询问：

- qBittorrent WebUI 端口
- qBittorrent 传入连接端口
- autobrr 端口
- Vertex 端口

### 一键卸载

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/uninstall.sh)
```

### 自动确认卸载

```bash
bash <(wget -qO- https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/uninstall.sh) -y
```

## 默认端口

| 服务 | 默认端口 |
| --- | --- |
| qBittorrent WebUI | `8080` |
| qBittorrent 传入连接 | `45000` |
| autobrr | `7474` |
| Vertex | `3000` |

## 安装完成后

脚本会输出访问地址和账号信息，例如：

```text
qBittorrent WebUI: http://服务器IP:8080
qBittorrent Username: admin
qBittorrent Password: adminadmin
```

请根据实际输出访问对应服务。

## 参考链接
[jerry048](https://github.com/jerry048/Dedicated-Seedbox)、
[qBittorrent Install](https://github.com/userdocs/qbittorrent-nox-static)、
[qBittorrent Password Set](https://github.com/KozakaiAya/libqbpasswd)、
[Deluge Password Set](https://github.com/amefs/quickbox-lite)、
[autoremove-torrents](https://github.com/jerrymakesjelly/autoremove-torrents)
[catcat.blog](https://catcat.blog/docker-vertex-pt)
