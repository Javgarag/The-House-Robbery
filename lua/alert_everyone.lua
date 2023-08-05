return function (instigator)
	if not managers.groupai:state():enemy_weapons_hot() then
		managers.groupai:state():propagate_alert({
			"vo_cbt",
			Vector3(),
			10000,
			managers.groupai:state():get_unit_type_filter("civilians_enemies"),
			managers.worlddefinition:get_unit(101631)
		})
	end
end