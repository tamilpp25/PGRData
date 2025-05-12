local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiScoreTowerTowerBattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiScoreTowerTowerBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiScoreTowerTowerBattleRoomRoleDetail")

---@param team XScoreTowerTowerTeam
function XUiScoreTowerTowerBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiScoreTowerTowerBattleRoomRoleDetail:GetEntities(characterType)
    return XMVCA.XScoreTower:GetTowerEntities(self.Team, characterType)
end

function XUiScoreTowerTowerBattleRoomRoleDetail:GetGridProxy()
    return require("XUi/XUiScoreTower/BattleRoom/XUiScoreTowerTowerRoleGrid")
end

function XUiScoreTowerTowerBattleRoomRoleDetail:GetRoleAbility(entityId)
    return XMVCA.XScoreTower:GetCharacterPower(entityId)
end

function XUiScoreTowerTowerBattleRoomRoleDetail:GetAutoCloseInfo()
    return true, XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end
end

function XUiScoreTowerTowerBattleRoomRoleDetail:GetFilterControllerConfig()
    return XMVCA.XCharacter:GetModelCharacterFilterController()["UiScoreTowerTowerBattleRoomRoleDetail"]
end

function XUiScoreTowerTowerBattleRoomRoleDetail:GetFilterSortOverrideFunTable()
    return XMVCA.XScoreTower:GetTowerCharacterFilterSort(self.Team:GetTowerId())
end

return XUiScoreTowerTowerBattleRoomRoleDetail
