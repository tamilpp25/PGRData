---@class XUiLuckyTenantMainStageGrid : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantMainStageGrid = XClass(XUiNode, "XUiLuckyTenantMainStageGrid")

function XUiLuckyTenantMainStageGrid:OnStart()
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnGiveUp, self.GiveUp, nil, true)
    self._Timer = false
end

function XUiLuckyTenantMainStageGrid:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiLuckyTenantMainStageGrid:UpdateRemainTime()
    local data = self._Data
    if data.IsCanChallenge then
        self.BtnChapter:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnChapter:SetButtonState(CS.UiButtonState.Disable)
        local currentTime = XTime.GetServerNowTimestamp()
        local remainTime = XFunctionManager.GetStartTimeByTimeId(self._Data.TimeId) - currentTime
        if remainTime >= 0 then
            local timeStr = XUiHelper.GetTime(math.max(remainTime, 1), XUiHelper.TimeFormatType.ACTIVITY)
            self.TxtTips.text = XUiHelper.GetText("LuckyTenantUnlockAfterTime", timeStr)
            if not self._Timer then
                self._Timer = XScheduleManager.ScheduleForever(function()
                    self:UpdateRemainTime()
                end, 1000)
            end
            return
        end
        if not data.IsPreStagePass then
            self.TxtTips.text = XUiHelper.GetText("LuckyTenantPreStageNotClear")
        end
    end
    if self._Timer then
        self._Control:UpdateStageList()
        local stages = self._Control:GetUiData().Stages
        local newData
        for i = 1, #stages do
            if stages[i].Id == self._Data.Id then
                newData = stages[i]
            end
        end
        if newData and newData.IsCanChallenge then
            XScheduleManager.UnSchedule(self._Timer)
            self._Timer = false
            self:Update(newData)
        end
    end
end

---@param data XUiLuckyTenantMainStageGridData
function XUiLuckyTenantMainStageGrid:Update(data)
    self._Data = data
    self.RImgBgNormal.gameObject:SetActiveEx(not data.IsSelected)
    self.CommonFuBenClear.gameObject:SetActiveEx(data.IsNormalClear)
    self:UpdateRemainTime()
    if self.RawImage then
        self.RawImage:SetRawImage(data.CoverImage)
    end
    self.TagOngoing.gameObject:SetActiveEx(data.IsPlaying)
    self.TxtScore.text = data.BesScore
    if self.RedPoint then
        self.RedPoint.gameObject:SetActiveEx(false)
    end
    self.RImgBgPress.gameObject:SetActiveEx(data.IsSelected)
    self.TxtTitle.text = data.Name
    self.TxtSchedule.text = data.BestRound
    --self.Max.gameObject:SetActiveEx(data.IsPerfectClear)
    if data.IsPlaying then
        self.TxtScheduleNow.text = data.PlayingRound
    end
    self.BtnGiveUp.gameObject:SetActiveEx(data.IsPlaying)
    self.TagNew.gameObject:SetActiveEx(data.IsNew)
end

function XUiLuckyTenantMainStageGrid:OnClick()
    if self._Data.IsOtherStagePlaying then
        XUiManager.TipText("LuckyTenantOtherStageIsPlaying")
        return
    end
    if self._Data.IsCanChallenge then
        XLuaUiManager.Open("UiLuckyTenantMainDetail", self._Data.Id)
    else
        if not self._Data.IsOnTime then
            local currentTime = XTime.GetServerNowTimestamp()
            local remainTime = XFunctionManager.GetStartTimeByTimeId(self._Data.TimeId) - currentTime
            if remainTime > 0 then
                local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
                XUiManager.TipMsg(XUiHelper.GetText("LuckyTenantUnlockAfterTime", timeStr))
            else
                if XFunctionManager.CheckInTimeByTimeId(self._Data.TimeId) then
                    XLog.Error("[XUiLuckyTenantMainStageGrid] 应该解锁了, 没刷新嘛??")
                    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_UPDATE_STAGE)
                end
            end
        else
            XUiManager.TipMsg(XUiHelper.GetText("FubenPreStageNotPass"))
        end
    end
end

function XUiLuckyTenantMainStageGrid:GiveUp()
    self._Control:GiveUpPlayingRecord(self._Data)
end

return XUiLuckyTenantMainStageGrid