# Module Spec: 全局排版、信息层级与响应式布局重构 (Global Typography & Responsive Layout)

## 1. Overview

本 Spec 定义博客（桌面端与移动端）全局排版、视觉层级与响应式布局的现代化重构标准。目标从**排版呼吸感**、**信息层级**与**视觉精致度**三个维度全面提升阅读体验：

1. **首屏与头部 (Header & Meta)**：
   - 移动端精简 Header 控件布局（单行自适应流，减少垂直堆叠空间占用）。
   - 文章元信息（日期、分类、标签）重构为统一的信息流，标签改用浅灰低饱和色胶囊（Pill）。
   - 文章主标题（H1）自适应字号（移动端 `1.5rem ~ 1.75rem`，行高 `1.35`；桌面端 `2.0rem ~ 2.25rem`，行高 `1.3`）。
2. **正文排版 (Typography & Body)**：
   - 段落呼吸感：正文行高提升至 `1.8`，段落间距调整为 `1.35em ~ 1.5em`。
   - 标题层级强化：H2 上方留白 `2.5em` 并搭配主题色左侧竖线装饰（`3px solid #005AF0`）；H3/H4 层级梯次分明。
   - 现代字体栈与混排：优先采用 `Segoe UI, system-ui, -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif`，支持 `text-wrap: pretty`。
3. **组件与辅助元素 (Components & Auxiliary)**：
   - 移动端 TOC FAB（悬浮目录按钮）升级为半透明毛玻璃质感（`backdrop-filter: blur(12px)` + 微弱阴影）。
   - 代码块与数学公式：代码块带卡片边框并保持移动端横向平滑滚动；KaTeX/MathJax 块级公式 `overflow-x: auto` 自适应。
   - 图表容器（D2 / Mermaid）：添加微边框（`1px solid #e2e8f0`）与精致圆角（`8px`），融入页面底色。

---

## 2. Interface / Style Contract

- **Target Files:**
  - `themes/drift-blog-theme/assets/css/main.css`
  - `themes/drift-blog-theme/assets/css/page.css`
  - `themes/drift-blog-theme/layouts/page.html`
  - `themes/drift-blog-theme/layouts/_partials/header.html`
- **Inputs:** 纯 CSS 与 HTML 模板结构重构
- **Outputs:** 桌面端与移动端下高清晰度、高呼吸感的现代化阅读界面

---

## 3. Acceptance Criteria (BDD)

### Feature: 头部与 Meta 信息流重构

#### Scenario 1: [SPEC-LAYOUT-001] 移动端头部单行紧凑排列
- **Given** 用户在移动端（屏幕宽度 ≤ 767px）访问任意页面
- **When** 渲染 `<header>` 元素
- **Then**
  - Header 导航保持紧凑，不产生多行冗余留白
  - 站点标题字号控制在 `1.15rem ~ 1.25rem`
- **Mapped Test:** `testings/layout/layout_typography_test.sh:test_header_mobile_compact`

#### Scenario 2: [SPEC-LAYOUT-002] 文章元信息（Meta & Tags）低饱和度胶囊化
- **Given** 用户访问包含分类与标签的文章页面
- **When** 渲染 `.metadata` 区域
- **Then**
  - 发布时间与分类、标签排成整洁的 Flex 流动行
  - 标签项 `.tag-item` 使用浅色低饱和背景搭配深灰文字，字号 `0.8rem`
  - 分类项 `.category-item` 带有轻微装饰前缀或文字标签
- **Mapped Test:** `testings/layout/layout_typography_test.sh:test_metadata_pill_tags`

#### Scenario 3: [SPEC-LAYOUT-003] 文章大标题字号与行高适配
- **Given** 渲染文章页面的主标题 `.metadata h1`
- **When** 在移动端（≤ 600px）与桌面端分别渲染
- **Then**
  - 移动端字号为 `1.5rem ~ 1.75rem`，行高为 `1.35`
  - 桌面端字号为 `2.0rem ~ 2.25rem`，行高为 `1.3`
  - 颜色使用沉稳深色 `#0f172a`
- **Mapped Test:** `testings/layout/layout_typography_test.sh:test_title_typography`

---

### Feature: 正文排版与标题层级

#### Scenario 4: [SPEC-LAYOUT-004] 正文段落行高与呼吸感
- **Given** 渲染文章正文段落 `article p`
- **When** 浏览器计算样式
- **Then**
  - 正文 `line-height` 为 `1.8`
  - 段落下边距 `margin-bottom` 为 `1.35em ~ 1.5em`
  - 颜色为 `#1e293b`
- **Mapped Test:** `testings/layout/layout_typography_test.sh:test_body_typography_rhythm`

#### Scenario 5: [SPEC-LAYOUT-005] 标题层级与 H2 极简装饰
- **Given** 渲染文章内的各级标题（`article h2`, `article h3`）
- **When** 页面加载
- **Then**
  - `article h2` 具有明显的上间距（`margin-top: 2.5em`），并带有左侧竖线装饰（`border-left: 3.5px solid var(--color-primary, #005AF0)`，`padding-left: 0.6em`）
  - `article h3` 具有清晰的子章节间距（`margin-top: 1.8em`）与字体层级（`font-size: 1.25rem ~ 1.35rem`）
- **Mapped Test:** `testings/layout/layout_typography_test.sh:test_heading_hierarchy_h2_decor`

---

### Feature: 组件细节（TOC FAB、代码块、公式、图表）

#### Scenario 6: [SPEC-LAYOUT-006] 移动端 TOC FAB 毛玻璃质感
- **Given** 移动端屏幕显示悬浮目录按钮 `.mobile-toc-trigger`
- **When** 按钮渲染在右下角
- **Then**
  - 背景为半透明毛玻璃：`background: rgba(255, 255, 255, 0.85); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px)`
  - 边框为细微灰线：`border: 1px solid rgba(0, 0, 0, 0.08)`
  - 图标颜色为深灰 `#1e293b`，阴影为 `0 4px 16px rgba(0, 0, 0, 0.08)`
- **Mapped Test:** `testings/layout/layout_typography_test.sh:test_mobile_toc_fab_acrylic`

#### Scenario 7: [SPEC-LAYOUT-007] 图表容器与代码块边框微调
- **Given** 页面包含 D2 图表容器 `.d2-container` 或 Mermaid 容器 `.mermaid-block`
- **When** 页面渲染
- **Then**
  - 容器外边框为 `1px solid #e2e8f0`，圆角为 `8px`
  - 代码块 `article pre` 在移动端与桌面端保持横向滑动，边框为 `1px solid #e2e8f0`，背景为 `#f8fafc`
  - 数学公式容器 `.katex-display` 支持横向平滑滑动（`overflow-x: auto`）
- **Mapped Test:** `testings/layout/layout_typography_test.sh:test_diagrams_codeblock_containers`

---

## 4. Test Strategy & Mapped Tests

- **Test Fixture:** `testings/layout/layout_typography_test.sh`
- **Verification:** `./scripts/check.sh`
