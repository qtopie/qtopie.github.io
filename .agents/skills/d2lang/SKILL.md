---
name: d2lang
description: "用于使用 D2 (Declarative Diagramming) 语言设计和绘制各种技术图表（如系统架构图、关系图、时序图、网络拓扑等）。默认使用 ELK 布局引擎，使用 d2 命令行工具进行编译与测试，能够输出语法正确且符合设计美学的 D2 脚本。"
---

# D2 绘图技能

这个技能引导 AI 代理使用 D2 声明式绘图语言（Declarative Diagramming）来设计和绘制技术图表。它确保生成的图表结构清晰、语义准确、并且在视觉上美观且符合现代设计原则。

## 核心流程

在需要绘制图表时，请遵循以下处理流程：

- **需求分析**：理解用户需要表达的架构、流程或关系，确定图表的类型（如系统架构图、状态机、时序图等）。
- **结构规划**：定义核心节点（Nodes）、嵌套容器（Containers）和连接关系（Connections）。
- **编写脚本**：按照 D2 语法规范编写 `.d2` 脚本，合理组织嵌套结构和标签。
- **美化设计**：运用样式（Style）和主题（Theme），控制图表的布局方向（Direction）和节点形状（Shape）。
- **代码输出**：提供完整的 D2 代码块，并在必要时协助用户使用命令行工具将其编译为 SVG 或 PNG 格式。

## D2 语法与设计规范

### 基础结构

D2 脚本通过声明节点和连接线来定义图表：

```d2
# 声明节点
database: "用户数据库"
api_service: "API 服务"

# 声明连接线
api_service -> database: "读取/写入"
```

### 嵌套容器

使用大括号 `{}` 表示嵌套关系，这对于表示模块、微服务架构或逻辑分组非常有用：

```d2
kubernetes_cluster: "Kubernetes 集群" {
  service_a: "服务 A"
  service_b: "服务 B"
  
  service_a -> service_b: "gRPC 调用"
}
```

### 形状与图标

D2 支持多种节点形状，能够传达更多的语义信息：

- 常用形状（`shape`）：`rectangle`（默认）, `oval`, `circle`, `cylinder`（用于数据库）, `cloud`（用于云服务/网络）, `queue`（用于消息队列）, `document`, `person`（用于用户/角色）。

```d2
user: "系统管理员" {
  shape: person
}
db: "订单数据库" {
  shape: cylinder
}
queue: "消息队列" {
  shape: queue
}
```

### 布局方向

在容器或根级别使用 `direction` 关键字控制图表的布局流向：

- `down` (从上到下，默认)
- `up` (从下到上)
- `left` (从右到左)
- `right` (从左到右)

```d2
direction: right
```

### 布局引擎与 CLI 工具

本技能使用 **ELK** 布局引擎作为默认的图表布局系统，以生成紧凑且易读的逻辑拓扑。在渲染和测试图表时，统一使用 **d2** 命令行工具。

### 样式定制

通过 `style` 属性可以细粒度地控制节点 and 连线的视觉表现：

- `fill`：填充颜色（十六进制格式，如 `"#F3F4F6"`）。
- `stroke`：边框颜色。
- `stroke-width`：边框粗细。
- `stroke-dash`：虚线样式（如 `5`）。
- `font-size`：字体大小。
- `font-color`：字体颜色。
- `bold`：是否粗体（`true`/`false`）。

```d2
server: "Web 服务器" {
  style: {
    fill: "#EFF6FF"
    stroke: "#3B82F6"
    stroke-width: 2
    bold: true
  }
}
```

## 核心规则与最佳实践

- **语义化命名**：节点 ID 应使用小写蛇形命名法（`snake_case`），标签（Label）应写在双引号内，避免直接使用复杂的字符作为节点 ID。
- **先结构后样式**：首先定义清晰的节点拓扑与逻辑关系，然后再进行美化（添加颜色、形状或微调边框），避免一开始就被样式细节干扰。
- **避免连接交叉**：如果连接线过于繁杂，应当考虑：
  - 使用更清晰的嵌套结构。
  - 调整 `direction` 改变流动方向。
  - 将复杂的系统图拆分为多张局部图。
- **合理使用注释**：使用 `#` 为复杂的拓扑结构添加注释，说明各个子系统的职责。
- **不要手动编号标题**：在相关的 Markdown 文档中，不要对标题进行手动编号，因为标题编号应由 TOC 工具自动生成。

## 常见图表模板

### 系统架构图模版

```
```d2
direction: right

client: "客户端 (SPA)" {
  shape: rectangle
}

gateway: "API 网关" {
  style.fill: "#EEF2F6"
}

services: "微服务集群" {
  auth_service: "认证服务"
  user_service: "用户服务"
  payment_service: "支付服务"
  
  auth_service -> user_service
}

db_cluster: "数据层" {
  primary_db: "主数据库" {
    shape: cylinder
  }
  replica_db: "从数据库" {
    shape: cylinder
  }
  
  primary_db -> replica_db: "主从复制" {
    style.stroke-dash: 5
  }
}

client -> gateway: "HTTPS"
gateway -> services.auth_service: "转发"
services.user_service -> db_cluster.primary_db: "读写"
```
```

### 时序图模版

时序图的顶层通常需要设置 `shape: sequence-diagram`。

```
```d2
shape: sequence-diagram

alice: "爱丽丝"
bob: "鲍勃"
server: "认证服务器"

alice -> bob: "你好，鲍勃！"
bob -> server: "验证爱丽丝的身份"
server -> bob: "身份合法"
bob -> alice: "你好，爱丽丝，验证通过！"
```
```
## 工具、编译与自我校验

本技能规定本地测试与编译采用 `d2` 命令行工具，并默认指定 `--layout=elk`（或 `-l elk`）布局引擎。为确保图表视觉比例协调、无重叠，AI 代理在交付最终图表前必须执行自我校验机制。

### 自我校验流程 (Auto-Verification & Correction)

AI 代理在生成 D2 图表后，应当遵循以下步骤进行质量诊断：

1. **基本编译**：
   使用 `d2` 编译生成 SVG 原图：
   ```bash
   d2 --layout=elk input.d2 output.svg
   ```

2. **尺寸与宽高比几何分析**：
   运行技能包内置的 Python 诊断脚本，检测宽高比是否失衡（如过窄或过宽）：
   ```bash
   python3 scripts/verify_diagram.py output.svg
   ```
   *如果脚本警告（例如宽高比 < 0.4 或 > 3.0），说明图表成为了不协调的“竖长条”或“扁平长条”，代理必须根据提示调整 `direction` 属性或容器布局结构并重新编译。*

3. **低质量 PNG 视觉校验**：
   为了降低 Token 消耗并使 Agent 能够直接观察排版，代理可以使用较低的分辨率和比例生成诊断 PNG：
   ```bash
   d2 --layout=elk --scale=0.3 input.d2 temp_diagnose.png
   ```
   使用 `view_file` 工具查看该低分辨率 PNG 图，通过视觉感知（如重叠、断线、长宽失衡）做最后人眼确认。确认无误后，删除临时 PNG。

4. **最终交付**：
   通过上述双重校验（代码几何验证 + 缩略图视觉验证）确认无误后，方可将最清晰的原始 `SVG` 文件返回交付给用户。

