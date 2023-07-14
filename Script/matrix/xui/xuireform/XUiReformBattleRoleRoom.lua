local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiReformBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiReformBattleRoleRoom")

-- team : XTeam
function XUiReformBattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
    self.ReformActivityManager = XDataCenter.ReformActivityManager
    self.BaseStage = self.ReformActivityManager.GetBaseStage(self.StageId)
    self.EvolableStage = self.BaseStage:GetCurrentEvolvableStage()
    self.MemberGroup = self.EvolableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
end

function XUiReformBattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiReformBattleRoleRoom:GetCharacterViewModelByEntityId(entityId)
    local source = self.MemberGroup:GetSourceById(entityId)
    local reuslt = nil
    if source then
        reuslt = source:GetCharacterViewModel()
    elseif entityId > 0 then
        reuslt = XDataCenter.CharacterManager.GetCharacter(entityId):GetCharacterViewModel()
    end
    return reuslt
end

function XUiReformBattleRoleRoom:GetPartnerByEntityId(entityId)
    local source = self.MemberGroup:GetSourceById(entityId)
    local reuslt = nil
    if source then
        reuslt = source:GetRobot():GetPartner()
    elseif entityId > 0 then
        reuslt = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(entityId)
    end
    return reuslt
end

function XUiReformBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiReform/XUiReformBattleRoomRoleDetail")
end

function XUiReformBattleRoleRoom:GetAutoCloseInfo()
    local endTime = self.ReformActivityManager.GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            self.ReformActivityManager.HandleActivityEndTime()
        end
    end
end

function XUiReformBattleRoleRoom:EnterFight(team, stageId)
    -- local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    -- local teamId = team:GetId()
    -- local isAssist = false
    -- local challengeCount = 1
    -- XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount)
    XLuaUiManager.Open("UiReformPreview2", team, stageId)
    XLuaUiManager.Remove("UiBattleRoleRoom")
end


return XUiReformBattleRoleRoom