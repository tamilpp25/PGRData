---@class XUiTheatre4PopupGeniusLvUpColorGrid : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4PopupGeniusLvUpColorGrid = XClass(XUiNode, "XUiTheatre4PopupGeniusLvUpColorGrid")

function XUiTheatre4PopupGeniusLvUpColorGrid:OnStart()
    self.ImgLv = {
        [XEnumConst.Theatre4.ColorType.Red] = self.ImgRedLv,
        [XEnumConst.Theatre4.ColorType.Yellow] = self.ImgYellowLv,
        [XEnumConst.Theatre4.ColorType.Blue] = self.ImgBlueLv,
    }
end

---@param data { Color: number, NewLevel: number, OldLevel: number}
function XUiTheatre4PopupGeniusLvUpColorGrid:Refresh(data)
    for id, v in pairs(self.ImgLv) do
        v.gameObject:SetActiveEx(id == data.Color)
    end
    self.TxtName.text = self._Control:GetColorTreeName(data.Color)
    self.TxtClassNumOld.text = data.OldLevel or 0
    self.TxtClassNumNew.text = data.NewLevel or 0
end

return XUiTheatre4PopupGeniusLvUpColorGrid
