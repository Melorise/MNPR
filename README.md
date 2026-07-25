# Melorise Nix Packages Repository

MNPR 是一个 Flake 原生的第三方软件聚合索引。软件的实际 Nix 构建逻辑仍由各自的上游仓库维护；MNPR 只负责统一命名、锁定来源、转发标准 Flake 输出、记录构建缓存，并为不提供 Flake 的传统 Nix 项目添加必要的薄适配层。

## 使用

查看当前输出：

```console
nix flake show github:Melorise/MNPR/unstable
```

临时构建、运行或安装软件：

```console
nix build github:Melorise/MNPR/unstable#<name>
nix run github:Melorise/MNPR/unstable#<name>
nix profile install github:Melorise/MNPR/unstable#<name>
```

并非每个软件都同时提供可运行的 app 和可执行 package；以 `nix flake show` 的实际输出为准。

在自己的 Flake 中添加 MNPR：

```nix
{
  inputs.mnpr.url = "github:Melorise/MNPR/unstable";

  outputs =
    { self, mnpr, ... }:
    {
      # 在现有配置中引用：
      # mnpr.packages.${system}.<name>
    };
}
```

不要为 MNPR 添加 `nixpkgs.follows`。MNPR 保留上游 Flake 自己锁定的输入图，以尽量保证上游构建缓存能够命中。

## Overlay

MNPR 提供一个带命名空间的默认 overlay：

```nix
nixpkgs.overlays = [ inputs.mnpr.overlays.default ];
```

应用后，软件包位于：

```nix
pkgs.mnpr.<name>
```

MNPR 也会以软件名称转发上游提供的默认 overlay。只有确实需要上游 overlay 行为时才使用这些输出。

## 构建缓存

直接从 MNPR 构建时，可明确接受仓库提供的 Flake 配置：

```console
nix --accept-flake-config build github:Melorise/MNPR/unstable#<name>
```

这会启用 MNPR 条目中登记的第三方 substituter 和公钥。公钥表示对对应缓存提供者的信任，请在接受前核实配置。

在 NixOS 配置中可以选择性启用所需软件的缓存：

```nix
{
  imports = [ inputs.mnpr.nixosModules.caches ];

  mnpr.caches.enable = [
    "<name>"
  ];
}
```

建议分两次应用配置：

1. 先只添加 MNPR 缓存模块及所需软件的缓存名称，然后执行一次 `switch`。
2. 确认新的 substituter 和公钥已经由 Nix daemon 加载。
3. 再把软件包加入系统配置，并再次执行 `switch`。

NixOS 在一次 rebuild 中会先完成构建，之后才切换到新配置。如果缓存设置和软件包在同一次变更中加入，负责本次构建的 Nix daemon 可能尚未使用新的缓存配置，导致软件仍从源码构建。先单独应用缓存配置，可以让后续软件构建正常查询并命中对应缓存。

MNPR 作为另一个 Flake 的 input 时，不应依赖其 `nixConfig` 自动成为系统的永久 Nix 配置。

## 仓库结构

```text
.
├── entries/                  # 每个软件一个索引条目
├── lib/mk-outputs.nix        # 通用 Flake 输出聚合器
├── modules/caches.nix        # 选择性缓存配置模块
├── mnpr-usage/               # 面向 AI 的 MNPR 使用 SKILL
├── scripts/generate-flake.py # 从条目生成字面 Flake inputs
└── flake.nix                 # 自动生成的顶层入口
```

普通 Flake 条目只需要来源与描述：

```nix
{
  description = "A concise description from upstream";
  source.url = "github:owner/repository/ref";
}
```

需要缓存时增加：

```nix
caches = [
  {
    substituter = "https://example.cachix.org";
    publicKey = "example.cachix.org-1:...";
  }
];
```

只有上游不提供 Flake 或无法按标准输出聚合时，条目才应定义 `adapter`。适配层必须调用上游实际的 Nix 入口，不复制上游打包逻辑。

## 维护

每个条目必须提供非空 `description`。新增或修改条目前，应核实上游指定 ref 的实际 Flake/Nix 输出、支持平台和缓存配置。

Nix 要求 `flake.nix` 的 inputs 为字面属性集，因此条目是来源信息的唯一事实来源，根 Flake 由脚本生成：

```console
python3 scripts/generate-flake.py
python3 scripts/generate-flake.py --check
```

不要直接修改生成文件中的 input 或缓存声明。

MNPR 的使用入口和默认开发分支均为 `unstable`。本文所有示例均明确跟踪该分支，不依赖 GitHub 默认分支设置。
