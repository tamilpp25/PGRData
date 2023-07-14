
local XUiPartnerPresetMainSkill = XLuaUiManager.Register(XLuaUi, "UiPartnerPresetMainSkill")
local XUiPanelSkillSelect = require("XUi/XUiPartner/PartnerPreset/UiPartnerSkill/XUiPartnerMainSkill/XUiPanelSkillSelect")
local XUiPanelSkillInfo   = require("XUi/XUiPartner/PartnerPreset/UiPartnerSkill/XUiPartnerMainSkill/XUiPanelSkillInfo")

--当前显示的类型
local PanelType = {
    --技能选择页面
    SkillSelectType = 1,
    --详情界面
    SkillInfoType   = 2,
}

function XUiPartnerPresetMainSkill:OnAwake()
    self:InitCb()
end

function XUiPartnerPresetMainSkill:OnStart(partner, partnerPrefab)
    self.Partner = partner
    self.PartnerPrefab = partnerPrefab
    local partnerId = self.Partner:GetId()
    self.IsCarry = partnerPrefab:GetIsCarry(partnerId)
    self.CharacterId = partnerPrefab:GetCharacterId(partnerId)
    self:Init()
    self:GoSkillSelectPanel()
    XDataCenter.PartnerManager.MarkedNewSkillRed(partnerId)
    XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED)
end

function XUiPartnerPresetMainSkill:InitCb()
    self.BtnTanchuangClose.CallBack = function() 
        self:OnBtnCloseClick()
    end
end 

function XUiPartnerPresetMainSkill:Init()
    --在预设界面被携带的，则用缓存的数据
    if self.IsCarry then
        self.SkillGroupList = XDataCenter.PartnerManager.GetPresetSkillList(self.Partner:GetId(), XPartnerConfigs.SkillType.MainSkill)
        --接口理论上返回的只有一个携带的主动技能，如果有多个，则取最后一个
        for _, group in pairs(self.SkillGroupList) do
            self.CurrentGroup = group
            self.InitGroup = group
        end
    else
        self.SkillGroupList = self.Partner:GetMainSkillGroupList()
        for _, group in pairs(self.SkillGroupList) do
            if group:GetIsCarry() then
                self.CurrentGroup = group
                self.InitGroup = group
            end
        end
    end
    
    local funcDict = {
        GetCurrentGroup = handler(self, self.GetCurrentGroup),
        SetCurrentGroup = handler(self, self.SetCurrentGroup),
        GoSkillInfoPanel = handler(self, self.GoSkillInfoPanel),
    }
    
    self.PanelSkillSelect = XUiPanelSkillSelect.New(self.PanelMainSkillOption, self.Partner, self.PartnerPrefab, funcDict)
    self.PanelSkillInfo   = XUiPanelSkillInfo.New(self.PanelElement, self)
end


function XUiPartnerPresetMainSkill:OnBtnCloseClick()
    if self.PanelType == PanelType.SkillSelectType then
        self:DoSkillSelect()
    elseif self.PanelType == PanelType.SkillInfoType then
        self:GoSkillSelectPanel()
    end
end 


function XUiPartnerPresetMainSkill:DoSkillSelect()
    local groupList = self.Partner:GetMainSkillGroupList()
    local skillDict = {}
    for _, group in pairs(groupList or {}) do
        local isWear = self.CurrentGroup 
                and group:GetId() == self.CurrentGroup:GetId() or false
        skillDict[group:GetDefaultActiveSkillId()] = isWear
    end
    
    if self:IsSkillChange() then
        XDataCenter.PartnerManager.RefreshPresetSkillCache(self.Partner:GetId(), skillDict, XPartnerConfigs.SkillType.MainSkill)
        XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_PRESET_SKILL_CHANGE, self.Partner)
    end
    
    self:Close()
end 

function XUiPartnerPresetMainSkill:IsSkillChange()
    return self.InitGroup:GetId() ~= self.CurrentGroup:GetId()
end

function XUiPartnerPresetMainSkill:GoSkillSelectPanel()
    self:ShowPanel(PanelType.SkillSelectType)
end 

function XUiPartnerPresetMainSkill:GoSkillInfoPanel(skillGroup)
    self:ShowPanel(PanelType.SkillInfoType, skillGroup)
end

function XUiPartnerPresetMainSkill:ShowPanel(panelType, skillGroup)
    self.PanelType = panelType
    if panelType == PanelType.SkillSelectType then
        self.PanelSkillSelect:Refresh()
    elseif panelType == PanelType.SkillInfoType then
        self.PanelSkillInfo:Refresh(skillGroup)
    end
    
    XScheduleManager.ScheduleOnce(function()
        if self.PanelType == PanelType.SkillSelectType then
            self:PlayAnimation("QieHuan2")
        elseif self.PanelType == PanelType.SkillInfoType then
            self:PlayAnimation("QieHuan1")
        end
    end, 1)
end 

function XUiPartnerPresetMainSkill:GetCurrentGroup()
    return self.CurrentGroup
end 

function XUiPartnerPresetMainSkill:SetCurrentGroup(group)
    if not group then return end
    self.CurrentGroup = group
end 