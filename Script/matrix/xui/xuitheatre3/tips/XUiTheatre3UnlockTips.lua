local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")
local XUiTheatre3EquipmentCell = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCell")

---@class XUiTheatre3UnlockTips : XLuaUi 解锁藏品/装备Tip
---@field _Control XTheatre3Control
local XUiTheatre3UnlockTips = XLuaUiManager.Register(XLuaUi, "UiTheatre3UnlockTips")

function XUiTheatre3UnlockTips:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiTheatre3UnlockTips:OnStart(param, callBack)
    self:RefreshTemplateGrids(self.Grid, param.datas, self.Grid.parent, nil, "UiTheatre3UnlockTips", function(grid, data)
        ---@type XUiGridTheatre3Reward
        local settleGrid = XUiGridTheatre3Reward.New(grid.PropGrid, self)
        ---@type XUiTheatre3EquipmentCell
        local equipGrid = XUiTheatre3EquipmentCell.New(grid.UiEquipment, self)
        if param.isUnlockEquip then
            equipGrid:Open()
            equipGrid:ShowEquip(data)
            settleGrid:Close()
        elseif param.isUnlockSettle then
            settleGrid:SetData(data, XEnumConst.THEATRE3.EventStepItemType.InnerItem)
            settleGrid:Open()
            equipGrid:Close()
        end
    end)

    self.RewardTitle.gameObject:SetActiveEx(param.isUnlockSettle)
    self.RewardTitleSet2.gameObject:SetActiveEx(param.isUnlockEquip)
    self.SViewlList.horizontalNormalizedPosition = 0
    self._CallBack = callBack
end

function XUiTheatre3UnlockTips:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

return XUiTheatre3UnlockTips