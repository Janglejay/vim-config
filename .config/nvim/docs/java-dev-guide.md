# Neovim Java 开发配置指南

> 本文档描述当前 Neovim 配置中所有与 Java 开发相关的插件、快捷键和维护方法。
> 目标：完全替代 IntelliJ IDEA，支持美团内部大型多模块 Maven 项目。

---

## 目录

1. [环境依赖](#1-环境依赖)
2. [插件架构总览](#2-插件架构总览)
3. [快捷键速查表](#3-快捷键速查表)
4. [配置文件导航](#4-配置文件导航)
5. [核心功能详解](#5-核心功能详解)
6. [常见操作流程](#6-常见操作流程)
7. [故障排除](#7-故障排除)
8. [维护与更新](#8-维护与更新)

---

## 1. 环境依赖

### 必须安装

| 依赖 | 版本要求 | 安装方式 |
|------|----------|----------|
| Neovim | 0.10+ | `brew install neovim` |
| Java | 21（jdtls 运行环境） | `brew install --cask zulu@21` |
| ripgrep | 任意 | `brew install ripgrep` |
| fd | 任意 | `brew install fd` |
| fzf | 任意 | `brew install fzf` |
| Node.js | 18+ | `brew install node`（prettier/ts-ls 依赖） |

### 通过 Mason 自动安装的工具

Mason（`:MasonUpdate`）会自动安装以下工具，无需手动操作：

```
jdtls                  # Java Language Server
google-java-format     # Java 格式化
pyright                # Python LSP
ts_ls                  # TypeScript/JavaScript LSP
vue_ls                 # Vue LSP
eslint                 # ESLint LSP
cssls / html / emmet   # 前端 LSP
stylua                 # Lua 格式化
black / isort          # Python 格式化
prettier               # JS/TS/Vue/CSS/HTML 格式化
jq                     # JSON 格式化
```

### Lombok 支持

Mason 安装 jdtls 时会自动携带 `lombok.jar`，路径：
```
~/.local/share/nvim/mason/packages/jdtls/lombok.jar
```
配置中通过 `-javaagent` 自动注入，无需额外配置。

### Spring Boot Language Server（可选）

用于 Bean 导航、`@RequestMapping` 补全、`application.yml` 智能提示：
```bash
bash ~/.config/nvim/scripts/install-spring-boot-ls.sh
```

---

## 2. 插件架构总览

```
lua/
├── init.lua                    # 启动入口（lazy.nvim 初始化）
└── user/
    ├── options.lua             # Neovim 基础选项
    ├── keymaps.lua             # 全局快捷键
    ├── autocommands.lua        # 自动命令
    ├── plugins/
    │   ├── init.lua            # 插件汇总入口
    │   ├── java.lua            # ★ jdtls Java LSP 核心配置
    │   ├── lsp.lua             # LSP 服务器（Mason）+ conform + cmp
    │   ├── search.lua          # fzf-lua + aerial + lspsaga + 书签
    │   ├── spring.lua          # Spring HTTP 接口搜索
    │   ├── dap.lua             # 调试器（nvim-dap + dap-ui）
    │   ├── test.lua            # 测试运行器（neotest-java）
    │   ├── editing.lua         # Treesitter + flash.nvim + 文本对象
    │   ├── git.lua             # Git 集成
    │   └── ui.lua              # 主题、状态栏、文件树等 UI
    └── lsp/
        ├── handlers.lua        # LSP 通用配置（诊断、快捷键、capabilities）
        └── conform.lua         # 格式化器配置
```

### Java 相关插件一览

| 插件 | 功能 | 对应 IDEA 功能 |
|------|------|----------------|
| `mfussenegger/nvim-jdtls` | Java LSP 核心 | 内置 Java 支持 |
| `ibhagwan/fzf-lua` | 所有搜索/跳转 | Search Everywhere / Find Usages |
| `stevearc/aerial.nvim` | 文件结构大纲 | Structure 窗口 |
| `nvimdev/lspsaga.nvim` | 调用链（Call Hierarchy） | Call Hierarchy |
| `mfussenegger/nvim-dap` | 调试器 | Debug 工具 |
| `rcarriga/nvim-dap-ui` | 调试 UI 面板 | Debug 侧边栏 |
| `theHamsta/nvim-dap-virtual-text` | 调试行内变量值 | 调试行内提示 |
| `nvim-neotest/neotest` | 测试运行框架 | JUnit 运行器 |
| `rcasia/neotest-java` | Java 测试适配器 | JUnit 4/5 支持 |
| `stevearc/conform.nvim` | 代码格式化 | google-java-format |
| `MattesGroeger/vim-bookmarks` | 书签管理 | Bookmarks |
| `nvim-treesitter/nvim-treesitter` | 语法高亮/折叠/文本对象 | 内置 |
| Spring Boot LS | Bean 导航 / yml 补全 | Spring 插件 |

---

## 3. 快捷键速查表

> `<Leader>` = 空格键

### 导航与跳转

| 快捷键 | 功能 | IDEA 对应 |
|--------|------|-----------|
| `gd` | 智能跳转：在定义处→显示引用，在引用处→跳到定义 | `Cmd+B` |
| `gD` | 跳到声明 | `Cmd+Alt+B` |
| `gr` | 查找所有引用（过滤 Maven .m2） | `Alt+F7` |
| `gi` | 跳到实现 | `Cmd+Alt+B`（接口→实现） |
| `gu` | 跳到父类/接口方法 | `Cmd+U` |
| `gR` | 调用链（来调者树，lspsaga GUI） | `Ctrl+Alt+H` |
| `qi` | 快速查看实现列表 | `Cmd+Alt+B` |
| `<c-p>` | 查看文档 Hover | `F1` |
| `J` | 跳到下一个方法 | `Ctrl+Down` |
| `K` | 跳到上一个方法 | `Ctrl+Up` |
| `f` | AceJump 字符跳转 | `Cmd+Shift+F` AceJump |
| `H` | 行首 | `Home` |
| `L` | 行尾 | `End` |

### 搜索

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `<Leader>f` | 搜索项目类/接口/枚举/方法声明 | ripgrep 即时，无 LSP 依赖 |
| `<Leader>F` | 全文内容搜索（live grep） | 适合搜字符串、注解值 |
| `<Leader>e` | 最近打开文件 | RecentFiles |
| `<Leader>s` | 当前文件结构大纲（aerial） | FileStructurePopup |
| `<Leader>ha` | 搜索项目所有 Spring HTTP 接口 | Cool Request 等价 |

### LSP 操作

| 快捷键 | 功能 | IDEA 对应 |
|--------|------|-----------|
| `<Leader>R` | 重命名 | `Shift+F6` |
| `ga` | 快速修复 / Code Action | `Alt+Enter` |
| `se` | 显示当前行诊断错误 | 鼠标悬停 |
| `<F2>` | 跳到下一个错误 | `F2` |
| `<Leader>oi` | 整理导入（Java） | `Ctrl+Alt+O` |
| `<Leader>T` | 重构菜单（Java） | `Ctrl+Alt+Shift+T` |
| `<Leader>ih` | 切换 Inlay Hints 显示 | 参数名内联提示 |
| `=` | 格式化当前文件/选区 | `Cmd+Alt+L` |

### 调试

| 快捷键 | 功能 | IDEA 对应 |
|--------|------|-----------|
| `bb` | 切换断点 | `F9` |
| `bc` | 条件断点 | `Ctrl+Shift+F8` |
| `br` | 继续运行（Resume） | `F9`（已暂停时） |
| `bi` | 单步进入（StepInto） | `F7` |
| `bn` | 单步跳过（StepOver） | `F8` |
| `bp` | 单步返回（StepOut） | `Shift+F8` |
| `bf` | 运行到光标处 | `Alt+F9` |
| `be` | 表达式求值 | `Alt+F8` |
| `bv` | 查看断点面板 | Breakpoints 窗口 |
| `sd` | 切换调试 UI 面板 | Debug 工具窗口 |

**远程调试（Attach）**：`br` 时选择 "Remote Debug (Attach)"，输入主机和端口（默认 `127.0.0.1:5005`）。

Spring Boot 启动参数：
```bash
java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 -jar app.jar
```

### 测试

| 快捷键 | 功能 | IDEA 对应 |
|--------|------|-----------|
| `zr` | 运行当前文件所有测试 | `Ctrl+Shift+F10` |
| `zR` | 运行整个项目所有测试 | Run All Tests |
| `zd` | 调试最近测试方法 | Debug Test |
| `zD` | 调试整个项目所有测试 | Debug All Tests |
| `sr` | 切换测试结果面板 | Run 工具窗口 |

### 书签

| 快捷键 | 功能 | IDEA 对应 |
|--------|------|-----------|
| `mm` | 打标/取消书签 | `F11` |
| `ma` | 查看所有书签（fzf） | `Shift+F11` |
| `gm` | 跳到下一个书签 | `F4`（Bookmarks） |
| `gM` | 跳到上一个书签 | `Shift+F4` |

### jdtls 索引管理

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `<Leader>jr` | 软刷新（同步 pom.xml 变更） | 不删 workspace，快 |
| `<Leader>jR` | 全量重建（删 workspace 重启） | 约 1-3 分钟，解决索引损坏 |

### 窗口管理

| 快捷键 | 功能 |
|--------|------|
| `gh/gj/gk/gl` | 窗口导航（左/下/上/右） |
| `<Leader>w` | 隐藏/恢复所有工具窗口（IDEA Shift+F12） |
| `<Leader><Arrow>` | 调整窗口大小 |
| `gn` | 跳转匹配括号 |

### 折叠

| 快捷键 | 功能 |
|--------|------|
| `zz` | 折叠/展开当前块 |
| `zZ` | 折叠/展开所有 |

---

## 4. 配置文件导航

修改某个功能时，应该改哪个文件：

| 需求 | 文件 |
|------|------|
| jdtls JVM 参数（内存、Lombok）| `lua/user/plugins/java.lua` |
| jdtls 项目设置（completion、importOrder）| `lua/user/plugins/java.lua` → `settings.java` |
| 添加新 LSP 服务器 | `lua/user/plugins/lsp.lua` |
| 修改格式化器 | `lua/user/lsp/conform.lua` |
| 修改搜索快捷键 | `lua/user/plugins/search.lua` |
| Spring 接口搜索逻辑 | `lua/user/plugins/spring.lua` |
| 调试配置（断点、远程 attach）| `lua/user/plugins/dap.lua` |
| 测试运行配置 | `lua/user/plugins/test.lua` |
| LSP 诊断样式、通用快捷键 | `lua/user/lsp/handlers.lua` |
| 全局编辑器选项 | `lua/user/options.lua` |
| 全局快捷键 | `lua/user/keymaps.lua` |

---

## 5. 核心功能详解

### 5.1 jdtls（Java LSP）

**配置要点**：

- **Java 21 运行环境**：通过 `/usr/libexec/java_home -v 21` 自动探测，fallback 到 Zulu 21
- **Lombok**：Mason 安装 jdtls 时自带 `lombok.jar`，自动通过 `-javaagent` 注入
- **内存**：`-Xmx6g`（大型多模块项目需要，info-search 等 OOM 级项目需要 4GB+）
- **多模块 Maven**：`find_root()` 向上遍历找最顶层 `pom.xml`，避免停在子模块
- **workspace**：存储在 `~/.local/share/nvim/jdtls-workspace/<项目名>/`

**状态栏指示器**（lualine）：
- `✓ jdtls`（绿色）= 索引完成，所有功能可用
- `󰔟 jdtls`（橙色）= 正在索引中，部分功能降级
- `✗ jdtls`（红色）= 未连接

### 5.2 搜索体系

三种搜索各司其职：

| 快捷键 | 适合场景 | 底层实现 |
|--------|----------|----------|
| `<Leader>f` | 搜类名、方法名、接口名 | ripgrep 扫声明行，即时 |
| `<Leader>F` | 搜字符串内容、注解值、配置项 | ripgrep live grep |
| `<Leader>ha` | 搜 HTTP 接口路径（Spring） | ripgrep 扫 @Mapping 注解 |

`<Leader>f` 识别的 Java 声明模式：
- `class Foo` / `interface Bar` / `enum Baz` / `@interface Qux`
- `public/protected/private void/String methodName(`

`<Leader>ha` 特性：
- 自动拼接类级别 `@RequestMapping` 前缀 + 方法级别路径
- 支持多行注解（`value` 在下一行的格式）
- 识别 HTTP 方法：GET/POST/PUT/DELETE/PATCH/ANY

### 5.3 格式化

格式化**只在手动按 `=` 时触发**，不自动格式化：

| 文件类型 | 格式化器 |
|----------|----------|
| Java | google-java-format |
| JSON / JSONC | jq（2 空格缩进） |
| YAML | yamlfmt |
| Lua | stylua |
| Python | black + isort + ruff_format |
| JS/TS/Vue/CSS/HTML | prettier |

禁用自动格式化的机制：
- conform 无 `format_on_save` 配置
- `willSaveWaitUntil` LSP 协议已禁用（防止 jdtls 在保存前注入格式化）

### 5.4 Call Hierarchy（调用链）

`gR` 使用 lspsaga 的 GUI 浮窗：

| 按键 | 功能 |
|------|------|
| `u` | 展开/折叠节点 |
| `<CR>` | 跳转到调用处 |
| `v` | 垂直分割打开 |
| `s` | 水平分割打开 |
| `q` | 关闭 |

### 5.5 Inlay Hints

在方法调用处显示参数名（灰色内联提示）：
```java
orderService.create(userId: id, quantity: 3)
//                  ^^^^^^^^   ^^^^^^^^  ← 灰色提示
```

- 默认**开启**（jdtls 就绪后自动生效）
- `<Leader>ih` 切换显示/隐藏

---

## 6. 常见操作流程

### 打开新 Java 项目

```bash
# 从项目根目录（含 pom.xml）启动 nvim
cd /path/to/insurance_mall
nvim src/main/java/com/example/SomeClass.java

# jdtls 自动启动并开始索引（状态栏显示 󰔟 jdtls）
# 等待变为 ✓ jdtls 后，gd/gr/gi 等功能全部可用（约 1-3 分钟）
```

### 重建损坏的索引

```
# 全量重建（删除 workspace 重启）
<Leader>jR

# 软刷新（pom.xml 依赖变更后同步）
<Leader>jr
```

### 远程调试 Spring Boot

1. 服务端启动时添加 JVM 参数：
   ```bash
   -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005
   ```
2. 在代码里设置断点：`bb`
3. 按 `br` → 选择 "Remote Debug (Attach)" → 输入 host/port
4. 调试过程：`bi`（进入）、`bn`（跳过）、`bp`（返回）、`be`（求值）

### 查找 Spring 接口

```
<Leader>ha   # 打开 Spring 接口列表
# 输入路径关键词过滤，如 "/order" 或 "createOrder"
# <Enter> 跳转到对应 Controller 方法
```

---

## 7. 故障排除

### jdtls 一直显示 `✗`（未连接）

1. 确认当前文件是 `.java` 文件（jdtls 只在 `ft=java` 时启动）
2. 确认项目根有 `pom.xml` 或 `build.gradle`
3. 检查 Java 21 是否安装：`/usr/libexec/java_home -v 21`
4. 检查 jdtls 是否已安装：`:Mason` → 搜索 jdtls
5. 查看 LSP 日志：`:LspLog`

### jdtls 索引超时/卡住

- 大型项目（info-search 等）首次索引可能需要 5-10 分钟
- 若超过 15 分钟仍未就绪，执行全量重建：`<Leader>jR`
- OOM 问题：当前 `-Xmx6g`，如果仍 OOM 可改 `java.lua` 的 `--jvm-arg=-Xmx8g`

### `gd` 跳转没反应

- jdtls 状态必须是 `✓`（索引完成）
- 若状态是 `󰔟`，等待索引完成
- 若 LSP 未就绪，`gd` 会弹出 "LSP 未连接" 提示

### `<Leader>f` 搜不到符号

- 确认从项目根目录（最顶层 pom.xml）打开 nvim
- 确认 ripgrep 已安装：`rg --version`
- `<Leader>f` 只搜 `*.java` 文件的声明行，不搜 JAR 包内的类（那是 `gd` + LSP 的职责）

### `<Leader>ha` 显示 "no path"

- 注解路径在下一行的多行格式已支持（向后读 4 行）
- 若仍显示 no path，说明路径用了常量（如 `@GetMapping(Const.PATH)`），ripgrep 无法静态解析

### 格式化后代码被意外修改

- 确认 conform.lua 没有 `format_on_save`（当前已移除）
- 确认 `autocommands.lua` 有 `willSaveWaitUntil` handler 覆盖
- 若仍有问题，在 Neovim 中运行 `:verbose autocmd BufWritePre` 查看注册的处理器

### google-java-format 未安装

```
:Mason
# 搜索 google-java-format，按 i 安装
```

---

## 8. 维护与更新

### 更新所有插件

```
:Lazy update
```

### 更新 Mason 工具

```
:MasonUpdate
```

### 修改 jdtls 内存限制

编辑 `lua/user/plugins/java.lua`：
```lua
table.insert(cmd, "--jvm-arg=-Xmx6g")  -- 改这里，单位 g
```

### 添加新 LSP 服务器

在 `lua/user/plugins/lsp.lua` 的 `mason-lspconfig` config 函数中，参照现有格式添加：
```lua
vim.lsp.config("新服务器名", {
  cmd = { mason_bin .. "/服务器binary", "--stdio" },
  filetypes = { "对应文件类型" },
  root_markers = { "项目标记文件" },
  on_attach = handlers.on_attach,
  capabilities = handlers.capabilities,
})
vim.lsp.enable("新服务器名")
```

### 添加新格式化器

在 `lua/user/lsp/conform.lua` 的 `formatters_by_ft` 中添加：
```lua
新文件类型 = { "格式化器名称" },
```
然后通过 Mason 安装对应格式化器。

### 禁用某个 LSP 的自动格式化

在对应 LSP 的 `on_attach` 中添加：
```lua
client.server_capabilities.documentFormattingProvider = false
```

---

## 附录：目录结构速查

```
~/.local/share/nvim/
├── lazy/                       # lazy.nvim 插件安装目录
├── mason/
│   ├── bin/jdtls               # jdtls 启动脚本
│   └── packages/jdtls/
│       └── lombok.jar          # Lombok 注解处理器
├── jdtls-workspace/            # jdtls 索引缓存（按项目名分目录）
└── spring-boot-ls/             # Spring Boot Language Server（可选）
    └── spring-boot-language-server.jar
```
