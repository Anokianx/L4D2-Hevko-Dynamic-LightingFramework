if ("Hevko" in getroottable())
{
	::Hevko.RegisterProvider("health", function(player, cfg)
	{
		if (!player || !player.IsValid()) return null
		local life = NetProps.GetPropInt(player, "m_lifeState")
		if (life != 0)
		{
			return { value = 0.0, tier = 0, raw = 0.0 }
		}
		if (player.IsIncapacitated() || player.IsHangingFromLedge())
		{
			return { value = 0.0, tier = 0, raw = 0.0 }
		}
		local perm = player.GetHealth().tofloat()
		local buf = player.GetHealthBuffer().tofloat()
		if (buf < 0.0) buf = 0.0
		local eff = perm + buf
		local th = cfg.thresholds
		if (eff >= th.highMin)
		{
			return { value = 1.0, tier = 2, raw = eff }
		}
		if (eff >= th.midMin)
		{
			return { value = 0.5, tier = 1, raw = eff }
		}
		return { value = 0.0, tier = 0, raw = eff }
	})
}
