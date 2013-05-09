HV_machines = {}

registered_HV_machines_count=0

function register_HV_machine (string1,string2)
registered_HV_machines_count=registered_HV_machines_count+1
HV_machines[registered_HV_machines_count]={}
HV_machines[registered_HV_machines_count].machine_name=string1
HV_machines[registered_HV_machines_count].machine_type=string2
end

minetest.register_craft({
	output = 'technic:hv_battery_box 1',
	recipe = {
		{'technic:mv_battery_box', 'technic:mv_battery_box', 'mv_technic:battery_box'},
		{'technic:mv_battery_box', 'technic:transformer', 'mv_technic:battery_box'},
		{'', 'technic:hv_cable', ''},
	}
}) 

hv_battery_box_formspec =
	"invsize[8,9;]"..
	"image[1,1;1,2;technic_power_meter_bg.png]"..
	"list[current_name;src;3,1;1,1;]"..
	"image[4,1;1,1;technic_battery_reload.png]"..
	"list[current_name;dst;5,1;1,1;]"..
	"label[0,0;HV Battery Box]"..
	"label[3,0;Charge]"..
	"label[5,0;Discharge]"..
	"label[1,3;Power level]"..
	"list[current_player;main;0,5;8,4;]"

minetest.register_node("technic:hv_battery_box", {
	description = "HV Battery Box",
	tiles = {"technic_hv_battery_box_top.png", "technic_hv_battery_box_bottom.png", "technic_hv_battery_box_side0.png",
		"technic_hv_battery_box_side0.png", "technic_hv_battery_box_side0.png", "technic_hv_battery_box_side0.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	technic_mv_power_machine=1,
	last_side_shown=0,
	drop="technic:hv_battery_box",
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("infotext", "HV Battery Box")
		meta:set_float("technic_hv_power_machine", 1)
		meta:set_string("formspec", battery_box_formspec)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 1)
		battery_charge = 0
		max_charge = 1500000
		last_side_shown=0
		end,	
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		if not inv:is_empty("dst") then
			return false
		elseif not inv:is_empty("src") then
			return false
		end
		return true
	end,
})


for i=1,8,1 do
minetest.register_node("technic:hv_battery_box"..i, {
	description = "HV Battery Box",
	tiles = {"technic_hv_battery_box_top.png", "technic_hv_battery_box_bottom.png", "technic_hv_battery_box_side0.png^technic_power_meter"..i..".png",
		"technic_hv_battery_box_side0.png^technic_power_meter"..i..".png", "technic_hv_battery_box_side0.png^technic_power_meter"..i..".png", "technic_hv_battery_box_side0.png^technic_power_meter"..i..".png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,not_in_creative_inventory=1},
	sounds = default.node_sound_wood_defaults(),
	paramtype="light",
	light_source=9,
	technic_power_machine=1,
	last_side_shown=0,
	drop="technic:hv_battery_box",
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("infotext", "hv Battery box")
		meta:set_float("technic_hv_power_machine", 1)
		meta:set_string("formspec", battery_box_formspec)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 1)
		battery_charge = 0
		max_charge = 1500000
		last_side_shown=0
		end,
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		if not inv:is_empty("dst") then
			return false
		elseif not inv:is_empty("src") then
			return false
		end
		return true
	end,
})
end


HV_nodes_visited = {}


minetest.register_abm({
	nodenames = {"technic:hv_battery_box","technic:hv_battery_box1","technic:hv_battery_box2","technic:hv_battery_box3","technic:hv_battery_box4",
		     "technic:hv_battery_box5","technic:hv_battery_box6","technic:hv_battery_box7","technic:hv_battery_box8"
			},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
	local meta = minetest.env:get_meta(pos)
	charge= meta:get_int("battery_charge")
	max_charge= 1500000
	local i=math.ceil((charge/max_charge)*8)
	if i>8 then i=8 end
	j=meta:get_float("last_side_shown")
	if i~=j then
	if i>0 then hacky_swap_node(pos,"technic:hv_battery_box"..i)  
	elseif i==0 then hacky_swap_node(pos,"technic:hv_battery_box") end 
	meta:set_float("last_side_shown",i)
	end

--loading registered power tools
	local inv = meta:get_inventory()
	if inv:is_empty("src")==false  then 
		local srcstack = inv:get_stack("src", 1)
		local src_item=srcstack:to_table()
		local src_meta=get_item_meta(src_item["metadata"])

		local item_max_charge=nil
		for i=1,registered_power_tools_count,1 do
			if power_tools[i].tool_name==src_item["name"] then
				src_meta=get_item_meta(src_item["metadata"])
				if src_meta==nil then 
					src_meta={}
					src_meta["technic_power_tool"]=true
					src_meta["charge"]=0
				else 
					if src_meta["technic_power_tool"]==nil then
						src_meta["technic_power_tool"]=true
						src_meta["charge"]=0
					end
				end
				item_max_charge=power_tools[i].max_charge
			end
		end
		
		if item_max_charge then
			load1=src_meta["charge"] 
			load_step=16000
			if load1<item_max_charge and charge>0 then 
				if charge-load_step<0 then load_step=charge end
				if load1+load_step>item_max_charge then load_step=item_max_charge-load1 end
				load1=load1+load_step
				charge=charge-load_step
				set_RE_wear(src_item,load1,item_max_charge)
				src_meta["charge"]=load1
				src_item["metadata"]=set_item_meta(src_meta)
				inv:set_stack("src", 1, src_item)
			end
			meta:set_int("battery_charge",charge)
		end	
	end
	
-- dischargin registered power tools
		if inv:is_empty("dst") == false then 
		srcstack = inv:get_stack("dst", 1)
		src_item=srcstack:to_table()
		local src_meta=get_item_meta(src_item["metadata"])
		local item_max_charge=nil
		for i=1,registered_power_tools_count,1 do
			if power_tools[i].tool_name==src_item["name"] then
				src_meta=get_item_meta(src_item["metadata"])
				if src_meta==nil then 
					src_meta={}
					src_meta["technic_power_tool"]=true
					src_meta["charge"]=0
				else 
					if src_meta["technic_power_tool"]==nil then
						src_meta["technic_power_tool"]=true
						src_meta["charge"]=0
					end
				end
				item_max_charge=power_tools[i].max_charge
			end
		end

		if item_max_charge then
		local load1=src_meta["charge"] 
		load_step=16000
		if load1>0 and charge<max_charge then 
			 if charge+load_step>max_charge then load_step=max_charge-charge end
		  	 if load1-load_step<0 then load_step=load1 end
		load1=load1-load_step
		charge=charge+load_step
		set_RE_wear(src_item,load1,item_max_charge)
		src_meta["charge"]=load1
		src_item["metadata"]=set_item_meta(src_meta)
		inv:set_stack("dst", 1, src_item)
		end		
		end
		end
		
	meta:set_int("battery_charge",charge)

	local load = math.floor((charge/1500000) * 100)
	meta:set_string("formspec",
				hv_battery_box_formspec..
				"image[1,1;1,2;technic_power_meter_bg.png^[lowpart:"..
						(load)..":technic_power_meter_fg.png]"
				)
		
	local pos1={}

	pos1.y=pos.y-1
	pos1.x=pos.x
	pos1.z=pos.z


	meta1 = minetest.env:get_meta(pos1)
	if meta1:get_float("hv_cablelike")~=1 then return end

		local HV_nodes = {}
		local PR_nodes = {}
		local RE_nodes = {}

		HV_nodes[1]={}
		HV_nodes[1].x=pos1.x
		HV_nodes[1].y=pos1.y
		HV_nodes[1].z=pos1.z
		HV_nodes[1].visited=false
	
table_index=1
	repeat
	check_HV_node (PR_nodes,RE_nodes,HV_nodes,table_index)
	table_index=table_index+1
	if HV_nodes[table_index]==nil then break end
	until false


local pos1={}
i=1
	repeat
	if PR_nodes[i]==nil then break end -- gettin power from all connected producers
		pos1.x=PR_nodes[i].x
		pos1.y=PR_nodes[i].y
		pos1.z=PR_nodes[i].z
	local meta1 = minetest.env:get_meta(pos1)
	local internal_EU_buffer=meta1:get_float("internal_EU_buffer")
	if charge<max_charge then 
	charge_to_take=4000
	if internal_EU_buffer-charge_to_take<=0 then
		charge_to_take=internal_EU_buffer
	end
	if charge_to_take>0 then 
	charge=charge+charge_to_take 
	internal_EU_buffer=internal_EU_buffer-charge_to_take
	meta1:set_float("internal_EU_buffer",internal_EU_buffer)
	end
	end
	i=i+1
	until false

if charge>max_charge then charge=max_charge end

i=1
	repeat
	if RE_nodes[i]==nil then break end
		pos1.x=RE_nodes[i].x         -- loading all conected machines buffers
		pos1.y=RE_nodes[i].y
		pos1.z=RE_nodes[i].z
	local meta1 = minetest.env:get_meta(pos1)
	local internal_EU_buffer=meta1:get_float("internal_EU_buffer")
	local internal_EU_buffer_size=meta1:get_float("internal_EU_buffer_size")

	local charge_to_give=4000
	if internal_EU_buffer+charge_to_give>internal_EU_buffer_size then
		charge_to_give=internal_EU_buffer_size-internal_EU_buffer
	end
	if charge-charge_to_give<0 then charge_to_give=charge end

	internal_EU_buffer=internal_EU_buffer+charge_to_give
	meta1:set_float("internal_EU_buffer",internal_EU_buffer)
	charge=charge-charge_to_give;
	
	i=i+1
	until false
	charge=math.floor(charge)
	charge_string=tostring(charge)
	meta:set_string("infotext", "HV Battery Box: \n"..charge_string.."/"..max_charge);
	meta:set_int("battery_charge",charge)

end
})

function add_new_HVcable_node (HV_nodes,pos1)
local i=1
	repeat
		if HV_nodes[i]==nil then break end
		if pos1.x==HV_nodes[i].x and pos1.y==HV_nodes[i].y and pos1.z==HV_nodes[i].z then return false end
		i=i+1
	until false
HV_nodes[i]={}
HV_nodes[i].x=pos1.x
HV_nodes[i].y=pos1.y
HV_nodes[i].z=pos1.z
HV_nodes[i].visited=false
return true
end

function check_HV_node (PR_nodes,RE_nodes,HV_nodes,i)
		local pos1={}
		pos1.x=HV_nodes[i].x
		pos1.y=HV_nodes[i].y
		pos1.z=HV_nodes[i].z
		HV_nodes[i].visited=true
		new_node_added=false
	
		pos1.x=pos1.x+1
		check_HV_node_subp (PR_nodes,RE_nodes,HV_nodes,pos1)
		pos1.x=pos1.x-2
		check_HV_node_subp (PR_nodes,RE_nodes,HV_nodes,pos1)
		pos1.x=pos1.x+1
		
		pos1.y=pos1.y+1
		check_HV_node_subp (PR_nodes,RE_nodes,HV_nodes,pos1)
		pos1.y=pos1.y-2
		check_HV_node_subp (PR_nodes,RE_nodes,HV_nodes,pos1)
		pos1.y=pos1.y+1

		pos1.z=pos1.z+1
		check_HV_node_subp (PR_nodes,RE_nodes,HV_nodes,pos1)
		pos1.z=pos1.z-2
		check_HV_node_subp (PR_nodes,RE_nodes,HV_nodes,pos1)
		pos1.z=pos1.z+1
return new_node_added
end

function check_HV_node_subp (PR_nodes,RE_nodes,HV_nodes,pos1)
meta = minetest.env:get_meta(pos1)
if meta:get_float("HV_cablelike")==1 then new_node_added=add_new_HVcable_node(HV_nodes,pos1) end
for i in ipairs(HV_machines) do
	if minetest.env:get_node(pos1).name == HV_machines[i].machine_name then 
		if HV_machines[i].machine_type == "PR" then
			new_node_added=add_new_HVcable_node(PR_nodes,pos1) 
			end
		if HV_machines[i].machine_type == "RE" then
			new_node_added=add_new_HVcable_node(RE_nodes,pos1) 
			end
	end
end
end

