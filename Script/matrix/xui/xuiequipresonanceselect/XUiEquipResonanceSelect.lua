local CsXTextManagerGetText = CS.XTextManager.GetText

local XUiGridEquip = require("XUi/XUiEquipAwarenessReplace/XUiGridEquip")
local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")

local TabConsumeType = {
    Equip = 0,
    Item = 1,
}

--对应按钮状态(避免歧义)
local TCTButtonState = {
    NORMAL = 0,
    SELECT = 2,
    Disable = 3
}

local XUiEquipResonanceSelect = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSelect")

function XUiEquipResonanceSelect:OnAwake()
    self:AutoAddListener()
    self.GridCurAwareness.gameObject:SetActiveEx(false)
    self.GridCurItem.gameObject:SetActiveEx(false)
end

function XUiEquipResonanceSelect:OnStart(equipId, rootUi)
    self.RootUi = rootUi
    self.EquipId = equipId
    self.DescriptionTitle = CsXTextManagerGetText("EquipResonanceExplainTitle")
    self.Description = string.gsub(CsXTextManagerGetText("EquipResonanceExplain"), "\\n", "\n")
end

function XUiEquipResonanceSelect:OnEnable(equipId)
    self.TabConsumeType = TabConsumeType.Equip
    self.EquipId = equipId or self.EquipId
    self:ClearData()
    self:InitRightView()
    self:UpdateBtnStatus()
    self:SetTCTButtonStateByTabConsumeType(self.TabConsumeType)
    self:OnTogConsumeTypeClick(self.TabConsumeType)
    self:UpdateCurCharacter()
    self:UpdateResonanceSkill()
    self:UpdateResonanceConsumeItem()
    self:UpdateCurGrid()
end

function XUiEquipResonanceSelect:OnGetEvents()
    return { XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY }
end

function XUiEquipResonanceSelect:OnNotify(evt, ...)
    local args = { ... }
    local equipId = args[1]
    local pos = args[2]
    if equipId ~= self.EquipId then return end
    if pos ~= self.Pos then return end

    if evt == XEventId.EVENT_EQUIP_RESONANCE_NOTYFY then
        self.RootUi:FindChildUiObj("UiEquipResonanceSkill").UiProxy:SetActive(true)
        self.UiProxy:SetActive(false)
        
        local forceShowBindCharacter = self.RootUi.ForceShowBindCharacter
        --如果是武器自选只需要弹提示
        if XDataCenter.EquipManager.IsClassifyEqual(self.EquipId, XEquipConfig.Classify.Weapon) then
            if self.IsNewSkill then
                XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, self.Pos, self.RootUi.CharacterId, nil, forceShowBindCharacter)
            else
                XUiManager.TipText("EquipResonanceChangeSuccess")
            end
        else
            XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, self.Pos, self.RootUi.CharacterId, nil, forceShowBindCharacter)
        end

        self:ClearData()
        self:UpdateBtnStatus()
        self:OnTogConsumeTypeClick(self.TabConsumeType)
        self:UpdateResonanceSkill()
    elseif evt == XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY then
        self:ClearData()
        self:UpdateBtnStatus()
        self:OnTogConsumeTypeClick(self.TabConsumeType)
        self:UpdateResonanceSkill()
    end
end

function XUiEquipResonanceSelect:Refresh(pos)
    self.Pos = pos
    self:ClearData()
end

function XUiEquipResonanceSelect:ClearData()
    self.SelectCharacterId = nil
    self.SelectEquipId = nil
    self.SelectSkillInfo = nil
    self.SelectItemId = nil
end

function XUiEquipResonanceSelect:UpdateConsumeTxt()
    local equipId = self.EquipId
    if self.TabConsumeType == TabConsumeType.Item then
        local consumeCount
        if XDataCenter.EquipManager.GetResonanceConsumeSelectSkillItemId(self.EquipId) == self.SelectItemId then
            consumeCount = XDataCenter.EquipManager.GetResonanceConsumeSelectSkillItemCount(equipId)
        else
            consumeCount = XDataCenter.EquipManager.GetResonanceConsumeItemCount(equipId)
        end
        self.TxtConsumeWhat.text = CsXTextManagerGetText("EquipResonanceConsumeItemCount", consumeCount)
    elseif self.TabConsumeType == TabConsumeType.Equip then
        if XDataCenter.EquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Weapon) then
            self.TxtConsumeWhat.text = CsXTextManagerGetText("WeaponStrengthenTitle")
            self.TogConsumeType:SetNameByGroup(0, CsXTextManagerGetText("TypeWeapon"))
        elseif XDataCenter.EquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness) then
            self.TxtConsumeWhat.text = CsXTextManagerGetText("AwarenessStrengthenTitle")
            self.TogConsumeType:SetNameByGroup(0, CsXTextManagerGetText("TypeWafer"))
        end
    end
end

function XUiEquipResonanceSelect:InitRightView()
    local equipId = self.EquipId

    --专属装备自动选择共鸣绑定角色
    local equipSpecialCharacterId = XDataCenter.EquipManager.GetEquipSpecialCharacterId(equipId)
    if equipSpecialCharacterId and equipSpecialCharacterId > 0 then
        self.SelectCharacterId = equipSpecialCharacterId
        self.PanelCharacter.gameObject:SetActiveEx(true)
    else
        --五星以上才可以选择共鸣绑定角色
        if XDataCenter.EquipManager.CanResonanceBindCharacter(equipId) then
            local wearingCharacterId = XDataCenter.EquipManager.GetEquipWearingCharacterId(equipId)
            self.SelectCharacterId = wearingCharacterId
            self.PanelCharacter.gameObject:SetActiveEx(true)
        else
            self.PanelCharacter.gameObject:SetActiveEx(false)
        end
    end

    self.CurEquipGird = self.CurEquipGird or XUiGridEquip.New(self.GridCurAwareness, function()
        self:OnBtnSelectAwarenessClick()
    end,self)

    self.CurItemGird = self.CurItemGird or XUiGridCommon.New(self, self.GridCurItem)
    self.CurItemGird:SetClickCallback(function ()
        self:OnBtnSelectAwarenessClick()
    end)
end

function XUiEquipResonanceSelect:UpdateCurGrid()
    local buttonState = self:GetTCTButtonState(self.TabConsumeType)
    if buttonState == TCTButtonState.Disable then
        self.CurItemGird.GameObject:SetActiveEx(false)
        self.CurEquipGird.GameObject:SetActiveEx(false)
        self.PanelNoAwareness.gameObject:SetActiveEx(false)
        self.TxtNoConsumption.gameObject:SetActiveEx(true)
    elseif buttonState == TCTButtonState.NORMAL then
        if not self.SelectEquipId then
            self.CurItemGird.GameObject:SetActiveEx(false)
            self.CurEquipGird.GameObject:SetActiveEx(false)
            self.PanelNoAwareness.gameObject:SetActiveEx(true)
            self.TxtNoConsumption.gameObject:SetActiveEx(false)
        else
            self.CurEquipGird:Refresh(self.SelectEquipId)
            self.CurEquipGird.GameObject:SetActiveEx(true)
            self.CurItemGird.GameObject:SetActiveEx(false)
            self.PanelNoAwareness.gameObject:SetActiveEx(false)
            self.TxtNoConsumption.gameObject:SetActiveEx(false)
        end
    elseif buttonState == TCTButtonState.SELECT then
        if not self.SelectItemId then
            self.CurEquipGird.GameObject:SetActiveEx(false)
            self.CurItemGird.GameObject:SetActiveEx(false)
            self.PanelNoAwareness.gameObject:SetActiveEx(true)
            self.TxtNoConsumption.gameObject:SetActiveEx(false)
        else
            self.CurItemGird:Refresh(self.SelectItemId)
            self.CurEquipGird.GameObject:SetActiveEx(false)
            self.CurItemGird.GameObject:SetActiveEx(true)
            self.PanelNoAwareness.gameObject:SetActiveEx(false)
            self.TxtNoConsumption.gameObject:SetActiveEx(false)
        end
    end
end

function XUiEquipResonanceSelect:UpdateCurCharacter()
    if not self.SelectCharacterId then
        self.PanelCurCharacter.gameObject:SetActiveEx(false)
        self.PanelNoCharacter.gameObject:SetActiveEx(true)
    else
        self.PanelCurCharacter.gameObject:SetActiveEx(true)
        self.PanelNoCharacter.gameObject:SetActiveEx(false)

        self.RImgHead:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.SelectCharacterId))
    end
end

function XUiEquipResonanceSelect:UpdateResonanceSkill()
    self.TxtSlot.text = self.Pos
    if self.TxtPos then
        self.TxtPos.text = string.format("%02d", self.Pos)
    end
    if self.SelectSkillInfo then
        self:UpdateUiGridResonanceSkill(self.SelectSkillInfo, self.SelectCharacterId)
        self.TxtNoAwareness.gameObject:SetActiveEx(false)
    elseif XDataCenter.EquipManager.CheckEquipPosResonanced(self.EquipId, self.Pos) then
        self:UpdateUiGridResonanceSkill()
        self.TxtNoAwareness.gameObject:SetActiveEx(false)
    else
        if self.ResonanceSkillGrid then
            self.ResonanceSkillGrid.GameObject:SetActiveEx(false)
        end
        self.TxtNoAwareness.gameObject:SetActiveEx(true)
    end
end

function XUiEquipResonanceSelect:UpdateUiGridResonanceSkill(skillInfo, characterId)
    if not self.ResonanceSkillGrid then
        self.ResonanceSkillGrid = XUiGridResonanceSkill.New(self.GridResonanceSkill, self.EquipId, self.Pos)
    end

    self.ResonanceSkillGrid:SetEquipIdAndPos(self.EquipId, self.Pos)
    self.ResonanceSkillGrid:Refresh(skillInfo, characterId)
    self.ResonanceSkillGrid.GameObject:SetActiveEx(true)
    self.TxtChoice.gameObject:SetActiveEx(self.SelectSkillInfo ~= nil)
end

function XUiEquipResonanceSelect:UpdateResonanceConsumeItem()
    local consumeItemId = XDataCenter.EquipManager.GetResonanceConsumeItemId(self.EquipId)
    local consumeSelectSkillItemId = XDataCenter.EquipManager.GetResonanceConsumeSelectSkillItemId(self.EquipId)

    if not consumeItemId and not consumeSelectSkillItemId then return end

    if not self.ConsumeItems then
        self.ConsumeItems = {}
    end

    local index = 1

    local function RefreshItem(itemId)
        local gridConsumeItem = self["GridConsumeItem" .. index]
        if not itemId then
            gridConsumeItem.gameObject:SetActiveEx(false)
            return
        end

        local consumeItemInfo = {}
        consumeItemInfo.TemplateId = itemId
        consumeItemInfo.Count = XDataCenter.ItemManager.GetCount(itemId)
    
        local consumeItem
        if self.ConsumeItems[index] then
            consumeItem = self.ConsumeItems[index]
        else
            consumeItem = XUiGridCommon.New(self, gridConsumeItem)
        end
        consumeItem:Refresh(consumeItemInfo)
        gridConsumeItem.gameObject:SetActiveEx(true)
        index = index + 1
    end

    RefreshItem(consumeItemId)
    RefreshItem(consumeSelectSkillItemId)
end

function XUiEquipResonanceSelect:UpdateBtnStatus()
    if self.SelectCharacterId then
        self.BtnSkillPreview.gameObject:SetActiveEx(true)
    else
        self.BtnSkillPreview.gameObject:SetActiveEx(false)
    end

    local state = self:GetBtnResonanceState()
    self.BtnResonance:SetDisable(not state)

    --物品不足时或可无消耗共鸣，不可切换至消耗物品，
    if not XDataCenter.EquipManager.CheckResonanceConsumeItemEnough(self.EquipId) or self:CheckIsNoConsumption() then
        self.TogConsumeType:SetDisable(true)
    else
        self.TogConsumeType:SetDisable(false)
        self:SetTCTButtonStateByTabConsumeType(self.TabConsumeType)
    end

    self:UpdateBtnSkillPreviewName()
end

--@region 绑定onclick事件
function XUiEquipResonanceSelect:AutoAddListener()
    self:RegisterClickEvent(self.BtnSkillPreview, self.OnBtnSkillPreviewClick)
    self:RegisterClickEvent(self.BtnSelectCharacter, self.OnBtnSelectCharacterClick)
    self:RegisterClickEvent(self.BtnCharacterClick, self.OnBtnCharacterClickClick)
    self:RegisterClickEvent(self.BtnSelectAwareness, self.OnBtnSelectAwarenessClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnNoConsumption, self.OnBtnNoConsumption)
    
    self.BtnResonance.CallBack = function() self:OnBtnResonanceClick() end
    self.TogConsumeType.CallBack = function(value) self:OnTogConsumeTypeClick(value, true) end
end

function XUiEquipResonanceSelect:OnBtnCharacterClickClick()
    local equipSpecialCharacterId = XDataCenter.EquipManager.GetEquipSpecialCharacterId(self.EquipId)
    if equipSpecialCharacterId and equipSpecialCharacterId > 0 then
        XUiManager.TipText("EquipIsBindCharacter")
        return
    end

    self:OnBtnSelectCharacterClick()
end

function XUiEquipResonanceSelect:OnBtnNoConsumption()
    XUiManager.TipText("EquipResonanceSelectFree")
end

function XUiEquipResonanceSelect:OnBtnResonanceClick()
    local useEquipId
    local useItemId
    local selectSkillId
    local equipResonanceType
    local state, msg = self:GetBtnResonanceState()

    if not state then
        XUiManager.TipMsg(msg)
        return
    end

    if self.SelectSkillInfo then
        selectSkillId = self.SelectSkillInfo:GetSkillIdToServer()
        equipResonanceType = self.SelectSkillInfo.EquipResonanceType
    end

    if not self:CheckIsNoConsumption() then
        if self.TabConsumeType == TabConsumeType.Equip then
            useEquipId = self.SelectEquipId
        else
            useItemId = self.SelectItemId
        end
    end

    --是否获得新技能
    if self:SelectCharacteIsBindCharacte() then
        self.IsNewSkill = not XDataCenter.EquipManager.CheckEquipPosResonanced(self.EquipId, self.Pos)
    else
        self.IsNewSkill = true
    end

    XDataCenter.EquipManager.Resonance(
        self.EquipId, 
        self.Pos, 
        self.SelectCharacterId, 
        useEquipId, 
        useItemId, 
        selectSkillId, 
        equipResonanceType
    )
end

function XUiEquipResonanceSelect:OnBtnSkillPreviewClick()
    XLuaUiManager.Open("UiEquipResonanceSkillPreview", {
        pos = self.Pos,
        rootUi = self, 
        selectSkillInfo = self.SelectSkillInfo,
        isNeedSelectSkill = self:IsNeedSelectSkill(),
        ClickCb = function (skillInfo)
            self.SelectSkillInfo = skillInfo
            self:UpdateBtnStatus()
            self:UpdateResonanceSkill()
        end
    })
end

function XUiEquipResonanceSelect:OnBtnSelectCharacterClick()
    local confirmCb = function(selectCharacterId)
        self.SelectCharacterId = selectCharacterId
        self:UpdateBtnStatus()
        self:UpdateCurCharacter()
        self:UpdateCurGrid()
    end
    self.RootUi:OpenChildUi("UiEquipResonanceSelectCharacter", self.EquipId, confirmCb)
end

function XUiEquipResonanceSelect:OnBtnSelectAwarenessClick()
    if self.TabConsumeType == TabConsumeType.Equip then
        self.RootUi:OpenChildUi("UiEquipResonanceSelectEquip", self.EquipId, function(selectEquipId)
            self.SelectEquipId = selectEquipId
            self:UpdateBtnStatus()
            self:OnTogConsumeTypeClick(self.TabConsumeType)
        end)
    elseif self.TabConsumeType == TabConsumeType.Item then
        local isEnough, itemIds = XDataCenter.EquipManager.CheckResonanceConsumeItemEnough(self.EquipId)

        if isEnough and #itemIds >= 2 then
            self.RootUi:OpenChildUi("UiEquipResonanceSelectItem", self.EquipId, function(selectItemId)
                self.SelectItemId = selectItemId
                self:UpdateBtnStatus()
                self:UpdateCurGrid()
            end)
        else
            if self.SelectItemId then
                XLuaUiManager.Open("UiTip", self.SelectItemId)
            end
        end
    end
end

function XUiEquipResonanceSelect:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip(self.DescriptionTitle, self.Description)
end

function XUiEquipResonanceSelect:OnTogConsumeTypeClick(value, doTip)
    local buttonState = self:GetTCTButtonState(self.TabConsumeType)
    if buttonState == TCTButtonState.Disable then
        return
    end

    if value == TabConsumeType.Item then
        local isEnough, itemIds = XDataCenter.EquipManager.CheckResonanceConsumeItemEnough(self.EquipId)
        if not isEnough then
            if doTip then
                XUiManager.TipText("EquipResonanceConsumeItemLack")
            end

            return
        end

        if not self.SelectItemId then
            if #itemIds == 1 then
                self.SelectItemId = itemIds[1]
            end
        end
        self.SelectEquipId = nil
    else
        self.SelectItemId = nil
    end

    self.TabConsumeType = value

    self:UpdateCurGrid()
    self:UpdateConsumeTxt()
    self:UpdateBtnStatus()
end

--@endregion

function XUiEquipResonanceSelect:UpdateBtnSkillPreviewName()
    if XDataCenter.EquipManager.IsClassifyEqual(self.EquipId, XEquipConfig.Classify.Weapon) then
        if XDataCenter.EquipManager.CheckEquipPosResonanced(self.EquipId, self.Pos) and self:SelectCharacteIsBindCharacte() then
            self.BtnSkillPreview:SetName(CsXTextManagerGetText("EquipResonanceChange"))
        else
            self.BtnSkillPreview:SetName(CsXTextManagerGetText("EquipResonanceSelect"))
        end
    else
        if XDataCenter.EquipManager.GetResonanceConsumeSelectSkillItemId(self.EquipId) == self.SelectItemId then
            self.BtnSkillPreview:SetName(CsXTextManagerGetText("EquipResonanceSelect"))
        else
            self.BtnSkillPreview:SetName(CsXTextManagerGetText("EquipResonancePreview"))
        end
    end
end

--不需要消耗材料即可共鸣
function XUiEquipResonanceSelect:CheckIsNoConsumption()
    if XDataCenter.EquipManager.IsClassifyEqual(self.EquipId, XEquipConfig.Classify.Weapon) then
        local isFiveStar = XDataCenter.EquipManager.IsFiveStar(self.EquipId)
        if not isFiveStar then
            return self:SelectCharacteIsBindCharacte()
        else
            return false
        end
    else
        return false
    end
end

function XUiEquipResonanceSelect:IsNeedSelectSkill()
    if XDataCenter.EquipManager.IsClassifyEqual(self.EquipId, XEquipConfig.Classify.Weapon) then
        if XDataCenter.EquipManager.CanResonanceBindCharacter(self.EquipId) then
            local isFiveStar = XDataCenter.EquipManager.IsFiveStar(self.EquipId)
            return not isFiveStar
        else
            return false
        end
    else
        if self.SelectItemId then
            return XDataCenter.EquipManager.GetResonanceConsumeSelectSkillItemId(self.EquipId) == self.SelectItemId
        else
            return false
        end
    end
end

function XUiEquipResonanceSelect:SetTCTButtonStateByTabConsumeType(tabConsumeType)
    self.TabConsumeType = tabConsumeType
    self.TogConsumeType:SetButtonState(self:GetTCTButtonState(tabConsumeType))
end

function XUiEquipResonanceSelect:GetTCTButtonState(tabConsumeType)
    if self:CheckIsNoConsumption() then
        return TCTButtonState.Disable
    else
        if tabConsumeType == TabConsumeType.Equip then
            return TCTButtonState.NORMAL
        else
            return TCTButtonState.SELECT
        end
    end
end

function XUiEquipResonanceSelect:GetBtnResonanceState()
    if self:IsNeedSelectSkill() and not self.SelectSkillInfo then
        return false, CsXTextManagerGetText("EquipResonanceSelectTips")
    else
        local buttonState = self:GetTCTButtonState(self.TabConsumeType)
        if buttonState == TCTButtonState.Disable then
            return true
        else
            if self.TabConsumeType == TabConsumeType.Equip and not self.SelectEquipId then
                return false, CsXTextManagerGetText("EquipResonanceSelectEquipTips")
            elseif self.TabConsumeType == TabConsumeType.Item and not self.SelectItemId then
                return false, CsXTextManagerGetText("EquipResonanceSelectItemTips")
            else
                return true
            end
        end
    end
end

function XUiEquipResonanceSelect:SelectCharacteIsBindCharacte()
    local bindCharacterId = XDataCenter.EquipManager.GetResonanceBindCharacterId(self.EquipId, self.Pos)
    return self.SelectCharacterId == bindCharacterId
end