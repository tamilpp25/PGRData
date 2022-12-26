--资源购买界面，右上角加成图标
local XUiGridStageBuffIcon = XClass(nil, "XUiGridStageBuffIcon")
 
function XUiGridStageBuffIcon:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiGridStageBuffIcon:Refresh(data)
    self.RImgIcon:SetRawImage(data.Icon)
    self.TxtStar.text = data.Star
end

function XUiGridStageBuffIcon:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiGridStageBuffIcon:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiGridStageBuffIcon