local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--- 排行榜界面
---@class XUiBagOrganizeRank: XLuaUi
---@field private _Control XBagOrganizeActivityControl
local XUiBagOrganizeRank = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizeRank')
local XUiGridBagOrganizeRank = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeRank/XUiGridBagOrganizeRank')

function XUiBagOrganizeRank:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)

    if self.BtnMainUi then
        self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    end
    
    self:InitDynamicTable()
    self:InitSelfRank()
end

function XUiBagOrganizeRank:OnStart(data)
    self.SelfScore = data.Score
    self.SelfRank = data.Rank
    self.TotalCount = data.TotalCount
    self.RankPlayerInfos = data.RankPlayerInfos
    self.SelfRankIsIn = false

    if not XTool.IsTableEmpty(self.RankPlayerInfos) then
        for i, v in pairs(self.RankPlayerInfos) do
            if v.Id == XPlayer.Id then
                self.SelfRankIsIn = true
                break
            end
        end
    end
    
    self:RefreshShow()
end

--region 初始化
function XUiBagOrganizeRank:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require('XUi/XUiBagOrganizeActivity/UiBagOrganizeRank/XUiGridBagOrganizeRank'), self)
    
    self.GridPlayerRank.gameObject:SetActiveEx(false)
end

function XUiBagOrganizeRank:InitSelfRank()
    self.SelfRankPGrid = XUiGridBagOrganizeRank.New(self.PanelMyRank, self)
    self.SelfRankPGrid:Open()
end
--endregion

--region 界面刷新

function XUiBagOrganizeRank:RefreshShow()
    local hasRankRecord = not XTool.IsTableEmpty(self.RankPlayerInfos)
    
    self.PanelNoRank.gameObject:SetActiveEx(not hasRankRecord)
    
    if hasRankRecord then
        -- 显示排行榜
        self.DynamicTable:SetDataSource(self.RankPlayerInfos)
        self.DynamicTable:ReloadDataASync()
    end
    
    -- 显示自己的数据
    self.SelfRankPGrid:RefreshSelf(self.SelfScore, self.SelfRank, XTool.IsNumberValid(self.TotalCount) and self.TotalCount or 1, not self.SelfRankIsIn)
end

--endregion

--region 事件回调

function XUiBagOrganizeRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        grid:RefreshByRankInfo(self.RankPlayerInfos[index], index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()
    end
end

--endregion

return XUiBagOrganizeRank