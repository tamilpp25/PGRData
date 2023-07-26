local XUiGridArenaLevel = require("XUi/XUiArenaLevelDetail/ArenaLevelDetailCommon/XUiGridArenaLevel")
local XUiGridRegion = require("XUi/XUiArenaLevelDetail/ArenaLevelDetailCommon/XUiGridRegion")

local MAX_GRID_NUM = 3

local XUiInfestorExploreLevelDetail = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreLevelDetail")

function XUiInfestorExploreLevelDetail:OnAwake()
    self:AutoAddListener()
    self.GridArenaLevel.gameObject:SetActive(false)
end

function XUiInfestorExploreLevelDetail:OnStart(...)
    self.GridRegionList = {}
    for i = 1, MAX_GRID_NUM do
        local regionGrid = XUiGridRegion.New(self["GridRegion" .. i], self)
        table.insert(self.GridRegionList, regionGrid)
    end

    self.DynamicTable = XDynamicTableNormal.New(self.SViewArenaLevel.transform)
    self.DynamicTable:SetProxy(XUiGridArenaLevel)
    self.DynamicTable:SetDelegate(self)
end

function XUiInfestorExploreLevelDetail:UpdateView()
    self.DiffConfigs = XDataCenter.FubenInfestorExploreManager.GetCurGroupDiffConfigs()
    
    local minLevel, maxLevel = XDataCenter.FubenInfestorExploreManager.GetCurGroupLevelBorder()
    self.TxtGrade.text = "Lv" .. minLevel .. "-" .. maxLevel

    local selectDiff = XDataCenter.FubenInfestorExploreManager.GetCurDiff()
    self:RefreshSelect(selectDiff)

    self.DynamicTable:SetDataSource(self.DiffConfigs)
    self.DynamicTable:ReloadDataSync()
end

function XUiInfestorExploreLevelDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DiffConfigs[index]
        local diff = index
        local curDiff = XDataCenter.FubenInfestorExploreManager.GetCurDiff()
        local icon = XDataCenter.FubenInfestorExploreManager.GetDiffIcon(diff)
        local name = XDataCenter.FubenInfestorExploreManager.GetDiffName(diff)
        grid:ResetData(diff, curDiff, icon, name)
        grid:SetSelect(index == self.SelectDiff)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if index == self.SelectDiff then
            return
        end

        local lastGrid = self.DynamicTable:GetGridByIndex(self.SelectDiff)
        if lastGrid then
            lastGrid:SetSelect(false)
        end
        grid:SetSelect(true)

        self:RefreshSelect(index)
    end
end

function XUiInfestorExploreLevelDetail:RefreshSelect(selectDiff)
    self.SelectDiff = selectDiff

    for region, grid in ipairs(self.GridRegionList) do
        local isNotBorder = not ((selectDiff == 1 and region == XFubenInfestorExploreConfigs.Region.DownRegion) or
        (selectDiff == #self.DiffConfigs and region == XFubenInfestorExploreConfigs.Region.UpRegion))

        local des = isNotBorder and XDataCenter.FubenInfestorExploreManager.GetCurGroupRankRegionDescText(selectDiff, region)
        or XFubenInfestorExploreConfigs.GetRankNotRegionDescText(region)

        local title = XFubenInfestorExploreConfigs.GetRankRegionColorText(region)
        local rewardId = XDataCenter.FubenInfestorExploreManager.GetCurGroupRankRegionRewardList(selectDiff, region)

        grid:SetMetaData(title, des, isNotBorder, rewardId)
    end
end

function XUiInfestorExploreLevelDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnBg, self.OnBtnBgClick)
end

function XUiInfestorExploreLevelDetail:OnBtnBgClick(eventData)
    self:Close()
end