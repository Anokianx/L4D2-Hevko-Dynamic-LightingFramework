if ("Hevko" in getroottable() && !("health_delta" in ::Hevko.Providers))
{
	local stateByPlayer = {}

	local function GetDeltaState(pid, eff, alive)
	{
		if (!(pid in stateByPlayer))
		{
			stateByPlayer[pid] <- {
				form = 0.0
				anchorHp = eff
				lastEff = eff
				wasAlive = alive
				lastEvalTime = -1.0
			}
		}
		return stateByPlayer[pid]
	}

	::Hevko.RegisterProvider("health_delta", function(player, cfg)
	{
		if (!player || !player.IsValid())
		{
			return { value = 0.0, tier = 0, raw = 0.0 }
		}

		local pid = player.GetEntityIndex()
		local now = Time()

		if ((pid in stateByPlayer) && stateByPlayer[pid].lastEvalTime == now)
		{
			local cached = stateByPlayer[pid]
			return { value = cached.form, tier = (cached.form >= 0.5) ? 1 : 0, raw = cached.lastEff }
		}

		local life = NetProps.GetPropInt(player, "m_lifeState")
		local alive = (life == 0)
		local eff = 0.0
		if (alive && !player.IsIncapacitated() && !player.IsHangingFromLedge())
		{
			local perm = player.GetHealth().tofloat()
			local buf = player.GetHealthBuffer().tofloat()
			if (buf < 0.0) buf = 0.0
			eff = perm + buf
			if (eff < 0.0) eff = 0.0
			if (eff > 100.0) eff = 100.0
		}

		local step = 20.0
		if (("thresholds" in cfg) && ("step" in cfg.thresholds))
		{
			step = cfg.thresholds.step.tofloat()
			if (step < 1.0) step = 20.0
		}

		local st = GetDeltaState(pid, eff, alive)

		if (now < st.lastEvalTime)
		{
			st.anchorHp = eff
			st.lastEff = eff
			st.wasAlive = alive
		}
		else if (alive && !st.wasAlive)
		{
			st.anchorHp = eff
		}
		else
		{
			local delta = eff - st.anchorHp
			if (delta < 0.0) delta = -delta
			if (delta >= step)
			{
				st.form = (st.form < 0.5) ? 1.0 : 0.0
				st.anchorHp = eff
			}
		}

		st.wasAlive = alive
		st.lastEff = eff
		st.lastEvalTime = now
		return { value = st.form, tier = (st.form >= 0.5) ? 1 : 0, raw = eff }
	})

	if ("RegisterEventHook" in ::Hevko)
	{
		::Hevko.RegisterEventHook("reset_runtime", "health_delta", function(_params)
		{
			stateByPlayer.clear()
		})
	}
}
