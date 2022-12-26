local XUiGuildEnlistNews = XClass(nil, "XUiGuildEnlistNews")
local XUiGridGuildEnlistItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildEnlistItem")

function XUiGuildEnlistNews:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
end

function XUiGuildEnlistNews:InitChildView()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade.gameObject)
    self.DynamicTable:SetProxy(XUiGridGuildEnlistItem)
    self.DynamicTable:SetDelegate(self)
    self.BtnSet.CallBack = function() self:OnBtnSetClick() end
end

function XUiGuildEnlistNews:UpdateEnlists()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        return
    end
    XDataCenter.GuildManager.GetGuildListApply(function()
        local applyList = XDataCenter.GuildManager.GetGuildApplyList()
        self.ApplyList = {}
        for _, v in pairs(applyList) do
            table.insert(self.ApplyList, v)
        end
        table.sort(self.ApplyList, function(applyA, applyB)
            if applyA.OnlineFlag == applyB.OnlineFlag then
                return applyA.LastLoginTime > applyB.LastLoginTime
            end
            return applyA.OnlineFlag > applyB.OnlineFlag
        end)
        if self.ImgEmpty then
            self.ImgEmpty.gameObject:SetActiveEx(#self.ApplyList <= 0)
        end
        self.DynamicTable:Clear()
        self.DynamicTable:SetDataSource(self.ApplyList)
        self.DynamicTable:ReloadDataASync()
    end)
end

function XUiGuildEnlistNews:RefreshEnlists()
    self.ApplyList = {}
    local applyList = XDataCenter.GuildManager.GetGuildApplyList()
    for _, v in pairs(applyList) do
        table.insert(self.ApplyList, v)
    end
    if self.ImgEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(#self.ApplyList <= 0)
    end
    table.sort(self.ApplyList, function(applyA, applyB)
        if applyA.OnlineFlag == applyB.OnlineFlag then
            return applyA.LastLoginTime > applyB.LastLoginTime
        end
        return applyA.OnlineFlag > applyB.OnlineFlag
    end)
    self.DynamicTable:Clear()
    self.DynamicTable:SetDataSource(self.ApplyList)
    self.DynamicTable:ReloadDataASync()
end

function XUiGuildEnlistNews:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ApplyList[index]
        if not data then return end
        grid:SetItemData(data)
    end
end

function XUiGuildEnlistNews:OnBtnSetClick()
    XLuaUiManager.Open("UiGuildChangePosition", XGuildConfig.TipsType.ApplySetting)
end

return XUiGuildEnlistNews