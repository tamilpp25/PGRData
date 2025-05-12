---@class XUiPanelRogueSimCasinoSettlement : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimPopupCommonHorizontal
local XUiPanelRogueSimCasinoSettlement = XClass(XUiNode, "XUiPanelRogueSimCasinoSettlement")

function XUiPanelRogueSimCasinoSettlement:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick, nil, true)
end

---@param eventGambleId number 事件投机自增Id
function XUiPanelRogueSimCasinoSettlement:Refresh(eventGambleId)
    self.Id = eventGambleId
    self:RefreshCasino()
    self:RefreshSettlement()
    self:PlayAnimationWithMask("PanelCasinoSettlementEnable")
end

function XUiPanelRogueSimCasinoSettlement:RefreshCasino()
    self.TxtTips2.text = self._Control:GetClientConfig("GambleLoading")
end

function XUiPanelRogueSimCasinoSettlement:RefreshSettlement()
    local eventOptionId, rewardRateIndex = self._Control.MapSubControl:GetEventGambleOptionIdAndRewardRateIndexById(self.Id)
    if eventOptionId <= 0 or rewardRateIndex <= 0 then
        XLog.Error("Refresh error, eventOptionId or rewardRateIndex is invalid")
        return
    end
    -- 返还奖励比例
    local rewardRate = self._Control.MapSubControl:GetEventOptionGambleRewardRates(eventOptionId, rewardRateIndex)
    local isWin = rewardRate >= XEnumConst.RogueSim.Denominator
    self.PanelUp.gameObject:SetActiveEx(isWin)
    self.PanelDown.gameObject:SetActiveEx(not isWin)

    local imgIcon = self._Control:GetClientConfig(isWin and "GambleImgWin" or "GambleImgLose")
    if not string.IsNilOrEmpty(imgIcon) then
        if isWin then
            self.ImgUp:SetRawImage(imgIcon)
        else
            self.ImgDown:SetRawImage(imgIcon)
        end
    end
    if isWin then
        self.TxtUp.text = self._Control:GetClientConfig("GambleDescWin")
    else
        self.TxtDown.text = self._Control:GetClientConfig("GambleDescLose")
    end

    self.PanelCoin.gameObject:SetActiveEx(true)
    -- 返还的资源数据
    local returnIcon = ""
    local returnCount = 0
    local returnResourceInfos = self._Control.MapSubControl:GetReturnResourceInfosById(self.Id)
    local returnCommodityInfos = self._Control.MapSubControl:GetReturnCommodityInfosById(self.Id)
    if XTool.IsTableEmpty(returnResourceInfos) and XTool.IsTableEmpty(returnCommodityInfos) then
        returnIcon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
        returnCount = 0
    elseif not XTool.IsTableEmpty(returnResourceInfos) then
        returnIcon = self._Control.ResourceSubControl:GetResourceIcon(returnResourceInfos[1].Id)
        returnCount = returnResourceInfos[1].Count
    else
        returnIcon = self._Control.ResourceSubControl:GetCommodityIcon(returnCommodityInfos[1].Id)
        returnCount = returnCommodityInfos[1].Count
    end
    if not string.IsNilOrEmpty(returnIcon) then
        self.RImgCoin:SetRawImage(returnIcon)
    end
    self.TxtCoin.text = returnCount

    -- 提示
    local gainTips = self._Control:GetClientConfig("GambleGainTips")
    local gain = math.floor((rewardRate - XEnumConst.RogueSim.Denominator) / XEnumConst.RogueSim.Percentage)
    self.TxtTips.text = XUiHelper.FormatText(gainTips, gain)
end

function XUiPanelRogueSimCasinoSettlement:OnBtnYesClick()
    if not XTool.IsNumberValid(self.Id) then
        XLog.Error("OnBtnYesClick error: Id is invalid")
        return
    end
    local curTurnNumber = self._Control:GetCurTurnNumber()
    local rewardTurnNumber = self._Control.MapSubControl:GetEventGambleRewardTurnNumberById(self.Id)
    if curTurnNumber < rewardTurnNumber then
        XUiManager.TipMsg(self._Control:GetClientConfig("GambleNotReady"))
        return
    end
    self._Control:RogueSimEventGambleGetRewardRequest(self.Id, function()
        self.Parent:OnBtnCloseClick()
    end)
end

return XUiPanelRogueSimCasinoSettlement
