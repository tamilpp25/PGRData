XUiPanelFavorabilityPlot = XClass(nil, "XUiPanelFavorabilityPlot")
--记录剧情标签进度条的位置，看完剧情后保持进度条的位置不变
local anchoredPosition

function XUiPanelFavorabilityPlot:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.GridLikePlotItem.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
end



function XUiPanelFavorabilityPlot:RefreshDatas()
    self:LoadDatas()
end

function XUiPanelFavorabilityPlot:LoadDatas()
    local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local plotDatas = XFavorabilityConfigs.GetCharacterStoryById(currentCharacterId)
    self:UpdatePlotList(plotDatas)
end

function XUiPanelFavorabilityPlot:UpdatePlotList(poltList)

    if not poltList then
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.TxtNoDataTip.text = CS.XTextManager.GetText("FavorabilityNoPlotData")
        self.PoltList = { }
    else
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self:SortPlots(poltList)
        self.PoltList = poltList
    end

    if not self.DynamicTablePolt then
        self.DynamicTablePolt = XDynamicTableNormal.New(self.SViewPlotList.gameObject)
        self.DynamicTablePolt:SetProxy(XUiGridLikePlotItem)
        self.DynamicTablePolt:SetDelegate(self)
    end

    self.DynamicTablePolt:SetDataSource(self.PoltList)
    self.DynamicTablePolt:ReloadDataASync()
end

function XUiPanelFavorabilityPlot:SortPlots(plotList)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    for _, plot in pairs(plotList) do
        local isUnlock = XDataCenter.FavorabilityManager.IsStoryUnlock(characterId, plot.Id)
        local canUnlock = XDataCenter.FavorabilityManager.CanStoryUnlock(characterId, plot.Id)
        plot.priority = 2
        if not isUnlock then
            plot.priority = canUnlock and 1 or 3
        end
    end
    table.sort(plotList, function(plotA, plotB)
        if plotA.priority == plotB.priority then
            return plotA.Id < plotB.Id
        else
            return plotA.priority < plotB.priority
        end
    end)
end

function XUiPanelFavorabilityPlot:GetAnchoredPosition()
    return anchoredPosition
end

function XUiPanelFavorabilityPlot:UpdateAnchoredPosition(pos)
    anchoredPosition = pos
end

function XUiPanelFavorabilityPlot:SetAnchoredPosition()
    if not self.SViewPlotList then
        anchoredPosition = nil
        return
    end
    local position = self.SViewPlotList.content
    self:UpdateAnchoredPosition(position.anchoredPosition)
end

function XUiPanelFavorabilityPlot:RefreshScroll()
    if not self.SViewPlotList  or not anchoredPosition then
        return
    end
    local position = self.SViewPlotList.content
    position.anchoredPosition = anchoredPosition
    anchoredPosition = nil
end

-- [列表事件]
function XUiPanelFavorabilityPlot:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.PoltList[index]
        if data ~= nil then
            grid:OnRefresh(data, index)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurPolt = self.PoltList[index]
        if not self.CurPolt then return end
        self:OnPlotClick(self.CurPolt, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:RefreshScroll()
    end
end

-- [剧情条目点击事件]
function XUiPanelFavorabilityPlot:OnPlotClick(plotData, grid)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = XDataCenter.FavorabilityManager.IsStoryUnlock(characterId, plotData.Id)
    local canUnlock = XDataCenter.FavorabilityManager.CanStoryUnlock(characterId, plotData.Id)

    if isUnlock then
        self.UiRoot:StopCvContent()
        self.UiRoot.FavorabilityMain.FavorabilityAudio:UnScheduleAudio()
        self.UiRoot.SignBoard:SetRoll(false)
        self.UiRoot.SignBoard:Freeze()
        --保存当前的位置
        self:SetAnchoredPosition()
        XDataCenter.MovieManager.PlayMovie(plotData.StoryId, function()
            self.UiRoot.SignBoard:SetRoll(true)
            self.UiRoot.SignBoard:Resume()
        end)
    elseif canUnlock then
        self.UiRoot:StopCvContent()
        self.UiRoot.FavorabilityMain.FavorabilityAudio:UnScheduleAudio()
        grid:HideRedDot()
        XDataCenter.FavorabilityManager.OnUnlockCharacterStory(characterId, plotData.Id)
        XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_PLOTUNLOCK)
        self.UiRoot.SignBoard:SetRoll(false)
        self.UiRoot.SignBoard:Freeze()
        --保存当前的位置
        self:SetAnchoredPosition()
        XDataCenter.MovieManager.PlayMovie(plotData.StoryId, function()
            self.UiRoot.SignBoard:SetRoll(true)
            self.UiRoot.SignBoard:Resume()
        end)
    else
        XUiManager.TipMsg(plotData.ConditionDescript)
    end
end

function XUiPanelFavorabilityPlot:SetViewActive(isActive)
    self.GameObject:SetActive(isActive)
    if isActive then
        self:RefreshDatas()
    end
end

function XUiPanelFavorabilityPlot:OnSelected(isSelected)
    self.GameObject:SetActive(isSelected)
    if isSelected then
        self:RefreshDatas()
    end
end


return XUiPanelFavorabilityPlot