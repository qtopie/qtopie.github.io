# Module Spec: Client-Side Page Translation Widget

## 1. Overview

为博客主题（drift-blog-theme）提供**浏览器端即时翻译**能力：在页面导航栏中加入 Google Translate 官方小组件，用户可选择目标语言，Google 翻译会就地替换当前页面文本，无需改动文章源文件（markdown 保持原始中文）。

- **方案**: Google Translate 官方 Element Widget（`translate.google.com/translate_a/element.js`）
- **特点**: 零配置、免费、支持语言最多
- **局限**: 依赖 Google 服务，中国大陆网络可能无法加载；脚本加载失败时需优雅降级（隐藏组件，不影响页面其他功能）

## 2. Interface / API Contract

- **输入**（主题配置 `config.yaml` → `params`）:
  - `params.translation.enabled` (bool, 默认 `true`)：是否启用翻译小组件
  - `params.translation.pageLanguage` (string, 默认 `zh-CN`)：源页面语言
  - `params.translation.includedLanguages` (string, 默认 `en,zh-CN`): 可翻译的目标语言（逗号分隔的 Google 语言代码，默认仅中文 + 英文）
  - `params.translation.layout` (string, 默认 `simple`)：组件布局，`simple` | `horizontal` | `vertical`
- **输出**:
  - 页面头部导航栏渲染出翻译语言选择组件（`#google_translate_element`）
  - 用户选择语言后，页面文本被翻译
- **视觉规范**: 组件外观遵循 **Fluent UI（微软设计系统）** 视觉语言——采用 **IconButton** 风格：32×32px 正方形、圆角 4px、1px 中性描边（`#8A8886`），仅显示翻译图标（隐藏「Select Language」文字），hover 时背景 `#F3F2F1`、描边 `#605E5C`，聚焦时描边/光环使用强调色 `#0F6CBD`；隐藏 Google logo 与「Powered by Google」品牌文案
- **错误处理**:
  - 脚本加载失败 / 网络不可达 → 组件区域隐藏，控制台输出警告，页面其他功能不受影响
  - `enabled=false` → 完全不输出组件及脚本

## 3. Acceptance Criteria (BDD)

### Feature: 翻译小组件渲染

#### Scenario 1: 默认启用时导航栏出现翻译组件 [SPEC-TRANSLATION-001]
- **Given** 站点配置未设置 `params.translation`（使用默认值）
- **When** 任意页面加载完成
- **Then** `header` 导航栏中出现 `#google_translate_element` 容器，且成功注入 Google Translate 初始化脚本（`cb=googleTranslateElementInit`）
- **Mapped Test:** `testings/translation/widget_render_test.sh:test_widget_renders_in_header`

#### Scenario 2: `enabled=false` 时完全禁用 [SPEC-TRANSLATION-002]
- **Given** `params.translation.enabled = false`
- **When** 页面渲染
- **Then** HTML 中不包含 `#google_translate_element`，也不加载任何 Google 翻译脚本
- **Mapped Test:** `testings/translation/widget_render_test.sh:test_widget_disabled`

### Feature: 翻译执行

#### Scenario 3: 用户选择语言后页面被翻译 [SPEC-TRANSLATION-003]
- **Given** 翻译组件已渲染且 Google 脚本加载成功
- **When** 用户在组件中选择目标语言（如 English）
- **Then** 页面 `<article>` 内容被翻译为目标语言，翻译进程状态指示器（`goog-te-banner-frame` 等）正常出现
- **Mapped Test:** `testings/translation/widget_render_test.sh:test_translate_executes`

### Feature: 优雅降级

#### Scenario 4: Google 脚本加载失败时静默隐藏 [SPEC-TRANSLATION-004]
- **Given** 网络无法访问 Google 服务（或脚本 404）
- **When** 初始化回调在超时（如 5s）内未触发
- **Then** `#google_translate_element` 容器被隐藏（`display:none`），控制台输出 `[translation-widget] Google Translate unavailable`，页面其余功能不受影响
- **Mapped Test:** `testings/translation/widget_render_test.sh:test_graceful_fallback`
