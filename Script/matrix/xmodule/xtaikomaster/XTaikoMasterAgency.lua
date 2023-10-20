local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XTaikoMasterAgency : XFubenActivityAgency
---@field private _Model XTaikoMasterModel
local XTaikoMasterAgency = XClass(XFubenActivityAgency, "XTaikoMasterAgency")
function XTaikoMasterAgency:OnInit()
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.TaikoMaster)
end

function XTaikoMasterAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyTaikoMasterData = handler(self, self.NotifyTaikoMasterData)
end

function XTaikoMasterAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------
--region Checker
function XTaikoMasterAgency:CheckIsFunctionOpen(isTip)
    return self._Model:CheckIsFunctionOpen(isTip)
end

function XTaikoMasterAgency:CheckIsActivityOpen()
    return self._Model:CheckIsActivityOpen()
end

function XTaikoMasterAgency:CheckCdUnlockRedPoint(songId)
    return self._Model:CheckCdUnlockRedPoint(songId)
end
--endregion

--region Fuben
---@param stage XTableStage
function XTaikoMasterAgency:PreFight(stage, teamId, isAssist, challengeCount)
    local preFight = {}
    preFight.RobotIds = self._Model:GetTeam():GetEntityIds()
    preFight.CardIds = { 0,0,0,0 }
    preFight.CaptainPos = self._Model:GetTeam():GetCaptainPos()
    preFight.FirstFightPos = self._Model:GetTeam():GetFirstFightPos()
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist
    preFight.ChallengeCount = challengeCount
    return preFight
end

function XTaikoMasterAgency:CallFinishFight()
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local res = fubenAgency:GetFubenSettleResult()
    if res then
        fubenAgency:CallFinishFight()
    else
        local beginData = fubenAgency:GetFightBeginData()
        local stageId = beginData.StageId
        self._Model:SetJustPassedStageId(stageId)
        fubenAgency:CallFinishFight()
    end
end

--战斗结束
function XTaikoMasterAgency:FinishFight(settle)
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    if settle.IsWin then
        fubenAgency:ChallengeWin(settle)
    else
        self._Model:SetJustPassedStageId(settle.StageId)
        fubenAgency:ChallengeLose(settle)
    end
end

function XTaikoMasterAgency:ShowReward(winData)
    local stageId = winData.StageId
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local historyScore, isPassed = self._Model:GetMyScore(stageId)
    self._Model:HandleWinData(stageId, winData.SettleData.TaikoMasterSettleResult)
    -- 教学关和训练关没有结算信息
    if XTool.IsTableEmpty(winData.SettleData.TaikoMasterSettleResult) then
        self._Model:SetJustPassedStageId(stageId)
        fubenAgency:ShowReward(winData)
    else
        XLuaUiManager.Open("UiTaikoMasterSettlement", winData, isPassed and historyScore, self._Model:GetMyScore(stageId))
    end
end

function XTaikoMasterAgency:OpenBattleRoom(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end
    XLuaUiManager.PopThenOpen("UiTaikoMasterBattleRoom", stageId)
end
--endregion

--region FubenEx
function XTaikoMasterAgency:ExOpenMainUi()
    if not self:CheckIsFunctionOpen(true) then
        return
    end
    if not self:CheckIsActivityOpen() then
        XUiManager.TipText("FestivalActivityNotInActivityTime")
        return
    end
    XLuaUiManager.Open("UiTaikoMasterMain")
end

function XTaikoMasterAgency:ExCheckInTime()
    -- 保持FubenActivity表TimeId清空功能有效
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    return self:CheckIsActivityOpen()
end

function XTaikoMasterAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    return self.ExConfig
end

function XTaikoMasterAgency:ExGetProgressTip()
    local finishCount = self._Model:GetFinishSongCount()
    local songCount = #self._Model:GetSongList()
    return XUiHelper.GetText("StrongholdActivityProgress", finishCount, songCount)
end

function XTaikoMasterAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.TaikoMaster
end
--endregion

--region Data
function XTaikoMasterAgency:GetTeam()
    return self._Model:GetTeam()
end

---@return XTaikoMasterUiData
function XTaikoMasterAgency:GetTaskData()
    return self._Model:GetTaskUiData()
end

function XTaikoMasterAgency:GetActivityStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self._Model:GetActivityTimeId()) or 0
end

function XTaikoMasterAgency:GetActivityEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self._Model:GetActivityTimeId()) or 0
end

function XTaikoMasterAgency:GetActivityChapters()
    local chapters = {}
    if not self:CheckIsActivityOpen() then
        return chapters
    end
    local temp = {}
    local activityId = self._Model._ActivityData:GetActivityId()
    local cfg = self._Model:GetActivityCfg(activityId)
    temp.Id = activityId
    temp.Name = cfg.Name
    temp.BannerBg = cfg.BannerBg
    temp.Type = self:ExGetChapterType()
    table.insert(chapters, temp)
    return chapters
end
--endregion
----------public end----------

----------private start----------
--region Rpc
function XTaikoMasterAgency:NotifyTaikoMasterData(data)
    self._Model:NotifyTaikoMasterData(data.TaikoMasterData)
end
--endregion
----------private end----------

return XTaikoMasterAgency