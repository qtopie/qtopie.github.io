# Module Spec: Header UI 改造（Fluent UI + Drift 风格）

## 1. Overview

对 `drift-blog-theme` 的 `<header>` 区域进行视觉升级，目标：

- 增加 **Sticky + Acrylic（毛玻璃）** 背景，滚动时与内容保持视觉层次
- 品牌标题采用 **Drift 渐变文字**（`#005AF0` → `#00DCC0`）强化主题感
- 在 `:root` 与 `body` 补全 **Fluent 字体栈**（Segoe UI / system-ui）
- 补充 **768-1023px (iPad)** 断点，避免布局在平板上降级到桌面样式

**仅修改文件：** `themes/drift-blog-theme/assets/css/main.css`
**不改动：** `header.html`、React 组件、其他 CSS 文件

---

## 2. Interface / API Contract

- **Inputs:** 无运行时输入，纯 CSS 声明变更
- **Outputs:** 浏览器渲染后的 `<header>` 视觉效果
- **Errors:** 无（CSS 降级安全）

---

## 3. Acceptance Criteria (BDD)

### Feature: Sticky Acrylic Header

#### Scenario 1: [SPEC-HEADER-001] 页面滚动时 header 固定在顶部并有毛玻璃背景

- **Given** 页面内容高度超过视口，用户向下滚动
- **When** 渲染 `<header>` 元素
- **Then**
  - `header` 具有 `position: sticky; top: 0; z-index: 100`
  - `header` 具有 `backdrop-filter: blur(16px)` 及 `-webkit-backdrop-filter: blur(16px)`
  - `header` 背景为半透明：`background: rgba(255,255,255,0.85)`
  - `header` 底部有 Fluent 细线分隔：`border-bottom: 1px solid rgba(0,0,0,0.06)`
- **Mapped Test:** `testings/header/header_style_test.sh:test_header_sticky_acrylic`

---

### Feature: Drift 渐变品牌标题

#### Scenario 2: [SPEC-HEADER-002] 品牌标题 h1 展示 Drift 渐变文字

- **Given** `<header>` 内存在 `<h1>` 站点标题
- **When** 页面正常加载
- **Then**
  - `header nav h1` 使用 `background: linear-gradient(135deg, #005AF0 0%, #00DCC0 100%)`
  - `header nav h1` 设置 `-webkit-background-clip: text; background-clip: text; color: transparent`
  - 桌面端（≥ 768px）字号为 `1.6rem`，移动端为 `1.25rem`，字重 `800`
- **Mapped Test:** `testings/header/header_style_test.sh:test_header_brand_gradient`

---

### Feature: 全局 Fluent 字体栈

#### Scenario 3: [SPEC-HEADER-003] body 使用 Fluent 标准字体栈

- **Given** 任意页面加载
- **When** 浏览器解析 CSS
- **Then**
  - `body` 的 `font-family` 为 `"Segoe UI", system-ui, -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif`
  - `:root` 新增 CSS 变量 `--font-family-base` 指向同一字体栈
- **Mapped Test:** `testings/header/header_style_test.sh:test_body_font_family`

---

### Feature: iPad 响应式断点（768-1023px）

#### Scenario 4: [SPEC-HEADER-004] Pad 设备上 header 布局正确

- **Given** 视口宽度在 768px 至 1023px 之间（平板设备）
- **When** 渲染 `<header>` 内 `<nav>`
- **Then**
  - `header nav` 保持单行 flex 布局（不折叠为 grid）
  - `header nav h1` 字号为 `1.4rem`
  - `.search-box` 最大宽度为 `480px`
  - `.search-root` 保持 `flex: 0 1 480px`
- **Mapped Test:** `testings/header/header_style_test.sh:test_header_ipad_breakpoint`

---

## 4. 实现范围（Changes）

| 文件 | 操作 | 内容 |
|------|------|------|
| `assets/css/main.css` | **修改** | `:root` 补 `--font-family-base`；`body` 加 `font-family`；`header` 加 sticky/acrylic；`header nav h1` 渐变文字 + 字号；新增 `@media (768px-1023px)` 断点 |

---

## 5. 不在本 Spec 范围内

- Dark Mode（单独 Spec）
- 卡片 Fluent 样式改造（单独 Spec）
- Pagination 按钮化（单独 Spec）
- Footer 改造（单独 Spec）
