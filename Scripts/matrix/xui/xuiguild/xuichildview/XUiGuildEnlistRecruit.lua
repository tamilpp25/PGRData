local XUiGuildEnlistRecruit = XClass(nil, "XUiGuildEnlistRecruit")
local XUiGridGuildEnlistItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildEnlistItem")
local LastRefreshTime = 0

function XUiGuildEnlistRecruit:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
end

function XUiGuildEnlistRecruit:InitChildView()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade.gameObject)
    self.DynamicTable:SetProxy(XUiGridGuildEnlistItem)
    self.DynamicTable:SetDelegate(self)

    self.UiRoot:BindHelpBtn(self.BtnInformation, "GuildRecruit")
    self.BtnRefresh.CallBack = function() self:OnBtnRefreshClick() end
end

function XUiGuildEnlistRecruit:UpdateEnlists()
    local reconmendDatas = XDataCenter.GuildManager.GetRandomRecommendPlayers()
    self.ReconmendDatas = {}
    for _, recruitInfo in pairs(reconmendDatas) do
        table.insert(self.ReconmendDatas, recruitInfo)
    end

    table.sort(self.ReconmendDatas, function(recruitA, recruitB)
        if recruitA.OnlineFlag == recruitB.OnlineFlag then
            if recruitA.Level == recruitB.Level then
                return recruitA.LastLoginTime > recruitB.LastLoginTime
            end
            return recruitA.Level > recruitB.Level
        end
        return recruitA.OnlineFlag > recruitB.OnlineFlag
    end)

    self.DynamicTable:Clear()
    if self.ImgEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(#self.ReconmendDatas <= 0)
    end
    self.DynamicTable:SetDataSource(self.ReconmendDatas)
    self.DynamicTable:ReloadDataASync()
end

function XUiGuildEnlistRecruit:RefreshEnlists()
    self:UpdateEnlists()
end

function XUiGuildEnlistRecruit:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ReconmendDatas[index]
        if not data then return end
        grid:SetItemData(data)
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

function XUiGuildEnlistRecruit:OnBtnRefreshClick()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        return
    end
    local now = XTime.GetServerNowTimestamp()
    if now - LastRefreshTime >= XGuildConfig.GUildRefreshCDTime then
        local currentPageNo = XDataCenter.GuildManager.GetRecommendPageNo()
        XDataCenter.GuildManager.GuildRecruitRecommendRequest(currentPageNo, function()
            self:RefreshEnlists()
        end)
        LastRefreshTime = now
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildRefreshRecruitInCd", XGuildConfig.GUildRefreshCDTime - (now - LastRefreshTime)))
    end
end

return XUiGuildEnlistRecruit