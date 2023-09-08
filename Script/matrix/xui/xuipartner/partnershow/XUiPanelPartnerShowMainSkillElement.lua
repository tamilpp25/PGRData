--########################## XUiGridPartnerShowMainSkillElement ##############################
local XUiGridPartnerShowMainSkillElement = XClass(nil, "XUiGridPartnerShowMainSkillElement")

function XUiGridPartnerShowMainSkillElement:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- skill : XPartnerMainSkillGroup
function XUiGridPartnerShowMainSkillElement:DynamicSetData(skill, isSelected)
    local elementConfig = XCharacterConfigs.GetCharElement(skill:GetActiveElement())
    self.Activate.gameObject:SetActiveEx(isSelected)
    self.Normal.gameObject:SetActiveEx(not isSelected)
    local rootPanel = isSelected and self.Activate or self.Normal
    rootPanel:GetObject("TxtContent").text = skill:GetSkillDesc()
    rootPanel:GetObject("RImgIcon"):SetRawImage(elementConfig.Icon2)
    rootPanel:GetObject("TxtName").text = elementConfig.ElementName
end

--########################## XUiPanelPartnerShowMainSkillElement ##############################
local XUiPanelPartnerShowMainSkillElement = XClass(nil, "XUiPanelPartnerShowMainSkillElement")

function XUiPanelPartnerShowMainSkillElement:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    -- XPartnerMainSkillGroup
    self.Skill = nil
    self.CharacterElement = nil
    -- XPartnerMainSkillGroup list
    self.ElementSkills = nil
    XTool.InitUiObject(self)
    -- 初始化动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelElementGroup)
    self.DynamicTable:SetProxy(XUiGridPartnerShowMainSkillElement)
    self.DynamicTable:SetDelegate(self)
    self.GridElement.gameObject:SetActiveEx(false)
end

-- skill : XPartnerMainSkillGroup
-- partner : XPartner
function XUiPanelPartnerShowMainSkillElement:SetData(partner, skill)
    self.Skill = skill
    if partner:GetIsCarry() then
        self.CharacterElement = XMVCA.XCharacter:GetCharacterElement(partner:GetCharacterId())
    end
    -- 刷新列表
    self:RefreshDynamicTable()
end

--########################## 私有方法 ##############################

function XUiPanelPartnerShowMainSkillElement:RefreshDynamicTable()
    self.ElementSkills = self.Skill:GetSelfElementSkillS()
    local selectIndex = 1
    for index, skill in ipairs(self.ElementSkills) do
        if skill:GetActiveElement() == self.CharacterElement then
            selectIndex = index
            break
        end
    end
    self.DynamicTable:SetDataSource(self.ElementSkills)
    self.DynamicTable:ReloadDataSync(selectIndex)
end

function XUiPanelPartnerShowMainSkillElement:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:DynamicSetData(self.ElementSkills[index], self.ElementSkills[index]:GetActiveElement() == self.CharacterElement)
    end
end

return XUiPanelPartnerShowMainSkillElement