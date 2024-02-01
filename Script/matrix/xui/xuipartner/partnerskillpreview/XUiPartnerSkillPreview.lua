local XUiPartnerSkillPreview = XLuaUiManager.Register(XLuaUi, "UiPartnerSkillPreview")
local XUiGridSkillDesc = require("XUi/XUiPartner/PartnerSkillPreview/XUiGridSkillDesc")
local XPartnerMainSkillGroup = require("XEntity/XPartner/XPartnerMainSkillGroup")
local XPartnerPassiveSkillGroup = require("XEntity/XPartner/XPartnerPassiveSkillGroup")

local CSTextManagerGetText = CS.XTextManager.GetText
local DefaultIndex = 1

function XUiPartnerSkillPreview:OnStart(skillGroupList, skillType)
    self.SkillGroupList = skillGroupList
    self.SkillType = skillType
    self:SetButtonCallBack()
    self:InitBtnGroup()
    self:InitDynamicTable()
    
end

function XUiPartnerSkillPreview:OnEnable()
    self:UpdateSkillOptionBtnGroup()

end

function XUiPartnerSkillPreview:OnDisable()

end

function XUiPartnerSkillPreview:InitBtnGroup()
    self.BtnSkillOptionList = {}
    self.BtnElementList = {}
    self.BtnSkillOption.gameObject:SetActiveEx(false)
    self.BtnElement.gameObject:SetActiveEx(false)
    self.CurSkillIndex = DefaultIndex
    self.CurElementIndex = DefaultIndex
    
    for index,skillgroup in pairs(self.SkillGroupList) do
        if skillgroup:GetIsCarry() then
            self.CurSkillIndex = index
            if self.SkillType == XPartnerConfigs.SkillType.MainSkill then
                local skillId = skillgroup:GetActiveSkillId()
                self.CurElementIndex = skillgroup:GetElementIndexBySkillId(skillId)
            end
            break
        end
    end
end

function XUiPartnerSkillPreview:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiPartnerSkillPreview:UpdateSkillOptionBtnGroup()
    for index,skillgroup in pairs(self.SkillGroupList) do
        local btn = self.BtnSkillOptionList[index]
        if not btn then
            local obj = CS.UnityEngine.Object.Instantiate(self.BtnSkillOption, self.PanelBtnSkillOptionGroup.transform)
            obj.gameObject:SetActiveEx(true)
            btn = obj:GetComponent("XUiButton")
            self.BtnSkillOptionList[index] = btn
        end
        
        btn:SetName(skillgroup:GetSkillName())
        btn:SetRawImage(skillgroup:GetSkillIcon())
        btn:ShowTag(skillgroup:GetIsLock())
    end
    self.PanelBtnSkillOptionGroup:Init(self.BtnSkillOptionList, function(index) self:SelectSkill(index) end)
    self.PanelBtnSkillOptionGroup:SelectIndex(self.CurSkillIndex)
end

function XUiPartnerSkillPreview:SelectSkill(index)
    self.CurSkillIndex = index
    self:UpdateElementBtnGroup()
end

function XUiPartnerSkillPreview:UpdateElementBtnGroup()
    if self.SkillType == XPartnerConfigs.SkillType.MainSkill then
        local skillgroup = self.SkillGroupList[self.CurSkillIndex]
        local elementList = skillgroup:GetElementList()
        self.CurElementIndex = self.CurElementIndex <= #elementList and self.CurElementIndex or DefaultIndex
        
        for index,element in pairs(elementList) do
            local btn = self.BtnElementList[index]
            if not btn then
                local obj = CS.UnityEngine.Object.Instantiate(self.BtnElement, self.PanelBtnElementGroup.transform)
                obj.gameObject:SetActiveEx(true)
                btn = obj:GetComponent("XUiButton")
                self.BtnElementList[index] = btn
            end
            local elementConfig = XMVCA.XCharacter:GetCharElement(element)
            btn:SetName(elementConfig.ElementName)
            btn:SetRawImage(elementConfig.Icon2)
        end
        
        self.PanelBtnElementGroup:Init(self.BtnElementList, function(index) self:SelectElement(index) end)
        self.PanelBtnElementGroup:SelectIndex(self.CurElementIndex)
        self.PanelBtnElementGroup.gameObject:SetActiveEx(true)
    else
        self.PanelBtnElementGroup.gameObject:SetActiveEx(false)
        self:SetupDynamicTable()
    end
end

function XUiPartnerSkillPreview:SelectElement(index)
    self.CurElementIndex = index
    self:SetupDynamicTable()
    self:PlayAnimation("QieHuan")
end

function XUiPartnerSkillPreview:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillDescList)
    self.DynamicTable:SetProxy(XUiGridSkillDesc)
    self.DynamicTable:SetDelegate(self)
    self.GridSkillDesc.gameObject:SetActiveEx(false)
end

function XUiPartnerSkillPreview:SetupDynamicTable()
    self.PageDatas = {}
    local skillGroup = self.SkillGroupList[self.CurSkillIndex]
    if self.SkillType == XPartnerConfigs.SkillType.MainSkill then
        for level = 1,skillGroup:GetLevelLimit() do
            local entity = XPartnerMainSkillGroup.New(skillGroup:GetId())
            local tmpData = {}
            tmpData.Level = level
            tmpData.IsLock = skillGroup:GetIsLock()
            tmpData.ActiveSkillId = skillGroup:GetSkillIdByElementIndex(self.CurElementIndex)
            tmpData.Type = self.SkillType
            entity:UpdateData(tmpData)
            table.insert(self.PageDatas,entity)
        end
    elseif self.SkillType == XPartnerConfigs.SkillType.PassiveSkill then
        for level = 1,skillGroup:GetLevelLimit() do
            local entity = XPartnerPassiveSkillGroup.New(skillGroup:GetId())
            local tmpData = {}
            tmpData.Level = level
            tmpData.IsLock = skillGroup:GetIsLock()
            tmpData.ActiveSkillId = skillGroup:GetActiveSkillId()
            tmpData.Type = self.SkillType
            entity:UpdateData(tmpData)
            table.insert(self.PageDatas,entity)
        end
    end
    
    local selectIndex = 1
    for index,data in pairs(self.PageDatas) do
        if skillGroup:GetLevel() == data:GetLevel() then
            selectIndex = index
            break
        end
    end
    
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(selectIndex)
end

function XUiPartnerSkillPreview:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local curLevel = self.SkillGroupList[self.CurSkillIndex]:GetLevel()
        grid:UpdateGrid(self.PageDatas[index], curLevel)
    end
end

function XUiPartnerSkillPreview:OnBtnCloseClick()
    self:Close()
end