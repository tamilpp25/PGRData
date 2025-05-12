---@class XUiGridSticker 拍照后贴纸列表的格子
---@field RootUi XUiPanelSticker
local XUiGridSticker = XClass(nil, "XUiGridSticker")

function XUiGridSticker:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridSticker:Init(rootUi)
    self.RootUi = rootUi
end

--- 设置数据
---@param stickerId - CaptureV217Sticker表的Id
function XUiGridSticker:SetData(stickerId, isUnlock)
    self.StickerId = stickerId
    self.IsUnlock = isUnlock
    local iconPath = self.RootUi._Control._Model:GetStickerCfgSmallIconPath(stickerId) or ""
    self.BtnSticker:SetSprite(iconPath)
    self:Refresh()
end

function XUiGridSticker:Refresh()
    self.BtnSticker:SetDisable(not self.IsUnlock, self.IsUnlock)
end

return XUiGridSticker