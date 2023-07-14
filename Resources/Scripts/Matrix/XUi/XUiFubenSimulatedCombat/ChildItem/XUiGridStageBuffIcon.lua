--关卡详细页面：关卡增益图标控件
local XUiGridStageBuffIcon = XClass(nil, "XUiGridStageBuffIcon")
 
function XUiGridStageBuffIcon:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiGridStageBuffIcon:RefreshData(eventId)
    local buffCfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)
    self.RImgIcon:SetRawImage(buffCfg.Icon)
end

function XUiGridStageBuffIcon:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiGridStageBuffIcon:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiGridStageBuffIcon