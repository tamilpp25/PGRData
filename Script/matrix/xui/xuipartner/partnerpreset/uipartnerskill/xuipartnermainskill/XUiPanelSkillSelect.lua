
local XUiGridPresetMainSkill = XClass(nil, "XUiGridPresetMainSkill")
local GridState = {
    Normal = 1,
    Select = 2,
    Locked = 3
}

function XUiGridPresetMainSkill:Ctor(ui, onSelect, goSkillInfo)
    XTool.InitUiObjectByUi(self, ui)
    self.NormalPanel = {}
    self.SelectPanel = {}
    self.LockedPanel = {}
    self.State = GridState.Normal
    self.OnSelect = onSelect
    self.GoSkillInfo = goSkillInfo
    
    XTool.InitUiObjectByUi(self.NormalPanel, self.Normal)
    XTool.InitUiObjectByUi(self.SelectPanel, self.Select)
    XTool.InitUiObjectByUi(self.LockedPanel, self.Lock)
    
    self:AddListener()
end

function XUiGridPresetMainSkill:AddListener()
    local selectFunc = function()
        if self.OnSelect then
            self.OnSelect(self.SkillGroup)
        end
    end
    
    self.BtnSelect.CallBack = selectFunc
    self.BtnSelect2.CallBack = selectFunc

    self.BtnDetail.CallBack = function()
        if self.GoSkillInfo then
            self.GoSkillInfo(self.SkillGroup)
        end
    end
end

function XUiGridPresetMainSkill:Refresh(skillGroup, isSelect, characterId)
    self.SkillGroup = skillGroup
    self.CharacterId = characterId

    if not skillGroup then return end
    if isSelect then
        self:RefreshProperty(GridState.Select)
    else
        local state = skillGroup:GetIsLock() and GridState.Locked or GridState.Normal
        self:RefreshProperty(state)
    end
    
end

function XUiGridPresetMainSkill:RefreshProperty(state)
    self.State = state
    
    local isNormal = state == GridState.Normal
    local isSelect = state == GridState.Select
    local isLocked = state == GridState.Locked
    
    self.Normal.gameObject:SetActiveEx(isNormal)
    self.Select.gameObject:SetActiveEx(isSelect)
    self.Lock.gameObject:SetActiveEx(isLocked)
    local activeSkillId = XDataCenter.PartnerManager.SwitchMainActiveSkillId(self.SkillGroup, self.CharacterId)
    
    local panel = {}
    if isNormal then
        panel = self.NormalPanel
        panel.TxtContent.text = self.SkillGroup:GetSkillDesc(activeSkillId)
    elseif isSelect then
        panel = self.SelectPanel
        panel.TxtContent.text = self.SkillGroup:GetSkillDesc(activeSkillId)
    elseif isLocked then
        panel = self.LockedPanel
        panel.TxtUnlock.text = self.SkillGroup:GetConditionDesc()
    end
    
    panel.RImgIcon:SetRawImage(self.SkillGroup:GetSkillIcon(activeSkillId))
    panel.TxtName.text = self.SkillGroup:GetSkillName(activeSkillId)
    panel.TxtLevel.text = CS.XTextManager.GetText("PartnerSkillLevelEN",self.SkillGroup:GetLevelStr())
end


--=========================================类分界线=========================================--


local XUiPanelSkillSelect = XClass(nil, "XUiPanelSkillSelect")

function XUiPanelSkillSelect:Ctor(ui, partner, partnerPrefab, funcDict)
    XTool.InitUiObjectByUi(self, ui)
    self.Partner = partner
    self.PartnerPrefab = partnerPrefab
    for funcName, func in pairs(funcDict or {}) do
        self[funcName] = func
    end
    
    self.CharacterId = self.PartnerPrefab:GetCharacterId(partner:GetId())
    self:InitPanel()
    self:InitDynamicTable()
end

function XUiPanelSkillSelect:InitPanel()
    self.TxtName.transform.parent.gameObject:SetActiveEx(false)
end

function XUiPanelSkillSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillOptionGroup)
    self.DynamicTable:SetProxy(XUiGridPresetMainSkill, handler(self, self.OnSelectCallback), self.GoSkillInfoPanel)
    self.DynamicTable:SetDelegate(self)
    self.GridSkillOption.gameObject:SetActiveEx(false)
end


function XUiPanelSkillSelect:Refresh()
    self.SkillList = self.Partner:GetMainSkillGroupList()

    self.DynamicTable:SetDataSource(self.SkillList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelSkillSelect:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local group = self.SkillList[index]
        grid:Refresh(group, self:IsSelect(group), self.CharacterId)
    end
end

function XUiPanelSkillSelect:IsSelect(group)
    local isSelect = false
    if self.GetCurrentGroup and group then
        local curGroup = self.GetCurrentGroup()
        isSelect = curGroup and curGroup:GetId() == group:GetId() or false
    end
    return isSelect
end

function XUiPanelSkillSelect:OnSelectCallback(group)
    if not group then return end
    
    if group:GetIsLock() then
        XUiManager.TipMsg(group:GetConditionDesc())
        return
    end
    self.SetCurrentGroup(group)
    
    self:Refresh()
end

return XUiPanelSkillSelect