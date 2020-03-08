local function getReloadTimeInPercent(self, t)
    if self.reload_start_t then
        return ((self._state_data.reload_expire_t - t) / (self._state_data.reload_expire_t - self.reload_start_t))
    else return 0 end
end


local _update_reload_timers_orig = PlayerStandard._update_reload_timers
function PlayerStandard:_update_reload_timers(t, dt, input)
    _update_reload_timers_orig(self, t, dt, input)
    self.reload_start_t = self._state_data.reload_expire_t and (self.reload_start_t or t) or nil
end
local _check_action_reload = PlayerStandard._check_action_reload
function PlayerStandard:_check_action_reload(t, input)
    local new_action = _check_action_reload(self, t, input)
    local action_wanted = input.btn_reload_press

    if action_wanted then
        local action_forbidden =
            self:_is_reloading() or self:_changing_weapon() or self:_is_meleeing() or self._use_item_expire_t or
            self:_interacting() or
            self:_is_throwing_projectile()

        if not action_forbidden and self._equipped_unit and not self._equipped_unit:base():clip_full() then
            ReloadTweaks.globals.reload_allowed = true
            self:_start_action_reload_enter(t)

            new_action = true
        end
    end

    return new_action
end

local _start_action_running_orig = PlayerStandard._start_action_running
function PlayerStandard:_start_action_running(t)
    if self._state_data.reload_expire_t and self.reload_start_t and ReloadTweaks.settings.prevent_run_cancel then
        local clip_empty = self._equipped_unit:base():clip_empty() and self._equipped_unit:base().clip_empty
        if ((getReloadTimeInPercent(self, t) >= ReloadTweaks.settings.prevent_reload_cancel) and not clip_empty ) or self.RUN_AND_RELOAD then
            _start_action_running_orig(self, t)
        end
    else
        _start_action_running_orig(self, t)
    end
end

local _check_action_primary_attack_orig = PlayerStandard._check_action_primary_attack
function PlayerStandard:_check_action_primary_attack(t, input)
    local new_action = _check_action_primary_attack_orig(self, t, input)
    local action_forbidden =
        self:_changing_weapon() or self:_is_meleeing() or self._use_item_expire_t or self:_interacting() or
        self:_is_throwing_projectile() or
        self:_is_deploying_bipod()
    local weap_base = self._equipped_unit:base()
    local btn = input.btn_primary_attack_press or input.btn_steelsight_press
    if not action_forbidden then
        self._queue_reload_interupt = nil
        self._ext_inventory:equip_selected_primary(false)
        if self._equipped_unit then
            if weap_base:out_of_ammo() then
                if input.btn_primary_attack_press then
                    weap_base:dryfire()
                end
            elseif weap_base.clip_empty and weap_base:clip_empty() and not weap_base:out_of_ammo() and
                    not self:_is_reloading() then
                if ReloadTweaks.settings.reload_style == 1 then
                    new_action = true
                    self:_start_action_reload_enter(t)
                elseif ReloadTweaks.settings.reload_style == 2 then
                    if weap_base:fire_mode() == "single" then
                        if input.btn_primary_attack_press and not new_action then
                            self:_start_action_reload_enter(t)
                        end
                    else
                        new_action = true
                        self:_start_action_reload_enter(t)
                    end
                elseif ReloadTweaks.settings.reload_style == 3 then 
                    ReloadTweaks.globals.reload_allowed = false
                    if input.btn_primary_attack_press then
                        weap_base:dryfire()
                    end
                end
                self:_check_stop_shooting()
            elseif weap_base:clip_not_empty() and btn and self:_is_reloading() and ReloadTweaks.settings.reload_cancel then
                if ReloadTweaks.settings.reload_cancel_barrelmag then --oh god this chunk is a disaster
                    if self._state_data.reload_enter_expire_t or (self._state_data.reload_expire_t and
                    (getReloadTimeInPercent(self, t)) >= ReloadTweaks.settings.prevent_reload_cancel)
                    then
                       
                        self._change_weapon_data = {selection_wanted = true}
                        self._unequip_weapon_expire_t = t
                        self:_interupt_action_reload(t)
                    end
                elseif not weap_base:reload_interuptable() or weap_base:is_category("grenade_launcher") then
                    if self._state_data.reload_enter_expire_t or (self._state_data.reload_expire_t and
                    (getReloadTimeInPercent(self, t)) >= ReloadTweaks.settings.prevent_reload_cancel)
                    then
                        self._change_weapon_data = {selection_wanted = true}
                        self._unequip_weapon_expire_t = t
                        self:_interupt_action_reload(t)
                    end
                end
            elseif self:_is_reloading() and weap_base:reload_interuptable() and btn then
                self._queue_reload_interupt = true
            end
        end
    end
    return new_action
end