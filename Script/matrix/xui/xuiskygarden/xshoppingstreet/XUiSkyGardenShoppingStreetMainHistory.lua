local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiSkyGardenShoppingStreetMainHistory : XUiNode
---@field BtnReturn XUiComponent.XUiButton
---@field TxtTitle UnityEngine.UI.Text
---@field ListStage UnityEngine.RectTransform
---@field GridStage UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetMainHistory = XClass(XUiNode, "XUiSkyGardenShoppingStreetMainHistory")

--region 生命周期
function XUiSkyGardenShoppingStreetMainHistory:OnStart(...)
    self:_RegisterButtonClicks()
    self:_InitDynamicTable()
end
--endregion

--region 共有方法

function XUiSkyGardenShoppingStreetMainHistory:Refresh()
    self._stageIds = self._Control:GetPassedStageIds()
    self.DynamicTable:SetDataSource(self._stageIds)
    self.DynamicTable:ReloadDataSync()
end

function XUiSkyGardenShoppingStreetMainHistory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if not self._stageIds then return end
        local stageId = self._stageIds[index]
        grid:ResetData(stageId)
    end
end

--endregion

--region 按钮事件
-- function XUiSkyGardenShoppingStreetMainHistory:OnBtnReturnClick()
-- end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetMainHistory:_InitDynamicTable()
    local XUiSkyGardenShoppingStreetMainGridStage = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetMainGridStage")
    self.DynamicTable = XDynamicTableNormal.New(self.ListStage.gameObject)
    self.DynamicTable:SetProxy(XUiSkyGardenShoppingStreetMainGridStage, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiSkyGardenShoppingStreetMainHistory:_RegisterButtonClicks()
    -- self.BtnReturn.CallBack = function() self:OnBtnReturnClick() end
end
--endregion

return XUiSkyGardenShoppingStreetMainHistory
