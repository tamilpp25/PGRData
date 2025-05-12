---@class XUiFangKuaiPropDetail : XLuaUi 大方块道具详情弹框
---@field _Control XFangKuaiControl
local XUiFangKuaiPropDetail = XLuaUiManager.Register(XLuaUi, "UiFangKuaiPropDetail")

function XUiFangKuaiPropDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCloseDetail, self.Close)
end

function XUiFangKuaiPropDetail:OnStart(itemId)
    local item = self._Control:GetItemConfig(itemId)
    self.RImgProp:SetRawImage(item.Icon)
    self.TxtDetail.text = item.Desc
    self.TxtBt.text = item.Name
end

return XUiFangKuaiPropDetail