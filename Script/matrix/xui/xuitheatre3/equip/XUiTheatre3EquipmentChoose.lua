local XUiTheatre3EquipmentTip = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentTip")
local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")

local TodayDontShowKey = "Theatre3EquipmentChoose"
local TipDescTxtKey = "UiTheatre3EquipmentChooseSwitch"

---@class XUiTheatre3EquipmentChoose : XLuaUi 选择装备界面
---@field _Control XTheatre3Control
local XUiTheatre3EquipmentChoose = XLuaUiManager.Register(XLuaUi, "UiTheatre3EquipmentChoose")

function XUiTheatre3EquipmentChoose:OnAwake()
    self._Control:RegisterClickEvent(self, self.BtnYes, self.OnChooseEquip)
    self._Control:RegisterClickEvent(self, self.BtnSetBag, self.OnShowEquip)
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBack)
    self._Control:RegisterClickEvent(self, self.BtnEmpty, self.OnCloseAllBuffDetail)
    self._Control:RegisterClickEvent(self, self.BtnSwitch, self.OnClickBtnSwitch)
    self._Control:RegisterClickEvent(self, self.BtnRefresh, self.OnClickBoxRefresh)
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
    self:UpdateBoxRefreshBtn()
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
    self:InitEquipment()
    self.BtnSetBag.gameObject:SetActiveEx(not self._Inherit)
    self.BtnYes.gameObject:SetActiveEx(false)
    self:HideSlotChoose()
end

function XUiTheatre3EquipmentChoose:InitEquipment()
    ---@type XUiTheatre3EquipmentTip[]
    self._TipMap = {}
    ---@type UnityEngine.Transform
    local bubblePanel
    ---@type UnityEngine.Transform
    local bubbleQuantumPanel
    for i = 1, 3 do
        local equipId = self._Equips[i]
        if not XTool.IsNumberValid(equipId) then
            break
        end
        local isQuantum = self._Control:CheckAdventureSuitIsQuantum(self._Control:GetEquipSuitIdById(equipId))
        bubblePanel = self["BubbleEquipment" .. i]
        bubbleQuantumPanel = self["BubbleQuantumEquipment" .. i]
        bubblePanel.gameObject:SetActiveEx(not isQuantum)
        bubbleQuantumPanel.gameObject:SetActiveEx(isQuantum)
        ---@type XUiTheatre3EquipmentTip
        local tip = XUiTheatre3EquipmentTip.New(isQuantum and bubbleQuantumPanel or bubblePanel, self)
        tip:ShowEquipTip(equipId, nil, nil, self.IsCheck, isQuantum)
        tip:SetBtnDetailCallBack(function()
            self:OnShowDetail(self._Equips[i], isQuantum)
        end)
        tip:SetSelectCallBack(function()
            self:OnSelectEquipment(i)
        end)
        tip:ShowCanActiveTag(self._Control:CanSuitComplete(equipId))
        tip:InitEffectPos()
        self._TipMap[i] = tip
        local btnEquipment = self["BtnEquipment" .. i]
        btnEquipment.CallBack = function()
            self:OnSelectEquipment(i)
        end
        self["ImgSelect" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3EquipmentChoose:CheckEquipTab()
    --边界值：防止继承装备时，装备数量少于3的情况，应该不会出现
    self.BtnEquipment1.gameObject:SetActiveEx(self._Equips[1] ~= nil)
    self.BtnEquipment2.gameObject:SetActiveEx(self._Equips[2] ~= nil)
    self.BtnEquipment3.gameObject:SetActiveEx(self._Equips[3] ~= nil)
end

function XUiTheatre3EquipmentChoose:CheckInitCharacterSelect()
    local index = self:GetFirstCanWearSlot()
    self.CharacterTab:SelectIndex(index)
end

function XUiTheatre3EquipmentChoose:GetFirstCanWearSlot()
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
    return isForbid and belong or 1
end

function XUiTheatre3EquipmentChoose:CheckRecoverIndex()
    -- 如果恢复的槽位没法穿戴该装备，需要重新找一个
    if not self._RecoverIndex then
        return
    end
    local recover = self._CharacterCells[self._RecoverIndex]
    if recover:IsForbidEquip() or not recover:HasEnoughCapcity() then
        self._RecoverIndex = self:GetFirstCanWearSlot()
    end
end

function XUiTheatre3EquipmentChoose:OnSelectSlot(index)
    if self._IsShowEmptySlotTip and self._RecoverIndex and self._RecoverIndex ~= index then
        local charId = self._Control:GetSlotCharacter(index)
        if charId == 0 then
            self._Control:OpenTextTip(handler(self, self.OnEmptySlotTipSure), XUiHelper.GetText("TipTitle"), XUiHelper.GetText("Theatre3EquipEmptySlotTip"), handler(self, self.OnEmptySlotTipCancel), TodayDontShowKey)
        end
        self:CheckRecoverIndex()
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
    local equipId = self._Equips[self._CurSelectEquip]
    local posId = self._CurSelectSlot
    self._Control:RequestSelectEquip(equipId, posId, false)
end

function XUiTheatre3EquipmentChoose:OnShowEquip()
    self._Control:OpenShowEquipPanel()
end

function XUiTheatre3EquipmentChoose:OnSelectEquipment(index)
    self:ShowSlotChoose()
    local isInit = self._CurSelectEquip == nil
    self._LastSelectEquip = self._CurSelectEquip
    self._CurSelectEquip = index
    self.BubbleCharacter.gameObject:SetActiveEx(true)
    self:PlayChooseAnim()
    for i = 1, 3 do
        local isCurSelect = i == index
        if not isCurSelect and self._TipMap[i] then
            self._TipMap[i]:CloseEffectDetail()
        end
        if not self._CharacterCells[i] then
            self._CharacterCells[i] = XUiTheatre3EquipmentCharacter.New(self["CharacterGrid" .. i], self, i)
        end
        self._CharacterCells[i]:UpdateByEquip(self._Equips[index])
        self["ImgSelect" .. i].gameObject:SetActiveEx(isCurSelect)
    end
    if isInit then
        self:CheckInitCharacterSelect()
        self:PlayAnimation("BubbleCharacterEnable")
    end
    self:CheckCharacterShow()
end

function XUiTheatre3EquipmentChoose:PlayChooseAnim()
    if self._LastSelectEquip == self._CurSelectEquip then
        return
    end
    local aniName
    if self._LastSelectEquip then
        aniName = string.format("BtnEquipment%s%s", self._LastSelectEquip, "Small")
        self:PlayAnimation(aniName)
    end
    if self._CurSelectEquip then
        aniName = string.format("BtnEquipment%s%s", self._CurSelectEquip, "Big")
        self:PlayAnimation(aniName)
    end
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
    if isCurHide and newSelect then
        -- 当前选中的装备被隐藏，则重新选中一个能装备上的
        self.CharacterTab:SelectIndex(newSelect)
    end
end

function XUiTheatre3EquipmentChoose:ShowSlotChoose()
    self.BtnYes.gameObject:SetActiveEx(true)
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

function XUiTheatre3EquipmentChoose:OnShowDetail(equipId, isQuantum)
    self._Control:OpenAdventureEquipDetail(equipId, nil, isQuantum)
end

function XUiTheatre3EquipmentChoose:OnCloseAllBuffDetail()
    for i = 1, 3 do
        if self._TipMap[i] then
            self._TipMap[i]:CloseEffectDetail()
        end
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
    for i, v in pairs(self._TipMap) do
        v:ShowDetailOrSimpleTxt(isDetail, self._Control:CheckAdventureSuitIsQuantum(self._Control:GetEquipSuitIdById(self._Equips[i])))
    end
end

--endregion

--region 装备箱刷新

function XUiTheatre3EquipmentChoose:UpdateBoxRefreshBtn()
    self.BtnRefresh.gameObject:SetActiveEx(not self._Inherit)
    self.TxtTimes.gameObject:SetActiveEx(not self._Inherit)
    if self._Inherit then
        return
    end
    local isRefreshTimesNone = false
    local freeTimes, _ = self._Control:GetFreeRefreshTimes()
    self._IsCanFreeRefresh = freeTimes > 0
    if self._IsCanFreeRefresh then
        -- 免费刷新
        self.BtnRefresh:SetRawImageVisible(false)
        self.BtnRefresh:SetNameByGroup(0, "")
        self.BtnRefresh:SetButtonState(CS.UiButtonState.Normal)
    else
        -- 付费刷新
        local payTimes, _ = self._Control:GetPayRefreshTimes()
        local isCanPayRefresh, costNum = self._Control:GetPayRefreshCost()
        self.BtnRefresh:SetRawImageVisible(true)
        self.BtnRefresh:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XEnumConst.THEATRE3.RefreshBoxCoin))
        self.BtnRefresh:SetNameByGroup(0, string.format("<color=%s>x%s</color>", isCanPayRefresh and "#FFFFFF" or "#FF0000", costNum))
        isRefreshTimesNone = payTimes <= 0
    end
    local payTimes, totalPayTimes = self._Control:GetTotalRefreshTimes()
    self.TxtTimes.text = XUiHelper.GetText("Theatre3RefreshTimes", payTimes, totalPayTimes)
    self.BtnRefresh:SetButtonState(isRefreshTimesNone and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiTheatre3EquipmentChoose:UpdateEquips()
    local step = self._Control:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if step then
        self._Equips = step:GetEquipIds()
        for i = 1, 3 do
            local equipId = self._Equips[i]
            if not XTool.IsNumberValid(equipId) then
                break
            end
            local tip = self._TipMap[i]
            local isQuantum = self._Control:CheckAdventureSuitIsQuantum(self._Control:GetEquipSuitIdById(equipId))
            tip:ShowEquipTip(equipId, nil, nil, self.IsCheck, isQuantum)
            tip:ShowCanActiveTag(self._Control:CanSuitComplete(equipId))
            tip:CloseEffectDetail()
        end
        self:CheckEquipTab()
    end
end

function XUiTheatre3EquipmentChoose:OnClickBoxRefresh()
    if self._Control:CheckRefreshEquipBox() then
        self._Control:RefreshEquipBoxRequest(function()
            self:UpdateEquips()
            self:UpdateBoxRefreshBtn()
            if XTool.IsNumberValid(self._CurSelectEquip) then
                self:OnSelectEquipment(self._CurSelectEquip)
            end
        end)
    end
end

--endregion

return XUiTheatre3EquipmentChoose