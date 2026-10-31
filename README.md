# Antigravity Proxy Launcher

让 Windows 上的 Antigravity 主程序和后台进程通过本机 HTTP 代理连接网络。

## 适用情况

浏览器能登录，Antigravity 却在访问 `googleapis.com` 时出现 `EOF`、连接重置或 TLS 错误，而同一接口通过本机 HTTP 代理可以访问。

本项目源于一次 Windows / Antigravity 2.28.2 的排障：开启全局 TUN 后仍然报错，改为显式 HTTP 代理启动后成功进入。其他版本和网络环境可用下面的诊断命令检查。

## 快速使用

准备好 Windows PowerShell 5.1、已安装的 Antigravity，以及代理客户端的 **HTTP 或 mixed 端口**。使用普通用户权限即可。

1. 下载本仓库，解压到长期保留的位置。
2. 将 `launcher.example.json` 复制为 `launcher.local.json`。
3. 把 `proxyPort` 改成自己代理客户端的 HTTP/mixed 端口。
4. 完全退出 Antigravity（包括托盘实例），双击 `Launch.cmd`。

```json
{
  "proxyPort": 7890,
  "executablePath": ""
}
```

`7890` 是示例值。启动器连接本机 `127.0.0.1`，适用于免认证的 HTTP/mixed 端口；SOCKS-only 端口需要在代理客户端中另开 HTTP/mixed 监听。

程序默认从当前用户和 Program Files 的常见安装位置查找 Antigravity。自定义安装位置可在 `executablePath` 填写完整路径，JSON 中的反斜杠写成 `\\`。

若 PowerShell 提示执行策略或下载文件限制，请审阅脚本后按 Windows 提示及所在组织的政策处理。

## 桌面和任务栏

在项目目录打开 PowerShell，执行：

```powershell
.\Install-Shortcut.ps1
```

桌面和开始菜单会出现 **Antigravity - HTTP Proxy**。在开始菜单搜索它，右键固定到任务栏即可。已有同名快捷方式会保留。

固定时选这个代理入口，普通 Antigravity 图标会走原来的启动方式。移动项目目录后，请删除旧快捷方式并重新创建。

## 检查连接

查看程序路径和启动参数：

```powershell
.\Start-AntigravityProxy.ps1 -CheckOnly
```

通过配置的代理测试 Google 接口：

```powershell
.\Start-AntigravityProxy.ps1 -Diagnose
```

- `curlExit=0` 且收到 HTTP 状态码：本次 TLS/HTTP 交换完成。
- `userinfo` 返回 **401**：测试请求未携带登录凭据，属于预期响应。
- 接口根路径返回 **404**：服务器已响应。
- `httpStatus=000` 或 curl 退出码异常：继续检查代理连接。

这些结果用于判断连通性，实际登录还需在应用中确认。

每次启动前会检查本机代理端口。若 Antigravity 已运行，启动器会提示先退出，让新实例加载代理设置。

## 工作原理

启动器为应用进程设置 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY`，同时传入 `--proxy-server` 参数，覆盖后台 HTTP 传输和 Chromium 网络栈。`NO_PROXY` 保留 localhost、IPv4 和 IPv6 回环地址，供应用内部通信使用。

设置仅作用于此次启动的进程及继承环境的子进程，Windows 全局代理与官方安装文件保持原样。

Google 官方文档列出了 Go HTTP 传输支持的代理环境变量：[HTTP_PROXY、HTTPS_PROXY、NO_PROXY](https://docs.cloud.google.com/docs/security/compliance/deploy-antigravity-us-public-sector#support-ssltls-inspection-and-certificates)。

## 官方更新后怎么用

入口每次查找当前安装的程序，常规原地更新后可以继续使用。更新完成后，完全退出自动打开的实例，再从代理入口启动。

若官方更改安装路径、后台服务或代理机制，可能需要调整配置或适配脚本。

## 测试和反馈

```powershell
.\Test-Launcher.ps1
```

自动测试覆盖端口校验、回环排除、环境变量作用范围和子进程继承。应用登录由实际使用验证。

提交问题时，请附上 Windows / Antigravity 版本、错误文字和诊断状态码。请隐去密码、OAuth 链接、Cookie 和代理密钥。

## 移除

退出应用，删除快捷方式和项目文件即可。

## 许可

社区项目，采用 [MIT License](LICENSE)。
