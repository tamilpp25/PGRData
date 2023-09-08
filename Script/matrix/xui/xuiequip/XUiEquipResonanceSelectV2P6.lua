local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local DISABLE = CS.UiButtonState.Disable

local XUiEquipResonanceSelectV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSelectV2P6")

function XUiEquipResonanceSelectV2P6:OnAwake()
    self:InitStateGrid()
    self:SetButtonCallBack()
end

function XUiEquipResonanceSelectV2P6:OnStart(parent, characterId, forceShowBindCharacter)
    self.Parent = parent
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
end

function XUiEquipResonanceSelectV2P6:OnDisable()
    self:ClearOpenUiTimer()
end

-- 在设置装备和位置的时候进行界面刷新
function XUiEquipResonanceSelectV2P6:SetPos(equipId, pos)
    self.EquipId = equipId
    self.TemplateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self.IsWeapon = XDataCenter.EquipManager.IsWeaponByTemplateId(self.TemplateId)
    self.Pos = pos

    self.SelectCharacterId = nil
    self.SelectEquipId = nil
    self.SelectItemId = nil
    self.SelectSkillInfo = nil
    self:InitBindCharacter()
    self:UpdateView()

    local textKey = self.IsWeapon and "EquipResonanceItemSelect" or "EquipResonanceItemSelect2"
    self.ItemSelect:GetObject("TxtStateName").text = XUiHelper.GetText(textKey)

    -- 共鸣结果未确认
    if XDataCenter.EquipManager.CheckEquipPosUnconfirmedResonanced(self.EquipId, pos) then
        XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, self.Pos, self.CharacterId, nil, self.ForceShowBindCharacter, function()
            self.Parent:OnResonanceSuccess(self.Pos, true)
        end)
    end
end

function XUiEquipResonanceSelectV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_RESONANCE_NOTYFY,
    }
end

function XUiEquipResonanceSelectV2P6:OnNotify(evt, ...)
    local args = { ... }
    local equipId = args[1]
    if equipId ~= self.EquipId then return end

    local slots = args[2]
    local isContainPos = table.contains(slots or {}, self.Pos)
    if not isContainPos then return end

    if evt == XEventId.EVENT_EQUIP_RESONANCE_NOTYFY then
        --如果是武器自选只需要弹提示
        if self.IsWeapon then
            if self.IsNewSkill then
                XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, self.Pos, self.CharacterId, nil, self.ForceShowBindCharacter, function()
                    self.Parent:OnResonanceSuccess(self.Pos, true)
                end)
            else
                XMVCA:GetAgency(ModuleId.XEquip):TipEquipOperation(nil, XUiHelper.GetText("DormTemplateSelectSuccess"))
                self.Parent:OnResonanceSuccess(self.Pos)
            end
        else
            XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, self.Pos, self.CharacterId, nil, self.ForceShowBindCharacter, function()
                self.Parent:OnResonanceSuccess(self.Pos, true)
            end)
        end
    end
end

function XUiEquipResonanceSelectV2P6:InitStateGrid()
    self.CharacterSelect:GetObject("TxtStateName").text = XUiHelper.GetText("EquipResonanceCharSelect")
    self.CharacterDisable:GetObject("TxtStateName").text = XUiHelper.GetText("EquipResonanceCharDisable")
    self.CharacterBlindEffect = self.CharacterBlind.transform:Find("Effect")
    self.CharacterBlindEffect.gameObject:SetActiveEx(false)

    self.ItemBlind:GetObject("TxtStateName").text = XUiHelper.GetText("EquipResonanceItemBlind")
    self.ItemDisable:GetObject("TxtStateName").text = XUiHelper.GetText("EquipResonanceItemDisable")
    self.ItemBlindEffect = self.ItemBlind.transform:Find("Effect")
    self.ItemBlindEffect.gameObject:SetActiveEx(false)

    self.SkillSelect:GetObject("TxtStateName").text = XUiHelper.GetText("EquipResonanceSkillSelect")
    self.SkillDisable:GetObject("TxtStateName").text = XUiHelper.GetText("EquipResonanceSkillDisable")
    self.SkillBlindEffect = self.SkillBlind.transform:Find("Effect")
end

function XUiEquipResonanceSelectV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.CharacterBlind, self.OnCharacterSelectClick)
    self:RegisterClickEvent(self.CharacterSelect, self.OnCharacterSelectClick)
    self:RegisterClickEvent(self.ItemBlind, self.OnItemSelectClick)
    self:RegisterClickEvent(self.ItemSelect, self.OnItemSelectClick)
    self:RegisterClickEvent(self.SkillBlind, self.OnSkillSelectClick)
    self:RegisterClickEvent(self.SkillSelect, self.OnSkillSelectClick)
    self:RegisterClickEvent(self.BtnResonance, self.OnBtnResonanceClick)
end

function XUiEquipResonanceSelectV2P6:OnCharacterSelectClick()
    XLuaUiManager.Open("UiEquipResonanceSelectCharacterV2P6", self.EquipId, function(selectCharacterId)
        -- 更换成员，清除当前选中技能
        if selectCharacterId ~= self.SelectCharacterId then
            self.SelectSkillInfo = nil
        end 

        self.SelectCharacterId = selectCharacterId
        self:UpdateView(true)

        self.CharacterBlindEffect.gameObject:SetActive(false)
        self.CharacterBlindEffect.gameObject:SetActive(true)
    end)
end

function XUiEquipResonanceSelectV2P6:OnItemSelectClick()
    XLuaUiManager.Open("UiEquipResonanceSelectEquipV2P6", self.EquipId, function(selectEquipId, selectItemId)
        self.SelectEquipId = selectEquipId
        self.SelectItemId = selectItemId

        -- 切换材料消耗，可能会变成随机技能，清除当前选中技能
        if not self:IsNeedSelectSkill() then
            self.SelectSkillInfo = nil
        end

        self:UpdateView(true)

        self.ItemBlindEffect.gameObject:SetActive(false)
        self.ItemBlindEffect.gameObject:SetActive(true)
    end)
end

function XUiEquipResonanceSelectV2P6:OnSkillSelectClick()
    if self.OnlyOneSkill then
        return
    end

    XLuaUiManager.Open("UiEquipResonanceSkillPreview", {
        pos = self.Pos,
        rootUi = self, 
        selectSkillInfo = self.SelectSkillInfo,
        isNeedSelectSkill = self:IsNeedSelectSkill(),
        ClickCb = function (skillInfo)
            self.SelectSkillInfo = skillInfo
            self:UpdateView(true)

            self.SkillBlindEffect.gameObject:SetActive(false)
            self.SkillBlindEffect.gameObject:SetActive(true)
        end
    })
end


function XUiEquipResonanceSelectV2P6:OnBtnResonanceClick()
    if self.BtnResonance.ButtonState == DISABLE then
        return
    end
    
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

    local noConsumption = self:CheckIsNoConsumption()
    if not noConsumption then
        useEquipId = self.SelectEquipId
        useItemId = self.SelectItemId
    end

    --是否获得新技能
    if self:SelectCharacterIsBindCharacter() then
        self.IsNewSkill = not XDataCenter.EquipManager.CheckEquipPosResonanced(self.EquipId, self.Pos)
    else
        self.IsNewSkill = true
    end

    -- 请求共鸣
    XMVCA:GetAgency(ModuleId.XEquip):RequestEquipResonance(self.EquipId, {self.Pos}, self.SelectCharacterId, useEquipId, useItemId, {selectSkillId}, equipResonanceType)
end

-- 初始化绑定角色
function XUiEquipResonanceSelectV2P6:InitBindCharacter()
    --专属装备自动选择共鸣绑定角色
    local specialCharacterId = XDataCenter.EquipManager.GetEquipSpecialCharacterId(self.EquipId)
    if specialCharacterId and specialCharacterId > 0 then
        self.SelectCharacterId = specialCharacterId
    end

    --五星以上才可以选择共鸣绑定角色
    self.CanBlindCharacter = XDataCenter.EquipManager.CanResonanceBindCharacter(self.EquipId)
    if self.CanBlindCharacter then
        self.SelectCharacterId = XDataCenter.EquipManager.GetEquipWearingCharacterId(self.EquipId)
    end
end

function XUiEquipResonanceSelectV2P6:UpdateView(checkOpenUi)
    self:UpdateCurResonanceSkill()
    self:UpdateBlindCharacter()
    self:UpdateBlindItem()
    self:UpdateBlindSkill()
    self:UpdateBtnResonance()

    self:ClearOpenUiTimer()
    if checkOpenUi then
        self.CheckOpenUiTimer = XScheduleManager.ScheduleOnce(function()
            self.CheckOpenUiTimer = nil
            self:CheckOpenSelectUi()
        end, 300)
    end
end

-- 刷新当前的技能
function XUiEquipResonanceSelectV2P6:UpdateCurResonanceSkill()
    local isEquip = XDataCenter.EquipManager.CheckEquipPosResonanced(self.EquipId, self.Pos) ~= nil
    self.GridResonanceSkill.gameObject:SetActiveEx(isEquip)
    if not isEquip then
        return
    end

    if not self.ResonanceSkillGrid then
        self.ResonanceSkillGrid = XUiGridResonanceSkill.New(self.GridResonanceSkill, self.EquipId, self.Pos, self.CharacterId, nil, nil, self.ForceShowBindCharacter)
    end
    self.ResonanceSkillGrid:SetEquipIdAndPos(self.EquipId, self.Pos)
    self.ResonanceSkillGrid:Refresh()
end

-- 刷新绑定角色栏
function XUiEquipResonanceSelectV2P6:UpdateBlindCharacter()
    if self.CanBlindCharacter then
        local isBlind = self.SelectCharacterId and self.SelectCharacterId > 0
        self.CharacterBlind.gameObject:SetActiveEx(isBlind)
        self.CharacterSelect.gameObject:SetActiveEx(not isBlind)
        self.CharacterDisable.gameObject:SetActiveEx(false)
        if isBlind then
            local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.SelectCharacterId)
            self.CharacterBlind:GetObject("ImgHead"):SetRawImage(icon)
            self.CharacterBlind:GetObject("TxtName").text = XMVCA.XCharacter:GetCharacterLogName(self.SelectCharacterId)

            local lastCharId = XDataCenter.EquipManager.GetResonanceBindCharacterId(self.EquipId, self.Pos)
            local isChange = lastCharId ~= 0 and lastCharId ~= self.SelectCharacterId
            local stateNameKey = isChange and "EquipResonanceCharChange" or "EquipResonanceCharBlind"
            self.CharacterBlind:GetObject("TxtStateName").text = XUiHelper.GetText(stateNameKey)
        end
    else
        self.CharacterBlind.gameObject:SetActiveEx(false)
        self.CharacterSelect.gameObject:SetActiveEx(false)
        self.CharacterDisable.gameObject:SetActiveEx(false)
    end
end

-- 刷新绑定道具栏
function XUiEquipResonanceSelectV2P6:UpdateBlindItem()
    -- 不需要消耗
    local noConsumption = self:CheckIsNoConsumption()
    if noConsumption then
        self.ItemBlind.gameObject:SetActiveEx(false)
        self.ItemSelect.gameObject:SetActiveEx(false)
        self.ItemDisable.gameObject:SetActiveEx(true)
        self.ItemDisable:GetObject("TxtStateName").text = XUiHelper.GetText("EquipResonanceItemNoConsume")
        return
    end

    -- 角色未绑定
    local isBlindChar = self.SelectCharacterId and self.SelectCharacterId > 0
    if self.CanBlindCharacter and not isBlindChar then
        self.ItemBlind.gameObject:SetActiveEx(false)
        self.ItemSelect.gameObject:SetActiveEx(false)
        self.ItemDisable.gameObject:SetActiveEx(true)
        self.ItemDisable:GetObject("TxtStateName").text = XUiHelper.GetText("EquipResonanceItemDisable")
        return
    end

    local isBlindItem = self.SelectEquipId or self.SelectItemId
    self.ItemBlind.gameObject:SetActiveEx(isBlindItem)
    self.ItemSelect.gameObject:SetActiveEx(not isBlindItem)
    self.ItemDisable.gameObject:SetActiveEx(false)
    if isBlindItem then
        local templateId = nil
        if self.SelectEquipId then
            local equip = XDataCenter.EquipManager.GetEquip(self.SelectEquipId)
            templateId = equip.TemplateId
        end
        if self.SelectItemId then
            templateId = self.SelectItemId
        end

        local goodInfo = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
        self.ItemBlind:GetObject("ImgHead"):SetRawImage(goodInfo.Icon)
        self.ItemBlind:GetObject("TxtName").text = goodInfo.Name
    end
end

-- 刷新绑定的技能
function XUiEquipResonanceSelectV2P6:UpdateBlindSkill()
    local selectSkillInfo = self.SelectSkillInfo

    -- 道具未绑定
    local noConsumption = self:CheckIsNoConsumption()
    local isBlindItem = self.SelectEquipId or self.SelectItemId
    if not noConsumption and not isBlindItem then
        self.SkillBlind.gameObject:SetActiveEx(false)
        self.SkillSelect.gameObject:SetActiveEx(false)
        self.SkillDisable.gameObject:SetActiveEx(true)
        return
    end

    -- 只有一个技能，直接选中，五星武器
    self.OnlyOneSkill = false
    if not selectSkillInfo then
        local skillInfoList = self._Control:GetResonancePreviewSkillInfoList(self.EquipId, self.SelectCharacterId, self.Pos)
        if #skillInfoList == 1 then
            selectSkillInfo = skillInfoList[1]
            self.OnlyOneSkill = true
        end
    end

    local isBlindSkill = selectSkillInfo ~= nil
    local isNeedSelectSkill = self:IsNeedSelectSkill()
    local showBlind = isBlindSkill or not isNeedSelectSkill
    self.SkillBlind.gameObject:SetActiveEx(showBlind)
    self.SkillSelect.gameObject:SetActiveEx(not showBlind)
    self.SkillDisable.gameObject:SetActiveEx(false)
    if isBlindSkill then
        self.SkillBlind:GetObject("ImgHead"):SetRawImage(selectSkillInfo.Icon)
        self.SkillBlind:GetObject("TxtName").text = selectSkillInfo.Name
        self.SkillBlind:GetObject("TxtStateName").gameObject:SetActiveEx(true)

        local lastSkillInfo = XDataCenter.EquipManager.GetResonanceSkillInfo(self.EquipId, self.Pos)
        local isChange = lastSkillInfo.Name and lastSkillInfo.Name ~= selectSkillInfo.Name
        local stateNameKey = isChange and "EquipResonanceSkillChange" or "EquipResonanceSkillBlind"
        self.SkillBlind:GetObject("TxtStateName").text = XUiHelper.GetText(stateNameKey)
    elseif not isNeedSelectSkill then
        local iconPath = CS.XGame.ClientConfig:GetString("EquipResonanceRandomSkillIcon") 
        self.SkillBlind:GetObject("ImgHead"):SetRawImage(iconPath)
        self.SkillBlind:GetObject("TxtName").text = XUiHelper.GetText("EquipResonanceRandomSkill")
        self.SkillBlind:GetObject("TxtStateName").gameObject:SetActiveEx(false)
    end
end

-- 刷新共鸣按钮
function XUiEquipResonanceSelectV2P6:UpdateBtnResonance()
    local state, msg = self:GetBtnResonanceState()
    self.BtnResonance:SetDisable(not state)
end

function XUiEquipResonanceSelectV2P6:IsNeedSelectSkill()
    if self.IsWeapon then
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

-- 不需要消耗材料即可共鸣
function XUiEquipResonanceSelectV2P6:CheckIsNoConsumption()
    if self.IsWeapon then
        local isFiveStar = XDataCenter.EquipManager.IsFiveStar(self.EquipId)
        if not isFiveStar then
            return self:SelectCharacterIsBindCharacter()
        else
            return false
        end
    else
        return false
    end
end

-- 检查设置的角色是否为已绑定角色
function XUiEquipResonanceSelectV2P6:SelectCharacterIsBindCharacter()
    local bindCharacterId = XDataCenter.EquipManager.GetResonanceBindCharacterId(self.EquipId, self.Pos)
    return self.SelectCharacterId == bindCharacterId
end

function XUiEquipResonanceSelectV2P6:GetBtnResonanceState()
    if self:IsNeedSelectSkill() and not self.SelectSkillInfo then
        return false, XUiHelper.GetText("EquipResonanceSelectTips")
    else
        if self:CheckIsNoConsumption() then
            return true
        else
            if not self.SelectEquipId and not self.SelectItemId then
                return false, XUiHelper.GetText("EquipResonanceSelectEquipTips")
            else
                return true
            end
        end
    end
end

-- 检测是否打开选择UI
function XUiEquipResonanceSelectV2P6:CheckOpenSelectUi()
    if XLuaUiManager.IsUiShow("UiEquipResonanceSelectCharacterV2P6") or XLuaUiManager.IsUiShow("UiEquipResonanceSelectEquipV2P6")
    or XLuaUiManager.IsUiShow("UiEquipResonanceSkillPreview") then
        return
    end

    local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(self.EquipId)
    if self.CanBlindCharacter and not self.SelectCharacterId then
        self:OnCharacterSelectClick()
        return
    end

    if not self.SelectEquipId and not self.SelectItemId and not self:CheckIsNoConsumption() then
        self:OnItemSelectClick()
        return
    end

    if not self.SelectSkillInfo and self:IsNeedSelectSkill() then
        self:OnSkillSelectClick()
        return
    end
end

function XUiEquipResonanceSelectV2P6:ClearOpenUiTimer()
    if self.CheckOpenUiTimer then
        XScheduleManager.UnSchedule(self.CheckOpenUiTimer)
        self.CheckOpenUiTimer = nil
    end
end

return XUiEquipResonanceSelectV2P6