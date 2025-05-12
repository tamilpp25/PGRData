local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--"隐藏节点!!!" 排行榜细节界面 (英文不是我起的 确实起名太模糊了)
---@class XUiGuildWarRankStage
local XUiGuildWarRankStage = XLuaUiManager.Register(XLuaUi, "UiGuildWarRankStage")
local XUiGuildWarRankStageGrid = require("XUi/XUiGuildWar/Ranking/Grid/XUiGuildWarRankStageGrid")

function XUiGuildWarRankStage:OnAwake()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRankList.gameObject)
    local gridProxy = XUiGuildWarRankStageGrid
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
    
    self.BtnTanchuangClose.CallBack = function() self:OnBtnClose() end
    self.BtnClose.CallBack = function() self:OnBtnClose() end
    self.PanelBtn.CallBack = function() self:OnBtnClose() end
end
--@param rankData XGuildWarRankInfo(C#)
function XUiGuildWarRankStage:OnStart(data)
    self.Data = data
    local allScore = 0
    --XGuildWarHideAreaMeta
    local areaDatas = data.HideAreaMetas
    for _,areaData in ipairs(areaDatas) do
        allScore = allScore + areaData.Point
    end
    self.TxtScore.text = allScore

    self.DynamicTable:SetDataSource(self.Data.HideAreaMetas)
    self.DynamicTable:ReloadDataASync(1)

end

--================
--动态列表事件
--================
function XUiGuildWarRankStage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.Data and self.Data.HideAreaMetas and self.Data.HideAreaMetas[index] then
            grid:RefreshData(self.Data.HideAreaMetas[index])
        end
    end
end

function XUiGuildWarRankStage:OnBtnClose()
    self:Close()
end

return XUiGuildWarRankStage