# Module Spec: TOC 三级目录折叠（H3 默认折叠）

## 1. Overview

博客文章侧边栏 TOC（`#TableOfContents`）已由 Hugo 生成包含 H3 的三级目录（`config.yaml` 的 `markup.tableOfContents.endLevel: 3`），但当前 H3 子项与 H2 平铺展示、不可折叠。本模块为 TOC 增加 **H3 默认折叠 + 点击展开/收起** 交互，并保证移动端抽屉 TOC 行为一致。

**仅修改文件：** `themes/drift-blog-theme/assets/js/toc.js`、`themes/drift-blog-theme/assets/css/page.css`

---

## 2. Interface / API Contract

- **Inputs:** Hugo 渲染的 `#TableOfContents` HTML（`ul > li > a + ul(> li > a)`）
- **Outputs:** 含折叠态的 TOC；H3 子级默认隐藏、可展开
- **Errors:** 无（JS 禁用时降级为全部展开，渐进增强）

---

## 3. Acceptance Criteria (BDD)

### Feature: 三级目录默认折叠

#### Scenario 1: [SPEC-TOC-001] TOC 渲染包含 H3 子项

- **Given** 文章包含 `###`（H3）标题
- **When** 页面渲染 `#TableOfContents`
- **Then** TOC 中包含 H3 链接，且嵌套在所属 H2 的 `<ul>` 中
- **Mapped Test:** `testings/toc/toc_collapse_test.sh:test_toc_contains_h3`

#### Scenario 2: [SPEC-TOC-002] 含子级的 H2 项默认折叠

- **Given** TOC 存在含 H3 子项的 H2 项
- **When** 页面加载完成、toc.js 执行后
- **Then** 该 H2 项的子级 `<ul>` 处于隐藏状态（折叠），并出现展开控制按钮
- **Mapped Test:** `testings/toc/toc_collapse_test.sh:test_h3_collapsed_by_default`

#### Scenario 3: [SPEC-TOC-003] 点击可展开/收起 H3 子项

- **Given** 某 H2 项处于折叠态
- **When** 用户点击其展开按钮
- **Then** 子级 `<ul>` 显示（`hidden` 移除）；再次点击则重新隐藏
- **Mapped Test:** `testings/toc/toc_collapse_test.sh:test_toggle_expand_collapse`

#### Scenario 4: [SPEC-TOC-004] 移动端抽屉 TOC 同步折叠

- **Given** 移动端抽屉 TOC 克隆了主 TOC
- **When** 抽屉打开
- **Then** 抽屉内 H3 同样默认折叠且可展开，点击 H3 链接可跳转
- **Mapped Test:** `testings/toc/toc_collapse_test.sh:test_mobile_toc_collapse_sync`

#### Scenario 5: [SPEC-TOC-005] 激活的 H3 自动展开其父级

- **Given** 某 H3 子项被 IntersectionObserver 标记为激活
- **When** 页面滚动到对应 H3 标题
- **Then** 其父级 H2 项自动展开，激活链接可见
- **Mapped Test:** `testings/toc/toc_collapse_test.sh:test_auto_expand_active_parent`

---

## 4. 实现范围（Changes）

| 文件 | 操作 | 内容 |
|------|------|------|
| `assets/js/toc.js` | **修改** | 初始化折叠态（含子级的 H2 项加 `collapsed`、隐藏子级 `<ul>`）；注入展开按钮；点击切换；激活时自动展开父级 |
| `assets/css/page.css` | **修改** | 展开按钮（chevron）样式；折叠态子级隐藏；`aria-expanded` 状态样式 |

---

## 5. 不在本 Spec 范围内

- TOC 层级扩展至 H4/H5 的折叠
- 折叠状态持久化（localStorage/URL）
- TOC 布局/字体/间距改造
