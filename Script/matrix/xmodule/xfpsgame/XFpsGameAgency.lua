local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XFpsGameAgency : XFubenActivityAgency
---@field private _Model XFpsGameModel
local XFpsGameAgency = XClass(XFubenActivityAgency, "XFpsGameAgency")

function XFpsGameAgency:OnInit()
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.FpsGame)
end

function XFpsGameAgency:InitRpc()
    XRpc.NotifyFpsGameData = handler(self, self.NotifyFpsGameData)
end

function XFpsGameAgency:InitEvent()

end

function XFpsGameAgency:NotifyFpsGameData(data)
    self._Model:NotifyFpsGameData(data.FpsGameDataDb)
end

---检查是否处于活动的游戏时间
function XFpsGameAgency:CheckActivityIsInGameTime()
    if not self:GetIsOpen(true) then
        return false
    end
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

---获取关卡结束时间
function XFpsGameAgency:GetActivityGameEndTime()
    if not self:GetIsOpen(true) then
        return 0
    end
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

---活动是否开启
function XFpsGameAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FpsGame, false, noTips) then
        return false
    end
    if not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

function XFpsGameAgency:GetWeaponById(id)
    return self._Model:GetWeaponById(id)
end

function XFpsGameAgency:CheckStageStar(stageId, star)
    if self._Model:IsStagePass(stageId) then
        -- 配成0星视为首通解锁
        if star == 0 then
            return true
        end
        if self._Model:GetStageStar(stageId) >= star then
            return true
        end
    end
    return false
end

---有奖励可领取 or 没进去过挑战模式
function XFpsGameAgency:CheckActivityRedPoint()
    if self._Model:IsChapterRewardGain(XEnumConst.FpsGame.Story) then
        return true
    end
    if self._Model:CheckChapterOpen(XEnumConst.FpsGame.Challenge, false) then
        if self._Model:IsChapterRewardGain(XEnumConst.FpsGame.Challenge) or not XSaveTool.GetData("FpsGameHardReddot") then
            return true
        end
    end
    return false
end

--region 扩展

function XFpsGameAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return
    end
    
    if not XMVCA.XSubPackage:CheckSubpackageByIdAndIntercept(XEnumConst.SUBPACKAGE.TEMP_VIDEO_SUBPACKAGE_ID.GAMEPLAY) then
        return
    end

    -- 打开主界面
    XLuaUiManager.Open("UiFpsGameMain")
end

function XFpsGameAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XFpsGameAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.FpsGame
end

function XFpsGameAgency:ExGetProgressTip()
    -- 游戏时间结束，不显示进度
    if not self:CheckActivityIsInGameTime() then
        return ""
    end
    if not self._Model:IsStoryPass() then
        local cur, all = self._Model:GetProgress(XEnumConst.FpsGame.Story)
        local progress = math.floor(cur / all * 100)
        return XUiHelper.GetText("FpsGameStoryProgress", math.min(progress, 100))
    elseif not self._Model:IsChallengePass() then
        local cur, all = self._Model:GetProgress(XEnumConst.FpsGame.Challenge)
        local progress = math.floor(cur / all * 100)
        return XUiHelper.GetText("FpsGameChallengeProgress", math.min(progress, 100))
    else
        return XUiHelper.GetText("FpsGameProgressEnd")
    end
end

function XFpsGameAgency:ExGetRunningTimeStr()
    if not self:GetIsOpen(true) then
        return ""
    end
    local isInGameTime = self:CheckActivityIsInGameTime()
    if isInGameTime then
        local gameEndTime = self:GetActivityGameEndTime()
        local gameTime = gameEndTime - XTime.GetServerNowTimestamp()
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        return XUiHelper.GetText("FpsGameResetTime", timeStr)
    else
        return XUiHelper.GetText("FpsGameActivityEnd")
    end
end

--endregion

--region 副本

function XFpsGameAgency:PreFight(stage, teamId, isAssist, challengeCount)
    local preFight = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = 1
    preFight.FirstFightPos = 1
    preFight.SelectFpsWeapons = self._Model:GetBattleWeapon()
    preFight.SelectFpsAssist = self._Model:GetBattleCharacterId()
    return preFight
end

function XFpsGameAgency:ShowReward()
    -- nothing
    -- 不走通用结算
end

function XFpsGameAgency:FinishFight(settleData)
    local stageId = settleData.StageId
    local stageType = XDataCenter.FubenManager.GetStageType(stageId)
    if stageType ~= XEnumConst.FuBen.StageType.FpsGame then
        return
    end
    if settleData.IsWin then
        local stage = XDataCenter.FubenManager.GetStageCfg(settleData.StageId)
        local chapterId = self._Model:GetStageById(stageId).ChapterId
        local endStoryId = XMVCA.XFuben:GetEndStoryId(settleData.StageId)
        local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and endStoryId
        local beginData = XDataCenter.FubenManager.GetFightBeginData()
        local isNotPass = stage and endStoryId and not beginData.LastPassed

        if isKeepPlayingStory or isNotPass then
            -- 播放剧情
            CsXUiManager.Instance:SetRevertAndReleaseLock(true)
            XDataCenter.MovieManager.PlayMovie(endStoryId, function()
                -- 弹出结算
                CsXUiManager.Instance:SetRevertAndReleaseLock(false)
                -- 防止带着bgm离开战斗
                XLuaAudioManager.StopCurrentBGM()
                self:ShowWinSettle(chapterId, stageId, settleData)
            end)
        else
            -- 弹出结算
            self:ShowWinSettle(chapterId, stageId, settleData)
        end
    else
        XLuaUiManager.Open("UiSettleLose", settleData)
    end
end

function XFpsGameAgency:ShowWinSettle(chapterId, stageId, settleData)
    if chapterId == XEnumConst.FpsGame.Challenge then
        XLuaUiManager.Open("UiFpsGameSettlement", settleData)
    else
        XLuaUiManager.Open("UiFpsGameStorySettlement")
    end
    -- 结算界面的奖励要显示是否已领取 所以最新的通关记录要在后面刷新
    local addStars = self._Model:GetStarsCount(settleData.StarsMark)
    self._Model:AddFinishStage(stageId)
    self._Model:UpdateStageStar(stageId, addStars)
    self._Model:UpdateStageScore(stageId, settleData.FpsGameSettleResult.Score)
end

--endregion

return XFpsGameAgency