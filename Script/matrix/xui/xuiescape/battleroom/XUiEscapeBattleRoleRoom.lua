local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiEscapeBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiEscapeBattleRoleRoom")

function XUiEscapeBattleRoleRoom:Ctor(team, stageId)
    self.StageId = stageId
end

function XUiEscapeBattleRoleRoom:GetAutoCloseInfo()
    local callback = function(isClose)
        if isClose then
            XDataCenter.EscapeManager.HandleActivityEndTime()
        end
    end
    return true, XDataCenter.EscapeManager.GetActivityEndTime(), callback
end

function XUiEscapeBattleRoleRoom:GetChildPanelData()
    if self.ChildPanelData == nil then
        self.ChildPanelData = {
            assetPath = XUiConfigs.GetComponentUrl("UiPanelEscapeTeam"),
            proxy = require("XUi/XUiEscape/BattleRoom/XUiEscapeBattleRoomExpand"),
            proxyArgs = { "Team", "StageId" }
        }
    end
    return self.ChildPanelData
end

function XUiEscapeBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiEscape/BattleRoom/XUiEscapeBattleRoomRoleDetail")
end

return XUiEscapeBattleRoleRoom