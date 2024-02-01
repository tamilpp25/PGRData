local XUiGridPresetSkillElement = XClass(nil, "XUiGridPresetSkillElement")

function XUiGridPresetSkillElement:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)

    self.Activate.gameObject:SetActiveEx(false)
    self.Normal.gameObject:SetActiveEx(true)
    
    self.PanelNormal = {}
    XTool.InitUiObjectByUi(self.PanelNormal, self.Normal)
end

function XUiGridPresetSkillElement:Refresh(skillGroup)
    self.SkillGroup = skillGroup
    local elementConfig = XMVCA.XCharacter:GetCharElement(self.SkillGroup:GetActiveElement())
    
    local panel = self.PanelNormal
    
    panel.RImgIcon:SetRawImage(elementConfig.Icon2)
    panel.TxtName.text = elementConfig.ElementName
    panel.TxtContent.text = self.SkillGroup:GetSkillDesc()
    
end

--=========================================类分界线=========================================--


local XUiPanelSkillInfo = XClass(nil, "XUiPanelSkillInfo")
local XPartnerMainSkillGroup = require("XEntity/XPartner/XPartnerMainSkillGroup")

function XUiPanelSkillInfo:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitDynamicTable()
end

function XUiPanelSkillInfo:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelElementGroup)
    self.DynamicTable:SetProxy(XUiGridPresetSkillElement)
    self.DynamicTable:SetDelegate(self)
    self.GridElement.gameObject:SetActiveEx(false)
end

function XUiPanelSkillInfo:Refresh(skillGroup)
    if not skillGroup then return end

    local elementList = skillGroup:GetElementList()

    self.SkillList = {}
    for _, element in ipairs(elementList) do
        local entity = XPartnerMainSkillGroup.New(skillGroup:GetId())
        local tempData = {}
        tempData.Level = skillGroup:GetLevel()
        tempData.IsLock = skillGroup:GetIsLock()
        tempData.ActiveSkillId = skillGroup:GetSkillIdByElement(element)
        tempData.Type = XPartnerConfigs.SkillType.MainSkill
        entity:UpdateData(tempData)
        table.insert(self.SkillList, entity)
    end
    
    self.DynamicTable:SetDataSource(self.SkillList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelSkillInfo:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.SkillList[index])
    end
end

return XUiPanelSkillInfo