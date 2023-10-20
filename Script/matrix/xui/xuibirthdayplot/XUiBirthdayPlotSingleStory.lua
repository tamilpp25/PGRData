
---@class XUiBirthdayPlotSingleStory : XLuaUi
---@field _Control XBirthdayPlotControl
local XUiBirthdayPlotSingleStory = XLuaUiManager.Register(XLuaUi, "UiBirthdayPlotSingleStory")

local XUiGridBirthdayRole = require("XUi/XUiBirthdayPlot/XUiGrid/XUiGridBirthdayRole")

local XUiPanelSingleStory = require("XUi/XUiBirthdayPlot/XUiPanel/XUiPanelSingleStory")

function XUiBirthdayPlotSingleStory:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBirthdayPlotSingleStory:OnStart(needPop)
    self.NeedPop = needPop
    self:InitView()
end

function XUiBirthdayPlotSingleStory:OnEnable()
    self:UpdateView()
end

function XUiBirthdayPlotSingleStory:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridBirthdayRole, self)
    self.DynamicTable:SetDelegate(self)
    self.GridBirthday.gameObject:SetActiveEx(false)
    
    self.PanelSingleStory.gameObject:SetActiveEx(false)
    
    self.SingleStoryPanel = XUiPanelSingleStory.New(self.PanelSingleStory, self)
end

function XUiBirthdayPlotSingleStory:InitCb()
    self.BtnBack.CallBack = function() 
        self:OnBtnBackClick()
    end
    
    self.BtnMainUi.CallBack = function() 
        self:OnBtnMainClick()
    end
    
    self._Control:SetShowSingleStoryCb(handler(self, self.ShowSingleStory))
    self._Control:SetHideSingleStoryCb(handler(self, self.HideSingleStory))
end

function XUiBirthdayPlotSingleStory:InitView()
    self.DataList = self:FilterDataList()
end

function XUiBirthdayPlotSingleStory:UpdateView()
    self:SetupDynamicTable()
end

function XUiBirthdayPlotSingleStory:SetupDynamicTable()
    self.DataList = self:SortDataList()
    
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync()
end

function XUiBirthdayPlotSingleStory:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], index)
    end
end

function XUiBirthdayPlotSingleStory:FilterDataList()
    local list = self._Control:GetSingleStoryList()
    local newList = {}
    
    for _, id in pairs(list) do
        if self._Control:IsShowInView(id) then
            table.insert(newList, id)
        end
    end
    
    return newList
end

function XUiBirthdayPlotSingleStory:SortDataList()
    
    table.sort(self.DataList, function(a, b) 
        local isReadA = self._Control:IsInvited(a)
        local isReadB = self._Control:IsInvited(b)

        if isReadA ~= isReadB then
            return isReadB
        end
        
        local levelA = self._Control:GetFavorAbilityLevel(a)
        local levelB = self._Control:GetFavorAbilityLevel(b)
        if levelA ~= levelB then
            return levelA > levelB
        end
        return a < b
    end)
    
    return self.DataList
end

function XUiBirthdayPlotSingleStory:OnBtnBackClick()
    if not self.NeedPop then
        self:Close()
        return
    end
    self:DoClose(function()
        self:Close()
        XMVCA.XBirthdayPlot:PlayEndMovie()
    end)
end

function XUiBirthdayPlotSingleStory:OnBtnMainClick()
    if not self.NeedPop then
        XLuaUiManager.RunMain()
        return
    end
    self:DoClose(function()
        XLuaUiManager.RunMain()
        XMVCA.XBirthdayPlot:PlayEndMovie()
    end)
end

function XUiBirthdayPlotSingleStory:DoClose(closeCb)
    local needPop = false
    for _, storyId in pairs(self.DataList) do
        --还有角色未邀请
        if not self._Control:IsInvited(storyId) then
            needPop = true
            break
        end
    end
    
    if not needPop then
        closeCb()
        return
    end

    local content = XUiHelper.ReplaceWithPlayerName(XUiHelper.GetText("SingleStoryQuitText"))
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, nil, nil, closeCb)
end

function XUiBirthdayPlotSingleStory:ShowSingleStory(storyId)
    self.SingleStoryPanel:RefreshView(storyId)
end

function XUiBirthdayPlotSingleStory:HideSingleStory()
    self.SingleStoryPanel:Close()
end