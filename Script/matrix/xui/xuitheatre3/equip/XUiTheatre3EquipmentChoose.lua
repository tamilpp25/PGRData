local XUiTheatre3EquipmentTip = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentTip")
local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")

local TodayDontShowKey = "Theatre3EquipmentChoose"
local TipDescTxtKey = "UiTheatre3EquipmentChooseSwitch"
local SelectScale = Vector3(0.94, 0.94, 0.94)
local NoSelectScale = Vector3(0.86, 0.86, 0.86)

---@class XUiTheatre3EquipmentChoose : XLuaUi 选择装备界面
---@field _Control XTheatre3Control
local XUiTheatre3EquipmentChoose = XLuaUiManager.Register(XLuaUi, "UiTheatre3EquipmentChoose")

function XUiTheatre3EquipmentChoose:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnChooseEquip)
    XUiHelper.RegisterClickEvent(self, self.BtnSetBag, self.OnShowEquip)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBack)
    XUiHelper.RegisterClickEvent(self, self.BtnEmpty, self.OnCloseAllBuffDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch, self.OnClickBtnSwitch)
end

function XUiTheatre3EquipmentChoose:OnStart(equipIds, inherit)
    self._Equips = equipIds
    self._Inherit = inherit or false
    ---@type XUiTheatre3EquipmentCharacter[]
    self._CharacterCells = {}
    self._CurSelectEquip = nil
    self._IsShowEmptySlotTip = not self._Control:GetTodayDontShowValue(TodayDontShowKey)

    self:InitSwitchBtn()
    self:InitComponent()
    self:InitGroup()
    self:CheckEquipTab()
    self:UpdateSuit()
end

function XUiTheatre3EquipmentChoose:OnDestroy()
    self._CharacterCells = {}
end

function XUiTheatre3EquipmentChoose:InitGroup()
    local tabs = {}
    table.insert(tabs, self.CharacterGrid1)
    table.insert(tabs, self.CharacterGrid2)
    table.insert(tabs, self.CharacterGrid3)
    self.CharacterTab:Init(tabs, function(index)
        self:OnSelectSlot(index)
    end)
end

function XUiTheatre3EquipmentChoose:InitComponent()
    ---@type XUiTheatre3EquipmentTip[]
    self._TipMap = {}
    for i = 1, 3 do
        local equipId = self._Equips[i]
        ---@type XUiTheatre3EquipmentTip
        local tip = XUiTheatre3EquipmentTip.New(self["BubbleEquipment" .. i], self)
        local funcShowDetail = function()
            self:OnShowDetail(equipId)
        end
        tip:ShowEquipTip(equipId, nil, nil, self.IsCheck)
        tip:SetBtnDetailCallBack(funcShowDetail)
        tip:SetSelectCallBack(function()
            self:OnSelectEquipment(i)
        end)
        self._TipMap[i] = tip
        self._CharacterCells[i] = XUiTheatre3EquipmentCharacter.New(self["CharacterGrid" .. i], self, i)
        self["BtnEquipment" .. i].CallBack = function()
            self:OnSelectEquipment(i)
        end
        self["ImgSelect" .. i].gameObject:SetActiveEx(false)
    end

    self.BtnSetBag.gameObject:SetActiveEx(not self._Inherit)
    self.BtnYes.gameObject:SetActiveEx(false)
    self:HideSlotChoose()
end

function XUiTheatre3EquipmentChoose:CheckEquipTab()
    --边界值：防止继承装备时，装备数量少于3的情况，应该不会出现
    self.BtnEquipment1.gameObject:SetActiveEx(self._Equips[1] ~= nil)
    self.BtnEquipment2.gameObject:SetActiveEx(self._Equips[2] ~= nil)
    self.BtnEquipment3.gameObject:SetActiveEx(self._Equips[3] ~= nil)
end

function XUiTheatre3EquipmentChoose:CheckInitCharacterSelect()
    --如果同套装下的某个装备穿戴在该槽位上，那么其余装备也只能放在这个槽位上
    local isForbid = false
    local belong = nil
    for i, v in ipairs(self._CharacterCells) do
        if v:IsForbidEquip() or not v:HasEnoughCapcity() then
            isForbid = true
        elseif not belong then
            belong = i
        end
    end
    self.CharacterTab:SelectIndex(isForbid and belong or 1)
end

function XUiTheatre3EquipmentChoose:OnSelectSlot(index)
    if self._IsShowEmptySlotTip and self._RecoverIndex and self._RecoverIndex ~= index then
        local charId = self._Control:GetSlotCharacter(index)
        if charId == 0 then
            self._Control:OpenTextTip(handler(self, self.OnEmptySlotTipSure), XUiHelper.GetText("TipTitle"), XUiHelper.GetText("Theatre3EquipEmptySlotTip"), handler(self, self.OnEmptySlotTipCancel), TodayDontShowKey)
        end
    else
        self._RecoverIndex = index
    end
    self._CurSelectSlot = index
    if self._CharacterCells[index]:IsForbidEquip() then
        XUiManager.TipMsg(XUiHelper.GetText("Theatre3EquipSiteTip"))
        return
    end
    if not self._CharacterCells[index]:HasEnoughCapcity() then
        XUiManager.TipMsg(XUiHelper.GetText("Theatre3EquipCapcityTip"))
        return
    end
    self:OnSelectEquipment(self._CurSelectEquip)
end

function XUiTheatre3EquipmentChoose:OnEmptySlotTipSure()
    self._IsShowEmptySlotTip = false
end

function XUiTheatre3EquipmentChoose:OnEmptySlotTipCancel()
    self.CharacterTab:SelectIndex(self._RecoverIndex)
    self._IsShowEmptySlotTip = not self._Control:GetTodayDontShowValue(TodayDontShowKey)
end

function XUiTheatre3EquipmentChoose:OnChooseEquip()
    self._Control:RequestSelectEquip(self._Equips[self._CurSelectEquip], self._CurSelectSlot, function()
        self._Control:CheckAndOpenAdventureNextStep(true)
    end)
end

function XUiTheatre3EquipmentChoose:OnShowEquip()
    self._Control:OpenShowEquipPanel()
end

function XUiTheatre3EquipmentChoose:OnSelectEquipment(index)
    local isInit = self._CurSelectEquip == nil
    self._CurSelectEquip = index
    for i = 1, 3 do
        local isCurSelect = i == index
        if not isCurSelect then
            self._TipMap[i]:CloseEffectDetail()
        end
        self._CharacterCells[i]:UpdateByEquip(self._Equips[index])
        self["BtnEquipment" .. i].transform.localScale = isCurSelect and SelectScale or NoSelectScale
        self["ImgSelect" .. i].gameObject:SetActiveEx(isCurSelect)
    end
    if isInit then
        self:CheckInitCharacterSelect()
        self:ShowSlotChoose()
    end
    self:CheckCharacterShow()
end

function XUiTheatre3EquipmentChoose:CheckCharacterShow()
    local isCurHide = false
    local newSelect = nil
    for i, v in ipairs(self._CharacterCells) do
        local canWear = v:CheckCharacterEquip()
        if canWear then
            v:Open()
            if not newSelect then
                newSelect = i
            end
        else
            v:Close() -- 穿不了当前装备则隐藏
            if i == self._CurSelectSlot then
                isCurHide = true
            end
        end
    end
    if isCurHide and newSelect then -- 当前选中的装备被隐藏，则重新选中一个能装备上的
        self.CharacterTab:SelectIndex(newSelect)
    end
end

function XUiTheatre3EquipmentChoose:ShowSlotChoose()
    self.BubbleCharacter.gameObject:SetActiveEx(true)
    self.BtnYes.gameObject:SetActiveEx(true)
    self.PanelEquipment.spacing = 30
    self.PanelZB.padding.left = -140
    self.BtnSwitch.transform.anchoredPosition = Vector2(self.BtnSwitchPosX - self.BubbleCharacter.rect.width, self.BtnSwitchPosY)
end

function XUiTheatre3EquipmentChoose:HideSlotChoose()
    self.BubbleCharacter.gameObject:SetActiveEx(false)
    self.BtnYes.gameObject:SetActiveEx(false)
    self.PanelEquipment.spacing = 80
    self.PanelZB.padding.left = 0
    self.BtnSwitch.transform.anchoredPosition = Vector2(self.BtnSwitchPosX, self.BtnSwitchPosY)
end

function XUiTheatre3EquipmentChoose:UpdateSuit()
    local count = self._Control:GetSlotCapcity(1) + self._Control:GetSlotCapcity(2) + self._Control:GetSlotCapcity(3)
    self.BtnSetBag:SetNameByGroup(0, XUiHelper.ReadTextWithNewLine("Theatre3EquipSuitNumNewLine", count))
end

function XUiTheatre3EquipmentChoose:OnBack()
    self._Control:OpenTextTip(handler(self, self.Close), XUiHelper.ReadTextWithNewLineWithNotNumber("TipTitle"), XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3EquipBackTip"))
end

function XUiTheatre3EquipmentChoose:OnShowDetail(equipId)
    XLuaUiManager.Open("UiTheatre3SetDetail", equipId)
end

function XUiTheatre3EquipmentChoose:OnCloseAllBuffDetail()
    for i = 1, 3 do
        self._TipMap[i]:CloseEffectDetail()
    end
end

--region 详略按钮

function XUiTheatre3EquipmentChoose:InitSwitchBtn()
    self.IsCheck = self._Control:GetToggleValue(TipDescTxtKey)
    self.BtnSwitch:SetButtonState(self.IsCheck and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    if not self.BtnSwitchPosX or not self.BtnSwitchPosY then
        self.BtnSwitchPosX = self.BtnSwitch.transform.anchoredPosition.x
        self.BtnSwitchPosY = self.BtnSwitch.transform.anchoredPosition.y
    end
end

function XUiTheatre3EquipmentChoose:OnClickBtnSwitch()
    self.IsCheck = not self.IsCheck
    self._Control:SaveToggleValue(TipDescTxtKey, self.IsCheck)
    self:ShowDetailOrSimpleView(self.IsCheck)
end

function XUiTheatre3EquipmentChoose:ShowDetailOrSimpleView(isDetail)
    for _, v in pairs(self._TipMap) do
        v:ShowDetailOrSimpleTxt(isDetail)
    end
end

--endregion

return XUiTheatre3EquipmentChoose