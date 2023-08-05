-- Elevation asset pack

MantleInteractionExt = MantleInteractionExt or class(UseInteractionExt)

function MantleInteractionExt:init(unit, ...)
    MantleInteractionExt.super.init(self, unit, ...)
	self._is_mantle_point = true
end
function MantleInteractionExt:can_select(player)
    if player:movement():m_head_pos().z > self._unit:position().z + 40 then
        return false
    end
	return MantleInteractionExt.super.can_select(self, player)
end

function MantleInteractionExt:check_interupt()
	return MantleInteractionExt.super.check_interupt(self)
end

function MantleInteractionExt:_interact_blocked(player)
	return true
end

function MantleInteractionExt:selected(player)
	if not self:can_select(player) then
		return
    end
	self._hand_id = hand_id
	self._is_selected = true
	local string_macros = {}

    self:_add_string_macros(string_macros)
    
    local text_id = self._tweak_data.text_id or alive(self._unit) and self._unit:base().interaction_text_id and self._unit:base():interaction_text_id()
	local text = managers.localization:text(text_id, string_macros)
    local icon = self._tweak_data.icon
    
    managers.hud:show_interact({
		text = text,
		icon = icon
	})
    return true
end

function MantleInteractionExt:_btn_interact()
	return managers.localization:btn_macro("jump", false)
end