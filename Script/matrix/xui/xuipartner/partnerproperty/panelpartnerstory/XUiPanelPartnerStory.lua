local XUiPanelPartnerStory = XClass(nil, "XUiPanelPartnerStory")
local XUiGridStoryInfo = require("XUi/XUiPartner/PartnerProperty/PanelPartnerStory/XUiGridStoryInfo")

function XUiPanelPartnerStory:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:InitDynamicTable()
end

function XUiPanelPartnerStory:UpdatePanel(data)
    self.Data = data
    self.StoryGridState = {}
    self:SetupDynamicTable(data)
    self.GameObject:SetActiveEx(true)
    self:PlayEnableAnime()
end

function XUiPanelPartnerStory:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelPartnerStory:InitDynamicTable()
    self.DynamicTable = XDynamicTableIrregular.New(self.PanelDataList)
    self.DynamicTable:SetDynamicEventDelegate(function(event, index, grid)
            self:OnDynamicTableEvent(event, index, grid)
        end)
    self.DynamicTable:SetProxy("XUiGridStoryInfo", XUiGridStoryInfo, self.GridStoryInfo.gameObject)
    self.DynamicTable:SetDelegate(self)
    self.GridStoryInfo.gameObject:SetActiveEx(false)
end

function XUiPanelPartnerStory:GetProxyType()
    return "XUiGridStoryInfo"
end

function XUiPanelPartnerStory:SetupDynamicTable(data)
    XScheduleManager.ScheduleOnce(function()--异形屏适配需要
            self.PageDatas = data:GetStoryEntityList()
            self.DynamicTable:SetDataSource(self.PageDatas)
            self.DynamicTable:ReloadDataSync(1)
        end, 1)

end

function XUiPanelPartnerStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index],self.StoryGridState)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnGridClick(self.PageDatas[index])
    end
end

function XUiPanelPartnerStory:OnGridClick(storyData)
    if storyData:GetIsLock() then
        XUiManager.TipMsg(storyData:GetConditionDesc())
        return
    end
    if storyData then
        if self.OldId and self.OldId ~= storyData:GetId() then
            self.StoryGridState[self.OldId] = false
        end
        self.StoryGridState[storyData:GetId()] = self.StoryGridState[storyData:GetId()] or false
        self.StoryGridState[storyData:GetId()] = not self.StoryGridState[storyData:GetId()]
        self.DynamicTable:ReloadDataSync()
        self.OldId = storyData:GetId()
    end

end

function XUiPanelPartnerStory:PlayEnableAnime()
    XScheduleManager.ScheduleOnce(function()
            self.Animation:GetObject("AnimEnable"):PlayTimelineAnimation()
        end, 1)
end

return XUiPanelPartnerStory
