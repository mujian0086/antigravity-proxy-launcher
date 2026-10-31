# Antigravity Proxy Launcher

Windows 下的非官方 Antigravity 显式 HTTP 代理启动器。把代理设置传给主程序及其继承环境的后台进程，不修改 Windows 全局代理、不修改官方安装文件，也不附带 VPN 服务或节点。

## 什么时候适用

浏览器能完成认证，但 Antigravity 后台访问 `googleapis.com` 时出现 `EOF`、连接重置或 TLS 失败，并且**相同接口通过本机 HTTP 代理可以收到响应**时，可以尝试本项目。

一个实际排障案例中，Windows 上的 Antigravity 2.28.2 在全局 TUN 下仍然失败；使用显式 HTTP 代理启动后，用户确认能够进入。这个案例不能证明所有 EOF 都由同一原因导致，也不能证明所有版本都兼容。

本项目不能修复密码错误、账号资格/地区限制、服务端故障、代理出口不可用或配额问题。它不是断线保护工具，不保证所有组件永远遵循代理，也不提供账号安全承诺。

## 快速使用

需要 Windows、Windows PowerShell 5.1、已安装的官方 Antigravity，以及一个已启动的本机 **HTTP 或 mixed 代理端口**。不需要管理员权限。不要填写 SOCKS-only 端口。

1. 下载本仓库并解压到长期保留的位置。
2. 把 `launcher.example.json` 复制为 `launcher.local.json`。
3. 将 `proxyPort` 改成代理客户端显示的 HTTP/mixed 端口。示例的 `7890` 只是默认值，不能假定每个人都相同。
4. 完全退出 Antigravity（包括托盘中的实例），再双击 `Launch.cmd`。

```json
{
  "proxyPort": 7890,
  "executablePath": ""
}
```

默认查找当前用户及 Program Files 下的稳定安装路径。自定义安装位置可填写 `Antigravity.exe` 的完整路径（JSON 中反斜杠需写成 `\\`）。只接受本机 `127.0.0.1` 的代理端口；不支持在配置中保存代理密码。

如果 PowerShell 执行策略阻止脚本，请先查看错误及所在组织的政策；本项目不自动修改执行策略、不使用 `ExecutionPolicy Bypass`。下载文件可能带有 Internet 标记，请在确认来源并审阅代码后按 Windows 提示处理，不要关闭系统安全保护。

## 桌面和任务栏入口

在项目目录打开 PowerShell，执行：

```powershell
.\Install-Shortcut.ps1
```

它只创建当前用户的桌面和开始菜单快捷方式 `Antigravity - HTTP Proxy`，已有同名入口不会被覆盖。可在开始菜单搜索这个入口，右键固定到任务栏；具体菜单取决于 Windows 版本/策略。

不要把运行后的普通 Antigravity 图标重新固定为启动入口，它可能绕过本脚本。移动项目目录后需要重新创建快捷方式。

## 检查与诊断

只检查路径和参数，不启动应用、不请求网络：

```powershell
.\Start-AntigravityProxy.ps1 -CheckOnly
```

经指定代理访问两个固定公开 Google 接口，不读取账号、Cookie 或令牌，不跟随重定向：

```powershell
.\Start-AntigravityProxy.ps1 -Diagnose
```

`curlExit=0` 且收到 HTTP 响应说明该次 TLS/HTTP 交换完成。`userinfo` 没有登录凭据时通常返回 **401**，接口根路径可能返回 **404**；这些不是登录成功的证明。`httpStatus=000` 或非零退出码应继续排查代理。诊断不自动直连，避免意外绕过用户的网络路径。

启动前只检查本机代理端口是否可连接，不代表代理远端一定健康。若程序已在运行，启动器会停止并提示退出，避免单实例复用旧环境；不会强制结束任务。

## 原理与更新兼容性

- 用进程级 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY` 指向本机 HTTP 代理；保留 `NO_PROXY=localhost,127.0.0.1,::1`，让应用内部回环连接直连。
- 同时传入 Chromium 风格 `--proxy-server` 参数；这个参数与环境变量针对不同网络栈，不等于系统级强制流量隔离。
- 每次启动重新定位已安装的程序，不复制或绑定某个版本的 EXE。通常的原地更新不会覆盖本项目。
- 更新器自动启动的实例、未来新服务或新的代理机制可能不继承设置。更新后请完全退出，再通过此入口打开；未来官方变更仍可能需要适配。
- 启动器不会修改服务端地址、关闭 TLS 验证、安装证书、修改账户区域或更改防火墙。

Google 的官方部署文档说明 Go HTTP 传输支持 `HTTP_PROXY`、`HTTPS_PROXY`、`NO_PROXY`。这里只引用其代理机制说明，不把面向美国公共部门的部署步骤作为普通账号配置建议：[官方文档](https://docs.cloud.google.com/docs/security/compliance/deploy-antigravity-us-public-sector#support-ssltls-inspection-and-certificates)。

## 测试与证据边界

```powershell
.\Test-Launcher.ps1
```

测试覆盖端口配置校验、回环排除、父进程环境不变、测试子进程继承代理环境。测试不会启动 Antigravity，不验证账号登录。最初的针对个人环境的启动器已有一次用户登录成功记录；本仓库的通用版本仍需要不同安装位置、版本和网络的用户反馈。

报告问题时可提供 Windows/Antigravity 版本、错误文字及诊断 HTTP 状态；不要上传密码、OAuth URL、Cookie、代理密钥、个人日志或完整 VPN 配置。

## 移除

退出应用，删除自行创建的快捷方式及本项目文件即可。没有常驻服务或系统代理设置需要回滚。

非 Google 官方项目，不附带或重新分发 Antigravity。MIT License。
