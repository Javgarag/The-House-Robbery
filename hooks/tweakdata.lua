if Global.game_settings and Global.game_settings.level_id == "hogar" then
	-- Adds enemy Force Pickup for HDD steal 
	tweak_data.pickups.hdd_hogar = {
		unit = Idstring("units/pd2_mod_hogar/pickups/hogar_pickup_hdd/hogar_pickup_hdd")
	}

	-- Adds enemy Force pickup for GenSec call event
	tweak_data.pickups.code_note_hogar = {
		unit = Idstring("units/pd2_mod_hogar/pickups/hogar_pickup_code_note/hogar_pickup_code_note")
	}

	-- Adds wrong code waypoint
	tweak_data.hud_icons.wrong_notebook = {
		texture = "textures/waypoints/wrong_code",
		texture_rect = {
			0,
			0,
			32,
			32
		}
	}

	-- Add instakill cop grenade to blackmarket tweak_data
	tweak_data.blackmarket.projectiles.frag_cops = {
		name_id = "bm_grenade_frag_cops",
		unit = "units/pd2_mod_hogar/props/hogar_wpn_frag_grenade_cops/wpn_frag_grenade",
		unit_dummy = "units/pd2_mod_hogar/props/hogar_wpn_frag_grenade_cops/wpn_frag_grenade_husk",
		sprint_unit = "units/pd2_mod_hogar/props/hogar_wpn_frag_grenade_cops/wpn_frag_grenade_sprint",
		throwable = true,
		animation = "throw_grenade",
		max_amount = 1,
		anim_global_param = "projectile_frag",
		throw_allowed_expire_t = 0.1,
		expire_t = 1.1,
		repeat_expire_t = 1.5,
		is_a_grenade = true,
		is_explosive = true,
	}

	-- Add instakill cop grenade to projectile tweak_data
	tweak_data.projectiles.frag_cops = {
		damage = 300,
		player_damage = 300,
		curve_pow = 0.1,
		range = 500,
		name_id = "bm_grenade_frag"
	}

	-- Fix range for weapon pickups
	tweak_data.interaction.take_weapons.interact_distance = 200

	-- Add crowbar requirement to crates
	tweak_data.interaction.crate_loot.special_equipment = "crowbar"
	tweak_data.interaction.crate_loot.equipment_text_id = "debug_interact_equipment_crowbar"

	-- Adjust bike engine secure value
	tweak_data.carry.bike_part_heavy.bag_value = "gold"

	-- Change biker flags
	tweak_data.character.biker.access = "security"
end