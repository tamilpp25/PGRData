local XUiGridRes = XClass(nil, "XUiGridRes")

function XUiGridRes:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCancelSelect, self.OnBtnSelectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
    self.BtnClose.CallBack = function() self:OnBtnCancelBuyClick() end 
end

function XUiGridRes:Init(uiRoot, isChallengeMode, isPassed, stageInterId)
    self.UiRoot = uiRoot
    self.IsChallengeMode = isChallengeMode
    self.isPassed = isPassed
    self.StageInterId = stageInterId
end

function XUiGridRes:UpdateState()
    self.PanelSelect.gameObject:SetActiveEx(self.Data.IsSelect)
    self.PanelBuy.gameObject:SetActiveEx(self.Data.BuyMethod)
end

function XUiGridRes:Refresh(data)
    self.Id = data.Id
    self.Type = data.Type
    self.Data = data

    self.PanelMember.gameObject:SetActiveEx(self.Type == XFubenSimulatedCombatConfig.ResType.Member)
    self.PanelBuff.gameObject:SetActiveEx(self.Type == XFubenSimulatedCombatConfig.ResType.Addition)
    if self.Type == XFubenSimulatedCombatConfig.ResType.Member then
        self.ResInfo = XFubenSimulatedCombatConfig.GetMemberById(data.Id)
        self.RImgMember:SetRawImage(XRobotManager.GetRobotSmallHeadIcon(self.ResInfo.RobotId))
        self.TxtName.text = XCharacterConfigs.GetCharacterFullNameStr(XRobotManager.GetCharacterId(self.ResInfo.RobotId))
    elseif self.Type == XFubenSimulatedCombatConfig.ResType.Addition then
        self.ResInfo = XFubenSimulatedCombatConfig.GetAdditionById(data.Id)
        self.RImgBuff:SetRawImage(self.ResInfo.Icon)
        self.TxtName.text = self.ResInfo.Name
    end
    self.TxtStarNum.text = self.ResInfo.Star
    self:ShowPrice()
    self:UpdateState()
end

function XUiGridRes:ShowPrice()
    local price1 = XDataCenter.FubenSimulatedCombatManager.CheckCurrencyFree() and 0 or self.ResInfo.ConsumeCounts[1]
    self.TxtPrice1.text = price1
    if XDataCenter.FubenSimulatedCombatManager.GetCurrencyByNo(1) < price1 then
        self.TxtPrice1.color = XFubenSimulatedCombatConfig.Color.INSUFFICIENT
    else
        self.TxtPrice1.color = XFubenSimulatedCombatConfig.Color.NORMAL
    end
    
    self.RImgIcon1:SetRawImage(XDataCenter.FubenSimulatedCombatManager.GetCurrencyIcon(1))
    self.Consume2.gameObject:SetActiveEx(not self.IsChallengeMode)
    self.TxtBuyMethodSplit.gameObject:SetActiveEx(not self.IsChallengeMode)
    if not self.IsChallengeMode then
        local price2 = self.isPassed and 0 or self.ResInfo.ConsumeCounts[2]
        self.TxtPrice2.text = price2
        self.RImgIcon2:SetRawImage(XDataCenter.FubenSimulatedCombatManager.GetCurrencyIcon(2))
        if XDataCenter.FubenSimulatedCombatManager.GetCurrencyByNo(2) < price2 then
            self.TxtPrice2.color = XFubenSimulatedCombatConfig.Color.INSUFFICIENT
        else
            self.TxtPrice2.color = XFubenSimulatedCombatConfig.Color.NORMAL
        end
    end
end

function XUiGridRes:OnBtnSelectClick()
    local result, desc = XDataCenter.FubenSimulatedCombatManager.SelectGridRes(self.Data)
    if result then
        self:UpdateState()
    else
        XUiManager.TipMsg(desc)
    end
end

function XUiGridRes:OnBtnDetailClick()
    if self.Type == XFubenSimulatedCombatConfig.ResType.Member then
        XLuaUiManager.Open("UiSimulatedCombatRoleList", self.Id, self.StageInterId)
    elseif self.Type == XFubenSimulatedCombatConfig.ResType.Addition then
        XLuaUiManager.Open("UiSimulatedCombatBuffTip", self.Id)
    end
end

function XUiGridRes:OnBtnCancelBuyClick()
    XDataCenter.FubenSimulatedCombatManager.CancelBuyGridRes(self.Data)
    self:UpdateState()
end

return XUiGridRes