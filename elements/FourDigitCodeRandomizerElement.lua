core:import("CoreMissionScriptElement")

FourDigitCodeRandomizerElement = FourDigitCodeRandomizerElement or class(CoreMissionScriptElement.MissionScriptElement)

function FourDigitCodeRandomizerElement:init(...)
	FourDigitCodeRandomizerElement.super.init(self, ...)
end

function FourDigitCodeRandomizerElement:client_on_executed(...)
	self:on_executed(...)
end

function FourDigitCodeRandomizerElement:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	
	if not self._values.sequence_activation_mode and not self._values.instance_mode then
		self:get_mission_element(self._values.counterelement1):counter_operation_set(math.random(0,9))
		self:get_mission_element(self._values.counterelement2):counter_operation_set(math.random(0,9))
		self:get_mission_element(self._values.counterelement3):counter_operation_set(math.random(0,9))
		self:get_mission_element(self._values.counterelement4):counter_operation_set(math.random(0,9))
	elseif not self._values.instance_mode then
		for _,id in ipairs(self._values.unit) do
			local unit = managers.worlddefinition:get_unit(id)
			if unit and unit:damage() then
				log(self._values.sequence.. tostring(self:get_mission_element(self._values.sequence_counter_append):counter_value()))
				unit:damage():run_sequence_simple(self._values.sequence.. tostring(self:get_mission_element(self._values.sequence_counter_append):counter_value() or ""))
			end
		end
	else
		log(self._values.instance or "no instance")
		local input_elements = managers.world_instance:get_registered_input_elements(self._values.instance, (self._values.instance_event or "").. tostring(self:get_mission_element(self._values.instance_counter_append) and self:get_mission_element(self._values.instance_counter_append):counter_value() or ""))
		if input_elements then
			for _, element in ipairs(input_elements) do
				element:on_executed(instigator)
			end
		end
	end

	self.super.on_executed(self, instigator)
end

-- Editor stuff because the module integration seems to be broken. Ty Oreztov!
if BLE then
	Hooks:Add("BeardLibPostInit", "FourDigitCodeRandomizerElementEditor", function(self)
		FourDigitCodeRandomizerEditor = FourDigitCodeRandomizerEditor or class(MissionScriptEditor)

		function FourDigitCodeRandomizerEditor:create_element()
		    self.super.create_element(self)

		    self._element.class = "FourDigitCodeRandomizerElement" 
			self._element.values.sequence_activation_mode = false
		end

		function FourDigitCodeRandomizerEditor:_build_panel()
			self:_create_panel()

			self:Text("This element sets four Counter elements to random values in an interval of [0,9].")
			self:BuildElementsManage("counterelement1", nil, {"ElementCounter"}, nil, {
				not_table = true,
				single_select = true
			})
			self:BuildElementsManage("counterelement2", nil, {"ElementCounter"}, nil, {
				not_table = true,
				single_select = true
			})
			self:BuildElementsManage("counterelement3", nil, {"ElementCounter"}, nil, {
				not_table = true,
				single_select = true
			})
			self:BuildElementsManage("counterelement4", nil, {"ElementCounter"}, nil, {
				not_table = true,
				single_select = true
			})

			self:Text("Alternatively, it can run a sequence in an unit, with a counter's value appended...")
			self:BooleanCtrl("sequence_activation_mode")
			self:BuildElementsManage("sequence_counter_append", nil, {"ElementCounter"}, nil, {
				not_table = true,
				single_select = true
			})
			self:BuildUnitsManage("unit", nil, nil, nil, {
				not_table = true,
				single_select = true
			})
			self:StringCtrl("sequence")

			self:Text("...Or it can run an input event in an instance. Only one mode can be active at a time.")
			self:BooleanCtrl("instance_mode")
			self:BuildElementsManage("instance_counter_append", nil, {"ElementCounter"}, nil, {
				not_table = true,
				single_select = true
			})
			local names = {}
			for _, name in ipairs(managers.world_instance:instance_names_by_script(self._element.script)) do
				if managers.world_instance:get_instance_data_by_name(name) then
					table.insert(names, name)
				end
			end
			self:ComboCtrl("instance", names)
			self:StringCtrl("instance_event")
		end

		table.insert(BLE._config.MissionElements, "FourDigitCodeRandomizerElement")
	end)
end