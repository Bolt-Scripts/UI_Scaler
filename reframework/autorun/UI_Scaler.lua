




local settings = {
	uiScale = 0.75;
	wirebugScale = 1.0;
	mapScale = 0.8;
	bottomRightScale = 0.75;
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
	["snow.gui.GuiQuestHudCustomShortCircle"] = {anchor = "RightCenter", },


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

			local typeString = behaviour:get_type_definition():get_full_name();
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

			local anchorIdx = anchors[elementData.anchor];


			local view = view_root:get_data(behaviour);
			tmpScale = elementData.scale;

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



			invScale = 1 - tmpScale;
			local scalePosX = baseWidth * invScale / tmpScale;
			local scalePosY = baseHeight * invScale / tmpScale;

			if elementData.isGlaive then
				HandleInsectGlaiveUI(behaviour);
				goto continue;
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
				CorrectReticlePos(_tgCameraUIAimPanel:get_data(behaviour));
			end			

			if elementData.offsetX then
				x = x + elementData.offsetX * scalePosX;
			end

			-- vecCtor:call(nPos, x, y, 0);
			set_Position:call(view, Vector4f.new(x, y, 0, 1));
		end
		
		
		::continue::
	end
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



re.on_draw_ui(function()

	local changed = false;
	
    if imgui.tree_node("UI Scaler") then

		changed, settings.uiScale = imgui.slider_float("Top Left Scale", settings.uiScale, 0, 1);
		changed, settings.bottomRightScale = imgui.slider_float("Right Scale", settings.bottomRightScale, 0, 1);
		changed, settings.mapScale = imgui.slider_float("Map Scale", settings.mapScale, 0, 1);
		changed, settings.wirebugScale = imgui.slider_float("WireBug Scale", settings.wirebugScale, 0, 1);



		--debug
		-- changed, ram = imgui.slider_int("ram", ram, 0, 100);
		-- imgui.text(curType);

        imgui.tree_pop();
    end

end)

re.on_application_entry("RenderGUI", function()
	CallChanges();
end)


re.on_config_save(function()
	SaveSettings();
end)