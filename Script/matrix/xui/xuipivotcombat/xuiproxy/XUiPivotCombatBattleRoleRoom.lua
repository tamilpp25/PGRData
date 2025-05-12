
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiPivotCombatBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiPivotCombatBattleRoleRoom")

local MAX_ROLE_COUNT = 3 --最大队员数量

function XUiPivotCombatBattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end 


--选人界面的代理界面
function XUiPivotCombatBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiPivotCombat/XUiProxy/XUiPivotCombatBattleRoomRoleDetail")
end

function XUiPivotCombatBattleRoleRoom:AOPOnStartAfter(rootUi)
    for idx = 1, MAX_ROLE_COUNT do
        local entityId = rootUi.Team:GetEntityIdByTeamPos(idx)
        if not XTool.IsNumberValid(entityId) then
            goto continue
        end
        local entity = self.Super.GetCharacterViewModelByEntityId(self, entityId)
        local id = entity and entity:GetId() or 0
        local locked = XDataCenter.PivotCombatManager.CheckCharacterLocked(self.StageId, id)
        if locked then
            rootUi.Team:UpdateEntityTeamPos(entityId, idx, false)
        end
        
        ::continue::
    end
end

function XUiPivotCombatBattleRoleRoom:AOPOnEnableAfter(rootUi)
    --隐藏编辑队伍预设
    --rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiPivotCombatBattleRoleRoom:GetAutoCloseInfo()
    return true, XDataCenter.PivotCombatManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.PivotCombatManager.OnActivityEnd()
        end
    end
end

--重写进入战斗
function XUiPivotCombatBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    local entityIds = team:GetEntityIds()
    for _, entityId in ipairs(entityIds) do
        if not XTool.IsNumberValid(entityId) then
            goto continue
        end
        local entity = self.Super.GetCharacterViewModelByEntityId(self, entityId)
        local id = entity and entity:GetId() or 0
        local locked = XDataCenter.PivotCombatManager.CheckCharacterLocked(self.StageId, id)
        if locked then
            XUiManager.TipError(XUiHelper.GetText("PivotCombatTeamLockTips"))
            return
        end
        
        ::continue::
    end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local teamId = team:GetId()
    XDataCenter.FubenManager.EnterFight(stageCfg, teamId, isAssist, challengeCount)
end





return XUiPivotCombatBattleRoleRoom