local XUiGuildLog = XLuaUiManager.Register(XLuaUi, "UiGuildLog")

local XUiGridGuildLogItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildLogItem")
local Dropdown = CS.UnityEngine.UI.Dropdown
local MaxCount = {
    [XGuildConfig.NewsType.Guild] = CS.XGame.Config:GetInt("GuildNewsMaxCount"),
    [XGuildConfig.NewsType.Member] = CS.XGame.Config:GetInt("GuildPlayerNewsMaxCount")
}
-- local GuildNewsMaxCount = CS.XGame.Config:GetInt("GuildNewsMaxCount") 
-- local GuildPlayerNewsMaxCount = CS.XGame.Config:GetInt("GuildPlayerNewsMaxCount")

function XUiGuildLog:OnAwake()
    self:InitChildView()
    self:InitDropdown()
end

function XUiGuildLog:OnStart()
    MaxCount[XGuildConfig.NewsType.All] = MaxCount[XGuildConfig.NewsType.Guild] + MaxCount[XGuildConfig.NewsType.Member]
end

function XUiGuildLog:OnDestroy()

end

function XUiGuildLog:InitDropdown()
    self.NewsTypes = {}
    for _, v in ipairs(XGuildConfig.NewsList) do
        local type = XGuildConfig.NewsType[v]
        table.insert(self.NewsTypes, {
            -- NewsType = i,
            -- TypeName = CS.XTextManager.GetText("GuildNews"..v),
            NewsType = type,
            TypeName = XGuildConfig.NewsName[type],
        })
    end

    local defaultIndex = 1
    self.DrdSort:ClearOptions()
    self.DrdSort.captionText.text = self.NewsTypes[defaultIndex].TypeName
    for i = 1, #self.NewsTypes do
        local op = Dropdown.OptionData()
        op.text = self.NewsTypes[i].TypeName
        self.DrdSort.options:Add(op)
    end
    self.DrdSort.onValueChanged:AddListener(function(value)
        self:OnNewsTypeChangedIndex(value + 1)
    end)
    self:OnNewsTypeChangedIndex(defaultIndex)
end

function XUiGuildLog:InitChildView()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end
    self.BtnYes.CallBack = function() self:OnBtnTanchuangClose() end

    if not self.DynamicCustomTable then
        self.DynamicCustomTable = XDynamicTableIrregular.New(self.ScrollChannel.gameObject)
        self.DynamicCustomTable:SetProxy("XUiGridGuildLogItem", XUiGridGuildLogItem, self.GridChannelItem.gameObject)
        self.DynamicCustomTable:SetDelegate(self)
    end

end

function XUiGuildLog:GetProxyType()
    return "XUiGridGuildLogItem"
end

function XUiGuildLog:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetItemData(self.AllGuildNews[index], self.CurrentNewsType)
        -- 拉到顶端了
        if index == 1 and self.LookBackwardPage > 0 then
            XDataCenter.GuildManager.GetGuildListNews(self.CurrentNewsType, self.LookBackwardPage, function()
                self.LookBackwardPage = self.LookBackwardPage - 1
                self:RefreshLogs(self.CurrentNewsType)
            end)
        end
    end
end

-- 切换动态类型
function XUiGuildLog:OnNewsTypeChangedIndex(index)
    if not self.NewsTypes[index] then return end
    self.CurrentNewsType = self.NewsTypes[index].NewsType
    self:GetLogs(self.CurrentNewsType)
end

function XUiGuildLog:GetLogs(type)
    XDataCenter.GuildManager.GetGuildListNews(type, 0, function()
        self.CurrentMaxPage = XDataCenter.GuildManager.GetGuildLogMaxPage(type)
        self.LookBackwardPage = self.CurrentMaxPage - 1
        self:RefreshLogs(type)
        -- self:GetLastPage()
    end)
end

-- function XUiGuildLog:GetLastPage()
--     if self.LookBackwardPage > 0 then
--         XDataCenter.GuildManager.GetGuildListNews(self.CurrentNewsType, self.LookBackwardPage, function()
--             self.LookBackwardPage = self.LookBackwardPage - 1
--             self:RefreshLogs(self.CurrentNewsType)
--             self:GetLastPage()
--         end)
--     end
-- end

function XUiGuildLog:RefreshLogs(type)
    local allGuildNews = XDataCenter.GuildManager.GetGuildLogListByType(type)
    local sortNews = {}
    for k, v in pairs(allGuildNews or {}) do
        table.insert(sortNews, v)
    end
    table.sort(sortNews, function(newA, newB)
        return newA.Time > newB.Time
    end)
    self.AllGuildNews = {}
    local totalLength = #sortNews
    local begin = totalLength - MaxCount[type] + 1
    begin = (begin <= 0) and 1 or begin
    local endIndex = totalLength
    for i = begin, endIndex do
        table.insert(self.AllGuildNews, sortNews[i])
    end

    self.DynamicCustomTable:SetDataSource(self.AllGuildNews)
    -- if self.LookBackwardPage == 0 then
    self.DynamicCustomTable:ReloadDataASync()
    -- end
end

function XUiGuildLog:OnBtnTanchuangClose()
    self:Close()
end