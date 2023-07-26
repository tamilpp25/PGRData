--######################## XUiReformChildPanel ########################
local XUiReformChildPanel = XClass(nil, "XUiReformChildPanel")

function XUiReformChildPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.ReformActivityManager = XDataCenter.ReformActivityManager
    self.EvolableStage = nil
end

function XUiReformChildPanel:SetData(stageId, team, rootUi)
    local baseStage = self.ReformActivityManager.GetBaseStage(stageId)
    local evolableStage = baseStage:GetCurrentEvolvableStage()
    self.EvolableStage = evolableStage
    local lastScore = evolableStage.__UiLastAnimScore or 0
    -- 当前分数
    local nextScore = evolableStage:GetChallengeScore(true)
    local diffValue = nextScore - lastScore
    local duration = math.min(math.abs( diffValue ) / 5, 1)
    XUiHelper.Tween(duration, function(t)
        if XTool.UObjIsNil(self.TxtTotalScore) then
            return
        end
        self.TxtTotalScore.text = math.floor(lastScore + diffValue * t)
    end, function()
        evolableStage.__UiLastAnimScore = nextScore
        if XTool.UObjIsNil(self.TxtTotalScore) then
            return
        end
        self.TxtTotalScore.text = nextScore
    end, function(t)
        return -t * t + 2 * t
    end)
    -- 推荐分数
    local recommendScore = baseStage:GetRecommendScore()
    self.TxtRecommendScore.text = XUiHelper.GetText("ReformRecommendScoreTip2"
        , recommendScore)
    self.TxtRecommendScore.gameObject:SetActiveEx(nextScore < recommendScore)
    self.TxtMaxScoreTip.text = XUiHelper.GetText("ReformMaxScoreTip"
        , evolableStage:GetMaxChallengeScore(true))
    local entityId
    for i = 1, 3 do
        entityId = team:GetEntityIdByTeamPos(i)
        self["BtnChar" .. i].gameObject:SetActiveEx(entityId > 0)
        if entityId > 0 then
            self["TxtCharScore" .. i].text = evolableStage:GetTeamRoleScore(
                rootUi:GetCharacterViewModelByEntityId(entityId):GetId())
        end
    end
end

function XUiReformChildPanel:OnDestroy()
    self.EvolableStage.__UiLastAnimScore = 0
end

--######################## XUiReformBattleRoleRoom ########################
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
        reuslt = XDataCenter.CharacterManager.GetCharacter(entityId)
        if reuslt then reuslt = reuslt:GetCharacterViewModel() end
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

-- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
--[[
    return : {
        assetPath : 资源路径
        proxy : 子面板代理
        proxyArgs : 子面板SetData传入的参数列表
    }
]]
function XUiReformBattleRoleRoom:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("PanelReformBattleRoom"),
        proxy = XUiReformChildPanel,
        proxyArgs = { "StageId", "Team", self }
    }
end

return XUiReformBattleRoleRoom