local XUiAnniversaryMain = XLuaUiManager.Register(XLuaUi, 'UiAnniversaryMain')

--region 生命周期
function XUiAnniversaryMain:OnAwake()
    self.BtnSignin.CallBack = handler(self, self.OnSignInClickEvent)
    self.BtnResearch.CallBack = handler(self, self.OnResearchClickEvent)
    self.BtnFourteenDay.CallBack = handler(self, self.OnFourteenDayClickEvent)
    self.BtnMemory.CallBack = handler(self, self.OnMemoryClickEvent)
    self.Btn1stRecharge.CallBack = handler(self, self.On1stRechargeClickEvent)
    self.BtnReview.CallBack = handler(self, self.OnReviewClickEvent)
    self.BtnRecall.CallBack = handler(self, self.OnReCallClickEvent)
    self.BtnBasicDraw.CallBack = handler(self, self.OnBasicDrawClickEvent)
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnAnniversaryClose.CallBack = handler(self, self.Close)
end

function XUiAnniversaryMain:OnStart()
    self:RefreshBtnState()

    self.ResearchRedPointId = self:AddRedPointEvent(self.BtnResearch, self.ResearchRedPointEvent, self, { XRedPointConditions.Types.CONDITION_ANNIVERSARY_DRAW })
    self.FourteenDayRedPointId = self:AddRedPointEvent(self.BtnFourteenDay, self.FourteenDayRedPointEvent, self, { XRedPointConditions.Types.CONDITION_SUMMER_SIGNIN_ACTIVITY })
    self.MemoryRedPointId = self:AddRedPointEvent(self.BtnMemory, self.MemoryRedPointEvent, self, { XRedPointConditions.Types.CONDITION_ANNIVERSARY_REPEATCHALLENGE })
end

function XUiAnniversaryMain:OnEnable()
    XRedPointManager.Check(self.ResearchRedPointId)
    XRedPointManager.Check(self.FourteenDayRedPointId)
    XRedPointManager.Check(self.MemoryRedPointId)
end
--endregion

--region 界面更新
function XUiAnniversaryMain:RefreshBtnState()
    local signinOpen, signindesc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.SignIn)
    local researchOpen, researchdesc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.AnniversaryDraw)
    local fourteenDay, fourteendesc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.DayDraw)
    local memory, memorydesc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.RepeatChallenge)
    local reviewOpen, reviewdesc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.Review)
    if reviewOpen then
        --如果配置判定开启了，则保底判定一次服务端下发的活动数据是否开启
        reviewOpen, reviewdesc = XMVCA.XAnniversary:CheckHasActivityInTime()
    end
    local rechargeOpen, rechargedesc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.FirstRecharge)
    local reCallOpen, reCalldesc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.ReCall)
    local basicDrawOpen, basicDrawdesc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.BasicDraw)
    
    self.signinOpen = signinOpen
    self.researchOpen = researchOpen
    self.fourteenDay = fourteenDay
    self.memoryOpen = memory
    self.reviewOpen = reviewOpen
    self.rechargeOpen = rechargeOpen
    self.reCallOpen = reCallOpen
    self.basicDrawOpen = basicDrawOpen
    
    self.BtnSignin:SetButtonState(signinOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnResearch:SetButtonState(researchOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnFourteenDay:SetButtonState(fourteenDay and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnMemory:SetButtonState(memory and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnReview:SetButtonState(reviewOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.Btn1stRecharge:SetButtonState(rechargeOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnRecall:SetButtonState(reCallOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnBasicDraw:SetButtonState(basicDrawOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    
    if not signinOpen then
        self.BtnSignin:SetNameByGroup(0, signindesc)
    end
    if not researchOpen then
        self.BtnResearch:SetNameByGroup(0, researchdesc)
    end
    if not fourteenDay then
        self.BtnFourteenDay:SetNameByGroup(0, fourteendesc)
    end
    if not memory then
        self.BtnMemory:SetNameByGroup(0, memorydesc)
    end
    if not reviewOpen then
        self.BtnReview:SetNameByGroup(0, reviewdesc)
    end
    if not rechargeOpen then
        self.Btn1stRecharge:SetNameByGroup(0, rechargedesc)
    end
    if not reCallOpen then
        self.BtnRecall:SetNameByGroup(0, reCalldesc)
    end
    if not basicDrawOpen then
        self.BtnBasicDraw:SetNameByGroup(0, basicDrawdesc)
    end
end

--endregion

--region 事件
function XUiAnniversaryMain:OnSignInClickEvent()
    --打开签到界面
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.SignIn)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.SignIn)
    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnResearchClickEvent()
    --跳转到角色抽卡界面
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.AnniversaryDraw)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.AnniversaryDraw)

    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnFourteenDayClickEvent()
    --跳转到每日一抽
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.DayDraw)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.DayDraw)

    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnMemoryClickEvent()
    --跳转到复刷关
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.RepeatChallenge)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.RepeatChallenge)

    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:On1stRechargeClickEvent()
    --首冲
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.FirstRecharge)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.FirstRecharge)

    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnReviewClickEvent()
    --跳转到周年回顾
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.Review)
    if isOpen then
        --如果配置判定开启了，则保底判定一次服务端下发的活动数据是否开启
        isOpen, desc = XMVCA.XAnniversary:CheckHasActivityInTime()
    end
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.Review)
    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnReCallClickEvent()
    -- 召回活动
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.ReCall)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.ReCall)
    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnBasicDrawClickEvent()
    -- 基准卡池
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.BasicDraw)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.BasicDraw)
    else
        XUiManager.TipMsg(desc)
    end
end

--endregion

--region 红点

function XUiAnniversaryMain:MemoryRedPointEvent(count)
    self.BtnMemory:ShowReddot(count >= 0 and self.memoryOpen)
end

function XUiAnniversaryMain:FourteenDayRedPointEvent(count)
    self.BtnFourteenDay:ShowReddot(count >= 0 and self.fourteenDay)
end

function XUiAnniversaryMain:ResearchRedPointEvent(count)
    self.BtnResearch:ShowReddot(count >= 0 and self.researchOpen)

end
--endregion

 

return XUiAnniversaryMain