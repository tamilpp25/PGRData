local XGridTheatre3MainCharacter = require("XUi/XUiTheatre3/Adventure/Main/XGridTheatre3MainCharacter")
local XGridTheatre3MainEquipSuit = require("XUi/XUiTheatre3/Adventure/Main/XGridTheatre3MainEquipSuit")

---@class XPanelTheatre3MainRoleInfo : XUiNode
---@field _Control XTheatre3Control
local XPanelTheatre3MainRoleInfo = XClass(XUiNode, "XPanelTheatre3MainRoleInfo")

function XPanelTheatre3MainRoleInfo:OnStart()
    self:AddBtnListener()
    self:InitCharacter()
    self:InitEquipSuit()
end

function XPanelTheatre3MainRoleInfo:OnEnable()
    self:AddEventListener()
end

function XPanelTheatre3MainRoleInfo:OnDisable()
    self:RemoveEventListener()
end

function XPanelTheatre3MainRoleInfo:Refresh(slotId)
    self._SlotId = slotId

    local equipSuitIdList = self._Control:GetSlotSuits(self._SlotId)
    self:RefreshCharacter()
    self:RefreshEquipSuit()
    if XTool.IsTableEmpty(equipSuitIdList) then
        self:SetIsSelect()
    end
end

function XPanelTheatre3MainRoleInfo:SetIsSelect(slotId)
    if self._IsSelect and self._SlotId == slotId then
        self._IsSelect = false
    else
        self._IsSelect = self._SlotId == slotId
    end
    self.PanelSet.gameObject:SetActiveEx(self._IsSelect)
    self.BtnOpen.gameObject:SetActiveEx(self._IsSelect)
    self:RefreshEquipSuit()
end

--region Ui - Character
function XPanelTheatre3MainRoleInfo:InitCharacter()
    ---@type XGridTheatre3MainCharacter
    self._Character = XGridTheatre3MainCharacter.New(self.CharacterGrid.transform, self)
end

function XPanelTheatre3MainRoleInfo:RefreshCharacter()
    self._Character:Refresh(self._SlotId)
    self.TxtSuit.text = self._Control:GetSlotCapcity(self._SlotId).."/"..self._Control:GetSlotMaxCapcity(self._SlotId)
end
--endregion

--region Ui - EquipSuit
function XPanelTheatre3MainRoleInfo:InitEquipSuit()
    local isShow = self.PanelSet.gameObject.activeInHierarchy
    self.PanelSet.gameObject:SetActiveEx(true)
    ---@type XGridTheatre3MainEquipSuit[]
    self._SuitList = {
        XGridTheatre3MainEquipSuit.New(self.BtnSet1, self),
        XGridTheatre3MainEquipSuit.New(self.BtnSet2, self),
        XGridTheatre3MainEquipSuit.New(self.BtnSet3, self),
    }
    self.BtnOpen.gameObject:SetActiveEx(true)
    self.PanelSet.gameObject:SetActiveEx(isShow)
end

function XPanelTheatre3MainRoleInfo:RefreshEquipSuit()
    if not self.PanelSet.gameObject.activeInHierarchy then
        return
    end
    local equipSuitIdList = self._Control:GetSlotSuits(self._SlotId)
    if XTool.IsTableEmpty(equipSuitIdList) then
        for _, suitGrid in ipairs(self._SuitList) do
            suitGrid:Close()
        end
        return
    end
    for i, suitGrid in ipairs(self._SuitList) do
        if XTool.IsNumberValid(equipSuitIdList[i]) then
            suitGrid:Refresh(equipSuitIdList[i])
            suitGrid:Open()
        else
            suitGrid:Close()
        end
    end
end

function XPanelTheatre3MainRoleInfo:OnOpenEquip(index)
    local equipSuitIdList = self._Control:GetSlotSuits(self._SlotId)
    if XTool.IsTableEmpty(equipSuitIdList) then
        return
    end
    self._Control:OpenShowEquipPanel(equipSuitIdList[index])
end
--endregion

--region Ui - BtnListener
function XPanelTheatre3MainRoleInfo:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.CharacterGrid, self.OnBtnCharacterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSet1, function()
        self:OnOpenEquip(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnSet2, function()
        self:OnOpenEquip(2)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnSet3, function()
        self:OnOpenEquip(3)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnOpen, self.OnBtnOpenClick)
end

function XPanelTheatre3MainRoleInfo:OnBtnOpenClick()
    self._Control:OpenShowEquipPanel()
end

function XPanelTheatre3MainRoleInfo:OnBtnCharacterClick()
    --local equipSuitIdList = self._Control:GetSlotSuits(self._SlotId)
    --if XTool.IsTableEmpty(equipSuitIdList) then
    --    XUiManager.TipErrorWithKey("Theatre3PlayRoleNoEquipTip")
    --    return
    --end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_SELECT_ROLE, self._SlotId)
end
--endregion

--region Event
function XPanelTheatre3MainRoleInfo:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_SELECT_ROLE, self.SetIsSelect, self)
end

function XPanelTheatre3MainRoleInfo:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_SELECT_ROLE, self.SetIsSelect, self)
end
--endregion

return XPanelTheatre3MainRoleInfo