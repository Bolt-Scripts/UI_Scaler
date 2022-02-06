




local settings = {
	uiScale = 0.75;
	wirebugScale = 1.0;
	mapScale = 0.8;
	bottomRightScale = 0.75;

	overkillMode = false;
};


--These can sort of be customized but the only youll wanna do is add a scale value like {scale=0.5} or w/e
--This will override the scale for that element
local elementDatas = {
	["snow.gui.GuiHud"] = {},
	["snow.gui.GuiHud_QuestTarget"] = {},
	["snow.gui.GuiHud_TimeLimit"] = {},
	["snow.gui.GuiLobbyQuestInfoWindow"] = {},
	["snow.gui.GuiHud_Sharpness"] = {},
	["snow.gui.GuiHud_Weapon_L_Swd"] = {},
	["snow.gui.GuiHud_Weapon_C_Axe"] = {},
	["snow.gui.GuiHud_Weapon_S_Axe"] = {},
	["snow.gui.GuiHud_Weapon_G_Lan"] = {},
	["snow.gui.GuiHud_Weapon_Horn"] = {},
	["snow.gui.GuiHud_Weapon_I_Glaive"] = {isGlaive = true},
	["snow.gui.GuiHud_Weapon_Ham"] = {},
	["snow.gui.GuiHud_Weapon_D_Bld"] = {},
	["snow.gui.GuiHud_Weapon_Bowgun"] = {useScale = true},
	["snow.gui.GuiQuestHudMapWindow"] = {anchor = "LeftBottom", isMap = true},
	["snow.gui.GuiQuestHudBulletSlider"] = {anchor = "RightBottom"},
	["snow.gui.GuiHud_ItemActionSlider"] = {anchor = "RightBottom"},
	["snow.gui.GuiChatInfoWindow"] = {anchor = "RightCenter"},
	["snow.gui.GuiProgressInfo"] = {anchor = "RightTop"},
	["snow.gui.GuiQuestHudCustomShortCircle"] = {anchor = "RightCenter"},


	--most of the issues below could be solved by moving the sub ui panels directly but thats really annoying to set up so 
	--it is what it is atm

	--you can try to turn this on but it makes the target reticle a bit off
	--id recommend just turning the target hud off entirely
	-- ["snow.gui.GuiHud_TgCamera"] = {isTargetElement = true, anchor = "RightTop"},

	--this ones a bit tricky since the bugs are on the same object as the reticle and it doesnt scale quite right
	--as a compromise im just shifting the reticle to the right so its still center
	--not sure if this will cause issues on other resolutions or something tho
	["snow.gui.GuiHud_HunterWire"] = {useScale = true, isWireB = true, anchor = "CenterCenter", offsetX = 0.25},

	--unfortunately this doesnt scale properly and is also for player names which are in world space
	--but this might be fine if you turn player names off anyway
	-- ["snow.gui.GuiCommonHeadMessage"] = {anchor = "CenterCenter"}, 
};

local anchors = {
	["LeftTop"     ] = 0,
	["LeftCenter"  ] = 1,
	["LeftBottom"  ] = 2,
	["CenterTop"   ] = 3,
	["CenterCenter"] = 4,
	["CenterBottom"] = 5,
	["RightTop"    ] = 6,
	["RightCenter" ] = 7,
	["RightBottom" ] = 8,
};

local dirScales = {
	[0] = { 0,  0, "LeftTop"     },
	[1] = { 0, .5, "LeftCenter"  },
	[2] = { 0,  1, "LeftBottom"  },
	[3] = {.5,  0, "CenterTop"   },
	[4] = {.5, .5, "CenterCenter"},
	[5] = {.5,  1, "CenterBottom"},
	[6] = { 1,  0, "RightTop"    },
	[7] = { 1, .5, "RightCenter" },
	[8] = { 1,  1, "RightBottom" },
};


local elementIdxs = {};

function GetElementSettings(typeString)

	local elementSettings = settings.elementSettings[typeString];

	-- elementSettings = nil;

	if not elementSettings then

		local data = elementDatas[typeString];
		local anchorIdx = 0;
		if data and data.anchor then
			anchorIdx = anchors[data.anchor];
		end

		elementSettings = {
			displayName = typeString:sub(10):gsub("GuiHud_", ""):gsub("Gui", "");
			scale = settings.uiScale;
			posX = 0;
			posY = 0;
			anchor = anchorIdx;
		};
		settings.elementSettings[typeString] = elementSettings;
	end

	return elementSettings;
end


function SaveSettings()
	json.dump_file("UI_Scaler.json", settings);
end

function LoadSettings()
	local loadedSettings = json.load_file("UI_Scaler.json");
	if loadedSettings then
		settings = loadedSettings;
	end

	if not settings.mapScale then settings.mapScale = 0.8; end
	if not settings.bottomRightScale then settings.bottomRightScale = settings.uiScale; end
	if not settings.elementSettings then settings.elementSettings = {}; end

	for key, element in pairs(elementDatas) do
		table.insert(elementIdxs, key);
	end

	table.sort(elementIdxs, function (left, right)
		return (GetElementSettings(left).displayName) < (GetElementSettings(right).displayName);
	end)
end

LoadSettings();


local baseWidth = 1920.0;
local baseHeight = 1080.0;
local aspect = 0.5625;
local scaleAdjust = 0.3;


 --for debug
local ram = -1;
local curType = "";


local guiManager = nil;

function GetGuiManager()
	if not guiManager then
		guiManager = sdk.get_managed_singleton("snow.gui.GuiManager");
	end
	
	return guiManager;
end

--this is complete ass that i have to do this if i dont wanna have all these lookups every frame >:(
local transformType = sdk.find_type_definition("via.gui.TransformObject");
local set_Scale = transformType:get_method("set_Scale");
local set_Position = transformType:get_method("set_Position");
local get_Position = transformType:get_method("get_Position");

local vec3Type = sdk.find_type_definition("via.vec3");
local vec3X = vec3Type:get_field("x");
local vec3Y = vec3Type:get_field("y");
local vecCtor = vec3Type:get_method(".ctor(System.Single, System.Single, System.Single)");
local vecGetItem = vec3Type:get_method("get_Item");
local vecAdd = vec3Type:get_method("op_Addition");
local vecSub = vec3Type:get_method("op_Subtraction");
local vecDiv = vec3Type:get_method("op_Division");
local vecMult = vec3Type:get_method("op_Multiply");

local sizeType = sdk.find_type_definition("via.Size");
local sizeCtor = sizeType:get_method(".ctor(System.Single, System.Single)");

local guiManagerType = sdk.find_type_definition("snow.gui.GuiManager");
local _guiSystemBehaviorTbl = guiManagerType:get_field("_guiSystemBehaviorTbl");

local behaviourTblType = sdk.find_type_definition("System.Collections.Generic.Dictionary`2<System.Type,System.Collections.Generic.List`1<snow.gui.GuiRootBaseBehavior>>");
local tblEntryType = sdk.find_type_definition("System.Collections.Generic.Dictionary`2.Entry<System.Type,System.Collections.Generic.List`1<snow.gui.GuiRootBaseBehavior>>");
local _count = behaviourTblType:get_field("_count");
local _entries = behaviourTblType:get_field("_entries");
local value = tblEntryType:get_field("value");

local behaviourListType = sdk.find_type_definition("System.Collections.Generic.List`1<snow.gui.GuiRootBaseBehavior>");
local mSize = behaviourListType:get_field("mSize");
local mItems = behaviourListType:get_field("mItems");

local behaviourType = sdk.find_type_definition("snow.gui.GuiRootBaseBehavior");
local behaviourTypeSystem = sdk.typeof("snow.gui.GuiRootBaseBehavior");
local bToString = behaviourType:get_method("ToString()");
local view_root = behaviourType:get_field("view_root");

local viewType = sdk.find_type_definition("via.gui.View");
local set_ScreenSize = viewType:get_method("set_ScreenSize");

local glaiveType = sdk.find_type_definition("snow.gui.GuiHud_Weapon_I_Glaive");
local glaiveTopPanel = glaiveType:get_field("pnl_I_Gla_Top");

local tgType = sdk.find_type_definition("snow.gui.GuiHud_TgCamera");
local _tgCameraUIAimPanel = tgType:get_field("_tgCameraUIAimPanel");

local panelType = sdk.find_type_definition("via.gui.Panel");

local viaGuiType = sdk.find_type_definition("via.gui.GUI");
local get_GameObject = viaGuiType:get_method("get_GameObject");
local goType = sdk.find_type_definition("via.GameObject");
local get_Components = goType:get_method("get_Components");
local getComponent = goType:get_method("getComponent(System.Type)");


local invScale = 0;
local tmpScale = 1;
local ramIdx = -1;

function GuiListIterate()

	local behaviourTable = _guiSystemBehaviorTbl:get_data(GetGuiManager());
	local count = _count:get_data(behaviourTable);
	local entries = _entries:get_data(behaviourTable);

	ramIdx = -1;

	for i=0, count do
		local bList = value:get_data(entries[i]);
		if not bList then
			goto continue;
		end
		
		local guiBaseRootBehaviours = mItems:get_data(bList);
		local behaviour = guiBaseRootBehaviours[0];

		if behaviour then
			ManipulateElement(behaviour);
		end
		
		
		::continue::
	end
end

function ManipulateElement(guiBehaviour)

	local typeString = guiBehaviour:get_type_definition():get_full_name();

	-- log.info(typeString);

	ramIdx = ramIdx + 1;
	if ramIdx == ram then
		curType = typeString;
		return;
	end
	

	local elementData = elementDatas[typeString];
	local elementSettings = nil;
	if settings.overkillMode then
		elementSettings = GetElementSettings(typeString);
	end

	if not elementData then
		elementData = {};
		if ramIdx ~= ram then
			return;
		end
	end
	if not elementData.anchor then
		elementData.anchor = "LeftTop";
	end

	local anchorIdx;
	if elementSettings then
		anchorIdx = elementSettings.anchor;
	else
		anchorIdx = anchors[elementData.anchor];
	end

	local view = view_root:get_data(guiBehaviour);
	tmpScale = elementData.scale;
	

	if elementSettings then
		tmpScale = elementSettings.scale;
	else
		if not tmpScale then
			tmpScale = settings.uiScale;
		end
		if anchorIdx > 5 then
			tmpScale = settings.bottomRightScale
		end
		
		if elementData.isWireB then
			tmpScale = settings.wirebugScale;
			
		elseif elementData.isMap then
			tmpScale = settings.mapScale;
		end		
	end


	invScale = 1 - tmpScale;
	local scalePosX = baseWidth * invScale / tmpScale;
	local scalePosY = baseHeight * invScale / tmpScale;

	if elementData.isGlaive then
		HandleInsectGlaiveUI(guiBehaviour);
		return;
	end

	
	local x = 0;
	local y = 0;
	if elementData.useScale then
		tmpScale = tmpScale + (invScale * scaleAdjust);
		set_Scale:call(view, Vector4f.new(tmpScale, tmpScale, 1.0, 1.0));
	else
		local scaleWidth = baseWidth / tmpScale;
		set_ScreenSize:call(view, Vector2f.new(scaleWidth, scaleWidth * aspect));

		local dir = dirScales[anchorIdx];			
		x = (dir[1] * scalePosX);
		y = (dir[2] * scalePosY);
	end


	if elementData.isTargetElement then
		CorrectReticlePos(_tgCameraUIAimPanel:get_data(guiBehaviour));
	end			

	if elementData.offsetX then
		x = x + elementData.offsetX * scalePosX;
	end

	if elementSettings then
		x = x + elementSettings.posX;
		y = y + elementSettings.posY;
	end

	set_Position:call(view, Vector4f.new(x, y, 0, 1));
end




function HandleInsectGlaiveUI(behaviour)
	--this is so annoying
	local tp = glaiveTopPanel:get_data(behaviour);
	set_Scale:call(tp, Vector4f.new(tmpScale, tmpScale, 1.0, 1.0));

	local oX = baseWidth * 0.15 * invScale;
	local oY = baseHeight * 0.1 * invScale;

	-- local pos = ;
	local offPos = vecSub:call(nil, 
		get_Position:call(tp),
	 	Vector4f.new(oX, oY, 1.0, 1.0)
	);

	set_Position:call(tp, offPos);
end

function CorrectReticlePos(reticle)

	local reticlePos = get_Position:call(reticle);

	local rX = -(baseWidth * invScale / tmpScale) * aspect;
	local rY = (baseHeight * invScale / tmpScale) * aspect;

	local addPos = vecAdd:call(nil, reticlePos, Vector4f.new(rX, rY, 0.0, 1.0));	
	set_Position:call(reticle, addPos);
end



function DrawElementSettings(element)
	imgui.text(element.displayName);
	imgui.spacing();
	imgui.begin_rect();
	local anchorName = dirScales[element.anchor][3];
	changed, element.scale = imgui.slider_float("Scale: "..element.displayName, element.scale, 0, 1);
	changed, element.posX = imgui.slider_float("X Pos: "..element.displayName, element.posX, -2000, 2000);
	changed, element.posY = imgui.slider_float("Y Pos: "..element.displayName, element.posY, -2000, 2000);

	changed, element.anchor = imgui.slider_int("Anchor: "..element.displayName, element.anchor, 0, 8);
	imgui.same_line();
	imgui.text(anchorName);

	imgui.end_rect(5);
	imgui.new_line();
end

re.on_draw_ui(function()

	local changed = false;
	
    if imgui.tree_node("UI Scaler") then

		changed, settings.uiScale = imgui.slider_float("Top Left Scale", settings.uiScale, 0, 1);
		changed, settings.bottomRightScale = imgui.slider_float("Right Scale", settings.bottomRightScale, 0, 1);
		changed, settings.mapScale = imgui.slider_float("Map Scale", settings.mapScale, 0, 1);
		changed, settings.wirebugScale = imgui.slider_float("WireBug Scale", settings.wirebugScale, 0, 1);

		imgui.spacing()
		changed, settings.overkillMode = imgui.checkbox("Overkill Mode", settings.overkillMode);

		if settings.overkillMode then
			if imgui.tree_node("Overkill Settings") then

				imgui.spacing();
				for i, key in ipairs(elementIdxs) do
					DrawElementSettings(GetElementSettings(key));
				end

				imgui.tree_pop();
			end
		end


		--debug
		-- changed, ram = imgui.slider_int("ram", ram, 0, 100);
		-- imgui.text(curType);
		
		imgui.spacing();
        imgui.tree_pop();
    end

end)



re.on_pre_gui_draw_element(function(element, context)

	local gui_game_object = get_GameObject:call(element);
	if gui_game_object == nil then return true end;	


	--not really sure which is faster with this
	--dunno if getcomponent is slow or not vs just getting the array of components
	--probably doesnt really matter but who knows
	--but it feels like itd be slower to do get_elements and iterate all the components
	--though I also dunno what get_elements() actually does.
	--I just hope none of this allocates a bunch of garbage but its really hard to know

    -- local components = get_Components:call(gui_game_object):get_elements();
    -- for i, component in ipairs(components) do
	-- 	ManipulateElement(component);
    -- end

	local behaviour = getComponent:call(gui_game_object, behaviourTypeSystem);
	if behaviour then
		ManipulateElement(behaviour);
	end
end)


re.on_config_save(function()
	SaveSettings();
end)