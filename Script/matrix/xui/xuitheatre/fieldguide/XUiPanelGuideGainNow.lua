local XUiGuideGainNowGrid = require("XUi/XUiTheatre/FieldGuide/XUiGuideGainNowGrid")

local CORE_SKILL_COUNT = 4

--当前增益布局
local XUiPanelGuideGainNow = XClass(nil, "XUiPanelGuideGainNow")

function XUiPanelGuideGainNow:Ctor(ui, clickCb, isCurSelectSkillFunc)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ClickCallback = clickCb
    self.IsCurSelectSkillFunc = isCurSelectSkillFunc

    self.UpGrids = {}
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()

    self:InitDynamicTable()
end

function XUiPanelGuideGainNow:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGuideGainNowGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridNameplate.gameObject:SetActiveEx(false)
end

--当前拥有的技能
function XUiPanelGuideGainNow:UpdateDynamicTable()
    self.CurrentSkills = self.AdventureManager and self.AdventureManager:GetCurrentSkills() or {}
    self.DynamicTable:SetDataSource(self.CurrentSkills)
    self.DynamicTable:ReloadDataSync()
    self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.CurrentSkills))
end

function XUiPanelGuideGainNow:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.ClickCallback, self.IsCurSelectSkillFunc)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local skill = self.CurrentSkills[index]
        grid:SetData(skill)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grid = self.DynamicTable:GetGridByIndex(1)
        if grid then
            grid:OnGridBtnClick()
        end
    end
end

--4个核心技能
function XUiPanelGuideGainNow:RefreshCoreSkills()
    for i = 1, CORE_SKILL_COUNT do
        local grid = self.UpGrids[i]
        if not grid then
            local gridObj = i == 1 and self.GridUpNameplate or XUiHelper.Instantiate(self.GridUpNameplate, self.PanelUp)
            grid = XUiGuideGainNowGrid.New(gridObj, true)
            grid:Init(self.ClickCallback, self.IsCurSelectSkillFunc, i)
            self.UpGrids[i] = grid
        end

        grid:SetData(self.AdventureManager:GetCoreSkillByPos(i), true)
    end
end

function XUiPanelGuideGainNow:Show()
    self:UpdateDynamicTable()
    self:RefreshCoreSkills()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelGuideGainNow:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelGuideGainNow