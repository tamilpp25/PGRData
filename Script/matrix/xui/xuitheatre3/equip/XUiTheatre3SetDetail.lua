local XUiTheatre3EquipmentTip = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentTip")

---@class XUiTheatre3SetDetail : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3SetDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre3SetDetail")

function XUiTheatre3SetDetail:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnMask, self.Close)
end

function XUiTheatre3SetDetail:OnStart(equipId)
    local equipCfg = self._Control:GetEquipById(equipId)
    local suitCfg = self._Control:GetSuitById(equipCfg.SuitId)
    local equipCfgs = self._Control:GetSameSuitEquip(equipId)

    self.TxtTitle.text = suitCfg.SuitName
    ---@type XUiTheatre3EquipmentTip[]
    self._Tips = {}

    ---@param data XTableTheatre3Equip
    self:RefreshTemplateGrids(self.Grid.transform, equipCfgs, self.Grid.transform.parent, nil, "UiTheatre3SetDetailGrid", function(grid, data)
        local tip = XUiTheatre3EquipmentTip.New(grid.BubbleEquipment, self)
        tip:ShowEquipTip(data.Id)
        tip:SetSelectCallBack(handler(self, self.OnClickTip))
        tip:ShowCurEquipTag(data.Id == equipId)
        self._Tips[data.Id] = tip
    end)
end

function XUiTheatre3SetDetail:OnClickTip(curId)
    for id, v in pairs(self._Tips) do
        if curId ~= id then
            v:CloseEffectDetail()
        end
    end
end

return XUiTheatre3SetDetail