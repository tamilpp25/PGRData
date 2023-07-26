local XUiGuideGainNowGrid = require("XUi/XUiTheatre/FieldGuide/XUiGuideGainNowGrid")

--增益图鉴布局
local XUiPanelGuideGainField = XClass(nil, "XUiPanelGuideGainField")

--clickCb：点击格子回调
--isCurSelectSkillFunc：检查是否当前选中的格子
--powerId：势力Id
function XUiPanelGuideGainField:Ctor(ui, clickCb, isCurSelectSkillFunc, powerId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ClickCallback = clickCb
    self.IsCurSelectSkillFunc = isCurSelectSkillFunc
    self.PowerId = powerId
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.TokenManager = self.TheatreManager.GetTokenManager()

    self:InitDynamicTable()
    self:InitDrdFilter()
end

function XUiPanelGuideGainField:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGuideGainNowGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridNameplate.gameObject:SetActiveEx(false)
end

function XUiPanelGuideGainField:InitDrdFilter()
    self.DrdFilter:ClearOptions()

    local CsDropdown = CS.UnityEngine.UI.Dropdown
    local op = CsDropdown.OptionData()
    local firstText = XUiHelper.GetText("ScreenAll")
    self.DrdFilter.captionText.text = firstText
    op.text = firstText
    self.DrdFilter.options:Add(op)

    local name
    self.PowerConditionIdList = XTheatreConfigs.GetPowerConditionIdList()
    for index, id in ipairs(self.PowerConditionIdList) do
        name = XTheatreConfigs.GetPowerConditionName(id)
        op = CsDropdown.OptionData()
        op.text = name
        self.DrdFilter.options:Add(op)

        if id == self.PowerId then
            self.FilterType = index
            self.DrdFilter.value = index
        end
    end

    self.DrdFilter.onValueChanged:AddListener(function()
        self.FilterType = self.DrdFilter.value
        self:UpdateDynamicTable()
    end)
end

function XUiPanelGuideGainField:UpdateDynamicTable()
    local powerId = self.FilterType and self.PowerConditionIdList[self.FilterType]
    self.TheatreSkillTemplateList = self.TokenManager:GetSkillTemplateList(powerId)
    self.DynamicTable:SetDataSource(self.TheatreSkillTemplateList)
    self.DynamicTable:ReloadDataSync()
    self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TheatreSkillTemplateList))
end

function XUiPanelGuideGainField:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.ClickCallback, self.IsCurSelectSkillFunc)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.TheatreSkillTemplateList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grid = self.DynamicTable:GetGridByIndex(1)
        if grid then
            grid:OnGridBtnClick()
        end
    end
end

function XUiPanelGuideGainField:Show()
    self:UpdateDynamicTable()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelGuideGainField:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelGuideGainField