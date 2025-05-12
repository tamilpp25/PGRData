local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiLinkCraftBattleRoleRoomLink = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityBattleRoleRoom/XUiPanelLinkCraftBattleRoleRoomLink')
local XUiLinkCraftActivityBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, 'XUiLinkCraftActivityBattleRoleRoom')

function XUiLinkCraftActivityBattleRoleRoom:AOPOnStartAfter(rootUi)
	if rootUi.BtnTeamPrefab then
    	rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
	end
end

function XUiLinkCraftActivityBattleRoleRoom:AOPOnEnableAfter(rootUi)
    self._PanelLink = XUiLinkCraftBattleRoleRoomLink.New(rootUi.BtnLink, rootUi)
    self._PanelLink:Open()
end

function XUiLinkCraftActivityBattleRoleRoom:GetRoleDetailProxy()
    return require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityBattleRoleRoom/XUiLinkCraftActivityBattleRoleRoomDetailProxy')
end

return XUiLinkCraftActivityBattleRoleRoom