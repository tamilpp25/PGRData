local XUiTheatre3EquipmentCell = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCell")

---@class XUiTheatre3SuitActiveTip : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3SuitActiveTip = XLuaUiManager.Register(XLuaUi, "UiTheatre3SuitActiveTip")

function XUiTheatre3SuitActiveTip:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiTheatre3SuitActiveTip:OnStart(suitId, cb)
    self._CallBack = cb
    local datas = self._Control:GetAllSuitEquip(suitId)
    self:RefreshTemplateGrids(self.GridRole, datas, self.GridRole.parent, nil, "UiTheatre3SuitActiveTip", function(grid, data)
        local equip = XUiTheatre3EquipmentCell.New(grid.EquipmentGrid, self, data.Id)
        equip:AddClick(function()
            self._Control:OpenEquipmentTipByAlign(data.Id, nil, nil, nil, grid.ImgTouxiang)
        end)
    end)
    local suitConfig = self._Control:GetSuitById(suitId)
    self.Txtbt2.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(XUiHelper.FormatText(suitConfig.Desc, suitConfig.TraitName)))
end

function XUiTheatre3SuitActiveTip:OnDestroy()

end

function XUiTheatre3SuitActiveTip:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

return XUiTheatre3SuitActiveTip