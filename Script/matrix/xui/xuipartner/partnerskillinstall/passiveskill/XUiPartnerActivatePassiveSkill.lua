local XUiPartnerActivatePassiveSkill = XLuaUiManager.Register(XLuaUi, "UiPartnerActivatePassiveSkill")
local XUiGridPassiveSkill = require("XUi/XUiPartner/PartnerSkillInstall/PassiveSkill/XUiGridPassiveSkill")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPartnerActivatePassiveSkill:OnStart(partner)
    self.Partner = partner
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitPanel()
    self.IsSendMeg = false
end

function XUiPartnerActivatePassiveSkill:OnEnable()
    self:SetupDynamicTable()
    self:UpdatePanel()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_SKILLCHANGE, self.CloseMask, self)

end

function XUiPartnerActivatePassiveSkill:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_SKILLCHANGE, self.CloseMask, self)

end

function XUiPartnerActivatePassiveSkill:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiPartnerActivatePassiveSkill:InitPanel()
    self.SelectSkillDic = {}
    local carryPassiveSkillGroupList = self.Partner:GetCarryPassiveSkillGroupList()
    for _,skillGroup in pairs(carryPassiveSkillGroupList) do
        self.SelectSkillDic[skillGroup:GetId()] = skillGroup
    end
end

function XUiPartnerActivatePassiveSkill:UpdatePanel()
    local count = 0
    for _,_ in pairs(self.SelectSkillDic or {}) do
        count = count + 1
    end
    
    self.TxtCurSkillCount.text = count
    self.TxtMaxSkillCount.text = string.format(" / %d",self.Partner:GetQualitySkillColumnCount())
    
    self.IsSelectCountFull = self.Partner:GetQualitySkillColumnCount() <= count
end

function XUiPartnerActivatePassiveSkill:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillDetails)
    self.DynamicTable:SetProxy(XUiGridPassiveSkill)
    self.DynamicTable:SetDelegate(self)
    self.GridSkillDetail.gameObject:SetActiveEx(false)
end

function XUiPartnerActivatePassiveSkill:SetupDynamicTable()
    self.PageDatas = self.Partner:GetPassiveSkillGroupList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiPartnerActivatePassiveSkill:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
    end
end

function XUiPartnerActivatePassiveSkill:SetSelectSkill(entity, IsAdd)
    if IsAdd then
        if self.IsSelectCountFull then
            XUiManager.TipText("PartnerSelectSkillFull")
            return
        end

        if not self.SelectSkillDic[entity:GetId()] then
            self.SelectSkillDic[entity:GetId()] = entity
        end
    else
        if self.SelectSkillDic[entity:GetId()] then
            self.SelectSkillDic[entity:GetId()] = nil
        end
    end
    
    self:UpdatePanel()
end

function XUiPartnerActivatePassiveSkill:CheckIsSelectSkill(id)
    return self.SelectSkillDic[id] and true or false
end

function XUiPartnerActivatePassiveSkill:CheckIsSkillChange()
    local passiveSkillGrouplist = self.Partner:GetPassiveSkillGroupList()
    local changeSkillDic = {}
    local IsChange = false
    for _,skillGroup in pairs(passiveSkillGrouplist) do
        if not skillGroup:GetIsCarry() then
            if self.SelectSkillDic[skillGroup:GetId()] then
                changeSkillDic[skillGroup:GetActiveSkillId()] = true
                IsChange = true
            end
        else
            if not self.SelectSkillDic[skillGroup:GetId()] then
                changeSkillDic[skillGroup:GetActiveSkillId()] = false
                IsChange = true
            end
        end
    end
    
    return IsChange, changeSkillDic
end

function XUiPartnerActivatePassiveSkill:OnBtnCloseClick()
    local IsChange = false
    local changeSkillDic = {}
    
    IsChange, changeSkillDic = self:CheckIsSkillChange()
    
    if IsChange then
        self:OpenMask()
        XDataCenter.PartnerManager.PartnerSkillWearRequest(self.Partner:GetId(), 
            changeSkillDic, 
            XPartnerConfigs.SkillType.PassiveSkill,
            function ()
                self:CloseMask()
            end)
    else
        self:Close()
    end
end

function XUiPartnerActivatePassiveSkill:OpenMask()
    if not self.IsSendMeg then
        XLuaUiManager.SetMask(true)
        self.IsSendMeg = true
    end
end

function XUiPartnerActivatePassiveSkill:CloseMask()
    if self.IsSendMeg then
        XLuaUiManager.SetMask(false)
        self.IsSendMeg = false
        self:Close()
    end
end