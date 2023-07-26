---@class XUiSlotMachineIconItem
local XUiSlotMachineIconItem = XClass(nil, "XUiSlotMachineIconItem")

function XUiSlotMachineIconItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiSlotMachineIconItem:OnCreate(data)
    local IconImageUrl = XSlotMachineConfigs.GetIconImageById(data.IconId)
    self.IconImage:SetRawImage(IconImageUrl)
end

function XUiSlotMachineIconItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiSlotMachineIconItem