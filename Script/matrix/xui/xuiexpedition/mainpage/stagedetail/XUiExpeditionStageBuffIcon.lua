--虚像地平线关卡详细页面：关卡增益图标控件
local XUiExpeditionStageBuffIcon = XClass(nil, "XUiExpeditionStageBuffIcon")

function XUiExpeditionStageBuffIcon:Ctor(ui, onClickCb)
    XTool.InitUiObjectByUi(self, ui)
    self.OnClickCb = onClickCb
    self.BtnClick.CallBack = function() self:OnClick() end
end

function XUiExpeditionStageBuffIcon:RefreshData(buffCfg)
    self.RImgIcon:SetRawImage(buffCfg.Icon)
end

function XUiExpeditionStageBuffIcon:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiExpeditionStageBuffIcon:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiExpeditionStageBuffIcon:OnClick()
    if self.OnClickCb then
        self.OnClickCb()
    end
end

return XUiExpeditionStageBuffIcon