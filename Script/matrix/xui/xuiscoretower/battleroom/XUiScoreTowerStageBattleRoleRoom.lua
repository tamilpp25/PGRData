local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiScoreTowerStageBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiScoreTowerStageBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiScoreTowerStageBattleRoleRoom")

---@param team XScoreTowerStageTeam
function XUiScoreTowerStageBattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

function XUiScoreTowerStageBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiScoreTower/BattleRoom/XUiScoreTowerStageBattleRoomRoleDetail")
end

function XUiScoreTowerStageBattleRoleRoom:GetRoleAbility(entityId)
    return XMVCA.XScoreTower:GetCharacterPower(entityId)
end

---@param team XScoreTowerStageTeam
function XUiScoreTowerStageBattleRoleRoom:GetIsCanEnterFight(team, stageId)
    local isSuccess, errorDesc = self.Super.GetIsCanEnterFight(self, team, stageId)
    if not isSuccess then
        return isSuccess, errorDesc
    end
    -- 检查是否可以进入战斗
    if not self.Team:GetIsFullMember() then
        local limit = self.Team:GetCurrentEntityLimit()
        return false, XUiHelper.FormatText(XMVCA.XScoreTower:GetClientConfig("StageTeamRoleNumberLimitDesc"), limit)
    end
    return true
end

---@param team XScoreTowerStageTeam
function XUiScoreTowerStageBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    XMVCA.XScoreTower:EnterFight(stageId, team, isAssist, challengeCount)
end

function XUiScoreTowerStageBattleRoleRoom:GetAutoCloseInfo()
    return true, XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end
end

-- 获取编队界面左下角提示信息，可追加自身玩法的信息
-- return : { "提示1", ... }
function XUiScoreTowerStageBattleRoleRoom:GetTipDescs()
    local limit = self.Team:GetCurrentEntityLimit()
    local desc = XMVCA.XScoreTower:GetClientConfig("StageTeamRoleNumberLimitDesc")
    return { XUiHelper.FormatText(desc, limit) }
end

function XUiScoreTowerStageBattleRoleRoom:AOPOnCharacterClickBefore(rootUi, index)
    return XMVCA.XScoreTower:OnCharacterClickBefore(self.Team, index)
end

---@param rootUi XUiBattleRoleRoom
function XUiScoreTowerStageBattleRoleRoom:AOPOnStartAfter(rootUi)
    -- 隐藏队伍预设按钮
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiScoreTowerStageBattleRoleRoom:CheckShowAnimationSet()
    return false
end

return XUiScoreTowerStageBattleRoleRoom
