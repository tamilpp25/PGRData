local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local UiGridColorTableRank = require("XUi/XUiColorTable/Grid/XUiGridColorTableRank")

-- 调色板战争排行榜
local XUiColorTableRank = XLuaUiManager.Register(XLuaUi, "UiColorTableRank")
local Normal = CS.UiButtonState.Normal
local Select = CS.UiButtonState.Select

function XUiColorTableRank:OnAwake()
    self.TagStageList =  XColorTableConfigs.GetDifficultStageList()
    self.SelectTagIndex = 1
    self.TagBtnList = {}

    self:RegisterEvent()
    self:InitTabList()
    self:InitDynamicTable()
    self:InitMyRankPanel()
    self:InitTimes()
    self:InitAssetPanel()
end

function XUiColorTableRank:OnEnable()
    self.Super.OnEnable(self)
    self:OnBtnTagClick(1)
    self:UpdateAssetPanel()
end

function XUiColorTableRank:OnDisable()
    self.Super.OnDisable(self)
end

function XUiColorTableRank:RegisterEvent()
    self.BtnMainUi.CallBack = handler(self, function() XLuaUiManager.RunMain() end)
    self.BtnBack.CallBack = handler(self, self.Close)
end

function XUiColorTableRank:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

---------------------------------------- 页签 begin ----------------------------------------

function XUiColorTableRank:InitTabList()
    for index, stage in ipairs(self.TagStageList) do
        local btn = self.BtnRankTag
        if index > 1 then
            local go = CS.UnityEngine.Object.Instantiate(self.BtnRankTag.gameObject, self.BtnRankTag.transform.parent)
            btn = go:GetComponent("XUiButton")
        end
        btn:SetName(stage.Name)
        self.TagBtnList[index] = btn

        local tempIndex = index
        XUiHelper.RegisterClickEvent(self, btn, function()
            self:OnBtnTagClick(tempIndex)
        end)
    end
end

function XUiColorTableRank:OnBtnTagClick(index)
    self.SelectTagIndex = index

    -- 切换按钮状态
    for index, btn in ipairs(self.TagBtnList) do
        local state = index == self.SelectTagIndex and Select or Normal
        btn:SetButtonState(state)
    end

    -- 刷新列表
    XDataCenter.ColorTableManager.RequestRankInfo(self:GetCurStageId(), function()
        self:RefreshDynamicTable()
        self:RefreshMyRank()
    end)
end

function XUiColorTableRank:GetCurStageId()
    local stageId = self.TagStageList[self.SelectTagIndex].Id
    return stageId
end

---------------------------------------- 页签 start ----------------------------------------

---------------------------------------- 排名列表 begin ----------------------------------------
function XUiColorTableRank:InitDynamicTable()
    self.PlayerRank.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(UiGridColorTableRank)
    self.DynamicTable:SetDelegate(self)
end

function XUiColorTableRank:RefreshDynamicTable()
    self.DataList = XDataCenter.ColorTableManager.GetRankList(self:GetCurStageId())
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)

    self.PanelNoRank.gameObject:SetActiveEx((not next(self.DataList)))
end

function XUiColorTableRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self.DataList[index]
        rankInfo.Rank = index
        grid:Refresh(rankInfo)
    end
end

function XUiColorTableRank:InitMyRankPanel()
    self.MyRank = UiGridColorTableRank.New(self.BtnMyRank)
end

function XUiColorTableRank:RefreshMyRank()
    local rankInfo = XDataCenter.ColorTableManager.GetMyRankInfo(self:GetCurStageId())
    self.MyRank:Refresh(rankInfo)
end
---------------------------------------- 排名列表 end ----------------------------------------

---------------------------------------- 资源栏 begin ----------------------------------------

function XUiColorTableRank:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.ColorTableCoin,
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiColorTableRank:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.ColorTableCoin,
        }
    )
end
---------------------------------------- 资源栏 end ----------------------------------------
