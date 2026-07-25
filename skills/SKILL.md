---
name: mnpr-usage
description: 指导 AI 查询、使用和维护 Melorise Nix Packages Repository（MNPR）聚合索引。用于用户要求从 MNPR 查找、安装、运行、添加、更新或移除软件包，接入软件包缓存，使用 MNPR 转发的 Flake 输出，排查 MNPR 软件包配置，或者维护 MNPR 索引条目时。必须先核实 MNPR GitHub 仓库中的当前条目，再访问条目指向的上游仓库并阅读实际 Flake 或 Nix 配置。
---

# MNPR Usage

## 仓库定位

将 MNPR 视为上游 Flake 和少量传统 Nix 软件包的聚合索引。

- MNPR 提供统一名称、来源索引、版本锁定、缓存信息和必要的兼容适配。
- 软件的实际构建逻辑由条目指向的上游仓库维护。
- MNPR 不储存上游 Flake 脚本的副本。
- 不把 MNPR 当作软件本身的文档来源。
- 不在本 SKILL 中维护或介绍具体软件包。

## 强制查询流程

当用户要求使用某个 MNPR 软件包时，严格按以下顺序操作。

### 1. 查询 MNPR

先读取 `https://github.com/Melorise/MNPR/tree/unstable` 的当前内容，不依赖记忆、GitHub 默认分支或旧文档。

1. 按用户给出的名称、别名和描述搜索软件条目。
2. 读取对应条目及 MNPR 当前的加载和输出规则。
3. 确认条目至少包含非空 `description` 和有效来源。
4. 记录来源 URL、分支或 ref、是否为 Flake、缓存信息、适配层和依赖关系。
5. 通过 MNPR 当前的 `flake.nix` 确认实际导出的属性路径，不根据约定猜测。

如果没有找到条目，明确说明该软件目前不在 MNPR 中。不要把直接使用上游 Flake 描述成从 MNPR 安装。

### 2. 查询上游

从 MNPR 条目取得来源后，访问该来源的指定 ref。

对于 Flake 来源：

1. 阅读上游 `flake.nix`。
2. 核实 `packages`、`apps`、`nixosModules`、`homeManagerModules` 和 `overlays` 中实际存在的相关输出。
3. 检查软件支持的 system。
4. 必要时阅读上游 `flake.lock` 和与 Nix 使用直接相关的文档。

对于传统 Nix 来源：

1. 阅读 MNPR 条目指定的适配层。
2. 阅读上游实际被调用的 `default.nix`、`package.nix` 或其他 Nix 入口。
3. 核实适配层注入的依赖来自哪里。
4. 不把 MNPR 的薄适配层误称为上游 Flake。

只读取完成当前请求所需的上游内容，不扩展成软件功能介绍。

### 3. 核实本地配置

如果用户要求修改配置，先读取其现有 Nix 配置并沿用已有结构。

- 复用现有的 `system`、`pkgs`、inputs、模块组织和锁文件管理方式。
- 不擅自引入 Home Manager、flake-parts、新的 overlay 体系或其他框架。
- 不重构与本次软件接入无关的配置。
- 用户只要求说明时，不修改文件。

## 添加 MNPR

仅给出接入所必需的配置。Flake 配置中的基本输入形式为：

```nix
inputs.mnpr.url = "github:Melorise/MNPR/unstable";
```

不要为 MNPR 或其上游输入添加 `nixpkgs.follows`。MNPR 应保留上游锁定的输入图，以免改变 derivation 并破坏上游构建缓存命中。

更新或锁定 MNPR 时，沿用用户项目已有的 lock 管理方式。不要顺带更新无关 inputs。

## 添加软件包

以 MNPR 当前 `flake.nix` 实际导出的属性为准。常见的直接引用形态是：

```nix
inputs.mnpr.packages.${system}.<package-name>
```

其中 `system` 必须来自用户现有配置；不要假定为 `x86_64-linux`。

只有在 MNPR 当前确实提供 overlay，并且用户配置已经采用 overlay 模式时，才建议使用 overlay。先核实实际命名空间和属性路径，再添加到用户已有的 overlay 列表。

只有在上游和 MNPR 当前确实导出相应模块时，才使用：

```nix
inputs.mnpr.nixosModules.<name>
inputs.mnpr.homeManagerModules.<name>
```

不要仅根据软件名称推测模块存在，也不要用包安装代替模块配置。

对于命令行安装、构建或运行，先通过 MNPR 当前输出核实名称，再选择适用命令：

```console
nix build github:Melorise/MNPR/unstable#<name>
nix run github:Melorise/MNPR/unstable#<name>
nix profile install github:Melorise/MNPR/unstable#<name>
```

不要承诺同时支持这三种操作；它们分别取决于包、应用和可执行程序输出。

## 配置构建缓存

缓存配置属于信任配置。必须从 MNPR 当前条目读取准确的 substituter 和公钥，不猜测、不从名称拼接。

遵循以下原则：

- 只添加用户实际请求的软件所需缓存。
- 不默认添加 MNPR 中全部第三方缓存。
- 不修改或替换用户已有的 `cache.nixos.org` 配置。
- 在添加公钥前说明该操作表示信任对应缓存提供者提供签名 store paths。

直接以 MNPR 作为顶层 Flake 执行命令时，先核实 MNPR 当前 `nixConfig` 是否包含所需缓存。若包含，可使用：

```console
nix --accept-flake-config build github:Melorise/MNPR/unstable#<name>
```

当 MNPR 只是用户 Flake 的一个 input 时，不要假定 MNPR 的 `nixConfig` 会成为用户的永久 Nix 配置。优先使用 MNPR 当前提供的缓存模块或选项；使用前必须从仓库核实其真实接口。

如果 MNPR 没有适合用户现有配置的缓存模块，将条目中的 substituter 和公钥合并到用户已经使用的 Nix settings 位置。不要为了添加两项设置而改变其配置体系。

当用户准备在 NixOS 中同时添加缓存和软件包时，建议分两次操作：

1. 先只添加所需 substituter 和公钥，执行用户现有流程中的一次 `switch`。
2. 确认 Nix daemon 已加载新的缓存配置。
3. 再添加软件包，并再次执行 `switch`。

解释这一顺序：NixOS rebuild 会在切换新配置之前构建软件。如果缓存和软件包在同一次变更中加入，本次构建可能仍由尚未加载新缓存设置的 Nix daemon 执行，无法命中缓存。不要擅自指定用户应使用 `nixos-rebuild`、`nh` 或其他具体管理工具；沿用其现有的 switch 流程。

## 保持上游缓存命中

MNPR 应直接转发上游 derivation。配置时：

- 不给上游添加 `nixpkgs.follows`。
- 不使用 `overrideAttrs` 改写上游包。
- 不替换上游锁定的依赖。
- 不为修改描述或别名重新构建包。

缓存是否命中取决于最终 store path 是否与缓存中已构建的路径一致。MNPR 更新不会触发上游仓库的 CI；需要区分“使用缓存”和“触发上游构建工作流”。

## 维护 MNPR

当用户明确要求新增、修改、更新或移除 MNPR 索引条目时，必须先完整读取
[维护指南](references/maintenance.md)，再执行维护操作。

未经用户授权，不修改 MNPR、本地 Nix 配置、锁文件或远端仓库。

## 结果说明

完成操作后简要列出：

- 已在 MNPR 中核实的软件条目名称。
- 条目指向的上游来源和 ref。
- 使用的 MNPR 输出属性。
- 添加或修改的配置文件。
- 是否配置缓存及其来源。
- 上游 system、输出或模块带来的必要限制。

为 MNPR 条目和上游配置提供直接链接，使用户能够复核。不要把未经读取的推断表述为事实。
