
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
    --更新队伍表现
    local stage = XDataCenter.PivotCombatManager.GetStage(self.StageId)
    --非中心关卡，角色如果被锁定，则更新队伍信息
    if stage and not stage:CheckIsScoreStage() then
        --锁定角色字典
        local characterIdDic = XDataCenter.PivotCombatManager.GetLockCharacterDict()
        for idx = 1, MAX_ROLE_COUNT do
            local entityId = rootUi.Team:GetEntityIdByTeamPos(idx)
            if XTool.IsNumberValid(entityId) then
                local entity = self.Super.GetCharacterViewModelByEntityId(self, entityId)
                local id = entity and entity:GetId() or 0
                if characterIdDic[id] then
                    rootUi.Team:UpdateEntityTeamPos(entityId, idx, false)
                end
            end
        end
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
    
    local stage = XDataCenter.PivotCombatManager.GetStage(stageId)
    --非中心关卡校验锁角色是否被锁定
    if stage and not stage:CheckIsScoreStage() then
        local entityIds = team:GetEntityIds()
        local characterIdDic = XDataCenter.PivotCombatManager.GetLockCharacterDict()
        for _, entityId in ipairs(entityIds) do
            if XTool.IsNumberValid(entityId) then
                local entity = self.Super.GetCharacterViewModelByEntityId(self, entityId)
                local id = entity and entity:GetId() or 0
                --有角色被锁定，不允许进战斗
                if characterIdDic[id] then
                    XUiManager.TipError(XUiHelper.GetText("PivotCombatTeamLockTips"))
                    return
                end
            end
        end
    end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local teamId = team:GetId()
    XDataCenter.FubenManager.EnterFight(stageCfg, teamId, isAssist, challengeCount)
end





return XUiPivotCombatBattleRoleRoom