---@class XUiTheatre3EquipmentCharacter : XUiNode 槽位信息
---@field _Control XTheatre3Control
local XUiTheatre3EquipmentCharacter = XClass(XUiNode, "XUiTheatre3EquipmentCharacter")

function XUiTheatre3EquipmentCharacter:OnStart(slotId)
    self._SlotId = slotId
    self:Init()
end

function XUiTheatre3EquipmentCharacter:Init()
    if self.ImgType then
        self.ImgType.gameObject:SetActiveEx(false)
    end
    if self.PanelLv then
        self.PanelLv.gameObject:SetActiveEx(false)
    end
    if self.PanelExp then
        self.PanelExp.gameObject:SetActiveEx(false)
    end
    if self.PanelLvUp then
        self.PanelLvUp.gameObject:SetActiveEx(false)
    end
    if self.TxtLoad then
        self.TxtLoad.gameObject:SetActiveEx(false)
    end
    if self.ImgShuZi then
        local icon = self._Control:GetClientConfig("Theatre3SlotIndexIcon", self._SlotId)
        self.ImgShuZi:SetSprite(icon)
    end
end

function XUiTheatre3EquipmentCharacter:UpdateByEquip(equipId)
    self._EquipId = equipId
    self:ShowHead()
    self:ShowCapcity()
    self:SetButtonState()
end

function XUiTheatre3EquipmentCharacter:Update()
    self:ShowHead()
    self:ShowCapcity()
end

function XUiTheatre3EquipmentCharacter:ShowHead()
    local characterId = self._Control:GetSlotCharacter(self._SlotId)
    local isNoEmpty = characterId ~= 0
    if isNoEmpty then
        ---@type XCharacterAgency
        local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
        local characterIcon = characterAgency:GetCharSmallHeadIcon(characterId)
        self.ImgRole:SetRawImage(characterIcon)
    end
    if self.ImgBg2 then
        self.ImgBg2.gameObject:SetActiveEx(isNoEmpty) --该槽位没有角色
    elseif self.ImgRole then
        self.ImgRole.gameObject:SetActiveEx(isNoEmpty)
    end
end

function XUiTheatre3EquipmentCharacter:ShowCapcity()
    if not self.TxtLv then
        return
    end
    if self.PanelLv then
        self.PanelLv.gameObject:SetActiveEx(true)
    end
    local cur = self._Control:GetSlotCapcity(self._SlotId)
    local all = self._Control:GetSlotMaxCapcity(self._SlotId)

    self._HasCapacity = cur < all

    local desc = self._Control:GetClientConfig("Theatre3EquipCapcityDesc", self._HasCapacity and 1 or 2)
    self.TxtLv.text = string.format(desc, cur, all)
end

function XUiTheatre3EquipmentCharacter:SetButtonState()
    if not self:CheckCharacterEquip() then
        self.CharacterGrid:SetButtonState(CS.UiButtonState.Disable)
    else
        if self.CharacterGrid.ButtonState == CS.UiButtonState.Disable then
            self.CharacterGrid:SetButtonState(CS.UiButtonState.Normal)
        end
    end
end

function XUiTheatre3EquipmentCharacter:CheckCharacterEquip()
    --容量未满 或者 该套装有任意一件其他装备穿戴在该槽位上
    return self._Control:CheckCharacterEquip(self._SlotId, self._EquipId)
end

function XUiTheatre3EquipmentCharacter:IsForbidEquip()
    --一件套装里的所有装备只能穿戴在同个槽位上
    local belong = self:GetBelong()
    return belong ~= -1 and belong ~= self._SlotId
end

---是否有足够的容量
function XUiTheatre3EquipmentCharacter:HasEnoughCapcity()
    local belong = self:GetBelong()
    if belong == self._SlotId then
        return true
    end
    return self._HasCapacity
end

function XUiTheatre3EquipmentCharacter:GetBelong()
    local equipCfg = self._Control:GetEquipById(self._EquipId)
    return self._Control:GetSuitBelong(equipCfg.SuitId)
end

function XUiTheatre3EquipmentCharacter:IsShowCapacity(isActive)
    if self.PanelLv then
        self.PanelLv.gameObject:SetActiveEx(isActive)
    end
end

return XUiTheatre3EquipmentCharacter