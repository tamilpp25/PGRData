---@class XUiRiftSettleSeason : XLuaUi
local XUiRiftSettleSeason = XLuaUiManager.Register(XLuaUi, "UiRiftSettleSeason")

function XUiRiftSettleSeason:OnAwake()
    self:RegisterClickEvent(self.BtnContinue, self.Close)
end

function XUiRiftSettleSeason:OnStart(seasonId, callBack)
    self._CallBack = callBack
    self.TxtSeason.text = XDataCenter.RiftManager:GetSeasonNameByIndex(seasonId)
    self.TxtLv.text = XDataCenter.RiftManager.GetTotalTemplateAttrLevel()
    local cur, all = XDataCenter.RiftManager.GetPluginCount()
    self.TxtCollectNum.text = string.format("%.1f%%", cur / all * 100)
    for star = 3, 6 do
        cur, all = XDataCenter.RiftManager.GetPluginCount(star)
        self["TxtHaveNum" .. star].text = cur
        self["TxtTotalNum" .. star].text = string.format("/%s", all)
    end
    self:InitCompnent()
end

function XUiRiftSettleSeason:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

function XUiRiftSettleSeason:OnDestroy()

end

function XUiRiftSettleSeason:InitCompnent()
    ---@type XUiRiftRankingGrid
    local myRank = require("XUi/XUiRift/Grid/XUiRiftRankingGrid").New(self.PlayerMyRank)
    local rankInfo = XDataCenter.RiftManager.GetMyRankInfo() -- 换成服务端下发的
    myRank:Init()
    myRank:Refresh(rankInfo)
    self:InitDynamicTable()
end

function XUiRiftSettleSeason:InitDynamicTable()
    local dynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    dynamicTable:SetProxy(require("XUi/XUiRift/Grid/XUiRiftRankingGrid"))
    dynamicTable:SetDelegate(self)
    self.DataList = XDataCenter.RiftManager.GetRankingList() -- 换成服务端下发的
    dynamicTable:SetDataSource(self.DataList)
    dynamicTable:ReloadDataASync(1)
end

function XUiRiftSettleSeason:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self.DataList[index]
        rankInfo.Rank = index
        grid:Refresh(rankInfo)
    end
end

return XUiRiftSettleSeason