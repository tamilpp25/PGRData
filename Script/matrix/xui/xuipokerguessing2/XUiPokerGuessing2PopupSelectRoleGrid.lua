---@class XUiPokerGuessing2PopupSelectRoleGrid : XUiNode
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2PopupSelectRoleGrid = XClass(XUiNode, "XUiPokerGuessing2PopupSelectRoleGrid")

function XUiPokerGuessing2PopupSelectRoleGrid:OnStart()
end

---@param data XUiPokerGuessing2PopupSelectRoleGridData
function XUiPokerGuessing2PopupSelectRoleGrid:Update(data)
    self.ImgIcon:SetRawImage(data.Icon)
    self.TxtName.text = data.Name
    self.ImgUse.gameObject:SetActiveEx(data.IsUse)
    self.ImgSelect.gameObject:SetActiveEx(data.IsSelected)
end

return XUiPokerGuessing2PopupSelectRoleGrid