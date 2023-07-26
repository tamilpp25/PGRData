local XUiGridPartnerTeachingBanner = XClass(nil, "XUiGridPartnerTeachingBanner")

function XUiGridPartnerTeachingBanner:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
end

function XUiGridPartnerTeachingBanner:Refresh(chapterId)
    self.ChapterId = chapterId

    -- 图标
    self.RImgBg:SetRawImage(XPartnerTeachingConfigs.GetChapterBannerIcon(chapterId))

    -- 名称
    self.TxtName.text = XPartnerTeachingConfigs.GetChapterName(chapterId)

    -- 关卡进度
    local progressRateTip = CS.XTextManager.GetText("PartnerTeachingProgressRate")
    local passNum, totalNum = XDataCenter.PartnerTeachingManager.GetChapterProgress(chapterId)
    self.TxtProgressRate.text = string.format(progressRateTip, tostring(passNum), tostring(totalNum))

    -- 活动标签
    local whetherInActivity = XDataCenter.PartnerTeachingManager.WhetherInActivity(chapterId)
    self.PanelActivityTag.gameObject:SetActiveEx(whetherInActivity)

    -- 活动剩余时间
    self.PanelLeftTime.gameObject:SetActiveEx(whetherInActivity)
    if whetherInActivity then
        self:RefreshTimer()
    end

    -- 解锁状态
    self.IsUnlock, self.LockTip = XDataCenter.PartnerTeachingManager.WhetherUnLockChapter(chapterId)
    if self.IsUnlock then
        self.ImgLock.gameObject:SetActiveEx(false)
    else
        self.ImgLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = self.LockTip
    end
end

---
--- 刷新注册的计时器函数
function XUiGridPartnerTeachingBanner:RefreshTimer()
    local leftTime = XDataCenter.PartnerTeachingManager.GetLeftTimeStamp(self.ChapterId)

    -- 刷新剩余时间
    local func = function()
        leftTime = leftTime > 0 and leftTime or 0

        local dataTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        if self.TextLeftTime then
            local leftTimeTip = CS.XTextManager.GetText("PartnerTeachingActivityLeftTime")
            self.TextLeftTime.text = string.format(leftTimeTip, dataTime)
        end

        if leftTime <= 0 then
            self:RemoveTimer()
            self:Refresh(self.ChapterId)
        end
    end

    func()
    self.Parent:RegisterTimerFun(self.ChapterId, function()
        leftTime = leftTime - 1
        func()
    end)
end

---
--- 格子回收时移除计时器函数
function XUiGridPartnerTeachingBanner:OnRecycle()
    self:RemoveTimer()
end

---
--- 移除计时器函数
function XUiGridPartnerTeachingBanner:RemoveTimer()
    self.Parent:RemoveTimerFun(self.ChapterId)
end

function XUiGridPartnerTeachingBanner:OnClick()
    if self.IsUnlock then
        XLuaUiManager.Open("UiPartnerTeachingChapter", self.ChapterId)
    else
        XUiManager.TipMsg(self.LockTip)
    end
end

return XUiGridPartnerTeachingBanner