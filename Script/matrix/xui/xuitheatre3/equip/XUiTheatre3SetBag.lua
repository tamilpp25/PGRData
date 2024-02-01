local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")
local XUiTheatre3EquipmentSuit = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentSuit")
local XUiTheatre3EquipmentCell = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCell")

local Mode = {
    ExchangeSuit = 1,
    RebuildEquip = 2,
    ShowEquip = 3,
    QuantumEquip = 4,
}
local Key = "UiTheatre3SetBagSwitch"

---@class XTheatre3SetBagParam
---@field isExchangeSuit
---@field isQuantumEquip
---@field isRebuildEquip
---@field isShowEquip
---@field autoSelectSuitId

---@class XUiTheatre3SetBag : XLuaUi 选择套装/交换套装
---@field _Control XTheatre3Control
---@field _IsChooseSuit boolean 是否正在选择套装
---@field _IsRebuildChooseSuit boolean 是否正在重铸
local XUiTheatre3SetBag = XLuaUiManager.Register(XLuaUi, "UiTheatre3SetBag")

function XUiTheatre3SetBag:OnAwake()
    if not self.TxtRecastTitle then
        self.TxtRecastTitle = XUiHelper.TryGetComponent(self.PanelRecast, "RImgBg01/Txt", "Text")
    end
    self:AddBtnListener()
end

---@param param XTheatre3SetBagParam
function XUiTheatre3SetBag:OnStart(param)
    self._IsChooseSuit = false
    self._IsRebuildChooseSuit = false
    self:SetMode(param)
    self:InitTitle()
    self:InitCharacter()
    self:InitEquip()
    self:InitSwitchBtn()
end

function XUiTheatre3SetBag:OnEnable()
    self:Update()
    self:AddEventListener()
end

function XUiTheatre3SetBag:OnDisable()
    self:RemoveEventListener()
end

function XUiTheatre3SetBag:OnDestroy()
    self._GridEquipSuitListDir = {}
    self._EmptyGridPool = {}
    self._GridCharacterList = nil
    self._ExpandCell = nil
end

function XUiTheatre3SetBag:Update()
    self:UpdateTitleTimes()
    self:UpdateCharacter()
    self:UpdateSuitList()
end

--region Data - Mode
---@param param XTheatre3SetBagParam
function XUiTheatre3SetBag:SetMode(param)
    if not param then
        self._Mode = Mode.ExchangeSuit
    elseif param.isExchangeSuit then
        self._Mode = Mode.ExchangeSuit
    elseif param.isRebuildEquip then
        self._Mode = Mode.RebuildEquip
    elseif param.isShowEquip then
        self._Mode = Mode.ShowEquip
        self._AutoSelectSuitId = param.autoSelectSuitId
    elseif param.isQuantumEquip then
        self._Mode = Mode.QuantumEquip
    end
end

function XUiTheatre3SetBag:IsShowEquipMode()
    return self:_IsMode(Mode.ShowEquip)
end

---交换套装: 选择套装 -> 选择拆入的位置
function XUiTheatre3SetBag:IsExchangeSuitMode()
    return self:_IsMode(Mode.ExchangeSuit)
end

---重铸装备: 打开套装 -> 选择套装某件装备 -> 选择另一套装
function XUiTheatre3SetBag:IsRebuildEquipMode()
    return self:_IsMode(Mode.RebuildEquip)
end

---量子化: 选择套装 -> 选择套装某件装备
function XUiTheatre3SetBag:IsQuantumEquipMode()
    return self:_IsMode(Mode.QuantumEquip)
end

function XUiTheatre3SetBag:_IsMode(mode)
    return self._Mode == mode
end
--endregion

--region Ui - Title
function XUiTheatre3SetBag:InitTitle()
    if self:IsShowEquipMode() then
        self.TxtTitle.text = XUiHelper.GetText("Theatre3EquipShowTitle")
    elseif self:IsExchangeSuitMode() then
        self.TxtTitle.text = XUiHelper.GetText("Theatre3EquipExchangeSuitSite")
    elseif self:IsQuantumEquipMode() then
        self.TxtTitle.text = XUiHelper.GetText("Theatre3EquipQuantumSelectTitle")
    else
        self.TxtTitle.text = XUiHelper.GetText("Theatre3EquipRebuildTitle")
    end
end

function XUiTheatre3SetBag:UpdateTitleTimes()
    if self:IsShowEquipMode() then
        self.TxtTimesTitle.gameObject:SetActiveEx(false)
    else
        local cur, total = self._Control:GetWorkshopCount()
        self.TxtTimesTitle.text = self:_GetTitleTxt()
        if self:IsQuantumEquipMode() then
            local curLast = total - cur
            self.TxtNum.text = XUiHelper.GetText("Theatre3EquipTimes", curLast < 0 and 0 or curLast, total)
        else
            self.TxtNum.text = XUiHelper.GetText("Theatre3EquipTimes", cur, total)
        end
        self.TxtTimesTitle.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre3SetBag:_GetTitleTxt()
    if self:IsRebuildEquipMode() then
        return XUiHelper.GetText("Theatre3EquipRebuildTimes")
    elseif self:IsExchangeSuitMode() then
        return XUiHelper.GetText("Theatre3EquipExchangeTimes")
    elseif self:IsQuantumEquipMode() then
        return XUiHelper.GetText("Theatre3EquipQuantumTimes")
    end
end
--endregion

--region Ui - Detail Btn
function XUiTheatre3SetBag:InitSwitchBtn()
    if self:IsShowEquipMode() then
        self.IsCheck = self._Control:GetToggleValue(Key)
        self.BtnSwitch.gameObject:SetActiveEx(true)
        self.BtnSwitch:SetButtonState(self.IsCheck and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        self:ShowDetailOrSimpleView(self.IsCheck)
    else
        self.BtnSwitch.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3SetBag:ShowDetailOrSimpleView(isDetailView)
    for _, grids in pairs(self._GridEquipSuitListDir) do
        for _, grid in pairs(grids) do
            grid:DoExpand(isDetailView)
        end
    end
end
--endregion

--region Ui - Character
function XUiTheatre3SetBag:InitCharacter()
    ---@type XUiTheatre3EquipmentCharacter[]
    self._GridCharacterList = {
        XUiTheatre3EquipmentCharacter.New(self.CharacterGrid1, self, 1),
        XUiTheatre3EquipmentCharacter.New(self.CharacterGrid2, self, 2),
        XUiTheatre3EquipmentCharacter.New(self.CharacterGrid3, self, 3),
    }
end

function XUiTheatre3SetBag:UpdateCharacter()
    for _, character in pairs(self._GridCharacterList) do
        character:Update()
    end
end
--endregion

--region Ui - Equip
function XUiTheatre3SetBag:InitEquip()
    ---@type table<number,table<number,XUiTheatre3EquipmentSuit>>
    self._GridEquipSuitListDir = {}
    ---@type XUiTheatre3EquipmentSuit[]
    self._EmptyGridPool = {}
    ---@type UnityEngine.Transform
    self._PanelEmptyList = {
        self.PanelEmpty1,
        self.PanelEmpty2,
        self.PanelEmpty3,
    }
    ---@type UnityEngine.Transform
    self._PanelContentList = {
        self.Content1,
        self.Content2,
        self.Content3,
    }
    
    self.BtnSet.gameObject:SetActiveEx(false)
    self.QuantumSetGrid.gameObject:SetActiveEx(false)
    self.PanelRecast.gameObject:SetActiveEx(false)
end

---@param isAddEmptyGrid boolean 在槽位容量没满的情况下，需不需要显示一个空的格子在最前面
---@param excludeSlot number 不需要显示空格子的槽位
function XUiTheatre3SetBag:UpdateSuitList(isAddEmptyGrid, excludeSlot)
    for pos = 1, 3 do
        self:_UpdateSuitListByPos(pos, isAddEmptyGrid, excludeSlot)
    end
end

function XUiTheatre3SetBag:_UpdateSuitListByPos(pos, isAddEmptyGrid, excludeSlot)
    -- 空格子:用于交换时显示插入的格子
    local emptyCell = self._EmptyGridPool[pos]
    if not emptyCell then
        emptyCell = XUiTheatre3EquipmentSuit.New(XUiHelper.Instantiate(self.BtnSet, self._PanelContentList[pos]), self)
        self._EmptyGridPool[pos] = emptyCell
    end
    local isFull = self._Control:IsSlotFull(pos)
    if isAddEmptyGrid and excludeSlot ~= pos and not isFull then
        emptyCell:Open()
        emptyCell:SetEmptySuit(pos)
    else
        emptyCell:Close()
    end
    -- 槽位下空套装刷新
    local suitList = self._Control:GetSlotSuits(pos)
    if XTool.IsTableEmpty(suitList) then
        self._PanelEmptyList[pos].gameObject:SetActiveEx(true)
        if not XTool.IsTableEmpty(self._GridEquipSuitListDir[pos]) then
            for _, grid in ipairs(self._GridEquipSuitListDir[pos]) do
                grid:Close()
            end
        end
        return
    end
    self._PanelEmptyList[pos].gameObject:SetActiveEx(false)
    -- 槽位下套装刷新
    for i, suitId in ipairs(suitList) do
        if not self._GridEquipSuitListDir[pos] then
            self._GridEquipSuitListDir[pos] = {}
        end
        local grid = self._GridEquipSuitListDir[pos][i]
        local isQuantum = self._Control:CheckAdventureSuitIsQuantum(suitId)
        if not grid then
            grid = XUiTheatre3EquipmentSuit.New(XUiHelper.Instantiate(isQuantum and self.QuantumSetGrid or self.BtnSet, self._PanelContentList[pos]), self)
            self._GridEquipSuitListDir[pos][i] = grid
        end
        grid:Open()
        grid:SetSuitId(suitId, pos, true, not self:IsExchangeSuitMode() and not self:IsQuantumEquipMode())
        grid:IsShowTip(true)
        
        if self:IsExchangeSuitMode() or self:IsQuantumEquipMode() then
            if not self._Control:IsWorkshopHasTimes() then
                grid:SetState(CS.UiButtonState.Disable)
            end
        elseif self:IsRebuildEquipMode() then
            if not self:CheckEquipRebuild(suitId) then
                grid:SetState(CS.UiButtonState.Disable)
            end
        elseif self:IsShowEquipMode() then
            if self._AutoSelectSuitId == grid.SuitConfig.Id then
                grid:DoExpand(true)
            end
        end
    end
    -- 多余装备套装节点隐藏
    for j = #suitList + 1, #self._GridEquipSuitListDir[pos] do
        self._GridEquipSuitListDir[pos][j]:Close()
    end
end

function XUiTheatre3SetBag:SetExpandCell(go)
    if self:IsShowEquipMode() then
        return
    end
    if self._ExpandCell and go then
        self._ExpandCell:DoExpand(false)
    end
    ---@type XUiTheatre3EquipmentSuit
    self._ExpandCell = go
end

function XUiTheatre3SetBag:ChangeListWidth()
    for i = 1, 3 do
        local scrollView = self["SViewSetList" .. i]
        scrollView.offsetMin = Vector2(200, scrollView.offsetMin.y)
        scrollView.offsetMax = Vector2(self._IsRebuildChooseSuit and -300 or 0, scrollView.offsetMax.y)
    end
end
--endregion

--region Ui - SuitChoose
---@param cell XUiTheatre3EquipmentSuit
function XUiTheatre3SetBag:ChooseSrcSuit(cell, isNotShowSelect)
    if self._SrcSuit and self._SrcSuit ~= cell then
        self._SrcSuit:ResetState()
    end
    if cell and not isNotShowSelect then
        cell:MarkSelected()
    end
    ---@type XUiTheatre3EquipmentSuit
    self._SrcSuit = cell
end

function XUiTheatre3SetBag:ChooseDitSuit(cell)
    if self._DstSuit and self._DstSuit ~= cell then
        self._DstSuit:ResetState()
    end
    if cell then
        cell:MarkSelected()
    end
    self._DstSuit = cell
end

---进入选择套装模式
---@param cell XUiTheatre3EquipmentSuit
function XUiTheatre3SetBag:EnterChooseSuitMode(cell)
    self._IsChooseSuit = true
    self:ChooseSrcSuit(cell)
    self:UpdateSuitList(true, cell.SlotId)
    local listCells = self._GridEquipSuitListDir[cell.SlotId] or {}
    for _, v in pairs(listCells) do
        if v ~= cell then
            v:SetState(CS.UiButtonState.Disable)
        end
    end
    cell:MarkSuitSelected()
end

function XUiTheatre3SetBag:ShowSuitTip(cell, suitId)
    if self:IsShowEquipMode() then
        return
    end

    if self:IsExchangeSuitMode() then
        if self._IsChooseSuit and cell == self._SrcSuit then
            --选择状态下点击自己tip不显示按钮
            self._Control:OpenSuitTip(suitId, nil, nil, nil, cell.Transform)
        else
            local btnTxt = self._IsChooseSuit and XUiHelper.GetText("Theatre3EquipExchange") or XUiHelper.GetText("MentorSelectStudentGiveText")
            self._Control:OpenSuitTip(suitId, btnTxt, function()
                if self._IsChooseSuit then
                    self:OpenExchangeSuitTip(cell, false)
                else
                    self:EnterChooseSuitMode(cell)
                end
            end, nil, cell.Transform)
        end
        return
    end

    if self:IsRebuildEquipMode() then
        if self._IsRebuildChooseSuit then
            self:ChooseDitSuit(cell)
            self._Control:OpenSuitTip(suitId, XUiHelper.GetText("Theatre3EquipRebuildEquipTipBtn"), function()
                self:OpenRebuildEquipTip()
            end, handler(self, self._OnRebuildTipClose), cell.Transform)
        end
        return
    end

    if self:IsQuantumEquipMode() then
        if self._Control:CheckAdventureSuitIsQuantum(suitId) then
            XUiManager.TipErrorWithKey("Theatre3AlreadyQuantum")
            return
        end
        if self._IsChooseSuit and cell == self._SrcSuit then
            self._Control:OpenSuitTip(suitId, nil, nil, nil, cell.Transform)
        else
            local btnTxt = XUiHelper.GetText("Theatre3EquipQuantumTitle")
            self._Control:OpenSuitTip(suitId, btnTxt, function()
                self:ChooseSrcSuit(cell, true)
                self:OpenQuantumTip()
            end, nil, cell.Transform)
        end
        return
    end
end

---退出选择套装模式
function XUiTheatre3SetBag:CancelChooseSuitMode()
    self._IsChooseSuit = false
    self:ChooseSrcSuit(nil)
    self:ChooseDitSuit(nil)
    self:UpdateSuitList()
end
--endregion

--region Ui - EquipChoose
function XUiTheatre3SetBag:ShowEquipTip(cell, equipId)
    if self:IsShowEquipMode() then
        self._Control:OpenEquipmentTipByAlign(equipId, nil, nil, nil, cell.Transform, nil, true)
        return
    end

    -- 没解锁的装备不给点
    if not self._Control:IsWearEquip(equipId) then
        return
    end

    if self:IsRebuildEquipMode() then
        self:ChooseSrcSuit(cell)
        self._Control:OpenEquipmentTipByAlign(equipId, XUiHelper.GetText("Theatre3EquipRebuildEquipTipBtn"), function()
            self:EnterRebuildChooseSuitState(cell, equipId)
        end, handler(self, self._OnRebuildTipClose), cell.Transform, nil, true)
        return
    end
end

function XUiTheatre3SetBag:ChooseSrcEquip(equipId)
    self._SrcEquip = equipId
end
--endregion

--region Action - ExChange
---@param cell XUiTheatre3EquipmentSuit
function XUiTheatre3SetBag:OpenExchangeSuitTip(cell, isEmpty)
    self:ChooseDitSuit(cell)
    local desc
    if isEmpty then
        desc = XUiHelper.GetText("Theatre3EquipExchangeEmptySuitTip", self._SrcSuit.SuitConfig.SuitName, self._DstSuit.SlotId)
    else
        desc = XUiHelper.GetText("Theatre3EquipExchangeSuitTip", self._SrcSuit.SuitConfig.SuitName, self._DstSuit.SuitConfig.SuitName)
    end
    self._Control:OpenTextTip(handler(self, self._OnConfirmExchange),
            XUiHelper.GetText("TipTitle"),
            desc, nil, nil,
            { SureText = XUiHelper.GetText("Theatre3SetBagBtnName") })
end

function XUiTheatre3SetBag:_OnConfirmExchange()
    if not self:IsExchangeSuitMode() or not self._IsChooseSuit then
        return
    end
    local dstSuit = self._DstSuit.SuitConfig and self._DstSuit.SuitConfig.Id or 0
    self._Control:RequestChangeSuitPos(self._SrcSuit.SuitConfig.Id, self._SrcSuit.SlotId, dstSuit, self._DstSuit.SlotId)
    self:CancelChooseSuitMode()
end
--endregion

--region Action - Rebuild
function XUiTheatre3SetBag:CheckEquipRebuild(suitId)
    -- 重铸次数不足或者套装满了则不能重铸
    if self._Control:IsSuitComplete(suitId) then
        return false
    end
    if not self._Control:IsWorkshopHasTimes() then
        return false
    end
    return true
end

---选择重铸
---@param cell XUiTheatre3EquipmentSuit
function XUiTheatre3SetBag:EnterRebuildChooseSuitState(cell, equipId)
    self._IsRebuildChooseSuit = true
    self:ChooseSrcEquip(equipId)
    cell:SetState(CS.UiButtonState.Disable)
    for _, cells in pairs(self._GridEquipSuitListDir) do
        for _, v in pairs(cells) do
            if self._Control:IsSuitComplete(v.SuitConfig.Id) then
                v:SetState(CS.UiButtonState.Disable)
            end
            v:ShowHideBtnOpen(false)
        end
    end
    self.PanelRecast.gameObject:SetActiveEx(true)
    if self.TxtRecastTitle then
        self.TxtRecastTitle.text = self._Control:GetClientConfig("EquipWorkShopTipTitle")
    end
    if not self._RebuildEquip then
        ---@type XUiTheatre3EquipmentCell
        self._RebuildEquip = XUiTheatre3EquipmentCell.New(self.EquipmentGrid, self)
    end
    self._RebuildEquip:Open()
    self._RebuildEquip:ShowEquip(equipId)
    self:ChangeListWidth()
end

function XUiTheatre3SetBag:CancelRebuildChooseSuitState()
    self._IsRebuildChooseSuit = false
    self:ChooseDitSuit(nil)
    if self._RebuildEquip then
        self._RebuildEquip:Close()
    end
    self.PanelRecast.gameObject:SetActiveEx(false)
    self:UpdateSuitList()
    self:ChangeListWidth()
end

function XUiTheatre3SetBag:OpenRebuildEquipTip()
    self._Control:OpenTextTip(handler(self, self._OnConfirmRebuild),
            XUiHelper.GetText("TipTitle"),
            XUiHelper.GetText("Theatre3EquipRebuildEquipTip", self._Control:GetEquipById(self._SrcEquip).EquipName))
end

function XUiTheatre3SetBag:_OnConfirmRebuild()
    if not self:IsRebuildEquipMode() or not self._IsRebuildChooseSuit then
        return
    end
    self._Control:RequestRebuildEquip(self._SrcEquip, self._DstSuit.SuitConfig.Id, self._DstSuit.SlotId)
    self:CancelRebuildChooseSuitState()
end

function XUiTheatre3SetBag:_OnRebuildTipClose()
    if not self:IsRebuildEquipMode() or not self._IsRebuildChooseSuit then
        return
    end
    if self._DstSuit then
        self._DstSuit:ResetState()
    end
end
--endregion

--region Action - Quantum
function XUiTheatre3SetBag:OpenQuantumTip()
    self._Control:OpenQuantumTextTip(handler(self, self._OnConfirmQuantum),
            XUiHelper.GetText("TipTitle"),
            XUiHelper.GetText("Theatre3EquipQuantumTipContent", self._SrcSuit.SuitConfig.SuitName))
end

function XUiTheatre3SetBag:_OnConfirmQuantum()
    if not self:IsQuantumEquipMode() or not XTool.IsNumberValid(self._SrcSuit.SuitConfig.Id) then
        return
    end
    self._Control:RequestEquipQuantum(self._SrcSuit.SuitConfig.Id)
end

function XUiTheatre3SetBag:_OnQuantumRefresh()
    if not self:IsQuantumEquipMode() then
        return
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3SetBag:AddBtnListener()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite, handler(self, self.OnBack))
    self:RegisterClickEvent(self.BtnCancel, handler(self, self.CancelRebuildChooseSuitState))
    self:RegisterClickEvent(self.BtnSwitch, handler(self, self.OnClickBtnSwitch))
end

function XUiTheatre3SetBag:OnBack()
    if self:IsShowEquipMode() then
        self:Close()
        return
    end
    if not self:IsShowEquipMode() and self._Control:IsWorkshopHasTimes() then
        local sureCb = handler(self, self._OnBack)
        local title = XUiHelper.GetText("TipTitle")
        local content = XUiHelper.GetText("Theatre3EquipRebuildCloseTip")
        if self:IsQuantumEquipMode() then
            self._Control:OpenQuantumTextTip(sureCb, title, content)
        else
            self._Control:OpenTextTip(sureCb, title, content)
        end
        return
    end
    self:_OnBack()
end

function XUiTheatre3SetBag:_OnBack()
    local closeFunc = function()
        if self._Control:CheckAndOpenAdventureNextStep(true) then
            return
        end
        self:Close()
    end
    local lastStep = self._Control:GetAdventureLastStep()
    if lastStep and lastStep:CheckIsOver() then
        closeFunc()
        return
    end
    self._Control:RequestAdventure3EndWorkShop(function()
        closeFunc()
    end)
end

function XUiTheatre3SetBag:OnClickBtnSwitch()
    self.IsCheck = not self.IsCheck
    self._Control:SaveToggleValue(Key, self.IsCheck)
    self:ShowDetailOrSimpleView(self.IsCheck)
end
--endregion

--region Event
function XUiTheatre3SetBag:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_UPDATE_WORKSHOP_TIMES, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_UPDATE_SLOTCAPACITY, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_UPDATE_EQUIP, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_QUANTUM_SUCCESS, self._OnQuantumRefresh, self)
end

function XUiTheatre3SetBag:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_UPDATE_WORKSHOP_TIMES, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_UPDATE_SLOTCAPACITY, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_UPDATE_EQUIP, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_QUANTUM_SUCCESS, self._OnQuantumRefresh, self)
end
--endregion

return XUiTheatre3SetBag