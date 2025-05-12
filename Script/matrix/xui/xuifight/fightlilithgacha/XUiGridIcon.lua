---@class XUiGridIcon 扭蛋图标
---@field _Control XFightCaptureV217Control
local XUiGridIcon = XClass(nil, "XUiGridIcon")

---@param RootUi XUiFightLilithGacha
function XUiGridIcon:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self._Model = rootUi._Control._Model
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GameObject:SetActiveEx(true)
end

-- id：表格id
-- isUnlock：是否解锁
function XUiGridIcon:Refresh(id, isUnlock)
    local icon = self._Model:GetGachaIcon(id)
    self.RImgIconGet:SetRawImage(icon)
    self.RImgIconUnGet:SetRawImage(icon)

    self.RImgIconGet.gameObject:SetActiveEx(isUnlock)
    self.RImgIconUnGet.gameObject:SetActiveEx(not isUnlock)
end

return XUiGridIcon