# Hevko

作者：Anokianx

[English](README.md) | **中文** | [Español](README_ES.md)

Hevko 是一个面向 *Left 4 Dead 2* 的通用、武器无关的动态状态光效驱动框架。核心脚本仅计算并输出状态值，不耦合具体枪模与贴图效果，可直接打包进任意武器皮肤 `.vpk` 中使用。

## 特性
- **内置 3 阈值血量状态源（Health Provider）**：自动合并永久血量与临时虚血（药丸/肾上腺素），并将倒地或挂边状态判定为低血量警戒区间；支持平滑插值过渡。
- **两种接入模式**：
  1. `mode = "color"`：零 VMT 数学表达式，仅需在 `.vmt` 内添加 `"MaterialModify" { "dummy" "0" }`，直接在武器配置里写三档 RGB 颜色。
  2. `mode = "scalar"`：输出平滑变量 `$hevko_t`（`0.0` 低 / `0.5` 中 / `1.0` 高），交由每把枪自己的 `.vmt` 独立演算颜色、脉冲节奏、纹理流速或旋转速度。

## 目录结构
- `scripts/vscripts/director_base_addon.nut`：自动引导入口
- `scripts/vscripts/hevko/core.nut`：多人跟踪与平滑插值核心引擎
- `scripts/vscripts/hevko/providers/health.nut`：血量检测状态源
- `scripts/vscripts/hevko/registry.nut`：武器配置文件加载清单
- `scripts/vscripts/hevko/weapons/`：各武器独立注册配置（如 `example_color.nut`、`example_scalar.nut`）
- `templates/`：VMT 模板文件

## 如何快速接入任意武器 MOD
1. 将 `scripts/` 目录直接复制进你的武器 MOD 目录中。
2. 新建 `scripts/vscripts/hevko/weapons/你的脚本名.nut`（文件名可自由起，如用 MOD 名或武器名，建议使用英文/数字/下划线），将下面两种模板之一复制进去，并修改武器类名和材质路径。
3. 在 `scripts/vscripts/hevko/registry.nut` 中追加一行 `IncludeScript("hevko/weapons/你的脚本名", getroottable())`。若你的自建服务器已使用其他 `director_base_addon.nut` 合集，只需在其中加上 `IncludeScript("hevko/core", getroottable())` 与注册行即可。
4. 在需要联动的每个 `.vmt` 文件 `"Proxies"` 中加入 `"MaterialModify" { "dummy" "0" }`（使用 `mode = "scalar"` 时可直接套用 `templates/hevko_scalar_unlit.vmt` 或 `templates/hevko_scalar_vertexlit.vmt`）。

### `你的脚本名.nut` 里面要写什么
方案 A — 直接改色模式（`mode = "color"`，最简单，VMT 无需写数学公式）：
```squirrel
if ("Hevko" in getroottable())
{
	::Hevko.RegisterWeapon("weapon_rifle", {
		author = "Anokianx"
		provider = "health"
		mode = "color"
		varName = "$selfillumtint"
		lerpSpeed = 7.5
		highColor = [1.10, 1.05, 1.35]
		midColor = [1.40, 0.95, 0.62]
		lowColor = [1.80, 0.32, 0.48]
		thresholds = {
			highMin = 60.0
			midMin = 30.0
		}
		materials = [
			"models/weapons/v_models/your_mod/weapon_glow"
		]
	})
}
```
方案 B — 标量驱动模式（`mode = "scalar"`，输出 `$hevko_t` `0.0~1.0` 供每把枪的 VMT 自定义特效）：
```squirrel
if ("Hevko" in getroottable())
{
	::Hevko.RegisterWeapon("weapon_rifle_ak47", {
		author = "Anokianx"
		provider = "health"
		mode = "scalar"
		varName = "$hevko_t"
		defaultValue = "1.000"
		lerpSpeed = 7.5
		thresholds = {
			highMin = 60.0
			midMin = 30.0
		}
		materials = [
			"models/weapons/v_models/your_mod/glow_layer"
		]
	})
}
```
字段说明：
- `RegisterWeapon` 第一个参数：**必须填 L4D2 游戏原版武器类名（Classname）**，不能填 MOD 名。
- `materials`：需要联动的 `.vmt` 路径列表，相对 `materials/` 目录，统一使用正斜杠 `/`，**不带**开头的 `materials/` 和末尾的 `.vmt`。单个条目也支持写成 `{ material = "...", varName = "$color" }` 单独指定变量；另可选填 `worldMaterials = [ ... ]` 精简第三人称联动材质数量。
- `varName`：要驱动的 VMT 变量名（`color` 模式常用 `"$selfillumtint"` 或 `"$color"`；`scalar` 模式默认 `"$hevko_t"`）。
- `thresholds`：`highMin`（≥ 此值为高血量档），`midMin`（≥ 此值为中血量档，低于此值为低血量档）。
- `lerpSpeed`：过渡平滑速度（数值越大切换越快，默认 `7.5`）。

## 常见 L4D2 武器类名对照
- 狙击枪：`"weapon_sniper_awp"`（AWP）、`"weapon_sniper_scout"`（鸟狙）、`"weapon_sniper_military"`（大狙/连狙）、`"weapon_hunting_rifle"`（猎枪）
- 步枪：`"weapon_rifle"`（M16）、`"weapon_rifle_ak47"`（AK-47）、`"weapon_rifle_desert"`（SCAR 三连发）、`"weapon_rifle_sg552"`（SG552）、`"weapon_rifle_m60"`（M60）
- 冲锋枪：`"weapon_smg"`（一代冲锋枪）、`"weapon_smg_silenced"`（消音冲锋枪）、`"weapon_smg_mp5"`（MP5）
- 霰弹枪：`"weapon_pumpshotgun"`（木喷）、`"weapon_shotgun_chrome"`（铁喷）、`"weapon_autoshotgun"`（一代连喷）、`"weapon_shotgun_spas"`（二代连喷）
- 手枪：`"weapon_pistol"`（小手枪）、`"weapon_pistol_magnum"`（沙鹰）
- 近战武器：`"weapon_melee"`（匹配全部近战）或 `"weapon_melee:<近战脚本名>"`（如 `"weapon_melee:katana"` 武士刀、`"weapon_melee:fireaxe"` 消防斧）

## 扩展其他检测指标
可通过 `::Hevko.RegisterProvider("指标名", function(player, cfg) { return { value = 0.0~1.0, tier = 0|1|2, raw = 数值 } })` 注册任意自定义状态计算源，并在武器配置中指定 `provider = "指标名"`。
