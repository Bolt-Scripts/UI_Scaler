

baseWidth = 1920.0;
baseHeight = 1080.0;
aspect = 0.5625;
scaleAdjust = 0.3;


elementDatas = {

	--isComplex is basically a flag that says that it should use the overkill settings regardless
	--for complex elements that have multiple sub panels in different screen locations

	["snow.gui.GuiHud"] = {},
	["snow.gui.GuiHud_QuestTarget"] = {},
	["snow.gui.GuiHud_Timelimit"] = {isComplex = true},
	["snow.gui.GuiHud_IntervalSkip"] = {anchor = "CenterTop"},
	["snow.gui.GuiLobbyQuestInfoWindow"] = {},
	["snow.gui.GuiHud_Sharpness"] = {},
	["snow.gui.GuiHud_Weapon_L_Swd"] = {},
	["snow.gui.GuiHud_Weapon_C_Axe"] = {},
	["snow.gui.GuiHud_Weapon_S_Axe"] = {},
	["snow.gui.GuiHud_Weapon_G_Lan"] = {},
	["snow.gui.GuiHud_Weapon_Horn"] = {},
	["snow.gui.GuiHud_Weapon_I_Glaive"] = {isComplex = true},
	["snow.gui.GuiHud_Weapon_Ham"] = {},
	["snow.gui.GuiHud_Weapon_D_Bld"] = {},
	["snow.gui.GuiHud_Weapon_Bowgun"] = {isComplex = true},
	["snow.gui.GuiQuestHudMapWindow"] = {anchor = "LeftBottom", isMap = true},
	["snow.gui.GuiQuestHudBulletSlider"] = {anchor = "RightBottom"},
	["snow.gui.GuiHud_ItemActionSlider"] = {anchor = "RightBottom"},
	["snow.gui.GuiChatInfoWindow"] = {anchor = "RightCenter"},
	["snow.gui.GuiProgressInfo"] = {anchor = "RightTop"},
	["snow.gui.GuiQuestHudCustomShortCircle"] = {anchor = "RightCenter"},

    ["snow.gui.StmGuiHudKeyboardShortcut"] = {anchor = "CenterBottom"},
	["snow.gui.GuiHud_TgCamera"] = {isComplex = true, anchor = "RightTop"},
	["snow.gui.GuiHud_HunterWire"] = {isComplex = true, anchor = "CenterBottom"},
	["snow.gui.GuiCommonHeadMessage"] = {isComplex = true, anchor = "CenterCenter"}, 
};


function SetDefaultSubPanels(settings)
	local eName = "snow.gui.GuiHud_Weapon_I_Glaive";
	if not settings.elementSettings[eName].subPanels then
		settings.elementSettings   [eName].subPanels = {
			pnl_I_Gla_Top = {
				anchor = 0.0;
				posAdjustX = 0.15;
				posAdjustY = 0.1;
				posX = 0.0;
				posY = 0.0;
				scale = 1.0;
				useGlobalScale = true;
			},
		};
	end

	eName = "snow.gui.GuiHud_TgCamera";
	if not settings.elementSettings[eName].subPanels then
		settings.elementSettings   [eName].subPanels = {
			_tgCameraIconPanel = {
				anchor = 6;
				posAdjustX = 1;
				posAdjustY = 0;
				posX = 0.0;
				posY = 0.0;
				scale = 1.0;
				useGlobalScale = true;
			},
		};
	end

	eName = "snow.gui.GuiCommonHeadMessage";
	if not settings.elementSettings[eName].subPanels then
		settings.elementSettings   [eName].subPanels = {
			_pnl_HeadUI = {
				anchor = 4;
				posAdjustX = 0;
				posAdjustY = 0;
				posX = 0.0;
				posY = 0.0;
				scale = 1.0;
				useGlobalScale = true;
			},
		};
	end

	eName = "snow.gui.GuiHud_Timelimit";
	if not settings.elementSettings[eName].subPanels then
		settings.elementSettings   [eName].subPanels = {
			_pnl_HyakuryuQuestTimer = {
				anchor = 3;
				posAdjustX = 0;
				posAdjustY = 0.185;
				posX = baseWidth / 2;
				posY = 200;
				scale = 1.0;
				useGlobalScale = true;
                absolutePos = true;                
			},
            _pnl_NomalQuestTimer = {
				anchor = 0;
				posAdjustX = 0;
				posAdjustY = 0;
				posX = 0;
				posY = 0;
				scale = 1.0;
				useGlobalScale = true;                
			},
            -- this exists but i dont really know what its for so idk what to do with it
            -- _pnl_TougiQuestTimer = {}
		};
	end

	eName = "snow.gui.GuiHud_HunterWire";
	if not settings.elementSettings[eName].subPanels then
		settings.elementSettings   [eName].subPanels = {
			pnl_HunterWire = {
				anchor = 5;
				posAdjustX = 1;
				posAdjustY = 0.925;
				posX = 0.0;
				posY = 0.0;
				scale = 1.0;
				useGlobalScale = true;
				absolutePos = true;
			},
			pnl_WireAiming = {
				anchor = 4;
				posAdjustX = 0;
				posAdjustY = 0;
				posX = 0.0;
				posY = 0.0;
				scale = 1.0;
				useGlobalScale = true;
			},
		};
	end

	eName = "snow.gui.GuiHud_Weapon_Bowgun";
	if not settings.elementSettings[eName].subPanels then
		settings.elementSettings   [eName].scale = 1;
		settings.elementSettings   [eName].subPanels = {
			_BowgunBulletPanel = {
				anchor = 0;
				posAdjustX = 0.075;
				posAdjustY = 0.115;
				posX = 0.0;
				posY = 0.0;
				scale = 1.0;
				useGlobalScale = true;
			},
			_BowgunSpecialPosPanel = {
				anchor = 8;
				posAdjustX = 1;
				posAdjustY = 0.3;
				posX = 0.0;
				posY = 0.0;
				scale = 1.0;
				useGlobalScale = true;
			},
			_BowgunBulletStatus = {
				anchor = 0;
				posAdjustX = 0;
				posAdjustY = 0;
				posX = 0.0;
				posY = 0.0;
				scale = 1.0;
				useGlobalScale = true;
			},
		};
	end

end