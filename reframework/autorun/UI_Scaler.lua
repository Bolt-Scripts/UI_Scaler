




local settings = {
	uiScale = 0.75;
	wirebugScale = 0.8;
	mapScale = 0.8;
};








function SaveSettings()
	json.dump_file("UI_Scaler.json", settings);
end

function LoadSettings()
	local loadedSettings = json.load_file("UI_Scaler.json");
	if loadedSettings then
		settings = loadedSettings;
	end

	if not settings.mapScale then
		settings.mapScale = 0.8;
	end
end

LoadSettings();


local baseWidth = 1920.0;
local baseHeight = 1080.0;
local aspect = 0.5625;
local scaleAdjust = 0.3;


 --for debug
local ram = -1;
local curType = "";


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
	[0] = { 0,  0},
	[1] = { 0, .5},
	[2] = { 0,  1},
	[3] = {.5,  0},
	[4] = {.5, .5},
	[5] = {.5,  1},
	[6] = { 1,  0},
	[7] = { 1, .5},
	[8] = { 1,  1},
};

function GetAnchorDir(type)
	return dirScales[anchors[type]];
end

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
	["snow.gui.GuiQuestHudCustomShortCircle"] = {anchor = "RightCenter", },

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
local bToString = behaviourType:get_method("ToString()");
local view_root = behaviourType:get_field("view_root");

local viewType = sdk.find_type_definition("via.gui.View");
local set_ScreenSize = viewType:get_method("set_ScreenSize");

local glaiveType = sdk.find_type_definition("snow.gui.GuiHud_Weapon_I_Glaive");
local glaiveTopPanel = glaiveType:get_field("pnl_I_Gla_Top");

local tgType = sdk.find_type_definition("snow.gui.GuiHud_TgCamera");
local _tgCameraUIAimPanel = tgType:get_field("_tgCameraUIAimPanel");

local panelType = sdk.find_type_definition("via.gui.Panel");

local invScale = 0;
local tmpScale = 1;

function CallChanges()

	local behaviourTable = _guiSystemBehaviorTbl:get_data(GetGuiManager());
	local count = _count:get_data(behaviourTable);
	local entries = _entries:get_data(behaviourTable);

	local idx = -1;

	for i=0, count do
		local bList = value:get_data(entries[i]);
		if not bList then
			goto continue;
		end
		
		local guiBaseRootBehaviours = mItems:get_data(bList);
		local behaviour = guiBaseRootBehaviours[0];		

		if behaviour then

			local typeString = bToString:call(behaviour);
			idx = idx + 1;
			if idx == ram then
				curType = typeString;
				-- goto continue;
			end
			

			local elementData = elementDatas[typeString];
			if not elementData then
				elementData = {};
				if idx ~= ram then
					goto continue;
				end
			end
			if not elementData.anchor then
				elementData.anchor = "LeftTop";
			end
			local view = view_root:get_data(behaviour);
			tmpScale = elementData.scale;
			if not tmpScale then
				tmpScale = settings.uiScale;
			end
			if elementData.isWireB then
				tmpScale = settings.wirebugScale;
			end
			if elementData.isMap then
				tmpScale = settings.mapScale;
			end

			invScale = 1 - tmpScale;
			local scalePosX = baseWidth * invScale / tmpScale;
			local scalePosY = baseHeight * invScale / tmpScale;

			if elementData.isGlaive then
				--this is so annoying
				local tp = glaiveTopPanel:get_data(behaviour);
				local newScale = ValueType.new(vec3Type);
				vecCtor:call(newScale, tmpScale, tmpScale, 1.0);
				set_Scale:call(tp, newScale);

				local off = ValueType.new(vec3Type);
				local oX = baseWidth * 0.15 * invScale;
				local oY = baseHeight * 0.1 * invScale;
				vecCtor:call(off, oX, oY, 1.0);

				local pos = get_Position:call(tp);
				local offPos = vecSub:call(nil, pos, off);
				set_Position:call(tp, offPos);

				goto continue;
			end
			
			local nPos = ValueType.new(vec3Type);
			local x = 0;
			local y = 0;
			if elementData.useScale then
				tmpScale = tmpScale + (invScale * scaleAdjust);
				local newScale = ValueType.new(vec3Type);
				vecCtor:call(newScale, tmpScale, tmpScale, 1.0);
				set_Scale:call(view, newScale);
			else
				--idunno why calling create instance for via.size doesnt work properly but what the heck ever man
				--edit: bc valuetype nonsense i.e. its a weird struct like type in RE
				local newSize = ValueType.new(sizeType);
				local scaleWidth = baseWidth / tmpScale;
				sizeCtor:call(newSize, scaleWidth, scaleWidth * aspect);
				set_ScreenSize:call(view, newSize);			

				local dir = GetAnchorDir(elementData.anchor);				
				x = (dir[1] * scalePosX);
				y = (dir[2] * scalePosY);
			end


			--correction for target reticle
			if elementData.isTargetElement then
				CorrectReticlePos(_tgCameraUIAimPanel:get_data(behaviour));
			end			

			if elementData.offsetX then
				x = x + elementData.offsetX * scalePosX;
			end

			vecCtor:call(nPos, x, y, 0);
			set_Position:call(view, nPos);
		end
		
		
		::continue::
	end
end


function CorrectReticlePos(reticle)

	local reticlePos = get_Position:call(reticle);

	local rX = -(baseWidth * invScale / tmpScale) * aspect;
	local rY = (baseHeight * invScale / tmpScale) * aspect;

	local adjustRetPos = ValueType.new(vec3Type);
	vecCtor:call(adjustRetPos, rX, rY, 0.0);

	local addPos = vecAdd:call(nil, reticlePos, adjustRetPos);
	
	set_Position:call(reticle, addPos);
end



re.on_draw_ui(function()

	local changed = false;
	
    if imgui.tree_node("UI Scaler") then

		changed, settings.uiScale = imgui.slider_float("Scale", settings.uiScale, 0, 1);
		changed, settings.wirebugScale = imgui.slider_float("WireBug Scale", settings.wirebugScale, 0, 1);
		changed, settings.mapScale = imgui.slider_float("Map Scale", settings.mapScale, 0, 1);

		--debug
		changed, ram = imgui.slider_int("ram", ram, 0, 100);
		imgui.text(curType);

        imgui.tree_pop();
    end

end)

re.on_application_entry("RenderGUI", function()
	CallChanges();
end)


re.on_config_save(function()
	SaveSettings();
end)