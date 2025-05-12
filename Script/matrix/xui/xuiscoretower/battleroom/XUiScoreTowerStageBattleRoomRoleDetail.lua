local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiScoreTowerStageBattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiScoreTowerStageBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiScoreTowerStageBattleRoomRoleDetail")

---@param team XScoreTowerStageTeam
function XUiScoreTowerStageBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
    -- 用于存储当前关卡的角色信息
    self.CharacterInfoList = XMVCA.XScoreTower:GetStageShowCharacterInfoList(self.Team)
end

function XUiScoreTowerStageBattleRoomRoleDetail:GetEntities(characterType)
    return XMVCA.XScoreTower:GetStageEntities(self.Team)
end

function XUiScoreTowerStageBattleRoomRoleDetail:GetGridProxy()
    return require("XUi/XUiScoreTower/BattleRoom/XUiScoreTowerStageRoleGrid")
end

function XUiScoreTowerStageBattleRoomRoleDetail:GetRoleAbility(entityId)
    return XMVCA.XScoreTower:GetCharacterPower(entityId)
end

function XUiScoreTowerStageBattleRoomRoleDetail:GetGridExParams()
    return {
        function(entityId)
            return self:GetStageShowCharacterInfo(entityId)
        end
    }
end

function XUiScoreTowerStageBattleRoomRoleDetail:GetAutoCloseInfo()
    return true, XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end
end

function XUiScoreTowerStageBattleRoomRoleDetail:CheckCustomLimit(entityId)
    local info = self:GetStageShowCharacterInfo(entityId)
    if not info then
        return true
    end
    if info.IsUsed then
        XUiManager.TipMsg(XMVCA.XScoreTower:GetClientConfig("StageTeamRelatedTips", 3))
        return true
    end
    return false
end

function XUiScoreTowerStageBattleRoomRoleDetail:GetFilterControllerConfig()
    return XMVCA.XCharacter:GetModelCharacterFilterController()["UiScoreTowerStageBattleRoomRoleDetail"]
end

function XUiScoreTowerStageBattleRoomRoleDetail:GetFilterSortOverrideFunTable()
    return XMVCA.XScoreTower:GetStageCharacterFilterSort(self.Team:GetStageCfgId())
end

---@return { Id:number, Pos:number, IsUsed:boolean, IsNow:boolean, StageId:number }
function XUiScoreTowerStageBattleRoomRoleDetail:GetStageShowCharacterInfo(entityId)
    if XTool.IsTableEmpty(self.CharacterInfoList) or not XTool.IsNumberValid(entityId) then
        return nil
    end
    for _, info in pairs(self.CharacterInfoList) do
        if info.Id == entityId then
            return info
        end
    end
    return nil
end

return XUiScoreTowerStageBattleRoomRoleDetail
