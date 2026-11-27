if (!("Hevko" in getroottable()))
{
	::Hevko <- {
		PROJECT = "Hevko"
		AUTHOR = "Anokianx"
		VERSION = 1

		Config = {
			provider = "health"
			tickInterval = 0.04
			idleScanInterval = 0.08
			switchGraceTime = 5.0
			lerpSpeed = 7.5
			includeBots = true
			applyViewModel = true
			applyWorldModel = true
			health = {
				highMin = 60.0
				midMin = 30.0
			}
		}

		Providers = {}
		Weapons = {}
		EventHooks = {}
		TickHooks = {}

		Runtime = {
			booted = false
			eventsBound = false
			thinkEnt = null
			lastTickTime = 0.0
			lastScanTime = 0.0
			players = {}
			worldBound = {}
		}

		function RegisterProvider(name, fn)
		{
			Providers[name] <- fn
		}

		function RegisterEventHook(eventName, id, fn)
		{
			if (!(eventName in EventHooks))
			{
				EventHooks[eventName] <- {}
			}
			EventHooks[eventName][id] <- fn
		}

		function RegisterTickHook(id, fn)
		{
			TickHooks[id] <- fn
		}

		function EmitEventHook(eventName, params)
		{
			if (!(eventName in EventHooks)) return
			foreach (id, fn in EventHooks[eventName])
			{
				try
				{
					fn(params)
				}
				catch (e) {}
			}
		}

		function RegisterWeapon(classname, spec)
		{
			local cfg = {
				author = AUTHOR
				provider = ("provider" in spec) ? spec.provider : Config.provider
				mode = ("mode" in spec) ? spec.mode : "scalar"
				varName = ("varName" in spec) ? spec.varName : "$hevko_t"
				defaultValue = ("defaultValue" in spec) ? spec.defaultValue : null
				lerpSpeed = ("lerpSpeed" in spec) ? spec.lerpSpeed : Config.lerpSpeed
				applyViewModel = ("applyViewModel" in spec) ? spec.applyViewModel : Config.applyViewModel
				applyWorldModel = ("applyWorldModel" in spec) ? spec.applyWorldModel : Config.applyWorldModel
				thresholds = ("thresholds" in spec) ? spec.thresholds : Config.health
				highColor = ("highColor" in spec) ? spec.highColor : [1.0, 1.0, 1.0]
				midColor = ("midColor" in spec) ? spec.midColor : [1.0, 0.78, 0.35]
				lowColor = ("lowColor" in spec) ? spec.lowColor : [1.25, 0.28, 0.28]
				materials = []
				worldMaterials = []
			}
			if (cfg.defaultValue == null)
			{
				if (cfg.mode == "color")
				{
					local c = cfg.highColor
					cfg.defaultValue = format("[%.3f %.3f %.3f]", c[0].tofloat(), c[1].tofloat(), c[2].tofloat())
				}
				else
				{
					cfg.defaultValue = "1.000"
				}
			}
			if ("materials" in spec)
			{
				foreach (item in spec.materials)
				{
					cfg.materials.append(NormalizeMaterialEntry(item, cfg.varName))
				}
			}
			if ("worldMaterials" in spec)
			{
				foreach (item in spec.worldMaterials)
				{
					cfg.worldMaterials.append(NormalizeMaterialEntry(item, cfg.varName))
				}
			}
			else
			{
				cfg.worldMaterials = cfg.materials
			}
			Weapons[classname] <- cfg
		}

		function NormalizeMaterialEntry(item, defaultVar)
		{
			if (typeof item == "string")
			{
				return {
					material = item
					varName = defaultVar
				}
			}
			return {
				material = item.material
				varName = ("varName" in item) ? item.varName : defaultVar
			}
		}

		function ResolveWeaponKey(wep)
		{
			if (!wep || !wep.IsValid()) return null
			local cls = wep.GetClassname()
			if (cls == "weapon_melee")
			{
				local mname = NetProps.GetPropString(wep, "m_strMapSetScriptName")
				if (mname && mname.len() > 0)
				{
					local mkey = cls + ":" + mname
					if (mkey in Weapons) return mkey
				}
			}
			if (cls in Weapons) return cls
			return null
		}

		function EvaluateState(player, cfg)
		{
			local pname = cfg.provider
			if (!(pname in Providers)) return null
			return Providers[pname](player, cfg)
		}

		function FormatOutput(cfg, val)
		{
			if (val < 0.0) val = 0.0
			if (val > 1.0) val = 1.0
			if (cfg.mode == "color")
			{
				local w1 = val * 2.0
				if (w1 > 1.0) w1 = 1.0
				local w2 = (val - 0.5) * 2.0
				if (w2 < 0.0) w2 = 0.0
				if (w2 > 1.0) w2 = 1.0
				local wLow = 1.0 - w1
				local wMid = w1 - w2
				local wHigh = w2
				local c0 = cfg.lowColor
				local c1 = cfg.midColor
				local c2 = cfg.highColor
				local r = c0[0] * wLow + c1[0] * wMid + c2[0] * wHigh
				local g = c0[1] * wLow + c1[1] * wMid + c2[1] * wHigh
				local b = c0[2] * wLow + c1[2] * wMid + c2[2] * wHigh
				return format("[%.3f %.3f %.3f]", r, g, b)
			}
			return format("%.3f", val)
		}

		function SpawnControl(parentEnt, entry, initValStr)
		{
			if (!parentEnt || !parentEnt.IsValid()) return null
			local ctrl = SpawnEntityFromTable("material_modify_control", {
				materialName = entry.material
				materialVar = entry.varName
				materialVarValue = initValStr
			})
			if (!ctrl || !ctrl.IsValid()) return null
			DoEntFire("!self", "SetParent", "!activator", 0.0, parentEnt, ctrl)
			DoEntFire("!self", "SetMaterialVar", initValStr, 0.0, null, ctrl)
			return ctrl
		}

		function SetControlValue(ctrl, valStr)
		{
			if (!ctrl || !ctrl.IsValid()) return
			DoEntFire("!self", "SetMaterialVar", valStr, 0.0, null, ctrl)
		}

		function ReleaseControlList(ctrls, defaultValStr)
		{
			if (!ctrls) return
			foreach (ctrl in ctrls)
			{
				if (ctrl && ctrl.IsValid())
				{
					if (defaultValStr != null)
					{
						DoEntFire("!self", "SetMaterialVar", defaultValStr, 0.0, null, ctrl)
						DoEntFire("!self", "Kill", "", 0.06, null, ctrl)
					}
					else
					{
						DoEntFire("!self", "Kill", "", 0.0, null, ctrl)
					}
				}
			}
		}

		function ReleaseViewModelCtrls(vmCtrls, clearDefault)
		{
			if (!vmCtrls) return
			foreach (k, slot in vmCtrls)
			{
				local defVal = (clearDefault && (k in Weapons)) ? Weapons[k].defaultValue : null
				ReleaseControlList(slot.list, defVal)
			}
		}

		function EnsureViewModelCtrls(st, vm, key, cfg, initValStr)
		{
			if (!vm || !vm.IsValid()) return
			if (st.vmEnt != vm || !st.vmCtrls)
			{
				ReleaseViewModelCtrls(st.vmCtrls, true)
				st.vmCtrls = {}
				st.vmEnt = vm
			}
			if (key in st.vmCtrls)
			{
				local validAll = true
				foreach (c in st.vmCtrls[key].list)
				{
					if (!c || !c.IsValid())
					{
						validAll = false
						break
					}
				}
				if (validAll)
				{
					st.vmCtrls[key].lastUsed = Time()
					return
				}
				ReleaseControlList(st.vmCtrls[key].list, null)
			}
			local list = []
			foreach (entry in cfg.materials)
			{
				local ctrl = SpawnControl(vm, entry, initValStr)
				if (ctrl) list.append(ctrl)
			}
			st.vmCtrls[key] <- {
				list = list
				lastUsed = Time()
				lastSent = initValStr
			}
		}

		function PruneViewModelCtrls(st, activeKey, now)
		{
			if (!st.vmCtrls) return
			local dropKeys = []
			foreach (k, slot in st.vmCtrls)
			{
				if (k != activeKey && (now - slot.lastUsed) >= Config.switchGraceTime)
				{
					dropKeys.append(k)
				}
			}
			foreach (k in dropKeys)
			{
				local defVal = (k in Weapons) ? Weapons[k].defaultValue : null
				ReleaseControlList(st.vmCtrls[k].list, defVal)
				st.vmCtrls.rawdelete(k)
			}
		}

		function EnsureWorldWeaponCtrls(wep, player, cfg, initValStr, st_cur)
		{
			if (!wep || !wep.IsValid()) return null
			local idx = wep.GetEntityIndex()
			if (idx in Runtime.worldBound)
			{
				local wb = Runtime.worldBound[idx]
				if (wb.wep == wep)
				{
					local ok = true
					foreach (c in wb.list)
					{
						if (!c || !c.IsValid())
						{
							ok = false
							break
						}
					}
					if (ok)
					{
						wb.ownerIdx = player.GetEntityIndex()
						return wb
					}
					ReleaseControlList(wb.list, null)
				}
			}
			local list = []
			foreach (entry in cfg.worldMaterials)
			{
				local ctrl = SpawnControl(wep, entry, initValStr)
				if (ctrl) list.append(ctrl)
			}
			local rec = {
				wep = wep
				key = ResolveWeaponKey(wep)
				ownerIdx = player.GetEntityIndex()
				defaultVal = cfg.defaultValue
				cur = st_cur
				hasInit = true
				lastSent = initValStr
				list = list
			}
			Runtime.worldBound[idx] <- rec
			return rec
		}

		function UpdateWorldWeapons(dt, now)
		{
			local stale = []
			local moving = false
			foreach (idx, wb in Runtime.worldBound)
			{
				if (!wb.wep || !wb.wep.IsValid())
				{
					ReleaseControlList(wb.list, null)
					stale.append(idx)
					continue
				}
				local owner = wb.wep.GetOwnerEntity()
				if (!owner || !owner.IsValid() || !owner.IsPlayer() || !owner.IsSurvivor() || !(wb.key in Weapons))
				{
					ReleaseControlList(wb.list, wb.defaultVal)
					stale.append(idx)
					continue
				}
				local cfg = Weapons[wb.key]
				local res = EvaluateState(owner, cfg)
				if (res == null) continue
				local target = res.value
				if (target < 0.0) target = 0.0
				if (target > 1.0) target = 1.0
				local diff = target - wb.cur
				local adiff = (diff < 0.0) ? -diff : diff
				if (adiff < 0.002)
				{
					wb.cur = target
				}
				else
				{
					if (dt > 0.001)
					{
						local alpha = dt * cfg.lerpSpeed
						if (alpha > 1.0) alpha = 1.0
						if (alpha < 0.02) alpha = 0.02
						wb.cur += diff * alpha
					}
					moving = true
				}
				local outStr = FormatOutput(cfg, wb.cur)
				if (wb.lastSent != outStr)
				{
					foreach (c in wb.list) SetControlValue(c, outStr)
					wb.lastSent = outStr
				}
			}
			foreach (idx in stale)
			{
				Runtime.worldBound.rawdelete(idx)
			}
			return moving
		}

		function GetPlayerState(player)
		{
			local pid = player.GetEntityIndex()
			if (!(pid in Runtime.players))
			{
				Runtime.players[pid] <- {
					player = player
					hasInit = false
					cur = 1.0
					target = 1.0
					activeKey = null
					vmEnt = null
					vmCtrls = {}
				}
			}
			local st = Runtime.players[pid]
			st.player = player
			return st
		}

		function UpdateSurvivor(player, dt, now)
		{
			if (!Config.includeBots && IsPlayerABot(player)) return false
			local st = GetPlayerState(player)
			local wep = player.GetActiveWeapon()
			local key = ResolveWeaponKey(wep)
			PruneViewModelCtrls(st, key, now)

			if (key == null)
			{
				st.activeKey = null
				return false
			}

			local cfg = Weapons[key]
			local res = EvaluateState(player, cfg)
			if (res == null) return false

			local target = res.value
			if (target < 0.0) target = 0.0
			if (target > 1.0) target = 1.0
			st.target = target

			if (!st.hasInit || st.activeKey != key)
			{
				st.cur = target
				st.hasInit = true
				st.activeKey = key
			}
			else if (dt > 0.001)
			{
				local diff = target - st.cur
				local adiff = (diff < 0.0) ? -diff : diff
				if (adiff < 0.002)
				{
					st.cur = target
				}
				else
				{
					local alpha = dt * cfg.lerpSpeed
					if (alpha > 1.0) alpha = 1.0
					if (alpha < 0.02) alpha = 0.02
					st.cur += diff * alpha
				}
			}

			local outStr = FormatOutput(cfg, st.cur)

			if (cfg.applyViewModel && !IsPlayerABot(player))
			{
				local vm = NetProps.GetPropEntity(player, "m_hViewModel")
				if (vm && vm.IsValid())
				{
					EnsureViewModelCtrls(st, vm, key, cfg, outStr)
					local slot = st.vmCtrls[key]
					if (slot.lastSent != outStr)
					{
						foreach (c in slot.list) SetControlValue(c, outStr)
						slot.lastSent = outStr
					}
				}
			}

			if (cfg.applyWorldModel)
			{
				EnsureWorldWeaponCtrls(wep, player, cfg, outStr, st.cur)
			}

			local rem = target - st.cur
			if (rem < 0.0) rem = -rem
			return rem >= 0.002
		}

		function Think()
		{
			local now = Time()
			local dt = now - Runtime.lastTickTime
			if (dt < 0.0) dt = 0.0
			if (dt > 0.25) dt = 0.25
			Runtime.lastTickTime = now

			local anyMoving = false
			local p = null
			while (p = Entities.FindByClassname(p, "player"))
			{
				if (p.IsValid() && p.IsSurvivor())
				{
					if (UpdateSurvivor(p, dt, now))
					{
						anyMoving = true
					}
				}
			}

			if (UpdateWorldWeapons(dt, now))
			{
				anyMoving = true
			}

			foreach (id, fn in TickHooks)
			{
				try
				{
					if (fn(dt, now))
					{
						anyMoving = true
					}
				}
				catch (e) {}
			}

			local staleP = []
			foreach (pid, st in Runtime.players)
			{
				if (!st.player || !st.player.IsValid())
				{
					if (st.vmCtrls)
					{
						foreach (_, slot in st.vmCtrls) ReleaseControlList(slot.list, null)
					}
					staleP.append(pid)
				}
			}
			foreach (pid in staleP) Runtime.players.rawdelete(pid)

			return anyMoving ? Config.tickInterval : Config.idleScanInterval
		}

		function ForcePulse()
		{
			EnsureThink()
			if (Runtime.thinkEnt && Runtime.thinkEnt.IsValid())
			{
				Think()
			}
		}

		function EnsureThink()
		{
			local ent = Runtime.thinkEnt
			if (ent && ent.IsValid()) return
			ent = Entities.FindByName(null, "hevko_think")
			if (!ent || !ent.IsValid())
			{
				ent = SpawnEntityFromTable("info_target", { targetname = "hevko_think" })
			}
			if (!ent || !ent.IsValid()) return
			ent.ValidateScriptScope()
			local sc = ent.GetScriptScope()
			sc["HevkoThink"] <- function()
			{
				return ::Hevko.Think()
			}
			AddThinkToEnt(ent, "HevkoThink")
			Runtime.thinkEnt = ent
			Runtime.lastTickTime = Time()
		}

		function ResetRuntime()
		{
			foreach (_, st in Runtime.players)
			{
				if (st.vmCtrls)
				{
					foreach (_, slot in st.vmCtrls) ReleaseControlList(slot.list, null)
				}
			}
			foreach (_, wb in Runtime.worldBound)
			{
				ReleaseControlList(wb.list, null)
			}
			Runtime.players.clear()
			Runtime.worldBound.clear()
			Runtime.thinkEnt = null
			Runtime.lastTickTime = Time()
			EmitEventHook("reset_runtime", {})
		}

		Events = {
			function OnGameEvent_round_start(params)
			{
				::Hevko.ResetRuntime()
				::Hevko.EnsureThink()
			}

			function OnGameEvent_map_transition(params)
			{
				::Hevko.ResetRuntime()
			}

			function OnGameEvent_player_spawn(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_player_hurt(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_heal_success(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_pills_used(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_adrenaline_used(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_revive_success(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_player_incapacitated(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_player_death(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_item_pickup(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_player_bot_replace(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_bot_player_replace(params) { ::Hevko.ForcePulse() }
			function OnGameEvent_weapon_reload(params)
			{
				::Hevko.EmitEventHook("weapon_reload", params)
				::Hevko.ForcePulse()
			}
			function OnGameEvent_weapon_fire(params)
			{
				::Hevko.EmitEventHook("weapon_fire", params)
				::Hevko.ForcePulse()
			}
			function OnGameEvent_player_say(params)
			{
				::Hevko.EmitEventHook("player_say", params)
			}

			function OnGameEvent_player_disconnect(params)
			{
				if (!("userid" in params)) return
				local p = GetPlayerFromUserID(params.userid)
				if (!p || !p.IsValid()) return
				local pid = p.GetEntityIndex()
				if (pid in ::Hevko.Runtime.players)
				{
					local st = ::Hevko.Runtime.players[pid]
					if (st.vmCtrls)
					{
						foreach (_, slot in st.vmCtrls) ::Hevko.ReleaseControlList(slot.list, null)
					}
					::Hevko.Runtime.players.rawdelete(pid)
				}
			}
		}

		function Boot()
		{
			if (!Runtime.eventsBound)
			{
				__CollectEventCallbacks(Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
				Runtime.eventsBound = true
			}
			Runtime.booted = true
			EnsureThink()
		}
	}
}

IncludeScript("hevko/providers/health", getroottable())
IncludeScript("hevko/providers/health_delta", getroottable())
::Hevko.Boot()
