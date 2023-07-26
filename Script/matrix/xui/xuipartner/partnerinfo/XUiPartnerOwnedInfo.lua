local XUiPartnerOwnedInfo = XLuaUiManager.Register(XLuaUi, "UiPartnerOwnedInfo")
local XUiGridSkill = require("XUi/XUiPartner/PartnerCommon/XUiGridSkill")
local XUiPanelMainSkill = require("XUi/XUiPartner/PartnerCommon/XUiPanelMainSkill")
local CSTextManagerGetText = CS.XTextManager.GetText
local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal
local DefaultIndex = 1
local SkillGridMaxCount = 6
function XUiPartnerOwnedInfo:OnStart(base)
    self.Base = base
    self.PassiveSkillGrid = {}
    self:SetButtonCallBack()
    self.GridSkill.gameObject:SetActiveEx(false)
    
end

function XUiPartnerOwnedInfo:OnDestroy()

end

function XUiPartnerOwnedInfo:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED, self.ShowPanelSkill, self)
end

function XUiPartnerOwnedInfo:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED, self.ShowPanelSkill, self)
end

function XUiPartnerOwnedInfo:SetButtonCallBack()
    self.BtnRename.CallBack = function()
        self:OnBtnRenameClick()
    end
    self.BtnLevelUp.CallBack = function()
        self:OnBtnLevelUpClick()
    end
    self.BtnPartnerLock.CallBack = function()
        self:OnBtnPartnerLockClick()
    end
end

function XUiPartnerOwnedInfo:OnBtnRenameClick()
    XLuaUiManager.Open("UiPartnerRename", self.Base, self.Data:GetId())
end

function XUiPartnerOwnedInfo:OnBtnLevelUpClick()
    self.Base:ChangeUiState(XPartnerConfigs.MainUiState.Property)
end

function XUiPartnerOwnedInfo:OnBtnPartnerLockClick()
    XDataCenter.PartnerManager.PartnerUpdateLockRequest(self.Data:GetId(), not self.Data:GetIsLock(), function ()
            self.Base:ShowPanel()
        end)
end

function XUiPartnerOwnedInfo:UpdatePanel(data)
    self.Data = data
    if data then
        self.TxtName.text = data:GetName()
        self.TxtAbility.text = data:GetAbility()
        self.TxtType.text = data:GetDesc()
        
        local btImg = data:GetBreakthroughIcon()
        self.ImgBreakthrough:SetSprite(btImg)

        self:ShowLock()
        self:ShowPanelSkill()
        self:PlayAnimation("QieHuan")
    end
end

function XUiPartnerOwnedInfo:ShowPanelSkill()
    local mainSkillList = self.Data:GetCarryMainSkillGroupList()
    local passiveSkillList = self.Data:GetCarryPassiveSkillGroupList()
    local skillCount = self.Data:GetQualitySkillColumnCount()
    local initQuality = self.Data:GetInitQuality()
    
    local panel = self.MainSkillPanel
    if not panel then
        panel = XUiPanelMainSkill.New(self.PanelMainSkill)
        self.MainSkillPanel = panel
    end
    panel:UpdatePanel(mainSkillList[DefaultIndex], self.Data)
    
    for index = 1, SkillGridMaxCount do
        local grid = self.PassiveSkillGrid[index]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridSkill,self.PanelSkillContent)
            obj.gameObject:SetActiveEx(true)
            grid = XUiGridSkill.New(obj)
            self.PassiveSkillGrid[index] = grid
        end
        local IsNone = false
        if index > XPartnerConfigs.PassiveSkillCount then
            IsNone = true
        end
        grid:UpdateGrid(passiveSkillList[index], self.Data, skillCount < index, XPartnerConfigs.SkillType.PassiveSkill, index + 1, IsNone)
    end
end

function XUiPartnerOwnedInfo:ShowLock()
    self.BtnPartnerLock:SetButtonState(self.Data:GetIsLock() and Select or Normal)
    self.BtnPartnerLock.TempState = self.Data:GetIsLock() and Select or Normal
end