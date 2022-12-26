local XUiPartnerActivateMainSkill = XLuaUiManager.Register(XLuaUi, "UiPartnerActivateMainSkill")

local XUiPanelMainSkillOption = require("XUi/XUiPartner/PartnerSkillInstall/MainSkill/XUiPanelMainSkillOption")
local XUiPanelElement = require("XUi/XUiPartner/PartnerSkillInstall/MainSkill/XUiPanelElement")

local PanelState = {
    SkillOption = 1,
    Element = 2,
}

local CSTextManagerGetText = CS.XTextManager.GetText
local DefaultIndex = 1

function XUiPartnerActivateMainSkill:OnStart(partner)
    self.Partner = partner
    self:SetButtonCallBack()
    self:Init()
    self:GoSkillOptionView()
    XDataCenter.PartnerManager.MarkedNewSkillRed(self.Partner:GetId())
    XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED)
end

function XUiPartnerActivateMainSkill:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_SKILLCHANGE, self.CloseMask, self)
end

function XUiPartnerActivateMainSkill:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_SKILLCHANGE, self.CloseMask, self)
end

function XUiPartnerActivateMainSkill:SetButtonCallBack()
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiPartnerActivateMainSkill:Init()
    self.SkillGroupList = self.Partner:GetMainSkillGroupList()

    for index,skillgroup in pairs(self.SkillGroupList) do
        if skillgroup:GetIsCarry() then
            self.CurSkillGroup = skillgroup
            self.PreviewSkillGroup = skillgroup
            break
        end
    end
    
    if self.Partner:GetIsCarry() then
        local charId = self.Partner:GetCharacterId()
        self.CharElement = XCharacterConfigs.GetCharacterElement(charId)
    end
    
    self.SkillOptionPanel = XUiPanelMainSkillOption.New(self.PanelMainSkillOption, self, self.Partner)
    self.ElementPanel = XUiPanelElement.New(self.PanelElement, self)
end


function XUiPartnerActivateMainSkill:SetPanelState(state)
    self.PanelState = state
end


function XUiPartnerActivateMainSkill:ShowPanel()
    --self.SkillOptionPanel:HidePanel()
    --self.ElementPanel:HidePanel()

    if self.PanelState == PanelState.SkillOption then
        self.SkillOptionPanel:UpdatePanel()
    elseif self.PanelState == PanelState.Element then
        self.ElementPanel:UpdatePanel()
    end
    self:PlayEnableAnime()
end

function XUiPartnerActivateMainSkill:SetCurSkillGroup(skillGroup)
    self.CurSkillGroup = skillGroup
end

function XUiPartnerActivateMainSkill:SetPreviewSkillGroup(skillGroup)
    self.PreviewSkillGroup = skillGroup
end

function XUiPartnerActivateMainSkill:OnBtnCloseClick()
    if self.PanelState == PanelState.SkillOption then
        self:DoSkillSelect()
    elseif self.PanelState == PanelState.Element then
        self:GoSkillOptionView()
    end
end

function XUiPartnerActivateMainSkill:DoSkillSelect()
    local IsChange = false
    local oldCarrySkillGroup = {}
    IsChange, oldCarrySkillGroup = self:CheckIsSkillChange()

    if IsChange then
        self:OpenMask()
        oldCarrySkillGroup:UpdateData({IsCarry = not oldCarrySkillGroup:GetIsCarry()})
        XDataCenter.PartnerManager.PartnerSkillWearRequest(self.Partner:GetId(),
            {[self.CurSkillGroup:GetActiveSkillId()] = true},
            XPartnerConfigs.SkillType.MainSkill,
            function ()
                oldCarrySkillGroup:UpdateData({IsCarry = not oldCarrySkillGroup:GetIsCarry()})
                self:CloseMask()
            end)
    else
        self:Close()
    end
end

function XUiPartnerActivateMainSkill:CheckIsSkillChange()
    local mainSkillGrouplist = self.SkillGroupList
    local changeSkillDic = {}
    local IsChange = false
    local oldCarrySkillGroup = {}
    for _,skillGroup in pairs(mainSkillGrouplist) do
        if not skillGroup:GetIsCarry() then
            if self.CurSkillGroup:GetId() == skillGroup:GetId() then
                IsChange = true
            end
        else
            oldCarrySkillGroup = skillGroup
        end
    end

    return IsChange, oldCarrySkillGroup
end

function XUiPartnerActivateMainSkill:OpenMask()
    if not self.IsSendMeg then
        XLuaUiManager.SetMask(true)
        self.IsSendMeg = true
    end
end

function XUiPartnerActivateMainSkill:CloseMask()
    if self.IsSendMeg then
        XLuaUiManager.SetMask(false)
        self.IsSendMeg = false
        self:Close()
    end
end

function XUiPartnerActivateMainSkill:GoElementView()
    self:SetPanelState(PanelState.Element)
    self:ShowPanel()
end

function XUiPartnerActivateMainSkill:GoSkillOptionView()
    self:SetPanelState(PanelState.SkillOption)
    self:ShowPanel()
end

function XUiPartnerActivateMainSkill:PlayEnableAnime()
    XScheduleManager.ScheduleOnce(function()
            if self.PanelState == PanelState.SkillOption then
                self:PlayAnimation("QieHuan2")
            elseif self.PanelState == PanelState.Element then
                self:PlayAnimation("QieHuan1")
            end
        end, 1)
end