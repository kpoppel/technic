-- The power radiator fuctions like an inductive charger
-- only better in the game setting.
-- The purpose is to allow small appliances to receive power
-- without the overhead of the wiring needed for larger machines.
--
-- The power radiator will consume power corresponding to the
-- sum(power rating of the attached appliances)/0.6
-- Using inductive power transfer is very inefficient so this is
-- set to the factor 0.6.

------------------------------------------------------------------
-- API for inductive powered nodes:
-- Use the functions below to set the corresponding callbacks
-- Also two nodes are needed: The inactive and the active one. The active must be called <name>_active .
------------------------------------------------------------------
-- Register a new appliance using this function
technic.inductive_nodes = {}
technic.register_inductive_machine = function(name)
					table.insert(technic.inductive_nodes, name)
					table.insert(technic.inductive_nodes, name.."_active")
				     end

-- Appliances:
--  has_supply: pos of supply node if the appliance has a power radiator near with sufficient power for the demand else ""
--  EU_demand: The power demand of the device.
--  EU_charge: Actual use. set to EU_demand if active==1
--  active: set to 1 if the device is on
technic.inductive_on_construct = function(pos, eu_demand, infotext)
				    local meta = minetest.env:get_meta(pos)
				    meta:set_string("infotext", infotext)
				    meta:set_int("technic_inductive_power_machine", 1)
				    meta:set_int("MV_EU_demand",eu_demand)     -- The power demand of this appliance
				    meta:set_int("EU_charge",0)       -- The actual power draw of this appliance
				    meta:set_string("has_supply","") -- Register whether we are powered or not. For use with several radiators.
				    meta:set_int("active", 0)    -- If the appliance can be turned on and off by using it use this.
				 end

technic.inductive_on_punch_off = function(pos, eu_charge, swapnode)
		    local meta = minetest.env:get_meta(pos)
		    if meta:get_string("has_supply") ~= "" then
		       hacky_swap_node(pos, swapnode)
		       meta:set_int("active", 1)
		       meta:set_int("EU_charge",eu_charge)
		       --print("-----------")
		       --print("Turn on:")
		       --print("EUcha:"..meta:get_int("EU_charge"))
		       --print("has_supply:"..meta:get_string("has_supply"))
		       --print("<----------->")
		    end
		 end

technic.inductive_on_punch_on = function(pos, eu_charge, swapnode)
		    local meta = minetest.env:get_meta(pos)
		    hacky_swap_node(pos, swapnode)
		    meta:set_int("active", 0)
		    meta:set_int("EU_charge",eu_charge)
		    --print("-----------")
		    --print("Turn off:")
		    --print("EUcha:"..meta:get_int("EU_charge"))
		    --print("has_supply:"..meta:get_string("has_supply"))
		    --print("<---------->")
		 end

local shutdown_inductive_appliances = function(pos)
					 -- The supply radius
					 local rad = 4
					 -- If the radiator is removed. turn off all appliances in region
					 -- If another radiator is near it will turn on the appliances again
					 local positions = minetest.env:find_nodes_in_area({x=pos.x-rad,y=pos.y-rad,z=pos.z-rad},{x=pos.x+rad,y=pos.y+rad,z=pos.z+rad}, technic.inductive_nodes)
					 for _,pos1 in ipairs(positions) do
					    local meta1 = minetest.env:get_meta(pos1)
					    -- If the appliance is belonging to this node
					    if meta1:get_string("has_supply") == pos.x..pos.y..pos.z then
					       local nodename = minetest.env:get_node(pos1).name
					       -- Swap the node and make sure it is off and unpowered
					       if string.sub(nodename, -7) == "_active" then
						  hacky_swap_node(pos1, string.sub(nodename, 1, -8))
						  meta1:set_int("active", 0)
						  meta1:set_int("EU_charge", 0)
					       end
					       meta1:set_string("has_supply", "")
					   end
					end
				     end


minetest.register_node(
   "technic:power_radiator", {
      description = "Power Radiator",
      tiles  = {"technic_hv_down_converter_top.png", "technic_hv_down_converter_bottom.png", "technic_hv_down_converter_side.png",
		"technic_hv_down_converter_side.png", "technic_hv_down_converter_side.png", "technic_hv_down_converter_side.png"},
      groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
      sounds = default.node_sound_wood_defaults(),
      drawtype = "nodebox",
      paramtype = "light",
      is_ground_content = true,
      node_box = {
	 type = "fixed",
	 fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      },
      selection_box = {
	 type = "fixed",
	 fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      },
      on_construct = function(pos)
			local meta = minetest.env:get_meta(pos)
			meta:set_int("technic_mv_power_machine", 1)  -- MV machine
			meta:set_int("MV_EU_demand",1)               -- Demand on the primary side when idle
			meta:set_int("connected_EU_demand",0)        -- Potential demand of connected appliances
			meta:set_string("infotext", "Power Radiator")
--			meta:set_int("active", 0)
		     end,
      on_dig = function(pos, node, digger)
		  shutdown_inductive_appliances(pos)
		  return minetest.node_dig(pos, node, digger)
	       end,
   })

minetest.register_craft(
   {
      output = 'technic:power_radiator 1',
      recipe = {
	 {'technic:stainless_steel_ingot', 'technic:stainless_steel_ingot', 'technic:stainless_steel_ingot'},
	 {'technic:copper_coil',           'technic:mv_transformer',        'technic:copper_coil'},
	 {'technic:rubber',                'technic:mv_cable',              'technic:rubber'},
      }
   })

minetest.register_abm(
   {nodenames = {"technic:power_radiator"},
    interval   = 1,
    chance     = 1,
    action = function(pos, node, active_object_count, active_object_count_wider)
		local meta             = minetest.env:get_meta(pos)
		local eu_input  = meta:get_int("MV_EU_input")
		local eu_demand = meta:get_int("MV_EU_demand")

		-- Power off automatically if no longer connected to a switching station
		technic.switching_station_timeout_count(pos, "MV")

		if eu_input == 0 then
		   -- No power
		   meta:set_string("infotext", "Power Radiator is unpowered");
--		      meta:set_int("active",1) -- used for setting textures someday maybe
		   shutdown_inductive_appliances(pos)
		   connected_EU_demand = 0
		elseif eu_input == eu_demand then
		   -- Powered and ready

		   -- The maximum EU sourcing a single radiator can provide.
		   local max_charge          = 3000 -- == the max EU demand of the radiator
		   local connected_EU_demand = meta:get_int("connected_EU_demand")

		   -- Efficiency factor
		   local eff_factor = 0.6
		   -- The supply radius
		   local rad = 6
		   
		   local meta1            = nil
		   local pos1             = {}
		   local used_charge      = 0
		   
		   -- Index all nodes within supply range
		   local positions = minetest.env:find_nodes_in_area({x=pos.x-rad,y=pos.y-rad,z=pos.z-rad},{x=pos.x+rad,y=pos.y+rad,z=pos.z+rad}, technic.inductive_nodes)
		   for _,pos1 in ipairs(positions) do
		      local meta1 = minetest.env:get_meta(pos1)
		      -- If not supplied see if this node can handle it.
		      if meta1:get_string("has_supply") == "" then
			 -- if demand surpasses the capacity of this node, don't bother adding it.
			 local app_eu_demand = meta1:get_int("EU_demand")/eff_factor
			 if connected_EU_demand + app_eu_demand <= max_charge then
			    -- We can power the appliance. Register, and spend power if it is on.
			    connected_EU_demand = connected_EU_demand + app_eu_demand

			    meta1:set_string("has_supply", pos.x..pos.y..pos.z)
			    used_charge = math.floor(used_charge+meta1:get_int("EU_charge")/eff_factor)
			 end
		      elseif meta1:get_string("has_supply") == pos.x..pos.y..pos.z then
			 -- The appliance has power from this node. Spend power if it is on.
			 used_charge = math.floor(used_charge+meta1:get_int("EU_charge")/eff_factor)
			 print("My Lamp ("..pos.x..","..pos.y..","..pos.z..") Used:"..used_charge)
		      end
		      meta:set_string("infotext", "Power Radiator is powered ("..math.floor(used_charge/max_charge*100).."% of maximum power)");
		      if used_charge == 0 then
			 meta:set_int("MV_EU_demand", 1) -- Still idle
		      else
			 meta:set_int("MV_EU_demand", used_charge)
		      end
--		      meta:set_int("active",1) -- used for setting textures someday maybe
		   end
		   -- Save state
		   meta:set_int("connected_EU_demand",connected_EU_demand)
		else
		   -- This is the case where input ~= demand. Overloaded or underpowered!
--		   --If demand surpasses actual supply turn off everything - we are out of power
--		   if used_charge>eu_input then
--		      meta:set_string("infotext", "Power Radiator is overloaded ("..math.floor(used_charge/eu_input*100).."% of available power)");
----		      meta:set_int("active",1) -- used for setting textures someday maybe
--		      shutdown_inductive_appliances(pos)
--		      connected_EU_demand = 0
		end
	     end,
 })

technic.register_MV_machine ("technic:power_radiator","RE")
