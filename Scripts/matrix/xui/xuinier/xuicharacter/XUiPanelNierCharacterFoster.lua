local XUiPanelNierCharacterFoster = XClass(nil, "XUiPanelNierCharacterFoster")
local XUiGrideNieRCharacterFoster = require("XUi/XUiNieR/XUiCharacter/XUiGrideNieRCharacterFoster")

function XUiPanelNierCharacterFoster:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = parent

    XTool.InitUiObject(self)
    self.BtnTcanchaungBlue.CallBack = function() self:OnBtnGoToUpAbilityClick() end
    self.BtnBuyJump1.CallBack = function() self:OnBtnUpLevelMatClick() end
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGrideNieRCharacterFoster)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelNierCharacterFoster:InitAllData()
    local characterData = XDataCenter.NieRManager.GetSelNieRCharacter()
    self.CharacterData = characterData
    self:UpdateLevelPanel(characterData)

    self.AbilityList = characterData:GetAbilityList()
    self.DynamicTable:SetDataSource(self.AbilityList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelNierCharacterFoster:UpdateLevelPanel(characterData)
    self.LevelLable.text =  characterData:GetNieRCharacterLevel()
    local exp = characterData:GetNieRCharacterExp()
    local maxExp = characterData:GetNieRCharacterMaxExp()
    if characterData:CheckNieRCharacterMaxLevel() then
        self.LevelMAX.gameObject:SetActiveEx(true)
    else
        self.LevelMAX.gameObject:SetActiveEx(false)
    end
    self.TxtExpNum.text = string.format( "<color=#62BAFF><size=32>%s</size></color>/%s", exp , maxExp)
    self.ImgProgress.fillAmount = exp / maxExp

    local attribs = characterData:GetAttribs()
    
    self.DamageNumLable.text = FixToInt(attribs[XNpcAttribType.AttackNormal])
    self.HealthNumLable.text = FixToInt(attribs[XNpcAttribType.Life])
    self.DefenseNumLable.text = FixToInt(attribs[XNpcAttribType.DefenseNormal])
    self.CritNumLable.text = FixToInt(attribs[XNpcAttribType.Crit])

    local abilityNum = characterData:GetAbilityNum()
    self.FightNum.text = abilityNum
    
    self.UpLevelItemId = characterData:GetNieRCharacterUpLevelItemId()
    self.ImgNormal:SetSprite(XDataCenter.ItemManager.GetItemIcon(self.UpLevelItemId))
    self.ImgPress:SetSprite(XDataCenter.ItemManager.GetItemIcon(self.UpLevelItemId))
    
    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(characterData:GetRobotCharacterId())
    local elementList = detailConfig.ObtainElementList
    for i = 1, 2 do
        local rImg = self["ProfessionIcon" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon2)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

end

function XUiPanelNierCharacterFoster:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.AbilityList[index], index)
    end
end

function XUiPanelNierCharacterFoster:OnDynamicGridClick(index)
    local data = self.AbilityList[index]
    local config = XNieRConfigs.GetAbilityGroupConfigById(data.ConfigId)
    local condit, desc = XConditionManager.CheckCondition(config.Condition)
    if XConditionManager.CheckCondition(config.Condition) then
        if data.Type == XNieRConfigs.AbilityType.Skill then
            local skillId = config.SkillId
            local skillLevel = config.SkillLevel
            local skillInfo = XCharacterConfigs.GetSkillGradeDesConfig(skillId, skillLevel)
            XUiManager.DialogDragTip(skillInfo.Name, skillInfo.Intro, XUiManager.DialogType.NoBtn, nil, nil)
        elseif data.Type == XNieRConfigs.AbilityType.Fashion then
            XLuaUiManager.Open("UiFashion", self.CharacterData:GetRobotCharacterId(), true, true, XUiConfigs.OpenUiType.NieRCharacterUI)
        elseif data.Type == XNieRConfigs.AbilityType.Weapon then
            local equipId = config.WeaponId
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(equipId, true, nil, nil, nil, XUiConfigs.OpenUiType.NieRCharacterUI)
        elseif data.Type == XNieRConfigs.AbilityType.FourWafer then
            local equipId = config.WaferId[1]
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(equipId, true, nil, nil, nil, XUiConfigs.OpenUiType.NieRCharacterUI)
        elseif data.Type == XNieRConfigs.AbilityType.TwoWafer then
            local equipId = config.WaferId[1]
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(equipId, true, nil, nil, nil, XUiConfigs.OpenUiType.NieRCharacterUI)
        end
    else
        XUiManager.TipMsg(desc)
    end
end

function XUiPanelNierCharacterFoster:ShowPanel(isPlayAnimation)
    self.IsPlayAnimation = isPlayAnimation
    self.GameObject:SetActiveEx(true)
end

function XUiPanelNierCharacterFoster:HidePanel()
    self.IsPlayAnimation = false
    self.GameObject:SetActiveEx(false)
end

function XUiPanelNierCharacterFoster:OnBtnGoToUpAbilityClick()
    XFunctionManager.SkipInterface(self.CharacterData:GetNieRClientSkipId())
end

function XUiPanelNierCharacterFoster:OnBtnUpLevelMatClick()
    local item = XDataCenter.ItemManager.GetItem(self.UpLevelItemId)
    local data = {
        Id = item.Id,
        Count = item ~= nil and tostring(item.Count) or "0"
    }
    XLuaUiManager.Open("UiTip", data)   
end

return XUiPanelNierCharacterFoster