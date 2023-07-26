--虚像地平线关卡层重置确认界面
local XUiExpeditionTierReset = XLuaUiManager.Register(XLuaUi, "UiExpeditionTierReset")

function XUiExpeditionTierReset:OnStart()
    self:InitPanel()
end

function XUiExpeditionTierReset:InitPanel()
    self.TxtInfo.text = CS.XTextManager.GetText("ExpeditionResetTips", XDataCenter.ExpeditionManager.GetRecruitNum())
    self:InitPanelConsume()
    self:InitButtons()
end

function XUiExpeditionTierReset:InitPanelConsume()
    self.ConsumePanel = {}
    XTool.InitUiObjectByUi(self.ConsumePanel, self.PanelConsume)
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local itemId = eActivity:GetResetChapterConsumeId()
    local haveCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = eActivity:GetResetChapterConsumeCount()
    if haveCount >= needCount then
        self.ConsumePanel.TxtNumber.text = needCount
    else
        self.ConsumePanel.TxtNumber.text = XUiHelper.GetText("CommonRedText", needCount)
    end
    local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
    self.ConsumePanel.RImgIcon:SetRawImage(icon)
end

function XUiExpeditionTierReset:InitButtons()
    self.BtnTanchuangClose.CallBack = handler(self, self.OnClickClose)
    self.BtnConfirm.CallBack = handler(self, self.OnClickConfirm)
    self.BtnClose.CallBack = handler(self, self.OnClickClose)
end

function XUiExpeditionTierReset:OnClickClose()
    self:Close()
end

function XUiExpeditionTierReset:OnClickConfirm()
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local itemId = eActivity:GetResetChapterConsumeId()
    local haveCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = eActivity:GetResetChapterConsumeCount()
    if needCount > haveCount then
        XUiManager.TipMsg(XUiHelper.GetText("CommonCoinNotEnough"))
        return
    end
    XDataCenter.ExpeditionManager.ResetTier(function() self:Close() end)
end