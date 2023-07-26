local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")

local XUiEquipResonanceSkill = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSkill")

function XUiEquipResonanceSkill:OnAwake()
    self:AutoAddListener()

    self.BtnHelp.gameObject:SetActiveEx(false)
    self.GridResonanceSkill.gameObject:SetActiveEx(false)
end

function XUiEquipResonanceSkill:OnStart(equipId, rootUi)
    self.EquipId = equipId
    self.RootUi = rootUi
    self.GridResonanceSkills = {}
    self.DescriptionTitle = CS.XTextManager.GetText("EquipResonanceExplainTitle")
    self.Description = string.gsub(CS.XTextManager.GetText("EquipResonanceExplain"), "\\n", "\n")
end

function XUiEquipResonanceSkill:OnEnable(equipId)
    self.EquipId = equipId or self.EquipId
    self:UpdateResonanceSkills()
end

function XUiEquipResonanceSkill:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY
    }
end

function XUiEquipResonanceSkill:OnNotify(evt, ...)
    local args = { ... }
    local equipId = args[1]
    local pos = args[2]
    if equipId ~= self.EquipId then return end

    if evt == XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY then
        self:UpdateResonanceSkill(pos)
    end
end

--v1.28-刷新共鸣界面数据
function XUiEquipResonanceSkill:RefreshData(equipId)
    self:OnEnable(equipId)
end

function XUiEquipResonanceSkill:UpdateResonanceSkills()
    local count = 1
    local resonanceSkillNum = XDataCenter.EquipManager.GetResonanceSkillNum(self.EquipId)
    for pos = 1, resonanceSkillNum do
        self:UpdateResonanceSkill(pos)
        self["PanelSkill" .. pos].gameObject:SetActiveEx(true)
        self["PanelSkill" .. pos].transform:GetComponent("CanvasGroup").alpha = 1
        count = count + 1
    end
    for pos = count, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
        self["PanelSkill" .. pos].gameObject:SetActiveEx(false)
    end
end

function XUiEquipResonanceSkill:UpdateResonanceSkill(pos)
    local equipId = self.EquipId
    local characterId = self.RootUi.CharacterId
    local forceShowBindCharacter = self.RootUi.ForceShowBindCharacter

    -- local btnAwake = self["BtnAwake" .. pos]
    -- local btnAwakeDetail = self["BtnAwakeDetail" .. pos]
    if XDataCenter.EquipManager.CheckEquipPosResonanced(equipId, pos) then
        if not self.GridResonanceSkills[pos] then
            local item = CS.UnityEngine.Object.Instantiate(self.GridResonanceSkill)
            self.GridResonanceSkills[pos] = XUiGridResonanceSkill.New(item, equipId, pos, characterId, nil, nil, forceShowBindCharacter)
            self.GridResonanceSkills[pos].Transform:SetParent(self["PanelSkill" .. pos], false)
        end
        self.GridResonanceSkills[pos]:SetEquipIdAndPos(equipId, pos)
        self.GridResonanceSkills[pos]:Refresh()
        self.GridResonanceSkills[pos].GameObject:SetActiveEx(true)
        self["PanelNoSkill" .. pos].gameObject:SetActiveEx(false)
        self["BtnRepeatResonance" .. pos].gameObject:SetActiveEx(true)

        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipAwake)
        and XDataCenter.EquipManager.CheckEquipStarCanAwake(equipId)
        and XDataCenter.EquipManager.IsAwareness(equipId) then
            if not XDataCenter.EquipManager.IsEquipPosAwaken(equipId, pos) then
                -- btnAwake:SetDisable(not XDataCenter.EquipManager.CheckEquipCanAwake(equipId))
                -- btnAwake.gameObject:SetActiveEx(true)
                -- btnAwakeDetail.gameObject:SetActiveEx(false)
            else
                -- btnAwake.gameObject:SetActiveEx(false)
                -- btnAwakeDetail.gameObject:SetActiveEx(true)
            end
        else
            -- btnAwake.gameObject:SetActiveEx(false)
        end
    else
        if self.GridResonanceSkills[pos] then
            self.GridResonanceSkills[pos].GameObject:SetActiveEx(false)
        end
        self["PanelNoSkill" .. pos].gameObject:SetActiveEx(true)
        self["BtnRepeatResonance" .. pos].gameObject:SetActiveEx(false)
        -- btnAwake.gameObject:SetActiveEx(false)
        -- btnAwakeDetail.gameObject:SetActiveEx(false)
    end
    self["BtnResonance" .. pos].transform:SetAsLastSibling()
end

function XUiEquipResonanceSkill:AutoAddListener()
    self:RegisterClickEvent(self.BtnResonance1, self.OnBtnResonance1Click)
    self:RegisterClickEvent(self.BtnResonance2, self.OnBtnResonance2Click)
    self:RegisterClickEvent(self.BtnResonance3, self.OnBtnResonance3Click)
    self:RegisterClickEvent(self.BtnRepeatResonance1, self.OnBtnResonance1Click)
    self:RegisterClickEvent(self.BtnRepeatResonance2, self.OnBtnResonance2Click)
    self:RegisterClickEvent(self.BtnRepeatResonance3, self.OnBtnResonance3Click)
    -- self:RegisterClickEvent(self.BtnAwake1, self.OnBtnAwake1Click)
    -- self:RegisterClickEvent(self.BtnAwake2, self.OnBtnAwake2Click)
    -- self:RegisterClickEvent(self.BtnAwake3, self.OnBtnAwake3Click)
    self:RegisterClickEvent(self.BtnAwakeDetail1, self.OnBtnAwakeDetail1Click)
    self:RegisterClickEvent(self.BtnAwakeDetail2, self.OnBtnAwakeDetail2Click)
    self:RegisterClickEvent(self.BtnAwakeDetail3, self.OnBtnAwakeDetail3Click)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
end

function XUiEquipResonanceSkill:OnBtnResonance3Click()
    self:OnBtnResonanceClick(3)
end

function XUiEquipResonanceSkill:OnBtnResonance1Click()
    self:OnBtnResonanceClick(1)
end

function XUiEquipResonanceSkill:OnBtnResonance2Click()
    self:OnBtnResonanceClick(2)
end

function XUiEquipResonanceSkill:OnBtnAwake3Click()
    self:OnBtnAwakeClick(3)
end

function XUiEquipResonanceSkill:OnBtnAwake1Click()
    self:OnBtnAwakeClick(1)
end

function XUiEquipResonanceSkill:OnBtnAwake2Click()
    self:OnBtnAwakeClick(2)
end

function XUiEquipResonanceSkill:OnBtnAwakeDetail3Click()
    self:OnBtnAwakeDetailClick(3)
end

function XUiEquipResonanceSkill:OnBtnAwakeDetail1Click()
    self:OnBtnAwakeDetailClick(1)
end

function XUiEquipResonanceSkill:OnBtnAwakeDetail2Click()
    self:OnBtnAwakeDetailClick(2)
end

function XUiEquipResonanceSkill:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip(self.DescriptionTitle, self.Description)
end

function XUiEquipResonanceSkill:OnBtnResonanceClick(pos)
    local equipId = self.EquipId

    if XDataCenter.EquipManager.IsWeapon(equipId)
    and XDataCenter.EquipManager.CheckEquipPosResonanced(equipId, pos)
    and XDataCenter.EquipManager.IsFiveStar(equipId) then
        XUiManager.TipText("EquipResonance5StarWeaponRepeatTip")
        return
    end

    self:PlayAnimationWithMask("PanelSkill" .. pos, function()
        if XDataCenter.EquipManager.CheckEquipPosUnconfirmedResonanced(self.EquipId, pos) then
            local forceShowBindCharacter = self.RootUi.ForceShowBindCharacter
            XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, pos, self.RootUi.CharacterId, nil, forceShowBindCharacter)
        else
            self.RootUi:FindChildUiObj("UiEquipResonanceSelect"):Refresh(pos)
            self.RootUi:FindChildUiObj("UiEquipResonanceSelectEquip"):Reset()
            self.RootUi:OpenOneChildUi("UiEquipResonanceSelect", equipId, self.RootUi)
        end
    end)
end

function XUiEquipResonanceSkill:OnBtnAwakeClick(pos)
    local equipId = self.EquipId

    if not XDataCenter.EquipManager.CheckEquipCanAwake(equipId, pos) then
        XUiManager.TipText("EquipCanNotAwakeCondition")
        return
    end

    self.RootUi:FindChildUiObj("UiEquipResonanceAwake"):Refresh(pos)
    self.RootUi:OpenOneChildUi("UiEquipResonanceAwake", equipId, self.RootUi)
end

function XUiEquipResonanceSkill:OnBtnAwakeDetailClick(pos)
    local equipId = self.EquipId
    local characterId = self.RootUi.CharacterId
    local isAwakeDes = true
    local forceShowBindCharacter = self.RootUi.ForceShowBindCharacter
    XLuaUiManager.Open("UiEquipResonanceSkillDetailInfo", equipId, pos, characterId, isAwakeDes, forceShowBindCharacter)
end