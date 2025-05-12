local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XMaverick3Agency : XFubenActivityAgency
---@field private _Model XMaverick3Model
local XMaverick3Agency = XClass(XFubenActivityAgency, "XMaverick3Agency")

function XMaverick3Agency:OnInit()
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.Maverick3)
end

function XMaverick3Agency:InitRpc()
    XRpc.NotifyMaverick3Data = handler(self, self.NotifyMaverick3Data)
end

function XMaverick3Agency:InitEvent()

end

function XMaverick3Agency:NotifyMaverick3Data(data)
    self._Model:NotifyMaverick3Data(data.Maverick3Data)
end

function XMaverick3Agency:IsTalentUnlock(id)
    return self._Model:IsTalentUnlock(id)
end

function XMaverick3Agency:CheckDifficultStar(difficult, star)
    local totalStar = 0
    local datas = self._Model:GetChapterConfigs()
    for _, data in pairs(datas) do
        if data.ChapterId == XEnumConst.Maverick3.ChapterType.MainLine and data.Difficult == difficult then
            local stages = self._Model:GetStagesByChapterId(data.ChapterId)
            for _, stage in pairs(stages) do
                totalStar = self._Model:GetStageStar(stage.StageId)
            end
        end
    end
    return totalStar >= star
end

---检查是否处于活动的游戏时间
function XMaverick3Agency:CheckActivityIsInGameTime()
    if not self:GetIsOpen(true) then
        return false
    end
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

---获取关卡结束时间
function XMaverick3Agency:GetActivityGameEndTime()
    if not self:GetIsOpen(true) then
        return 0
    end
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

---活动是否开启
function XMaverick3Agency:GetIsOpen(noTips, activityId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Maverick3, false, noTips) then
        return false
    end
    if XTool.IsNumberValid(activityId) then
        local activityCfg = self._Model:GetActivityById(activityId)
        if activityCfg then
            local startTime, endTime = XFunctionManager.GetTimeByTimeId(activityCfg.TimeId)
            local nowTime = XTime.GetServerNowTimestamp()
            if nowTime < startTime then
                if not noTips then
                    XUiManager.TipText("Maverick3TimeNotOpen")
                end
                return false
            elseif nowTime > endTime then
                if not noTips then
                    XUiManager.TipText("Maverick3TimeEnd")
                end
                return false
            end
        end
    else
        if not self:ExCheckInTime() then
            if not noTips then
                XUiManager.TipText("CommonActivityNotStart")
            end
            return false
        end
    end
    return true
end

function XMaverick3Agency:ExOpenMainUi(activityId)
    if not XMVCA.XSubPackage:CheckSubpackageByIdAndIntercept(XEnumConst.SUBPACKAGE.TEMP_VIDEO_SUBPACKAGE_ID.GAMEPLAY) then
        return
    end
    
    if not self:GetIsOpen(nil, activityId) then
        return
    end
    -- 打开主界面
    XLuaUiManager.Open("UiMaverick3Main", self._Model:GetParam())
end

function XMaverick3Agency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.Maverick3
end

function XMaverick3Agency:ExGetProgressTip()
    -- 游戏时间结束，不显示进度
    if not self:CheckActivityIsInGameTime() then
        return ""
    end
    local pass, total = 0, 0
    local datas = self._Model:GetChapterConfigs()
    for _, data in pairs(datas) do
        local stages = self._Model:GetStagesByChapterId(data.ChapterId)
        for _, stage in pairs(stages) do
            if self._Model:IsStageFinish(stage.StageId) then
                pass = pass + 1
            end
            total = total + 1
        end
    end
    return XUiHelper.GetText("Maverick3Progress", math.floor(pass / total * 100))
end

function XMaverick3Agency:ExGetRunningTimeStr()
    if not self:GetIsOpen(true) then
        return ""
    end
    local isInGameTime = self:CheckActivityIsInGameTime()
    if isInGameTime then
        local gameEndTime = self:GetActivityGameEndTime()
        local gameTime = gameEndTime - XTime.GetServerNowTimestamp()
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        return XUiHelper.GetText("Maverick3ResetTime", timeStr)
    else
        return XUiHelper.GetText("Maverick3ActivityEnd")
    end
end

function XMaverick3Agency:CheckActivityRedPoint()
    if not self:GetIsOpen(true) then
        return false
    end
    -- 重登时 可能协议还没下发
    if not self._Model.ActivityData then
        return false
    end
    -- 商店可购买
    if self._Model:IsShopRed() then
        return true
    end
    -- 奖励可领取
    if self._Model:IsDailyRewardCanGain() then
        return true
    end
    -- 章节开放
    if self._Model:IsMainLineNormalRed() or self._Model:IsMainLineHardRed() or self._Model:IsInfiniteRed() then
        return true
    end
    return false
end

function XMaverick3Agency:IsStageFinish(stageId)
    return self._Model:IsStageFinish(stageId)
end

--region 副本

function XMaverick3Agency:PreFight(stage, teamId, isAssist, challengeCount)
    local stageId = stage.StageId
    local preFight = {}
    preFight.StageId = stageId
    preFight.CaptainPos = 1
    preFight.FirstFightPos = 1
    preFight.Maverick3PreFightInfo = {}

    local robotId
    if not self._Model:IsStagePlaying(stageId) then
        -- 开始新战斗（继续战斗不用传下面这些 服务端有存档）
        local chapterId = self._Model:GetStageById(stageId).ChapterId
        if self._Model:GetChapterById(chapterId).Type == XEnumConst.Maverick3.ChapterType.Teach then
            -- 教学关锁定第一个角色、默认必杀、默认挂饰
            robotId = tonumber(self._Model:GetClientConfig("TeachStageRobotId"))
            preFight.Maverick3PreFightInfo.RobotId = 1
            preFight.Maverick3PreFightInfo.SelectUltimateSkill = tonumber(self._Model:GetClientConfig("DefaultSlayId"))
            preFight.Maverick3PreFightInfo.SelectHangings = tonumber(self._Model:GetClientConfig("DefaultOrnamentId"))
        else
            robotId = self._Model:GetFightIndex()
            local slayId = self._Model:GetSelectSlayId(robotId)
            if not self._Model:IsTalentUnlock(slayId) then
                slayId = tonumber(self._Model:GetClientConfig("DefaultSlayId"))
            end

            local ornamentsId = self._Model:GetSelectOrnamentsId(robotId)
            if not self._Model:IsTalentUnlock(ornamentsId) then
                ornamentsId = tonumber(self._Model:GetClientConfig("DefaultOrnamentId"))
            end

            preFight.Maverick3PreFightInfo.RobotId = robotId
            preFight.Maverick3PreFightInfo.SelectUltimateSkill = slayId
            preFight.Maverick3PreFightInfo.SelectHangings = ornamentsId
        end
    end

    self._Model:RecordTempFightCharId(stageId, robotId)

    return preFight
end

function XMaverick3Agency:ShowReward()
    -- nothing
    -- 不走通用结算
end

function XMaverick3Agency:FinishFight(settleData)
    local stageId = settleData.StageId
    local stageType = XDataCenter.FubenManager.GetStageType(stageId)
    if stageType ~= XEnumConst.FuBen.StageType.Maverick3 then
        return
    end
    if settleData.Maverick3SettleResult and settleData.Maverick3SettleResult.RobotSaved then
        self._Model.ActivityData:UpdateStageSave(settleData.StageId, settleData.Maverick3SettleResult.RobotSaved)
    end
    local stageConfig = self._Model:GetStageById(stageId)
    local chapterType = self._Model:GetChapterById(stageConfig.ChapterId).Type
    if chapterType == XEnumConst.Maverick3.ChapterType.MainLine then
        -- 主线模式
        if settleData.IsWin then
            self:PlayBattleEndStory(settleData, function()
                XLuaUiManager.Open("UiMaverick3Settlement", settleData)
            end)
        else
            XLuaUiManager.Open("UiSettleLose", settleData)
            -- 战斗失败需要打开关卡详情界面
            self._Model:SetNeedOpenChapterDetailId(stageId)
        end
    else
        -- 无尽模式
        if settleData.Maverick3SettleResult then
            -- 无论输赢都是战斗胜利
            XLuaUiManager.Open("UiMaverick3Settlement", settleData)
        else
            -- 主动撤退
            XLuaUiManager.Open("UiSettleLose", settleData)
        end
    end
end

function XMaverick3Agency:PlayBattleEndStory(settleData, callBack)
    local stage = XDataCenter.FubenManager.GetStageCfg(settleData.StageId)
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
            callBack()
        end)
    else
        -- 弹出结算
        callBack()
    end
end

function XMaverick3Agency:GetTempFightCharId()
    return self._Model:GetTempFightCharId()
end

---退出关卡重开（先发此协议再prefight）
function XMaverick3Agency:RequestMaverick3ExitStage(stageId, cb)
    local request = { StageId = stageId }
    XNetwork.CallWithAutoHandleErrorCode("Maverick3ExitStageRequest", request, function(res)
        self._Model.ActivityData:UpdateStageSave(stageId, nil)
        if cb then
            cb()
        end
    end)
end

--endregion

--region 配置

function XMaverick3Agency:GetStageById(id)
    return self._Model:GetStageById(id)
end

function XMaverick3Agency:GetChapterById(id)
    return self._Model:GetChapterById(id)
end

function XMaverick3Agency:GetRobotById(id)
    return self._Model:GetRobotById(id)
end

--endregion

return XMaverick3Agency