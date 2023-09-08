local XUiPanelMainSkillOption = XClass(nil, "XUiPanelMainSkillOption")
local XUiGridMainSkill = require("XUi/XUiPartner/PartnerSkillInstall/MainSkill/XUiGridMainSkill")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelMainSkillOption:Ctor(ui, base, partner)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Partner = partner
    XTool.InitUiObject(self)
    self:InitPanel()
    self:InitDynamicTable()
end

function XUiPanelMainSkillOption:InitPanel()
    local charName = CSTextManagerGetText("PartnerNoBadyCarry")
    if self.Partner:GetIsCarry() then
        local charId = self.Partner:GetCharacterId()
        charName = XMVCA.XCharacter:GetCharacterLogName(charId)
        local elementConfig = XCharacterConfigs.GetCharElement(self.Base.CharElement)
        self.ElementIcon:SetRawImage(elementConfig.Icon2)
        self.ElementIcon.gameObject:SetActiveEx(true)
    else
        self.ElementIcon.gameObject:SetActiveEx(false)
    end
    self.TxtName.text = charName
end

function XUiPanelMainSkillOption:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillOptionGroup)
    self.DynamicTable:SetProxy(XUiGridMainSkill)
    self.DynamicTable:SetDelegate(self)
    self.GridSkillOption.gameObject:SetActiveEx(false)
end

function XUiPanelMainSkillOption:UpdatePanel()
    self:SetupDynamicTable()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelMainSkillOption:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelMainSkillOption:SetupDynamicTable()
    local selectIndex = 1
    self.PageDatas = self.Partner:GetMainSkillGroupList()

    local curSkillId = self.Base and self.Base.CurSkillGroup and self.Base.CurSkillGroup:GetId()
    for index,data in pairs(self.PageDatas) do
        if data:GetId() == curSkillId then
            selectIndex = index
            break
        end
    end

    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(selectIndex)
end

function XUiPanelMainSkillOption:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self, self.Base)
    end
end

function XUiPanelMainSkillOption:SelectSkill(skillGroup)
    self.Base:SetCurSkillGroup(skillGroup)
end

function XUiPanelMainSkillOption:SelectPreviewSkill(skillGroup)
    self.Base:SetPreviewSkillGroup(skillGroup)
end

return XUiPanelMainSkillOption