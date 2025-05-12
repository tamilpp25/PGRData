local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")

---@class XUiTheatre3TeamInstall : XLuaUi 队伍调整
---@field _Control XTheatre3Control
local XUiTheatre3TeamInstall = XLuaUiManager.Register(XLuaUi, "UiTheatre3TeamInstall")

function XUiTheatre3TeamInstall:OnAwake()
    self.BtnTanchuangClose.CallBack = handler(self, self.OnBack)
    self.BtnYes.CallBack = handler(self, self.OnSave)
    self.BtnAnimationSet.CallBack = handler(self, self.OnBtnAnimationSetClick)
end

function XUiTheatre3TeamInstall:OnStart()
    self._ColorTab = {}
    self._Colors = {}
    self._Forbids = {}

    for i = 1, 3 do
        self._Colors[i] = self._Control:GetSlotOrder(i)
    end

    self:InitCompnent()
    self:CheckButtonForbid()
end

function XUiTheatre3TeamInstall:OnEnable()
    self:OnAnimationSetChange()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_ANIM_ENABLE, self.OnAnimationSetChange, self)
end

function XUiTheatre3TeamInstall:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_ANIM_ENABLE, self.OnAnimationSetChange, self)
end

function XUiTheatre3TeamInstall:OnDestroy()

end

function XUiTheatre3TeamInstall:InitCompnent()
    for i = 1, 3 do
        local go = self["PanelColur" .. i]
        local uiObject = {}
        XTool.InitUiObjectByUi(uiObject, go)
        go:Init({ uiObject.BtnRed, uiObject.BtnBlud, uiObject.BtnYellow }, function(index)
            self:OnSelectColor(index, i)
        end)
        go:SelectIndex(self._Colors[i])
        self._ColorTab[i] = go
    end

    self.CaptainTab:Init({ self.BtnCaptain1, self.BtnCaptain2, self.BtnCaptain3 }, function(index)
        self:OnSelectCaptain(index)
    end)
    self.CaptainTab:SelectIndex(self._Control:GetEquipCaptainPos())

    self.FirstFightTab:Init({ self.BtnFirst1, self.BtnFirst2, self.BtnFirst3 }, function(index)
        self:OnSelectFirstFight(index)
    end)
    self.FirstFightTab:SelectIndex(self._Control:GetEquipFirstFightPos())

    local char1 = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid1, self, 1)
    local char2 = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid2, self, 2)
    local char3 = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid3, self, 3)
    char1:Update()
    char2:Update()
    char3:Update()
    char1:IsShowCapacity(false)
    char2:IsShowCapacity(false)
    char3:IsShowCapacity(false)

    self.BtnYes:SetButtonState(CS.UiButtonState.Disable)
end

function XUiTheatre3TeamInstall:CheckButtonForbid()
    for i = 1, 3 do
        if not self._Control:CheckIsHaveCharacter(i) then
            self._Forbids[i] = true
            if self.CaptainTab.CurSelectId == i then
                self._CaptainForbidBtn = self["BtnCaptain" .. i]
            else
                self["BtnCaptain" .. i]:SetButtonState(CS.UiButtonState.Disable)
            end
            if self.FirstFightTab.CurSelectId == i then
                self._FirstFightForbidBtn = self["BtnFirst" .. i]
            else
                self["BtnFirst" .. i]:SetButtonState(CS.UiButtonState.Disable)
            end
        end
    end
end

function XUiTheatre3TeamInstall:OnSelectColor(colorIndex, index)
    local dstColor = self._Colors[index]
    if dstColor == colorIndex then
        return
    end
    for i, color in ipairs(self._Colors) do
        if i ~= index and color == colorIndex then
            self._Colors[i] = dstColor
            self._Colors[index] = colorIndex
            self._ColorTab[i]:SelectIndex(dstColor)
            self:UpdateButtonState()
            return
        end
    end
end

function XUiTheatre3TeamInstall:OnSelectCaptain(index)
    if self._Forbids[index] then
        return
    end
    if self._CaptainForbidBtn then
        self._CaptainForbidBtn:SetButtonState(CS.UiButtonState.Disable)
        self._CaptainForbidBtn = nil
    end
    self._CurCaptain = index
    self:UpdateButtonState()
end

function XUiTheatre3TeamInstall:OnSelectFirstFight(index)
    if self._Forbids[index] then
        return
    end
    if self._FirstFightForbidBtn then
        self._FirstFightForbidBtn:SetButtonState(CS.UiButtonState.Disable)
        self._FirstFightForbidBtn = nil
    end
    self._CurFirstFight = index
    self:UpdateButtonState()
end

function XUiTheatre3TeamInstall:CheckSettingChange()
    for i = 1, 3 do
        local slotInfo = self._Control:GetSlotInfo(i)
        if slotInfo:GetColorId() ~= self._Colors[i] then
            return true
        end
        if self._Control:CheckIsCaptainPos(slotInfo:GetColorId()) and i ~= self._CurCaptain then
            return true
        end
        if self._Control:CheckIsFirstFightPos(slotInfo:GetColorId()) and i ~= self._CurFirstFight then
            return true
        end
    end
    return false
end

function XUiTheatre3TeamInstall:UpdateButtonState()
    self.BtnYes:SetButtonState(self:CheckSettingChange() and XUiButtonState.Normal or XUiButtonState.Disable)
end

function XUiTheatre3TeamInstall:OnSave()
    if self.BtnYes.ButtonState == XUiButtonState.Disable then
        XUiManager.TipMsg(XUiHelper.GetText("Theatre3SaveTeamSettingTip"))
        return
    end
    local slotInfo1 = self._Control:GetSlotInfo(self._CurCaptain)
    local slotInfo2 = self._Control:GetSlotInfo(self._CurFirstFight)
    if not slotInfo1:CheckIsHaveCharacter() then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if not slotInfo2:CheckIsHaveCharacter() then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    local resultEntityIdList = {}
    for pos, ColorId in pairs(self._Colors) do
        local slotInfo = self._Control:GetSlotInfo(pos)
        slotInfo:UpdateEquipPosColorId(ColorId)
        resultEntityIdList[ColorId] = slotInfo:GetRoleId()
    end
    self._Control:UpdateTeamEntityIdList(resultEntityIdList)
    self._Control:UpdateCaptainPosAndFirstFightPos(slotInfo1:GetColorId(), slotInfo2:GetColorId())
    self._Control:RequestSetTeam()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_SAVE_TEAM)
    self:Close()
end

function XUiTheatre3TeamInstall:OnBack()
    if self:CheckSettingChange() then
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("Theatre3SetTeamBackTip"),
                XUiManager.DialogType.Normal, handler(self, self.Close), handler(self, self.OnSave))
        return
    end
    self:Close()
end

function XUiTheatre3TeamInstall:OnBtnAnimationSetClick()
    local team = self._Control:GetTeamData()
    ---@type TeamAnimationSetParam
    local param = {}
    param.EnterCgIndex = team:GetEnterCgIndex()
    param.SettleCgIndex = team:GetSettleCgIndex()
    param.OnSave = function(enterCgIndex, settleCgIndex)
        team:SetEnterCgIndex(enterCgIndex)
        team:SetSettleCgIndex(settleCgIndex)
        team:Save()
    end

    param.EntitiyIds = {}
    local map = {}
    for pos, ColorId in pairs(self._Colors) do
        local slotInfo = self._Control:GetSlotInfo(pos)
        param.EntitiyIds[ColorId] = slotInfo:GetRoleId()
        map[pos] = ColorId
    end

    param.FirstFightPos = map[self._CurFirstFight]

    XLuaUiManager.Open("UiPopupAnimationSet", nil, param)
end

function XUiTheatre3TeamInstall:OnAnimationSetChange()
    self.BtnAnimationSet.gameObject:SetActiveEx(XMVCA.XFuben:IsFightCgEnable())
end

return XUiTheatre3TeamInstall