local BasePanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--==================
--超级爬塔 爬塔 结算界面增益面板控件
--==================
local XUiStTsEnhanceInfoPanel = XClass(BasePanel, "XUiStTsEnhanceInfoPanel")

function XUiStTsEnhanceInfoPanel:InitPanel()
    self:InitEnhanceInfos()
    self.GridEnhance.gameObject:SetActiveEx(false)
    self:InitEnhanceList()
end

function XUiStTsEnhanceInfoPanel:InitEnhanceInfos()
    self.EnhanceIds = self.RootUi.Theme:GetTierEnhanceIds()
end

function XUiStTsEnhanceInfoPanel:InitEnhanceList()
    local gridScript = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerEnhanceGrid")
    for _, id in pairs(self.EnhanceIds) do
        local enhanceGo = CS.UnityEngine.Object.Instantiate(self.GridEnhance.gameObject, self.GridContent)
        local grid = gridScript.New(enhanceGo, function(enhanceGrid) self:OnClickEnhance(enhanceGrid) end)
        grid:RefreshData(id)
        grid:ShowPanel()
    end
end

function XUiStTsEnhanceInfoPanel:OnClickEnhance(enhanceGrid)
    XLuaUiManager.Open("UiSuperTowerEnhanceDetails", enhanceGrid.EnhanceId)
end

return XUiStTsEnhanceInfoPanel