



local settings = {
	uiScale = 0.75;
	centerScale = 0.75;
	mapScale = 0.8;
	bottomRightScale = 0.75;
	namesScale = 0.75;

	overkillMode = false;
	unlockScaleSliders = false;
};


local elementSetup = require("UI_Scaler.UI_Scaler_Element_Setup");
local elementDatas = elementSetup.datas;

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

local subDirScales = {
	[0] = { -1, -1, "LeftTop"     },
	[1] = { -1, .5, "LeftCenter"  },
	[2] = { -1,  1, "LeftBottom"  },
	[3] = { .5, -1, "CenterTop"   },
	[4] = { .5, .5, "CenterCenter"},
	[5] = { .5,  1, "CenterBottom"},
	[6] = {  1, -1, "RightTop"    },
	[7] = {  1, .5, "RightCenter" },
	[8] = {  1,  1, "RightBottom" },
};


local baseWidth = 1920.0;
local baseHeight = 1080.0;
local aspect = 0.5625;
local scaleAdjust = 0.3;

local elementIdxs = {};
local foundElements = {};
local uiOpen = false;


local function GetElementClassDisplayName(typeString)
	return typeString:sub(10):gsub("GuiHud_", ""):gsub("Gui", "");
end

local function GetElementSettings(typeString)

	local elementSettings = settings.elementSettings[typeString];

	if not elementSettings then

		local data = elementDatas[typeString];
		local anchorIdx = 0;
		if data and data.anchor then
			anchorIdx = anchors[data.anchor];
		end

		elementSettings = {
			displayName = GetElementClassDisplayName(typeString);
			scale = settings.uiScale;
			posX = 0;
			posY = 0;
			anchor = anchorIdx;
		};
		settings.elementSettings[typeString] = elementSettings;
	end

	return elementSettings;
end


local function SortElements()

	elementIdxs = {};

	for key, element in pairs(elementDatas) do
		table.insert(elementIdxs, key);
	end

	table.sort(elementIdxs, function (left, right)
		return (GetElementSettings(left).displayName) < (GetElementSettings(right).displayName);
	end)
end

local function SaveSettings()
	log.info("UI_SCALER: Saved Settings");
	json.dump_file("UI_Scaler.json", settings);
end

local function LoadSettings()

	log.info("UI_SCALER: Loaded Settings");

	local loadedSettings = json.load_file("UI_Scaler.json");
	if loadedSettings then
		settings = loadedSettings;
	end

	if not settings.namesScale then settings.namesScale = 0.75; end
	if not settings.mapScale then settings.mapScale = 0.8; end
	if not settings.centerScale then settings.centerScale = 0.75; end
	if not settings.bottomRightScale then settings.bottomRightScale = settings.uiScale; end
	if not settings.elementSettings then settings.elementSettings = {}; end

	for key, element in pairs(settings.elementSettings) do
		if not elementDatas[key] then
			elementDatas[key] = {}
		end

		if element.subPanels then
			for panelName, subPanel in pairs(element.subPanels) do
				if sdk.find_type_definition(key):get_field(panelName):get_type():is_a(guiElementType) then
					subPanel.isElementType = true;
				end
			end
		end
	end

	SortElements();

	elementSetup.SetDefaultSubPanels(settings);
end



LoadSettings();


 --for debug
local ram = -1;
local curType = "";


local guiManager = nil;

local function GetGuiManager()
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
local vecCtor = vec3Type:get_method(".ctor(System.Single, System.Single, System.Single)");
local vecGetItem = vec3Type:get_method("get_Item");
local vecAdd = vec3Type:get_method("op_Addition");
local vecSub = vec3Type:get_method("op_Subtraction");

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
local view_root = behaviourType:get_field("view_root");

local viewType = sdk.find_type_definition("via.gui.View");
local set_ScreenSize = viewType:get_method("set_ScreenSize");

local glaiveType = sdk.find_type_definition("snow.gui.GuiHud_Weapon_I_Glaive");
local glaiveTopPanel = glaiveType:get_field("pnl_I_Gla_Top");

local tgType = sdk.find_type_definition("snow.gui.GuiHud_TgCamera");
local _tgCameraUIAimPanel = tgType:get_field("_tgCameraUIAimPanel");

local panelType = sdk.find_type_definition("via.gui.Panel");
local guiElementType = sdk.find_type_definition("via.gui.Element");

local viaGuiType = sdk.find_type_definition("via.gui.GUI");
local get_GameObject = viaGuiType:get_method("get_GameObject");
local goType = sdk.find_type_definition("via.GameObject");
local get_Components = goType:get_method("get_Components");
local getComponent = goType:get_method("getComponent(System.Type)");

local invScale = 0;
local tmpScale = 1;
local ramIdx = -1;

local function GetElementList()
	local behaviourTable = _guiSystemBehaviorTbl:get_data(GetGuiManager());
	local count = _count:get_data(behaviourTable);
	local entries = _entries:get_data(behaviourTable);

	return entries, count;
end

local function GuiListIterate()

	local count;
	local entries, count = GetElementList();

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


----------------------------- UI MANIP CODE ------------------------------------------
local function HandleSubPanel(behaviour, subPanel, subPanelName)

	local tp = behaviour:get_field(subPanelName);
	if not tp then return end;

	if subPanel.useGlobalScale then
		if subPanel.isName then
			tmpScale = settings.namesScale;
		elseif subPanel.anchor > 5 then
			tmpScale = settings.bottomRightScale;
		elseif subPanel.anchor > 2 then
			tmpScale = settings.centerScale;
		else
			tmpScale = settings.uiScale;
		end
	else
		tmpScale = subPanel.scale;
	end
	invScale = 1 - tmpScale;


	if not subPanel.vectorPos then subPanel.vectorPos = Vector4f.new(0,0,0,1); end
	if not subPanel.vectorScale then subPanel.vectorScale = Vector4f.new(1,1,1,1); end

	local dir = subDirScales[subPanel.anchor];
	subPanel.vectorPos.x = (dir[1] * baseWidth *  subPanel.posAdjustX * invScale);
	subPanel.vectorPos.y = (dir[2] * baseHeight * subPanel.posAdjustY * invScale);

	if settings.overkillMode or subPanel.absolutePos then
		subPanel.vectorPos.x = subPanel.vectorPos.x + subPanel.posX;
		subPanel.vectorPos.y = subPanel.vectorPos.y + subPanel.posY;
	end

	if not subPanel.absolutePos then
		local startPos = get_Position:call(tp);
		subPanel.vectorPos.x = subPanel.vectorPos.x + startPos.x;
		subPanel.vectorPos.y = subPanel.vectorPos.y + startPos.y;
	end


	set_Position:call(tp, subPanel.vectorPos);

	if subPanel.isElementType then
		--these dont really support scale properly
		return;
	end

	subPanel.vectorScale.x = tmpScale;
	subPanel.vectorScale.y = tmpScale;
	set_Scale:call(tp, subPanel.vectorScale);
end

local function ManipulateElement(guiBehaviour)

	local typeString = guiBehaviour:get_type_definition():get_full_name();

	-- log.info(typeString);

	if uiOpen then
		foundElements[typeString] = true;
	end

	ramIdx = ramIdx + 1;
	if ramIdx == ram then
		curType = typeString;
		return;
	end


	local elementData = elementDatas[typeString];

	if not elementData then
		if ramIdx ~= ram then
			return;
		end
		elementData = {};
	end
	if not elementData.anchor then
		elementData.anchor = "LeftTop";
	end

	local elementSettings = nil;
	if settings.overkillMode or elementData.isComplex then
		elementSettings = GetElementSettings(typeString);
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
		if elementData.isComplex then
			--dont really wanna use the scale on the parent component for these since its handled in the panels themselves
			tmpScale = 1;
		else
			tmpScale = elementSettings.scale;
		end
	else
		if not tmpScale then
			tmpScale = settings.uiScale;
		end
		if anchorIdx > 5 then
			tmpScale = settings.bottomRightScale
		elseif anchorIdx > 2 then
			tmpScale = settings.centerScale;
		end


		if elementData.isMap then
			tmpScale = settings.mapScale;
		end
	end

	invScale = 1 - tmpScale;
	local scalePosX = baseWidth * invScale / tmpScale;
	local scalePosY = baseHeight * invScale / tmpScale;

	--who knows anymore
	if not elementData.pos then	elementData.pos = Vector4f.new(0,0,0,1); end
	if not elementData.size then elementData.size = Vector2f.new(0,0); end
	if not elementData.scaleV then elementData.scaleV = Vector4f.new(1,1,1,1); end

	local x = 0;
	local y = 0;
	if elementData.useScale then
		tmpScale = tmpScale + (invScale * scaleAdjust);
		elementData.scaleV.x = tmpScale;
		elementData.scaleV.y = tmpScale;
		set_Scale:call(view, elementData.scaleV);
	else
		local scaleWidth = baseWidth / tmpScale;

		elementData.size.x = scaleWidth;
		elementData.size.y = scaleWidth * aspect;
		set_ScreenSize:call(view, elementData.size);

		local dir = dirScales[anchorIdx];
		x = (dir[1] * scalePosX);
		y = (dir[2] * scalePosY);
	end


	if elementSettings and elementSettings.subPanels then
		for panelName, subPanel in pairs(elementSettings.subPanels) do
			HandleSubPanel(guiBehaviour, subPanel, panelName);
		end
	end

	if elementSettings and settings.overkillMode then
		x = x + elementSettings.posX;
		y = y + elementSettings.posY;
	end

	elementData.pos.x = x;
	elementData.pos.y = y;
	set_Position:call(view, elementData.pos);
end










------------------------------------INSANE UI GARBAGE----------------------------------------------

local function GetEmptyElement(bName)
	return {
		displayName = GetElementClassDisplayName(bName);
		anchor = 0;
		scale = 1;
		posX = 0;
		posY = 0;
	};
end

local function DrawElementSelector()

	local count;
	local entries, count = GetElementList();
	local behaviourNames = {"Click to Add a UI Element"};

	for i=0, count do
		local bList = value:get_data(entries[i]);
		if not bList then
			goto continue;
		end

		local guiBaseRootBehaviours = mItems:get_data(bList);
		local behaviour = guiBaseRootBehaviours[0];

		if behaviour then
			local bName = behaviour:get_type_definition():get_full_name();
			if not elementDatas[bName] then
				foundElements[bName] = true;
			end
		end

		::continue::
	end

	for bName, value  in pairs(foundElements) do
		table.insert(behaviourNames, bName);
	end

	local value;
	changed, value = imgui.combo("GUI Elements", 0, behaviourNames);
	if changed and value > 1 then
		--selected panel from drop down so add it to the list
		local bName = behaviourNames[value];

		settings.elementSettings[bName] = GetEmptyElement(bName);
		elementDatas[bName] = GetEmptyElement(bName);
		elementDatas[bName].anchor = "LeftTop";
		SortElements();
	end
end

local function DrawPositioningUI(element)
	if settings.unlockScaleSliders then
		changed, element.scale = imgui.drag_float("Scale", element.scale, 0.001, 0, 100);
	else
		changed, element.scale = imgui.slider_float("Scale", element.scale, 0, 1);
	end
	changed, element.posX = imgui.drag_float("X Pos" , element.posX, 0.1, -2500, 2500);
	changed, element.posY = imgui.drag_float("Y Pos" , element.posY, 0.1, -2500, 2500);
	changed, element.anchor = imgui.slider_int("Anchor:", element.anchor, 0, 8);
	imgui.same_line();
	local anchorName = dirScales[element.anchor][3];
	imgui.text(anchorName);
end

local function DrawElementSettings(element, typeName)

	if imgui.tree_node(element.displayName) then

		imgui.same_line();
		if imgui.button("Remove Element") then
			elementDatas[typeName] = nil;
			settings.elementSettings[typeName] = nil;
			SortElements();
		end

		imgui.spacing();
		imgui.begin_rect();

		imgui.text("Full Type Name: "..typeName);
		DrawPositioningUI(element);

		imgui.new_line();
		imgui.text("Sub Panels");
		imgui.spacing();

		local elementType = sdk.find_type_definition(typeName);
		if elementType then

			local fields = elementType:get_fields();
			local fieldNames = {"Click to Add a Sub-Panel"};

			if not element.subPanels then
				element.subPanels = {};
			end

			for i, field in ipairs(fields) do
				if (field:get_type():is_a(transformType) or field:get_type():is_a(guiElementType)) and not element.subPanels[field:get_name()] then
					table.insert(fieldNames, field:get_name());
				end
			end

			--draw panel selection dropdown
			local value;
			changed, value = imgui.combo("Panel List ", 0, fieldNames);
			if changed and value > 1 then
				--selected panel from drop down so add it to the list
				local panelName = fieldNames[value];
				local newSub = {
					displayName = panelName:gsub("pnl_", "");
					anchor = element.anchor;
					posX = 0;
					posY = 0;
					posAdjustX = 0;
					posAdjustY = 0;
					scale = 1;
					absolutePos = true;
				};

				if elementType:get_field(panelName):get_type():is_a(guiElementType) then
					newSub.isElementType = true;
				end

				element.subPanels[panelName] = newSub;
			end


			--draw individual sub panel ui
			if element.subPanels then
				for panelName, subPanel in pairs(element.subPanels) do

					imgui.spacing();

					if not subPanel.displayName then
						subPanel.displayName = panelName;
					end

					if imgui.tree_node(subPanel.displayName.."  - SubPanel") then

						imgui.same_line();
						if imgui.button("Remove") then
							element.subPanels[panelName] = nil;
						end

						imgui.begin_rect();
						DrawPositioningUI(subPanel);
						changed, subPanel.posAdjustX = imgui.slider_float("Pos Adjust X", subPanel.posAdjustX, 0, 1);
						changed, subPanel.posAdjustY = imgui.slider_float("Pos Adjust Y", subPanel.posAdjustY, 0, 1);
						changed, subPanel.useGlobalScale = imgui.checkbox("Use Global Scale", subPanel.useGlobalScale);
						changed, subPanel.absolutePos = imgui.checkbox("Absolute Position", subPanel.absolutePos);
						imgui.end_rect(5);

						imgui.spacing();
						imgui.tree_pop();
					end
				end
			end


		else
			re.msg("Bad UI Type: "..typeName);
		end

		imgui.end_rect(5);
		imgui.tree_pop();
	end

	imgui.spacing();
end


local confirmReset = false;

local function DrawOverkillUI()
	if imgui.tree_node("Overkill Settings") then

		changed, settings.unlockScaleSliders = imgui.checkbox("Unlock Scale Sliders", settings.unlockScaleSliders);

		imgui.same_line();
		if imgui.button("Copy Left Scale to All") then
			for elementName, element in pairs(settings.elementSettings) do
				element.scale = settings.uiScale;
				if element.subPanels then
					for panelName, subPanel in pairs(element.subPanels) do
						subPanel.scale = settings.uiScale;
					end
				end
			end
		end


		imgui.same_line();
		if imgui.button(confirmReset and "Are you sure?" or "Reset All") then
			if confirmReset then
				settings.elementSettings = nil;
				SaveSettings();
				LoadSettings();
				SortElements();
				confirmReset = false;
			else
				confirmReset = true;
			end
		end

		imgui.spacing();
		if imgui.tree_node("Currently Available GUI Element Selector") then
			DrawElementSelector();
			imgui.tree_pop();
		end

		imgui.new_line();

		imgui.begin_rect();
		imgui.spacing();
		for i, key in ipairs(elementIdxs) do
			DrawElementSettings(GetElementSettings(key), key);
		end
		imgui.end_rect(5);

		imgui.tree_pop();
	end
end


re.on_draw_ui(function()

	local changed = false;
	uiOpen = true;

    if imgui.tree_node("UI Scaler") then

		changed, settings.uiScale = imgui.slider_float("Left Scale", settings.uiScale, 0, 1);
		changed, settings.centerScale = imgui.slider_float("Center Scale", settings.centerScale, 0, 1);
		changed, settings.bottomRightScale = imgui.slider_float("Right Scale", settings.bottomRightScale, 0, 1);
		changed, settings.mapScale = imgui.slider_float("Map Scale", settings.mapScale, 0, 1);
		changed, settings.namesScale = imgui.slider_float("Names Scale", settings.namesScale, 0, 1);

		--debug
		-- changed, ram = imgui.slider_int("ram", ram, 0, 100);
		-- imgui.text(curType);

		imgui.new_line();
		changed, settings.overkillMode = imgui.checkbox("Overkill Mode", settings.overkillMode);
		-- if settings.overkillMode then
			DrawOverkillUI();
		-- end

		imgui.new_line();
        imgui.tree_pop();
    end

end)


-- re.on_application_entry("RenderGUI", function()
-- 	GuiListIterate();
-- end)


re.on_pre_application_entry("PreupdateGUI", function()
	uiOpen = false;
end)

local drawElementBehaviour;
local drawGameObject;
re.on_pre_gui_draw_element(function(element, context)

	drawGameObject = get_GameObject:call(element);
	if drawGameObject == nil then return true end;


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

	drawElementBehaviour = getComponent:call(drawGameObject, behaviourTypeSystem);
	if drawElementBehaviour then
		ManipulateElement(drawElementBehaviour);
	end
end)


re.on_config_save(function()
	SaveSettings();
end)