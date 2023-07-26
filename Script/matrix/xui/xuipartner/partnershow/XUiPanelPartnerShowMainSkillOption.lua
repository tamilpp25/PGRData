--########################## XUiGridPartnerShowMainSkillOption ##############################
local XUiGridPartnerShowMainSkillOption = XClass(nil, "XUiGridPartnerShowMainSkillOption")

function XUiGridPartnerShowMainSkillOption:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.DetailClickFunc = nil
    -- XPartnerMainSkillGroup
    self.Skill = nil
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    -- 默认隐藏选择按钮
    local showBtnSelect = self.Normal.gameObject:FindGameObject("BtnSelect2")
    if showBtnSelect then
        showBtnSelect:SetActiveEx(false)
    end
end

-- skill : XPartnerMainSkillGroup
function XUiGridPartnerShowMainSkillOption:DynamicSetData(skill, isSelected, detailClickFunc)
    self.Skill = skill
    self.DetailClickFunc = detailClickFunc
    self.Normal.gameObject:SetActiveEx(not isSelected)
    self.Select.gameObject:SetActiveEx(isSelected)
    local rootPanel = isSelected and self.Select or self.Normal
    rootPanel:GetObject("TxtContent").text = skill:GetSkillDesc()
    rootPanel:GetObject("RImgIcon"):SetRawImage(skill:GetSkillIcon())
    rootPanel:GetObject("TxtName").text = skill:GetSkillName()
    rootPanel:GetObject("TxtLevel").text = CS.XTextManager.GetText("PartnerSkillLevelEN", skill:GetLevelStr())
end

--########################## 私有方法 ##############################

function XUiGridPartnerShowMainSkillOption:RegisterUiEvents()
    self.BtnDetail.CallBack = function() self:OnBtnDetailClicked() end
end

function XUiGridPartnerShowMainSkillOption:OnBtnDetailClicked()
    if self.DetailClickFunc then
        self.DetailClickFunc(self.Skill)
    end
end

--########################## XUiPanelPartnerShowMainSkillOption ##############################
local XUiPanelPartnerShowMainSkillOption = XClass(nil, "XUiPanelPartnerShowMainSkillOption")

function XUiPanelPartnerShowMainSkillOption:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- 重定义名称
    self.RImgElementIcon = self.ElementIcon
    -- XPartnerMainSkillGroup
    self.Skill = nil
    -- XPartner
    self.Partner = nil
    self.DetailClickFunc = nil
    -- XPartnerMainSkillGroup list
    self.MainSkillGroups = nil
    self.SelectedSkillIndex = nil
    -- 初始化动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillOptionGroup)
    self.DynamicTable:SetProxy(XUiGridPartnerShowMainSkillOption)
    self.DynamicTable:SetDelegate(self)
    self.GridSkillOption.gameObject:SetActiveEx(false)
end

-- skill : XPartnerMainSkillGroup
-- partner : XPartner
function XUiPanelPartnerShowMainSkillOption:SetData(skill, partner, detailClickFunc)
    self.Skill = skill
    self.Partner = partner
    self.DetailClickFunc = detailClickFunc
    self.TxtTitle.text = CS.XTextManager.GetText("PartnerMainSkill")
    -- 携带角色名称
    self.TxtName.text = self:GetCharacterName()
    -- 属性图标
    local elementResult = self:GetCharacterElementIcon()
    if elementResult then
        self.RImgElementIcon:SetRawImage(elementResult)
    else
        self.RImgElementIcon.gameObject:SetActiveEx(false)
    end
    -- 动态列表
    self:RefreshDynamicTable()
end

--########################## 私有方法 ##############################

function XUiPanelPartnerShowMainSkillOption:RefreshDynamicTable()
    -- XPartnerMainSkillGroup list
    self.MainSkillGroups = self.Partner:GetMainSkillGroupList()
    -- 获取被选中的技能
    self.SelectedSkillIndex = 1
    for index, data in ipairs(self.MainSkillGroups) do
        if data:GetId() == self.Skill:GetId() then
            self.SelectedSkillIndex = index
            break
        end
    end
    self.DynamicTable:SetDataSource(self.MainSkillGroups)
    self.DynamicTable:ReloadDataSync(self.SelectedSkillIndex)
end

function XUiPanelPartnerShowMainSkillOption:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:DynamicSetData(self.MainSkillGroups[index], index == self.SelectedSkillIndex, self.DetailClickFunc)
    end
end

function XUiPanelPartnerShowMainSkillOption:GetCharacterName()
    local result = CS.XTextManager.GetText("PartnerNoBadyCarry")
    if self.Partner:GetIsCarry() then
        result = XCharacterConfigs.GetCharacterLogName(self.Partner:GetCharacterId())
    end
    return result
end

function XUiPanelPartnerShowMainSkillOption:GetCharacterElementIcon()
    local result
    if self.Partner:GetIsCarry() then
        local element = XCharacterConfigs.GetCharacterElement(self.Partner:GetCharacterId())
        result = XCharacterConfigs.GetCharElement(element).Icon2
    end
    return result
end

return XUiPanelPartnerShowMainSkillOption