# Project 001: Neon Pawn (赛博当铺模拟器原型)

基于 **Godot 4.7** 打造的 **3D + 2D 混合架构（3D 与 2D 穿插）** 赛博朋克模拟经营游戏基础框架，玩法方向参考 *Probably Stolen - Cyberpunk Shopkeeper Sim*。

## 核心特色与技术框架

### 1. 3D 与 2D 穿插表现方式
本项目在框架内直接示范并集成了三种实用的 3D/2D 混合技术路径：
1. **3D 商店空间 + 2D 纸片人顾客 (`SubViewport` -> `Sprite3D` Y-Billboard)**
   - 场景：`scenes/world3d/shop_world_3d.tscn` & `scenes/world3d/hybrid_customer_3d.tscn`
   - 3D 赛博当铺店铺（霓虹灯光、货架、柜台、动态 3D 商品摆件、可切换视角相机）与 2D 程序化/精灵动画顾客穿插共存。
2. **3D 实体终端内的 2D 实时屏幕 (`SubViewport` -> 3D `StandardMaterial3D`)**
   - 场景：`scenes/world3d/shop_monitor_3d.tscn`
   - 店铺墙上的 3D 显示器实时映射 2D UI 画面（营业状态、嫌疑度警报、信用点滚动播报）。
3. **3D 经营现场 <-> 2D 交互式鉴宝/黑市工作台无缝穿插**
   - 场景：`scenes/minigame2d/appraisal_workbench_2d.tscn`
   - 在 3D 柜台点击待交易物品或按 `Tab` 切入 **2D 鉴定工作台**，使用鼠标移动 **2D 紫外线/X光扫描镜头 (`F` 键开关)** 检查隐藏赃物序列号、CorpSec 追踪标记、纯度信息，并与顾客实时砍价/成交/拒收/举报。

### 2. 赛博模拟经营核心循环 (`Autoload` 单例架构)
- `scripts/autoload/game_events.gd`：全局强类型信号总线，解耦 3D 世界、2D 工作台与 UI。
- `scripts/autoload/economy_manager.gd`：信用点 (`¢`)、周期房租倒计时、买断店铺终极目标 (`2500 ¢`)、嫌疑度 (`Heat`) 与三方势力声望 (`Scavengers` / `Syndicate` / `CorpSec`)。
- `scripts/autoload/time_manager.gd`：昼夜/班次阶段流转 (`PREP` -> `OPEN` -> `CLOSING`) 与每日结算。
- `scripts/autoload/inventory_manager.gd`：商品目录、库存管理、赃物 (`HOT`) 标记与定价利润计算。

## 操作说明
- **开始营业 / 接待下一位顾客**：点击 HUD 按钮或点击 3D 店铺门口/终端。
- **切入 2D 鉴定工作台**：点击 3D 柜台上的物品，或按 `Tab`。
- **2D 紫外线扫描仪 (UV Lens)**：在 2D 工作台移动鼠标探测隐藏线索，按 `F` 切换 UV 灯。
- **3D 镜头微调**：`A` / `D` 左右微调视角，`1` / `2` / `3` 切换全景/柜台/货架焦距。

## 目录结构
```text
Game-001/
├── docs/GDD_001.md                 # 游戏概念与后续扩展设计文档
├── scenes/
│   ├── main/main.tscn              # 主协调场景 (3D世界 + 2D工作台 + HUD + 日结)
│   ├── world3d/                    # 3D 当铺、2D-in-3D 顾客、3D 终端屏幕
│   ├── minigame2d/                 # 2D 交互鉴宝与砍价工作台
│   └── ui/                         # HUD 与每日结算面板
└── scripts/
    ├── autoload/                   # 核心状态机与事件总线
    ├── data/                       # ItemData 资源类与赛博物品目录
    └── systems/                    # 顾客与交易生成器
```
