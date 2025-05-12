local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelElement = XClass(nil, "XUiPanelElement")
local XUiGridSkillElement = require("XUi/XUiPartner/PartnerSkillInstall/MainSkill/XUiGridSkillElement")
local XPartnerMainSkillGroup = require("XEntity/XPartner/XPartnerMainSkillGroup")

function XUiPanelElement:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:InitDynamicTable()
end

function XUiPanelElement:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelElementGroup)
    self.DynamicTable:SetProxy(XUiGridSkillElement)
    self.DynamicTable:SetDelegate(self)
    self.GridElement.gameObject:SetActiveEx(false)
end

function XUiPanelElement:UpdatePanel()
    self:SetupDynamicTable()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelElement:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelElement:SetupDynamicTable()
    local selectIndex = 1
    local skillGroup = self.Base.PreviewSkillGroup
    local elementList = skillGroup:GetElementList()
    
    self.PageDatas = {}
    for _,element in pairs(elementList or {}) do
        local entity = XPartnerMainSkillGroup.New(skillGroup:GetId())
        local tmpData = {}
        tmpData.Level = skillGroup:GetLevel()
        tmpData.IsLock = skillGroup:GetIsLock()
        tmpData.ActiveSkillId = skillGroup:GetSkillIdByElement(element)
        tmpData.Type = XPartnerConfigs.SkillType.MainSkill
        entity:UpdateData(tmpData)
        table.insert(self.PageDatas,entity)
    end
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(selectIndex)
end

function XUiPanelElement:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self.Base.CharElement)
    end
end

return XUiPanelElement