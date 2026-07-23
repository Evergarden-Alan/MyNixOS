# Lessons Learned

记录开发过程中遇到的问题与解决方案。

## [2026-07-23] 项目初始化完成

**问题**：无

**成果**：
- 完成 Vibe Coding Skill 的 Stage 1-3
- 生成 6 份规范文档（PRD, APP_FLOW, TECH_STACK, FRONTEND_GUIDELINES, BACKEND_STRUCTURE, IMPLEMENTATION_PLAN）
- 创建项目骨架（CLAUDE.md, progress.txt, lessons.md）

**下一步**：
- 开始 Phase 0：安装 Nix 包管理器到 Arch Linux

---

## [2026-07-23] Phase 0-2 完成，DMS 下载失败

**问题**：DankMaterialShell flake 下载失败
```
error: cannot read file from tarball: Truncated tar archive detected while reading data
```

**原因**：
- GitHub 网络问题或仓库 stable 分支损坏
- 可能是临时性网络故障

**解决方案**：
- 临时注释掉 flake.nix 中的 DMS input
- 先完成基础框架验证
- 稍后重试或使用主分支：`url = "github:AvengeMedia/DankMaterialShell";`

**教训**：
- 外部 flake 依赖可能不稳定，需要降级方案
- 可以先手动安装 DMS 包，不通过 flake 集成
