local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelStory = require("XUi/XUiActivityBrief/XUiPanelStory")
local XUiActivityBriefStory = XLuaUiManager.Register(XLuaUi, "UiActivityBriefStory")

local tableInsert = table.insert
local tableSort = table.sort

function XUiActivityBriefStory:OnAwake()
    self.DynamicTableAudios = XDynamicTableNormal.New(self.PanelList.gameObject)
    self.DynamicTableAudios:SetProxy(XUiPanelStory)
    self.DynamicTableAudios:SetDelegate(self)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function()
        XEventManager.DispatchEvent(XEventId.EVENT_STORY_DISTORY)
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XEventManager.DispatchEvent(XEventId.EVENT_STORY_DISTORY)
        XLuaUiManager.RunMain()
    end
end

function XUiActivityBriefStory:OnStart()
    self.Config = XDataCenter.ActivityBriefManager.GetActivityStoryConfig()
    self.RankedConfig = {}
    self.NotOpenConfig = {}
    local isUnlock
    local desc = ""
    for i = 1, #self.Config do
        isUnlock,desc = XConditionManager.CheckCondition(self.Config[i].ConditionId)
        if isUnlock then
            tableInsert(self.RankedConfig,self.Config[i])
        else
            tableInsert(self.NotOpenConfig,self.Config[i])
        end
    end
    table.sort(self.RankedConfig, function(a, b)
        return a.Priority < b.Priority
    end)
    table.sort(self.NotOpenConfig, function(a, b)
        return a.Priority < b.Priority
    end)
    for i = 1, #self.NotOpenConfig do
        tableInsert(self.RankedConfig,self.NotOpenConfig[i])
    end
    self:RefreshIllustratedHandBook()
end

function XUiActivityBriefStory:RefreshIllustratedHandBook()
    if self.DynamicTableAudios then
        self.DynamicTableAudios:SetDataSource(self.RankedConfig)
        self.DynamicTableAudios:ReloadDataASync()
    end
    
end

function XUiActivityBriefStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RankedConfig[index]
        if data ~= nil then
            grid:OnRefreshDatas(data)
        end
    end
end

