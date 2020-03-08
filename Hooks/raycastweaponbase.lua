function RaycastWeaponBase:can_reload()
    if ReloadTweaks.settings.reload_style == 3 and not ReloadTweaks.globals.reload_allowed and
     self:ammo_base():get_ammo_remaining_in_clip() == 0 then
        return false
    else 
        return self:ammo_base():get_ammo_remaining_in_clip() < self:ammo_base():get_ammo_total()
    end
end