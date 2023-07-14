--虚像地平线关卡详细页面：关卡增益图标控件
local XUiExpeditionStageBuffIcon = XClass(nil, "XUiExpeditionStageBuffIcon")

function XUiExpeditionStageBuffIcon:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi   
    XTool.InitUiObject(self)
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

return XUiExpeditionStageBuffIcon