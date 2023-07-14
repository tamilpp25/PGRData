local XUiGridPresetPassiveSkill = XClass(nil, "XUiGridPresetPassiveSkill")

function XUiGridPresetPassiveSkill:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    --采用动态列表点击
   self.BtnAddSelect.gameObject:SetActiveEx(false)
end

function XUiGridPresetPassiveSkill:Refresh(group, isSelect)
    self.SkillGroup = group
    if not group then return end

    local level = group:GetLevelStr()
    self.TxtLevel.text = CS.XTextManager.GetText("PartnerSkillLevelCN",level)
    self.TxtName.text = group:GetSkillName()
    self.TxtContent.text = group:GetSkillDesc()
    self.RImgIcon:SetRawImage(group:GetSkillIcon())
    
    self:SetSelect(isSelect)
end

function XUiGridPresetPassiveSkill:CheckIsSelect()
    return self.IsSelect
end

function XUiGridPresetPassiveSkill:SetSelect(isSelect)
    self.IsSelect = isSelect
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
end

--=========================================类分界线=========================================--


local XUiPartnerPresetPassiveSkill = XLuaUiManager.Register(XLuaUi, "UiPartnerPresetPassiveSkill")

function XUiPartnerPresetPassiveSkill:OnAwake()
    self:InitUi()
    self:InitCb()
    self.InitGroup = {}
end

function XUiPartnerPresetPassiveSkill:OnStart(partner, partnerPrefab)
    self.Partner = partner
    self.PartnerPrefab = partnerPrefab
    self:Init()
end 

function XUiPartnerPresetPassiveSkill:OnEnable()
    self:SetupDynamicTable()
    self:Refresh()
end

function XUiPartnerPresetPassiveSkill:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillDetails)
    self.DynamicTable:SetProxy(XUiGridPresetPassiveSkill, handler(self, self.OnSelect))
    self.DynamicTable:SetDelegate(self)
    self.GridSkillDetail.gameObject:SetActiveEx(false)
end 

function XUiPartnerPresetPassiveSkill:InitCb()
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end 

function XUiPartnerPresetPassiveSkill:Init()
    
    local partnerId = self.Partner:GetId()
    self.IsCarry = self.PartnerPrefab:GetIsCarry(partnerId)
    self.CharacterId = self.PartnerPrefab:GetCharacterId(partnerId)
    self.SelectSkillDict = {}
    
    local groupList
    if self.IsCarry then
        groupList = XDataCenter.PartnerManager.GetPresetSkillList(self.Partner:GetId(), XPartnerConfigs.SkillType.PassiveSkill)
    else
        groupList = self.Partner:GetCarryPassiveSkillGroupList()
    end
    
    for _, group in ipairs(groupList) do
        self.SelectSkillDict[group:GetId()] = group
        self.InitGroup[group:GetId()] = group
    end
    
end

function XUiPartnerPresetPassiveSkill:Refresh()
    local count = 0
    for id, group in pairs(self.SelectSkillDict or {}) do
        if XTool.IsNumberValid(id) and group then
            count = count + 1
        end
    end

    self.TxtCurSkillCount.text = count
    self.TxtMaxSkillCount.text = string.format(" / %d",self.Partner:GetQualitySkillColumnCount())

    self.IsFullSelection = self.Partner:GetQualitySkillColumnCount() <= count
end

function XUiPartnerPresetPassiveSkill:SetupDynamicTable()
    self.SkillList = self.Partner:GetPassiveSkillGroupList()
    self.DynamicTable:SetDataSource(self.SkillList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPartnerPresetPassiveSkill:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local group = self.SkillList[index]
        grid:Refresh(group, self:CheckIsSelect(group:GetId()))
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local group = self.SkillList[index]
        local isSelect = grid:CheckIsSelect()
        self:OnSelect(group, not isSelect)
        grid:SetSelect(self:CheckIsSelect(group:GetId()))
    end
end

function XUiPartnerPresetPassiveSkill:OnSelect(group, isAdd)
    local id = group:GetId()
    if isAdd then
        if self.IsFullSelection then
            XUiManager.TipText("PartnerSelectSkillFull")
            return
        end

        if not self.SelectSkillDict[id] then
            self.SelectSkillDict[id] = group
        end
    else
        if self.SelectSkillDict[id] then
            self.SelectSkillDict[id] = nil
        end
    end
    self:Refresh()
end

function XUiPartnerPresetPassiveSkill:OnBtnCloseClick()
    self:DoSkillSelect()
end 

function XUiPartnerPresetPassiveSkill:DoSkillSelect()
    local groupList = self.Partner:GetPassiveSkillGroupList()
    local skillDict = {}
    for _, group in pairs(groupList) do
        local id = group:GetId()
        local isWear = self:CheckIsSelect(id)
        skillDict[group:GetDefaultActiveSkillId()] = isWear
    end

    if self:IsSkillChange() then
        XDataCenter.PartnerManager.RefreshPresetSkillCache(self.Partner:GetId(), skillDict, XPartnerConfigs.SkillType.PassiveSkill)
        XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_PRESET_SKILL_CHANGE, self.Partner)
    end
    
    self:Close()
end 

function XUiPartnerPresetPassiveSkill:IsSkillChange()
    local countInit = XTool.GetTableCount(self.InitGroup)
    local countSel  = XTool.GetTableCount(self.SelectSkillDict)
    if countInit ~= countSel then
        return true
    end
    for id, _ in pairs(self.SelectSkillDict) do
        if not self.InitGroup[id] then
            return true
        end
    end
    return false
end

function XUiPartnerPresetPassiveSkill:CheckIsSelect(id)
    return self.SelectSkillDict[id] and true or false
end 