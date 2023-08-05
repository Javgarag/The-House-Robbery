-- Add events for pickups

local old_init = MissionManager.init

function MissionManager:init(...)
    old_init(self, ...)
    table.insert(self._global_event_list, "pku_hogar_code_note")
    table.insert(self._global_event_list, "pku_hogar_hdd")
end