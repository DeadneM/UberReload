--These functions were made by Deadly Mutton Chops and B1313
function NewRaycastWeaponBase:clip_full()
	if ReloadTweaks.settings.reload_realistic and self:ammo_base():weapon_tweak_data().tactical_reload then
		return self:ammo_base():get_ammo_remaining_in_clip() == self:ammo_base():get_ammo_max_per_clip() + self:ammo_base():weapon_tweak_data().tactical_reload
	else
		return self:ammo_base():get_ammo_remaining_in_clip() == self:ammo_base():get_ammo_max_per_clip()
	end
end

--Realistic bullet keep in chamber when reloading
function NewRaycastWeaponBase:on_reload()
	local ammo_base = self._reload_ammo_base or self:ammo_base()
	local current_throw_ammo = self:get_ammo_total() - self:get_ammo_remaining_in_clip()
	local zero_ammo = 0
--Player Tased reloading
	if ReloadTweaks.settings.reload_tased and managers.player:current_state() == "tased" then
		return
	end
	if ammo_base:weapon_tweak_data().uses_clip == true then
		if ammo_base:get_ammo_remaining_in_clip() <= ammo_base:get_ammo_max_per_clip()  then
			ammo_base:set_ammo_remaining_in_clip(math.min(ammo_base:get_ammo_total(),
			ammo_base:get_ammo_max_per_clip(),
			ammo_base:get_ammo_remaining_in_clip() + ammo_base:weapon_tweak_data().clip_capacity))
		end
	else
--Throw Ammo from magazine
		if ReloadTweaks.settings.reload_throw then
			if ReloadTweaks.settings.reload_throw and ReloadTweaks.settings.reload_realistic and ammo_base:get_ammo_remaining_in_clip() >= 1 and ammo_base:weapon_tweak_data().tactical_reload == 1 then
				ammo_base:set_ammo_total(current_throw_ammo + 1)
			elseif ReloadTweaks.settings.reload_throw and ReloadTweaks.settings.reload_realistic and ammo_base:get_ammo_remaining_in_clip() == 1 and ammo_base:weapon_tweak_data().tactical_reload == 2 then
				ammo_base:set_ammo_total(current_throw_ammo + 1)
			elseif ReloadTweaks.settings.reload_throw and ReloadTweaks.settings.reload_realistic and ammo_base:get_ammo_remaining_in_clip() >= 2 and ammo_base:weapon_tweak_data().tactical_reload == 2 then
				ammo_base:set_ammo_total(current_throw_ammo + 2)
			elseif ReloadTweaks.settings.reload_throw and ammo_base:get_ammo_remaining_in_clip() == 0 and not ammo_base:weapon_tweak_data().tactical_reload then
				-- Do nothing for Contraband m203 for exemple
			else
				ammo_base:set_ammo_total(current_throw_ammo)
			end
			if ammo_base:get_ammo_total() <= 0 then ammo_base:set_ammo_total(zero_ammo) end
		end
--Tactical reload part MOSTLY
		if ReloadTweaks.settings.reload_realistic and ammo_base:get_ammo_remaining_in_clip() >= 1 and ammo_base:weapon_tweak_data().tactical_reload == 1 then
			ammo_base:set_ammo_remaining_in_clip(math.min(ammo_base:get_ammo_total(), ammo_base:get_ammo_max_per_clip() + 1))
		elseif ReloadTweaks.settings.reload_realistic and ammo_base:get_ammo_remaining_in_clip() == 1 and ammo_base:weapon_tweak_data().tactical_reload == 2 then
			ammo_base:set_ammo_remaining_in_clip(math.min(ammo_base:get_ammo_total(), ammo_base:get_ammo_max_per_clip() + 1))
		elseif ReloadTweaks.settings.reload_realistic and ammo_base:get_ammo_remaining_in_clip() >= 2 and ammo_base:weapon_tweak_data().tactical_reload == 2 then
			ammo_base:set_ammo_remaining_in_clip(math.min(ammo_base:get_ammo_total(), ammo_base:get_ammo_max_per_clip() + 2))
		elseif ReloadTweaks.settings.reload_realistic and ammo_base:get_ammo_remaining_in_clip() > 0 and not ammo_base:weapon_tweak_data().tactical_reload then
			ammo_base:set_ammo_remaining_in_clip(math.min(ammo_base:get_ammo_total(), ammo_base:get_ammo_max_per_clip()))
		elseif self._setup.expend_ammo then
			ammo_base:set_ammo_remaining_in_clip(math.min(ammo_base:get_ammo_total(), ammo_base:get_ammo_max_per_clip()))
		else
			ammo_base:set_ammo_remaining_in_clip(ammo_base:get_ammo_max_per_clip())
			ammo_base:set_ammo_total(ammo_base:get_ammo_max_per_clip())
		end
	end
	managers.job:set_memory("kill_count_no_reload_" .. tostring(self._name_id), nil, true)
	self._reload_ammo_base = nil
end

function NewRaycastWeaponBase:reload_expire_t()
	if self._use_shotgun_reload then
		local ammo_remaining_in_clip = self:get_ammo_remaining_in_clip()
		if ReloadTweaks.settings.reload_realistic and self:get_ammo_remaining_in_clip() > 0 and  self:weapon_tweak_data().tactical_reload == 1 then
			return math.min(self:get_ammo_total() - ammo_remaining_in_clip, self:get_ammo_max_per_clip() + 1 - ammo_remaining_in_clip) * self:reload_shell_expire_t()
		elseif ReloadTweaks.settings.reload_realistic and self:get_ammo_remaining_in_clip() > 0 and  self:weapon_tweak_data().tactical_reload == 2 then
			return math.min(self:get_ammo_total() - ammo_remaining_in_clip, self:get_ammo_max_per_clip() + 2 - ammo_remaining_in_clip) * self:reload_shell_expire_t()
		else
			return math.min(self:get_ammo_total() - ammo_remaining_in_clip, self:get_ammo_max_per_clip() - ammo_remaining_in_clip) * self:reload_shell_expire_t()
		end
	end
	return nil
end

function NewRaycastWeaponBase:update_reloading(t, dt, time_left)
	if self._use_shotgun_reload and t > self._next_shell_reloded_t then
		local speed_multiplier = self:reload_speed_multiplier()
		self._next_shell_reloded_t = self._next_shell_reloded_t + self:reload_shell_expire_t() / speed_multiplier
		if ReloadTweaks.settings.reload_realistic and self:get_ammo_remaining_in_clip() > 0 and  self:weapon_tweak_data().tactical_reload == 1 then
			self:set_ammo_remaining_in_clip(math.min(self:get_ammo_max_per_clip() + 1, self:get_ammo_remaining_in_clip() + 1))
			return true
		elseif ReloadTweaks.settings.reload_realistic and self:get_ammo_remaining_in_clip() > 0 and  self:weapon_tweak_data().tactical_reload == 2 then
			self:set_ammo_remaining_in_clip(math.min(self:get_ammo_max_per_clip() + 2, self:get_ammo_remaining_in_clip() + 2))
			return true
		else
			self:set_ammo_remaining_in_clip(math.min(self:get_ammo_max_per_clip(), self:get_ammo_remaining_in_clip() + 1))
			return true
		end
		managers.job:set_memory("kill_count_no_reload_" .. tostring(self._name_id), nil, true)
		return true
	end
end