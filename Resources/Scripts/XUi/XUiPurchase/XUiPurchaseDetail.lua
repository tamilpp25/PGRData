local XUiPurchaseDetail = XClass(nil, "XUiPurchaseDetail")

function XUiPurchaseDetail:Ctor(ui, uiroot, callback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Uiroot = uiroot
    self.CallBack = callback
    XTool.InitUiObject(self)
    self:Init()
end

function XUiPurchaseDetail:Init()
    self.BtnBgClick.CallBack = function()
        self:OnBtnBgClick()
    end
    self.BtnCloseBg.CallBack = function()
        self:OnBtnCloseBgClick()
    end
end

function XUiPurchaseDetail:OnBtnBgClick()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiPurchaseDetail:OnBtnCloseBgClick()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiPurchaseDetail:Show()
    --显示有偿黑卡的数量
    local TxtYouChangcount = XDataCenter.ItemManager.GetPaidGemCount()
    self.TxtYouChangNum.text = TxtYouChangcount
    --显示无偿黑卡的数量
    local TxtWuChangCount = XDataCenter.ItemManager.GetFreeGemCount()
    self.TxtWuChangNum.text = TxtWuChangCount
end

return XUiPurchaseDetail