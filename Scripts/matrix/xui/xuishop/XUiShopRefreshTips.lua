---@class XUiShopRefreshTips
local XUiShopRefreshTips = XClass(nil, "XUiShopRefreshTips")

function XUiShopRefreshTips:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnClose.CallBack = function()
        self:Hide()
    end
    self:Hide()
end

function XUiShopRefreshTips:SetText(text)
    self.TxtName.text = text
end

function XUiShopRefreshTips:Show()
    self.GameObject:SetActiveEx(true)
    self.BtnClose.gameObject:SetActiveEx(true)
end

function XUiShopRefreshTips:Hide()
    self.GameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(false)
end

return XUiShopRefreshTips