GrapplePoint = GrapplePoint or class()

local ids_rope_obj = Idstring("rope")
local ids_interact_obj = Idstring("interact")
local ids_grapple_obj = Idstring("a_grapple_end")
local ids_rope_end = Idstring("a_rope_end")
function GrapplePoint:init(unit)
	self._unit = unit
	self._rope_obj = unit:get_object(ids_rope_obj)
	self._interact_obj = unit:get_object(ids_interact_obj)
	self._grapple_object = unit:get_object(ids_grapple_obj)
	self._rope_end = unit:get_object(ids_rope_end)

	self._current_time = 0
	self._start_pos = self._unit:position()
	self._end_pos = self._grapple_object:position()
	self._interact_pos = self._start_pos - self._unit:rotation():z() * 100
	self._speed = 300
	self._slack = 0

	self._line_data = {
		offset = Vector3(20, 0, 150),
		pos = mvector3.copy(self._start_pos),
		current_dir = Vector3(),
	}

	self._sled_data = {
		len = 200,
		object = self._unit:get_object(Idstring("move")),
		pos = Vector3(),
		tip1 = Vector3(),
		tip2 = Vector3()
	}
	self._sound_source = SoundDevice:create_source("grapplepoint")

	self._sound_source:link(self._sled_data.object)

	self:_update_interact_object()
	self:_update_total_time()
	self:set_enabled(true)
end

function GrapplePoint:update(unit, t, dt)
	if not self._enabled then
		return
	end

	self:_update_sounds(t, dt)
end

function GrapplePoint:_update_sounds(t, dt)
	if self._current_time ~= 0 and not self._running then
		self._sound_data = {
			last_pos = mvector3.copy(self._sled_data.pos)
		}

		self._sound_source:post_event("zipline_hook")
		self._sound_source:post_event("zipline_start")

		self._running = true
	elseif self._running then
		local speed = mvector3.length(self._sled_data.pos - self._sound_data.last_pos) / dt

		mvector3.set(self._sound_data.last_pos, self._sled_data.pos)

		local rtpc = math.clamp(speed, 0, 1500) / 1500

		self._sound_source:set_rtpc("zipline_speed", rtpc)

		if not self._sound_data.has_hooked_off and not alive(self._user_unit) then
			self._sound_source:post_event("zipline_unhook")
			self._sound_source:post_event("zipline_stop")
			self._sound_data = nil
			self._running = false
		end
	end
end

function GrapplePoint:_check_interaction_active_state()
	if not self._enabled then
		self._unit:interaction():set_active(false)

		return
	end

	self._unit:interaction():set_active(not self:is_interact_blocked())
end

function GrapplePoint:on_interacted(unit)
	if self:is_interact_blocked() then
		return
	end

	if Network:is_server() then
		if not alive(self._user_unit) then
			self:set_user(unit)
		end
	else
		self:_client_request_access(unit)
	end
end

function GrapplePoint:set_user(unit)
	local old_unit = self._user_unit
	self._user_unit = unit

	if self._user_unit then
		self:run_sequence("on_person_enter", self._user_unit)
		self:set_start_pos(self._user_unit:position())
		self._user_unit:movement():on_enter_zipline(self._unit)
		self:_send_net_event(ZipLine.NET_EVENTS.set_user)
	else
		if old_unit and alive(old_unit) and  old_unit:movement():current_state() then
			DelayedCalls:Add("PlayMantleAnim", 0.01, function()
				old_unit:movement():current_state():_start_action_mantle(nil, nil, self._unit:position())
			end)
		end

		self:run_sequence("on_person_exit", old_unit)
		self:_send_net_event(ZipLine.NET_EVENTS.remove_user)
		self:_update_pos_data()
		self:_check_dirty()
		self._current_time = 0
	end

	self:_check_interaction_active_state()
end

function GrapplePoint:sync_set_user(unit)
	self._booked_by_peer_id = nil
	local old_unit = self._user_unit
	self._user_unit = unit
	self._synced_user = alive(self._user_unit) and true or nil

	if self._user_unit then
		self:run_sequence("on_person_enter", self._user_unit)
		self._user_unit:movement():on_enter_zipline(self._unit)
	elseif old_unit then
		old_unit:movement():on_exit_zipline()
		self:run_sequence("on_person_exit", old_unit)
		self:_send_net_event(self.NET_EVENTS.remove_user)
		self:_update_pos_data()
		self:_check_dirty()
		self._current_time = 0
	end

	self:_check_interaction_active_state()
end

function GrapplePoint:sync_remove_user()
	if alive(self._user_unit) then
		self:run_sequence("on_person_exit", self._user_unit)
		self._user_unit:movement():on_exit_zipline()
		self._user_unit:movement():_perform_movement_action_zipline_end()
	end

	self._user_unit = nil
	self._synced_user = nil
	self._current_time = 0
	self:_update_pos_data()
	self:_check_dirty()

	self:_check_interaction_active_state()
end

function GrapplePoint:_client_request_access(unit)
	self._request_unit = unit

	managers.network:session():send_to_host("sync_unit_event_id_16", self._unit, "zipline", ZipLine.NET_EVENTS.request_access)
end

function GrapplePoint:debug_draw(t, dt)
	if not self:is_valid() then
		return
	end

	local brush = Draw:brush(Color.white:with_alpha(0.5))
end

function GrapplePoint:run_sequence(sequence_name, user_unit)
	if self._unit:damage():has_sequence(sequence_name) then
		self._unit:damage():run_sequence_simple(sequence_name, {
			unit = user_unit
		})
	end
end

function GrapplePoint:_send_net_event(event_id)
	managers.network:session():send_to_peers_synched("sync_unit_event_id_16", self._unit, "zipline", event_id)
end

function GrapplePoint:_update_interact_object()
	if not self:is_valid() then
		return
	end

	if self._unit and alive(self._unit) and self._interact_obj then
		self._interact_obj:set_position(self._interact_pos)
		self._unit:set_moving()

		if self._unit:interaction():active() then
			self._unit:interaction():_upd_interaction_topology()
		end
	end
end

function GrapplePoint:_update_sled_object()
	if self._sled_data.object then
		self._sled_data.object:set_position(self._sled_data.pos)
		self._sled_data.object:set_rotation(Rotation(self._line_data.current_dir, math.UP))
		self._unit:set_moving()
	end
end


local ease_bezier_points = {
	0,
	0,
	1,
	1
}

function GrapplePoint:update_and_get_pos_at_time(time)
	self._current_time = time
	local bezier_value = math.bezier(ease_bezier_points, time)
	local pos = math.lerp(self._start_pos, self._end_pos, bezier_value)

	mvector3.set_z(pos, mvector3.z(pos))
	mvector3.set(self._line_data.pos, pos + self._line_data.offset)
	mvector3.set(self._sled_data.pos, pos)

	self:_update_pos_data()
	self:_check_dirty()

	return pos
end

function GrapplePoint:update_and_get_pos_at_time_linear(time)
	self._current_time = time
	local pos = math.lerp(self._start_pos, self._end_pos, time)

	self:_update_pos_data()
	self:_check_dirty()
	return pos
end

function GrapplePoint:speed_at_time(time, step)
	step = step or 0.01
	local pos1 = self:pos_at_time(time)
	local pos2 = self:pos_at_time(math.clamp(time + step, 0, 1))
	local dist = mvector3.distance(pos1, pos2)

	return dist
end

function GrapplePoint:pos_at_time(time)
	local bezier_value = math.bezier(ease_bezier_points, time)
	local pos = math.lerp(self._start_pos, self._end_pos, bezier_value)

	return pos
end


function GrapplePoint:_update_pos_data()
	if not self:is_valid() then
		return
	end

	if self._user_unit and alive(self._user_unit) then
		local offset = mvector3.copy(self._line_data.offset)
		if managers.player:local_player() and alive(managers.player:local_player()) and self._user_unit == managers.player:local_player() then
			local cam_rot = Rotation(self._user_unit:camera():rotation():yaw(), 0, 0)
			mvector3.rotate_with(offset, cam_rot)
		end

		self._line_data.start_pos = self._user_unit:position() + offset
		self._line_data.end_pos = self._rope_end:position()
		self._line_data.dir = self._line_data.end_pos - self._line_data.start_pos
		self._line_data.dir_s = self._line_data.start_pos:normalized()
		self._line_data.dir_e = self._line_data.end_pos:normalized()

		mvector3.set_z(self._line_data.dir, 0)
		mvector3.normalize(self._line_data.dir)
		mvector3.lerp(self._line_data.current_dir, self._line_data.dir_s, self._line_data.dir_e, self._current_time)
	else
		self._line_data.start_pos = self._rope_end:position()
		self._line_data.end_pos = self._rope_end:position()
	end

	self._dirty = true
end
local down_offset_vec = math.UP * -10
function GrapplePoint:_check_dirty()
	if not self._dirty then
		return
	end

	self._dirty = nil

	if self._user_unit and alive(self._user_unit) then
		local len = 16

		mvector3.set(self._sled_data.tip1, self._line_data.start_pos)
		mvector3.set(self._sled_data.tip2, self._rope_end:position())
		mvector3.add(self._sled_data.tip2, down_offset_vec)
	else
		self._sled_data.tip1 = self._rope_end:position()
		self._sled_data.tip2 = self._rope_end:position()
	end

	if self._sled_data.object then
		self._sled_data.object:set_position(self._sled_data.pos)
		self._sled_data.object:set_rotation(Rotation(self._line_data.current_dir, math.UP))
		self._unit:set_moving()
	end

	self:_update_sled_object()
	self._rope_obj:set_control_points({
		self._line_data.start_pos,
		self._sled_data.tip1,
		self._sled_data.tip2,
		self._line_data.end_pos
	})
end

function GrapplePoint:sync_net_event(event_id, peer)
	local net_events = ZipLine.NET_EVENTS

	if event_id == net_events.request_access then
		if self:is_interact_blocked() then
			peer:send_queued_sync("sync_unit_event_id_16", self._unit, "zipline", ZipLine.NET_EVENTS.access_denied)
		else
			self._booked_by_peer_id = peer:id()

			peer:send_queued_sync("sync_unit_event_id_16", self._unit, "zipline", ZipLine.NET_EVENTS.access_granted)
		end
	elseif event_id == net_events.access_denied then
		self._request_unit = nil
	elseif event_id == net_events.access_granted then
		if alive(self._request_unit) then
			self:set_user(self._request_unit)
		end

		self._request_unit = nil
	elseif event_id == net_events.set_user then
		local unit = peer:unit()

		if alive(unit) then
			self:sync_set_user(unit)
		end
	elseif event_id == net_events.remove_user then
		self:sync_remove_user()
	end
end

function GrapplePoint:set_enabled(enabled)
	self._enabled = enabled

	self:_check_interaction_active_state()
end

function GrapplePoint:current_direction()
	return self._line_data.current_dir
end

function GrapplePoint:is_valid()
	return self._start_pos and self._end_pos and true
end

function GrapplePoint:is_usage_type_bag()
	return false
end

function GrapplePoint:is_interact_blocked()
	if self._booked_by_peer_id then
		return true
	end
	
	return self._current_time ~= 0 or alive(self:user_unit())
end

function GrapplePoint:user_unit()
	return self._user_unit
end

function GrapplePoint:start_pos()
	return self._start_pos
end

function GrapplePoint:set_start_pos(pos)
	self._start_pos = pos
	self._end_pos = self._grapple_object:position()

	self:_update_interact_object()
	self:_update_total_time()
end

function GrapplePoint:end_pos()
	if managers.editor then
		return self._interact_pos
	else
		return self._end_pos
	end
end

function GrapplePoint:set_end_pos(pos)
	self._interact_pos = pos

	self:_update_interact_object()
	self:_update_total_time()
end

function GrapplePoint:speed()
	return self._speed
end

function GrapplePoint:set_speed(speed)
	if not speed then
		return
	end

	self._speed = speed
	self:_update_total_time()
end

function GrapplePoint:slack()
	return self._slack
end

function GrapplePoint:set_slack(slack)
end

function GrapplePoint:usage_type()
	return "person"
end

function GrapplePoint:set_usage_type(usage_type)
end

function GrapplePoint:ai_ignores_bag()
	return true
end

function GrapplePoint:set_ai_ignores_bag(ai_ignores_bag)
end

function GrapplePoint:total_time()
	return self._total_time
end

function GrapplePoint:set_total_time(total_time)
	self._total_time = total_time
end

function GrapplePoint:_update_total_time()
	self:set_total_time((self._start_pos - self._end_pos):length() / self._speed)
end

function GrapplePoint:save(data)
	local state = {
		enabled = self._enabled,
		current_time = self._current_time,
		interact_pos = self._interact_pos,
		speed = self._speed
	}
	data.GrapplePoint = state
end

function GrapplePoint:load(data)
	local state = data.GrapplePoint

	if state.enabled ~= self._enabled then
		self:set_enabled(state.enabled)
	end

	self:set_end_pos(state.interact_pos)
	self:set_speed(state.speed)

	self._current_time = state.current_time

	managers.worlddefinition:use_me(self._unit)
end