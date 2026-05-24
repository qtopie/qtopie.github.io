---
name: rednote-travel-plan
description: "小红书深圳到中山旅游攻略抓取与总结"
author: github-copilot
created: 2026-01-26
tools:
  - chrome-devtools-mcp
language: zh-CN
---

## 目标
- 基于小红书公开内容，抓取并总结“深圳到中山旅游攻略”。
- 使用 `chrome-devtools-mcp` 完成页面操作与内容获取。

## 前置条件
- 用户具备可扫码登录的小红书账号。
- 已在本地启用 `chrome-devtools-mcp`，可打开浏览器页面并执行交互。

## 操作步骤
1) 打开小红书网页版 `https://www.xiaohongshu.com/explore`。
2) 等待登录页加载，提示用户扫码登录；监听到页面刷新表示登录成功。
3) 定位顶部搜索框，输入关键词（默认：`深圳到中山旅游攻略`），提交搜索。
4) 在搜索结果页抓取前若干条笔记（标题、作者、发布日期、点赞/收藏数、正文摘要、笔记链接）。
5) 调用 LLM 对抓取内容做路线/景点/交通/预算/避坑要点的总结，形成简洁攻略。

## 建议的工具调用序列（伪代码）
- `chrome-devtools-mcp.new_page(url="https://www.xiaohongshu.com/explore")`
- `chrome-devtools-mcp.wait_for(text="扫码登录" 或 搜索框)`
- `chrome-devtools-mcp.fill(uid=<搜索框>, value="深圳到中山旅游攻略")`
- `chrome-devtools-mcp.press_key(key="Enter")`
- `chrome-devtools-mcp.take_snapshot()` 并解析结果列表，抽取所需字段
- 将抓取的结构化数据传给 LLM，总结输出

## 输出期望
- 结构化列表：`标题 / 作者 / 发布时间 / 互动数据 / 链接 / 重点摘录`
- 总结：
  - 推荐路线与时间规划
  - 交通方案（船/车/地铁/滴滴）
  - 住宿/餐饮/景点清单
  - 预算估算与节奏建议
  - 风险与避坑提醒（人流高峰、订票、天气、带娃/长辈注意事项等）

## 辅助提示
- 登录失败或跳转异常时，重新加载页面并提示用户再次扫码。
- 若元素选择器变化，先调用 `take_snapshot` 确认搜索框与结果列表的 uid，再进行填充与点击。
- 控制抓取数量（如前 5-10 条）以避免被风控；不要抓取用户个人敏感信息。
- 如果页面采用懒加载，考虑滚动或等待加载完毕再取 DOM。

## 示例对话开场（给 Copilot）
- "运行 `rednote-travel-plan`，抓取小红书‘深圳到中山旅游攻略’并给我路线总结。"
- "用 chrome-devtools-mcp 打开小红书，登录后搜‘深圳到中山旅游攻略’，抓 5 条笔记并总结交通+避坑。"