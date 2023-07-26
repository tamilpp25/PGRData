--===========================================================================
--v1.28 分阶拆分-XUiPanelQualityPreview-属性成长动态列表：XUiPanelQualityAttributeDynamic
--===========================================================================
local XUiPanelQualityAttributeDynamic = XClass(nil, "XUiPanelQualityAttributeDynamic")
local UiPanelQualityAttributeGrid = require("XUi/XUiCharacter/XUiPanelQualityPreview/XUiPanelQualityPreviewGrid/XUiPanelQualityAttributeGrid")
local AttributeGrade = {
    Before = 1,     --升级前
    After = 2,      --升级后
}
local AttributeShow = {
    Life = 1,
    AttackNormal = 2,
    DefenseNormal = 3,
    Crit = 4,
    Quality = 5
}

function XUiPanelQualityAttributeDynamic:Ctor(ui, attributeData, quality)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.AttributeData = attributeData
    self.Quality = quality

    XTool.InitUiObject(self)
    self.DynamicTable = XDynamicTableNormal.New(ui)
    self.DynamicTable:SetProxy(UiPanelQualityAttributeGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelQualityAttributeDynamic:RefreshData(attributeData, quality)
    self.AttributeData = attributeData
    self.Quality = quality
end

function XUiPanelQualityAttributeDynamic:UpdateDynamicTable(index)
    if not index then index = 1 end
    self.DynamicTable:SetDataSource(self.AttributeData)
    self.DynamicTable:ReloadDataASync(index)
end

function XUiPanelQualityAttributeDynamic:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local isSelect = self.Quality == self.AttributeData[index][AttributeGrade.Before][AttributeShow.Quality]
        local isMax = false
        -- 满级特殊处理
        if index == #self.AttributeData then
            isMax = self.Quality == self.AttributeData[index][AttributeGrade.After][AttributeShow.Quality]
        end
        grid:Refresh(self.AttributeData[index], isSelect, isMax)
    end
end

return XUiPanelQualityAttributeDynamic