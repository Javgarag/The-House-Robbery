-- Add contractor description to CRIME.NET codex

Hooks:PostHook( GuiTweakData, "init", "cartel_contact", function(self)
	local contact_data = {
		id = "cartel",
		name_id = "contact_cartel_name",
		{
			desc_id = "contact_cartel_desc",
			video = "bain",
			post_event = nil
		}
	}
	
	table.insert(self.crime_net.codex[1], contact_data)
end)