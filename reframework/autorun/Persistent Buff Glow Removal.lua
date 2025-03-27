log.info("[Persistent Buff Glow Removal] started loading")

local showDebug = false
local context = nil

local configPath = "Persistent_Buff_Glow_Removal_Config.json"
local drawOptionsWindow = false

local config = {
	version = "1.0.5",
	suppressAllEffectLoops = false,
	hideAllEffectLoops = false,
	blockEffects = {
		["33816597"] = true, --PL_BUF_HEAL_LOOP
		["33816600"] = true, --"PL_BUF_STAMINA_LOOP"
		["33816602"] = true, --"PL_BUF_ATTACK_LOOP"
		["33816604"] = true, --"PL_BUF_DEFENCE_LOOP"
		["33816606"] = true, --"PL_BUF_IMMUNIZER_LOOP"
		["33816608"] = true, --"PL_BUF_HOT_DRINK_LOOP"
		["33816610"] = true, --"PL_BUF_COOLER_DRINK_LOOP"
		["34996523"] = true, --PL_CLOAK_ACTIVE_SKILL_005_BUFF_MODE
		["33882171"] = false, --"PL_DEBUF_FRENZY_INFECT"
		["33882172"] = false, --"PL_DEBUF_FRENZY_OUTBREAK"
		["33882173"] = true, --"PL_DEBUF_FRENZY_OVERCOME"
		["34537692"] = false, --"PL_WP10_EXTRACT_1"
		["34537693"] = false, --"PL_WP10_EXTRACT_2"
		["34537694"] = false, --"PL_WP10_EXTRACT_3"
		["86770196"] = true, --"OTOMO_BUF_STAMINA_LOOP"
		["86770198"] = true, --"OTOMO_BUF_ATTACK_LOOP"
		["86770200"] = true --"OTOMO_BUF_DEFENCE_LOOP"
		},
	blockBodyEffects = {
		["33947714"] = false, --PL_WP00_CHARGE_1
		["33947715"] = false,
		["33947716"] = false,
		["34013268"] = false, --"PL_WP02_KIJIN_ON"
		["34013269"] = false, --"PL_WP02_KIJIN_ENHANCEMENT"
		["34013275"] = false, --"PL_WP02_JUST_DODGE"
		["34078814"] = false, --PLWP03
		["34078815"] = false,
		["34078816"] = false,
		["34078818"] = false,
		["34078819"] = false,
		["34078820"] = false,
		["34078821"] = false,
		["34078822"] = false,
		["34078823"] = false,
		["34144368"] = false, --PL_WP04_CHARGE_LV1
		["34144369"] = false,
		["34144370"] = false,
		["34144371"] = false,
		["34144372"] = false,
		["34144373"] = false,
		["34144374"] = false,
		["34144375"] = false,
		["34144376"] = false,
		["34144377"] = false,
		["34144378"] = false,
		["34144379"] = false,
		["34406560"] = false, --PL_WP08_AXE_ENHANCED
		["34406561"] = false, --PL_WP08_AWAKE_POWER
		["34406562"] = false,
		["34406563"] = false,
		["34406564"] = false,
		["34406565"] = false,
		["34406566"] = false,
		["34406567"] = false,
		["34406568"] = false,
		["34406569"] = false,
		["34406570"] = false,
		["34472137"] = false, --PL_WP09_SHIELD_ENHANCED
		["34472139"] = false, --PL_WP09_SWORD_ENHANCED
		["34472140"] = false,
		["34472141"] = false,
		["34472142"] = false,
		["34472143"] = false,
		["34472144"] = false,
		["34472145"] = false, --PL_WP09_SWORD_CHARGE_S
		["34472146"] = false,
		["34472147"] = false,
		["34472148"] = false, --PL_WP09_AXE_ENHANCED
		["34472149"] = false, --PL_WP09_AXE_SHIELD_ENHANCED
		["34603245"] = false, --"PL_WP11_CHARGE_LV1"
		["34603246"] = false,
		["34603247"] = false,
		["34603248"] = false
		},
	blockBadConditionMesh = {
		["0"] = false, --Fire
		["1"] = false, --Dragon
		["2"] = false, --Debuff?
		["3"] = false, --Ice
		["4"] = false, --Tear?
		["5"] = false, --Poison
		["6"] = false, --Frozen
		["7"] = false --Virus
		}
	}

local function fixConfig() --well, FALSES can be ignored
	if config.version == "1.0.0" then
		config.version = "1.0.5"
		config.blockEffects["34996523"] = true
		config.blockBodyEffects = {
			["34013268"] = false
			}
		config.blockBadConditionMesh = {
			["0"] = false
			}
		json.dump_file(configPath, config)
	elseif config.version == "1.0.1" then
		config.version = "1.0.5"
		config.blockEffects["34996523"] = true
		config.blockBodyEffects = {
			["34013268"] = false
			}
		config.blockBadConditionMesh = {
			["0"] = false
			}
		json.dump_file(configPath, config)
	elseif config.version == "1.0.2" then
		config.version = "1.0.5"
		config.blockBodyEffects = {
			["34013268"] = false
			}
		config.blockBadConditionMesh = {
			["0"] = false
			}
		json.dump_file(configPath, config)
	elseif config.version == "1.0.3" then
		config.version = "1.0.5"
		config.blockBadConditionMesh = {
			["0"] = false
			}
		json.dump_file(configPath, config)
	elseif config.version == "1.0.4" then
		config.version = "1.0.5"
		config.blockBadConditionMesh = {
			["0"] = false
			}
		json.dump_file(configPath, config)
	end
end

if json ~= nil then
    file = json.load_file(configPath)
    if file ~= nil then
		config = file
		fixConfig()
    else
        json.dump_file(configPath, config)
    end
end

local function logDebug(argStr)
	if showDebug then
		log.info("[Persistent Buff Glow Removal] "..tostring(argStr));
	end
end

local haveSeenBodyEffect = {[0] = {[0] = -1}} --empty arrays go poof

sdk.hook(sdk.find_type_definition("app.cHunterEffect"):get_method("update(app.HunterCharacter)"),
function(args) --degrade 'seen' effects
	local HunterID = sdk.to_int64(sdk.to_managed_object(args[2]):get_field("<HunterCharacter>k__BackingField"):call("get_StableMemberIndex()"))
	if haveSeenBodyEffect[HunterID] == nil then
		haveSeenBodyEffect[HunterID] = {[0] = -1} --empty arrays go poof
	end
	for k, v in pairs(haveSeenBodyEffect[HunterID]) do
		if k ~= 0 then
			--logDebug("PAIR:"..tostring(HunterID)..":"..tostring(k)..":"..tostring(v))
			if v > 0 then
				haveSeenBodyEffect[HunterID][k] = v-1
			end
		end
	end
end,
function(retval)
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.cHunterEffect"):get_method("playBodyEffectLoop(app.EffectID_Common.ID, System.UInt64, app.cEffectOverwriteParams)"),
function(args) --allow new effects through, then block them
	local Hunter = sdk.to_managed_object(args[2]):get_field("<HunterCharacter>k__BackingField")
	if not Hunter then return sdk.PreHookResult.CALL_ORIGINAL end
	local HunterID = sdk.to_int64(Hunter:call("get_StableMemberIndex()"))
	local EffectID = sdk.to_int64(args[3])
	--logDebug("BEFL:"..tostring(HunterID)..":"..tostring(EffectID)..":"..tostring(config.blockBodyEffects[tostring(EffectID)]))
	if config.hideAllEffectLoops then
		args[3] = 0
	elseif (config.blockBodyEffects[tostring(EffectID)] or config.suppressAllEffectLoops) then
		if haveSeenBodyEffect[HunterID] == nil then 
			haveSeenBodyEffect[HunterID] = {[0] = -1} --empty arrays go poof
		end
		--logDebug(tostring(haveSeenBodyEffect[HunterID][EffectID]))
		if haveSeenBodyEffect[HunterID][EffectID] == nil or haveSeenBodyEffect[HunterID][EffectID] == 0 then
			haveSeenBodyEffect[HunterID][EffectID] = 20
		else
			haveSeenBodyEffect[HunterID][EffectID] = 20
			args[3] = 0
		end
	end
end,
function(retval)
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.cHunterEffect"):get_method("playBodyEffect(app.EffectID_Common.ID, app.cEffectOverwriteParams)"),
function(args)
	if config.blockEffects[tostring(sdk.to_int64(args[3]))] or config.hideAllEffectLoops then
		args[3] = 0
	end
end,
function(retval)
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.cEffectController"):get_method("playEffectLoopCore(System.UInt32, app.EffectID_Common.ID, System.UInt64, via.GameObject, app.cEffectOverwriteParams, via.GameObject)"),
function(args)
	if config.blockEffects[tostring(sdk.to_int64(args[4]))] or config.hideAllEffectLoops then
		args[4] = 0
	end
end,
function(retval)
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.CharacterBadConditioinVisualManager"):get_method("getVirusRate(app.cBadConditionVisualPriorityManager.ExtContidion, app.CharacterBadConditioinVisualManager.PartsIndex)"),
function(args)
	
end,
function(retval)
	if config.blockEffects["FRENZYMESH"] then
		return 0
	end
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.cBadConditionVisualPriorityManager"):get_method("getElement(System.Int32)"),
function(args)
	
end,
function(retval)
	local Element = sdk.to_managed_object(retval)
	if config.blockBadConditionMesh[tostring(Element:get_field("_Idx"))] then
		Element:set_field("_Rate", 0)
		return sdk.to_ptr(Element)
	end
	return retval;
end
)

re.on_draw_ui(function()
	if imgui.button("[Persistent Buff Glow Removal] Options##Suppressed_Buff_Glow") then
		drawOptionsWindow = true
	end
	
    if drawOptionsWindow then
        if imgui.begin_window("Persistent Buff Glow Removal Options##Suppressed_Buff_Glow", true, 64) then
			if imgui.tree_node("Item and Skill Buff Effects##Suppressed_Buff_Glow") then
				if imgui.tree_node("Generic Buffs##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Healing Loop (Potions, Mantle, etc.) [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["33816597"])
					if changed then
						doWrite = true
						config.blockEffects["33816597"] = value
					end
					changed, value = imgui.checkbox('Hide Attack Boost [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["33816602"])
					if changed then
						doWrite = true
						config.blockEffects["33816602"] = value
					end
					changed, value = imgui.checkbox('Hide Defense Boost [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["33816604"])
					if changed then
						doWrite = true
						config.blockEffects["33816604"] = value
					end
					changed, value = imgui.checkbox('Hide Stamina Boost [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["33816600"])
					if changed then
						doWrite = true
						config.blockEffects["33816600"] = value
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Item Buffs##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Heat/Cold Drink [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["33816608"])
					if changed then
						doWrite = true
						config.blockEffects["33816608"] = value
						config.blockEffects["33816610"] = value
					end
					changed, value = imgui.checkbox('Hide Immunizer Buff [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["33816606"])
					if changed then
						doWrite = true
						config.blockEffects["33816606"] = value
					end
					changed, value = imgui.checkbox('Hide Corrupted Mantle Buff [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["34996523"])
					if changed then
						doWrite = true
						config.blockEffects["34996523"] = value
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Skill Buffs##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox("Hide 'Common' Skills [Hunter Flashes]##Suppressed_Buff_Glow", config.blockEffects["35127600"])
					imgui.text("   Affects multiple Skills: Adrenaline Rush, Burst, Counterstrike, Maximum Might")
					if changed then
						doWrite = true
						config.blockEffects["35127600"] = value
					end
					changed, value = imgui.checkbox('Hide Latent Power Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127601"])
					if changed then
						doWrite = true
						config.blockEffects["35127601"] = value
					end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_KAZIBA Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127602"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127602"] = value
					-- end
					changed, value = imgui.checkbox('Hide Resentment Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127603"])
					if changed then
						doWrite = true
						config.blockEffects["35127603"] = value
					end
					changed, value = imgui.checkbox('Hide Agitator Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127604"])
					if changed then
						doWrite = true
						config.blockEffects["35127604"] = value
					end
					changed, value = imgui.checkbox('Hide Peak Performance Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127605"])
					if changed then
						doWrite = true
						config.blockEffects["35127605"] = value
					end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_KATSU Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127606"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127606"] = value
					-- end
					changed, value = imgui.checkbox('Hide Divine Blessing Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127607"])
					if changed then
						doWrite = true
						config.blockEffects["35127607"] = value
					end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_GUTS Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127608"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127608"] = value
					-- end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_HUNKI Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127609"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127609"] = value
					-- end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_HUKUTU Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127610"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127610"] = value
					-- end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_RYUNYU Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127611"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127611"] = value
					-- end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_ELEMENT_CONVERT Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127612"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127612"] = value
					-- end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_ASSAULT_SHOT Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127613"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127613"] = value
					-- end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_FIRST_SHOT Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127614"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127614"] = value
					-- end
					changed, value = imgui.checkbox('Hide Offensive Guard Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127616"])
					if changed then
						doWrite = true
						config.blockEffects["35127616"] = value
					end
					changed, value = imgui.checkbox('Hide Convert Element Skill [Weapon Sparks]##Suppressed_Buff_Glow', config.blockEffects["35127615"])
					if changed then
						doWrite = true
						config.blockEffects["35127615"] = value
						for n = 35127617,35127631,1 do
							config.blockEffects[tostring(n)] = value
						end
					end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_RYUKI_ADD Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127632"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127632"] = value
					-- end
					-- changed, value = imgui.checkbox('Hide PL_SKILL_RYUKI Skill [Hunter Flash]##Suppressed_Buff_Glow', config.blockEffects["35127633"])
					-- if changed then
						-- doWrite = true
						-- config.blockEffects["35127633"] = value
					-- end
					imgui.tree_pop()
				end
				imgui.tree_pop()
			end
			if imgui.tree_node("Weapon Buff Effects##Suppressed_Buff_Glow") then
				imgui.text("'Hide' prevents an effect entirely")
				imgui.text("'Reduce' will attempt to to let it flash on activation, then suppress it")
				imgui.text("Neither affects any Hyper Armor glow e.g. GS tackle")
				if imgui.tree_node("Great Sword##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Great Sword Charge [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["33947714"])
					if changed then
						doWrite = true
						for n = 33947714,33947731,1 do
							config.blockEffects[tostring(n)] = value
						end
					end
					changed, value = imgui.checkbox('Reduce Great Sword Charge [Hunter Glow]##Suppressed_Buff_Glow', config.blockBodyEffects["33947714"])
					if changed then
						doWrite = true
						for n = 33947714,33947731,1 do
							config.blockBodyEffects[tostring(n)] = value
						end
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Dual Blades##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Dual Blades Demon Mode [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["34013268"])
					if changed then
						doWrite = true
						config.blockEffects["34013268"] = value
						config.blockEffects["34013276"] = value
					end
					changed, value = imgui.checkbox('Hide Dual Blades Sword Enhancements [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34013269"])
					if changed then
						doWrite = true
						config.blockEffects["34013269"] = value
					end
					changed, value = imgui.checkbox('Hide Dual Blades Demon Boost [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["34013275"])
					if changed then
						doWrite = true
						config.blockEffects["34013275"] = value
					end
					changed, value = imgui.checkbox('Hide Dual Blades Blade Dance/Demon Flurry [Hunter Flashes]##Suppressed_Buff_Glow', config.blockEffects["34013270"])
					if changed then
						doWrite = true
						for n = 34013270,34013274,1 do
							config.blockEffects[tostring(n)] = value
						end
					end
					changed, value = imgui.checkbox('Reduce Dual Blades Demon Mode [Hunter Glow]##Suppressed_Buff_Glow', config.blockBodyEffects["34013268"])
					if changed then
						doWrite = true
						config.blockBodyEffects["34013268"] = value
						config.blockBodyEffects["34013276"] = value
					end
					changed, value = imgui.checkbox('Reduce Dual Blades Demon Boost [Hunter Glow]##Suppressed_Buff_Glow', config.blockBodyEffects["34013275"])
					if changed then
						doWrite = true
						config.blockBodyEffects["34013275"] = value
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Long Sword##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Long Sword Gauge [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34078814"])
					if changed then
						doWrite = true
						for n = 34078814,34078823,1 do
							config.blockEffects[tostring(n)] = value
						end
					end
					changed, value = imgui.checkbox('Reduce Long Sword Gauge [Weapon Glow]##Suppressed_Buff_Glow', config.blockBodyEffects["34078814"])
					if changed then
						doWrite = true
						for n = 34078814,34078823,1 do
							config.blockBodyEffects[tostring(n)] = value
						end
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Hammer##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Hammer Charge [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34144368"])
					if changed then
						doWrite = true
						for n = 34144368,34144379,1 do
							config.blockEffects[tostring(n)] = value
						end
					end
					changed, value = imgui.checkbox('Reduce Hammer Charge [Weapon Glow]##Suppressed_Buff_Glow', config.blockBodyEffects["34144368"])
					if changed then
						doWrite = true
						for n = 34144368,34144379,1 do
							config.blockBodyEffects[tostring(n)] = value
						end
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Switch Axe##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Switch Axe Power Axe [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34406560"])
					if changed then
						doWrite = true
						config.blockEffects["34406560"] = value
					end
					changed, value = imgui.checkbox('Hide Switch Axe Amped State [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34406561"])
					if changed then
						doWrite = true
						for n = 34406561,34406570,1 do
							config.blockEffects[tostring(n)] = value
						end
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Charge Blade##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Charge Blade Gauge [Sword Glow]##Suppressed_Buff_Glow', config.blockEffects["34472145"])
					if changed then
						doWrite = true
						config.blockEffects["34472145"] = value
						config.blockEffects["34472146"] = value
						config.blockEffects["34472147"] = value
					end
					changed, value = imgui.checkbox('Hide Charge Blade Element Boost [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34472137"])
					if changed then
						doWrite = true
						config.blockEffects["34472137"] = value
					end
					changed, value = imgui.checkbox('Hide Charge Blade Sword Boost [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34472139"])
					if changed then
						doWrite = true
						for n = 34472139,34472144,1 do
							config.blockEffects[tostring(n)] = value
						end
					end
					changed, value = imgui.checkbox('Hide Charge Blade Power Axe [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34472148"])
					if changed then
						doWrite = true
						config.blockEffects["34472148"] = value
						config.blockEffects["34472149"] = value
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Insect Glaive##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Insect Glaive Kinsect Buffs [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["34537692"])
					if changed then
						doWrite = true
						config.blockEffects["34537692"] = value
						config.blockEffects["34537693"] = value
						config.blockEffects["34537694"] = value
					end
					imgui.tree_pop()
				end
				if imgui.tree_node("Bow##Suppressed_Buff_Glow") then
					changed, value = imgui.checkbox('Hide Bow Charge [Weapon Glow]##Suppressed_Buff_Glow', config.blockEffects["34603245"])
					if changed then
						doWrite = true
						for n = 34603245,34603248,1 do
							config.blockEffects[tostring(n)] = value
						end
					end
					changed, value = imgui.checkbox('Reduce Bow Charge [Weapon Glow]##Suppressed_Buff_Glow', config.blockBodyEffects["34603245"])
					if changed then
						doWrite = true
						for n = 34603245,34603248,1 do
							config.blockBodyEffects[tostring(n)] = value
						end
					end
					imgui.tree_pop()
				end
				imgui.tree_pop()
			end
			if imgui.tree_node("Palico Buff Effects##Suppressed_Buff_Glow") then
				changed, value = imgui.checkbox('Hide Attack Boost [Palico Glow##Suppressed_Buff_Glow', config.blockEffects["86770200"])
				if changed then
					doWrite = true
					config.blockEffects["86770200"] = value
				end
				changed, value = imgui.checkbox('Hide Defense Boost [Palico Glow]##Suppressed_Buff_Glow', config.blockEffects["86770198"])
				if changed then
					doWrite = true
					config.blockEffects["86770198"] = value
				end
				changed, value = imgui.checkbox('Hide Stamina Boost [Palico Glow]##Suppressed_Buff_Glow', config.blockEffects["86770196"])
				if changed then
					doWrite = true
					config.blockEffects["86770196"] = value
				end
				imgui.tree_pop()
			end
			if imgui.tree_node("Debuff Effects##Suppressed_Buff_Glow") then
				changed, value = imgui.checkbox('Hide Frenzy: Onset [Hunter Glow, Smoke, Sound]##Suppressed_Buff_Glow', config.blockEffects["33882171"])
				if changed then
					doWrite = true
					config.blockEffects["33882171"] = value
				end
				changed, value = imgui.checkbox('Hide Frenzy: Infected [Smoke, Sound]##Suppressed_Buff_Glow', config.blockEffects["33882172"])
				if changed then
					doWrite = true
					config.blockEffects["33882172"] = value
				end
				changed, value = imgui.checkbox('Hide Frenzy: Cured [Hunter Glow]##Suppressed_Buff_Glow', config.blockEffects["33882173"])
				if changed then
					doWrite = true
					config.blockEffects["33882173"] = value
				end
				changed, value = imgui.checkbox('Hide Frenzy: Corruption [Hunter Texture]##Suppressed_Buff_Glow', config.blockBadConditionMesh["7"])
				if changed then
					doWrite = true
					config.blockBadConditionMesh["7"] = value
				end
				changed, value = imgui.checkbox('Hide Blastblight: Sparks [Hunter Effect]##Suppressed_Buff_Glow', config.blockEffects["33882159"])
				if changed then
					doWrite = true
					config.blockEffects["33882159"] = value
					config.blockEffects["33882160"] = value
				end
				changed, value = imgui.checkbox('Hide Dragonblight: Sparks [Hunter Effect]##Suppressed_Buff_Glow', config.blockEffects["33882157"])
				if changed then
					doWrite = true
					config.blockEffects["33882157"] = value
				end
				changed, value = imgui.checkbox('Hide Dragonblight: Corruption [Hunter Texture]##Suppressed_Buff_Glow', config.blockBadConditionMesh["1"])
				if changed then
					doWrite = true
					config.blockBadConditionMesh["1"] = value
				end
				changed, value = imgui.checkbox('Hide Fireblight: Flames [Hunter Effect]##Suppressed_Buff_Glow', config.blockEffects["33882152"])
				if changed then
					doWrite = true
					config.blockEffects["33882152"] = value
				end
				changed, value = imgui.checkbox('Hide Fireblight: Burns [Hunter Texture]##Suppressed_Buff_Glow', config.blockBadConditionMesh["0"])
				if changed then
					doWrite = true
					config.blockBadConditionMesh["0"] = value
				end
				changed, value = imgui.checkbox('Hide Poison: Smoke [Hunter Effect]##Suppressed_Buff_Glow', config.blockEffects["33882148"])
				if changed then
					doWrite = true
					config.blockEffects["33882148"] = value
				end
				changed, value = imgui.checkbox('Hide Poison: Corruption [Hunter Texture]##Suppressed_Buff_Glow', config.blockBadConditionMesh["5"])
				if changed then
					doWrite = true
					config.blockBadConditionMesh["5"] = value
				end
				changed, value = imgui.checkbox('Hide Thunderblight: Sparks [Hunter Effect]##Suppressed_Buff_Glow', config.blockEffects["33882155"])
				if changed then
					doWrite = true
					config.blockEffects["33882155"] = value
				end
				changed, value = imgui.checkbox('Hide Waterblight: Soaked [Hunter Effect]##Suppressed_Buff_Glow', config.blockEffects["33882154"])
				if changed then
					doWrite = true
					config.blockEffects["33882154"] = value
				end
				imgui.tree_pop()
			end
			if imgui.tree_node("Other##Suppressed_Buff_Glow") then
				changed, value = imgui.checkbox('Hide Monster Wounds [Glow in Focus and Mount]##Suppressed_Buff_Glow', config.blockEffects["137822824"])
				if changed then
					doWrite = true
					for n = 137822824,137822828,1 do
						config.blockEffects[tostring(n)] = value
					end
					config.blockEffects["137953907"] = value
					config.blockEffects["137953908"] = value
				end
				changed, value = imgui.checkbox('Hide Everything the Glows Touch [Glow, Sound, Etc.]##Suppressed_Buff_Glow', config.hideAllEffectLoops)
				if changed then
					doWrite = true
					config.hideAllEffectLoops = value
				end
				imgui.text("   Not much tested; just hides everything that goes through the 'cHunterEffect' loop functions.")
				imgui.tree_pop()
			end
			if doWrite then
				json.dump_file(configPath, config)
			end
			imgui.end_window()
        else
            drawOptionsWindow = false
        end
    end
end)

log.info("[Persistent Buff Glow Removal] finished loading")