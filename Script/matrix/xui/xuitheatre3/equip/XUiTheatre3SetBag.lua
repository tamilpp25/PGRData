local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")
local XUiTheatre3EquipmentSuit = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentSuit")
local XUiTheatre3EquipmentCell = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCell")

local Mode = { SelectEquip = 1, SelectSuit = 2, ShowEquip = 3 }
local Key = "UiTheatre3SetBagSwitch"

---@class XUiTheatre3SetBag : XLuaUi 选择套装/交换套装
---@field _Control XTheatre3Control
---@field _IsChooseSuit boolean 是否正在选择套装
---@field _IsChooseEquip boolean 是否正在重铸
local XUiTheatre3SetBag = XLuaUiManager.Register(XLuaUi, "UiTheatre3SetBag")

function XUiTheatre3SetBag:OnAwake()
    self:RegisterClickEvent(self.BtnCancel, handler(self, self.CancelChooseEquipMode))
    self:RegisterClickEvent(self.BtnSwitch, handler(self, self.OnClickBtnSwitch))
end

function XUiTheatre3SetBag:OnStart(param)
    ---@type table<number,table<number,XUiTheatre3EquipmentSuit>>
    self._Pool = {}
    ---@type XUiTheatre3EquipmentSuit[]
    self._EmptyGridPool = {}
    ---@type XUiTheatre3EquipmentCharacter[]
    self._Slots = {}
    self._IsChooseSuit = false
    self._IsChooseEquip = false
    self:SetMode(param)
    self:InitCompnent()
end

function XUiTheatre3SetBag:OnEnable()
    self:Update()
    self:InitSwitchBtn()
end

function XUiTheatre3SetBag:SetMode(param)
    if not param then
        self._Mode = Mode.SelectEquip
    elseif param.isChooseEquip then
        self._Mode = Mode.SelectEquip
    elseif param.isChooseSuit then
        self._Mode = Mode.SelectSuit
    elseif param.isShowEquip then
        self._Mode = Mode.ShowEquip
        self._AutoSelectSuitId = param.autoSelectSuitId
    end
end

function XUiTheatre3SetBag:OnDestroy()
    self._Pool = {}
    self._EmptyGridPool = {}
    self._Slots = {}
    self._ExpandCell = nil
end

function XUiTheatre3SetBag:OnGetEvents()
    return {
        XEventId.EVENT_THEATRE3_UPDATE_WORKSHOP_TIMES,
        XEventId.EVENT_THEATRE3_UPDATE_SLOTCAPACITY,
        XEventId.EVENT_THEATRE3_UPDATE_EQUIP,
    }
end

function XUiTheatre3SetBag:OnNotify(evt)
    self:Update()
end

function XUiTheatre3SetBag:InitCompnent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite, handler(self, self.OnBack))
    self._Slots[1] = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid1, self, 1)
    self._Slots[2] = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid2, self, 2)
    self._Slots[3] = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid3, self, 3)

    if self._Mode == Mode.ShowEquip then
        self.TxtTitle.text = XUiHelper.GetText("Theatre3EquipShowTitle")
    elseif self._Mode == Mode.SelectSuit then
        self.TxtTitle.text = XUiHelper.GetText("Theatre3EquipExchangeSuitSite")
    else
        self.TxtTitle.text = XUiHelper.GetText("Theatre3EquipRebuildTitle")
    end

    ---@type XUiTheatre3EquipmentCell
    self._RebuildEquip = XUiTheatre3EquipmentCell.New(self.EquipmentGrid, self)

    self.BtnSet.gameObject:SetActiveEx(false)
    self.PanelRecast.gameObject:SetActiveEx(false)
end

function XUiTheatre3SetBag:OnBack()
    if self._Mode ~= Mode.ShowEquip and self._Control:IsWorkshopHasTimes() then
        self._Control:OpenTextTip(handler(self, self._OnBack), XUiHelper.GetText("TipTitle"), XUiHelper.GetText("Theatre3EquipRebuildCloseTip"))
        return
    end
    self:_OnBack()
end

function XUiTheatre3SetBag:_OnBack()
    if self._Mode == Mode.ShowEquip then
        self:Close()
        return
    end
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

function XUiTheatre3SetBag:Update()
    self:UpdateSlot()
    self:UpdateSuitList()
    self:UpdateRebuildTimes()
end

function XUiTheatre3SetBag:UpdateRebuildTimes()
    if self._Mode == Mode.ShowEquip then
        self.TxtTimesTitle.gameObject:SetActiveEx(false)
    else
        local cur, total = self._Control:GetWorkshopCount()
        local key = self._Mode == Mode.SelectSuit and "Theatre3EquipExchangeTimes" or "Theatre3EquipRebuildTimes"
        self.TxtTimesTitle.text = XUiHelper.GetText(key)
        self.TxtNum.text = XUiHelper.GetText("Theatre3EquipTimes", cur, total)
        self.TxtTimesTitle.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre3SetBag:UpdateSlot()
    for _, slot in pairs(self._Slots) do
        slot:Update()
    end
end

---@param isAddEmptyGrid boolean 在槽位容量没满的情况下，需不需要显示一个空的格子在最前面
---@param excludeSlot number 不需要显示空格子的槽位
function XUiTheatre3SetBag:UpdateSuitList(isAddEmptyGrid, excludeSlot)
    isAddEmptyGrid = isAddEmptyGrid or false
    for SlotId = 1, 3 do
        local content = self["Content" .. SlotId]

        local emptyCell = self._EmptyGridPool[SlotId]
        if not emptyCell then
            emptyCell = XUiTheatre3EquipmentSuit.New(XUiHelper.Instantiate(self.BtnSet, content), self)
            self._EmptyGridPool[SlotId] = emptyCell
        end
        local isFull = self._Control:IsSlotFull(SlotId)
        if isAddEmptyGrid and excludeSlot ~= SlotId and not isFull then
            emptyCell:Open()
            emptyCell:SetEmptySuit(SlotId)
        else
            emptyCell:Close()
        end

        local datas = self._Control:GetSlotSuits(SlotId)
        if #datas == 0 then
            self["PanelEmpty" .. SlotId].gameObject:SetActiveEx(true)
        else
            for i = 1, #datas do
                local suitId = datas[i]
                if not self._Pool[SlotId] then
                    self._Pool[SlotId] = {}
                end
                local grid = self._Pool[SlotId][i]
                if not grid then
                    grid = XUiTheatre3EquipmentSuit.New(XUiHelper.Instantiate(self.BtnSet, content), self)
                    self._Pool[SlotId][i] = grid
                end
                grid:Open()
                grid:SetSuitId(suitId, SlotId, true, self._Mode ~= Mode.SelectSuit)
                grid:IsShowTip(true)
                if self._Mode == Mode.SelectEquip then
                    if not self:CheckEquipRebuild(suitId) then
                        grid:SetState(CS.UiButtonState.Disable)
                    end
                elseif self._Mode == Mode.SelectSuit then
                    if not self._Control:IsWorkshopHasTimes() then
                        grid:SetState(CS.UiButtonState.Disable)
                    end
                elseif self._Mode == Mode.ShowEquip and self._AutoSelectSuitId == grid.SuitConfig.Id then
                    grid:DoExpand(true)
                end
            end
            self["PanelEmpty" .. SlotId].gameObject:SetActiveEx(false)
        end
        if self._Pool[SlotId] then
            for j = #datas + 1, #self._Pool[SlotId] do
                self._Pool[SlotId][j]:Close()
            end
        end
    end
end

function XUiTheatre3SetBag:ShowSuitTip(cell, suitId)
    if self._Mode ~= Mode.SelectSuit and not self._IsChooseEquip then
        return
    end

    if self._IsChooseSuit and cell == self._SrcSuit then
        --选择状态下点击自己tip不显示按钮
        self._Control:OpenSuitTip(suitId, nil, nil, handler(self, self.OnTipClose), cell.Transform)
    elseif self._IsChooseEquip then
        self:SignDitSuit(cell)
        self._Control:OpenSuitTip(suitId, XUiHelper.GetText("Theatre3EquipRebuildEquipTipBtn"), function()
            self:RebuildEquip()
        end, handler(self, self.OnTipClose), cell.Transform)
    else
        local btnTxt = self._IsChooseSuit and XUiHelper.GetText("Theatre3EquipExchange") or XUiHelper.GetText("MentorSelectStudentGiveText")
        self._Control:OpenSuitTip(suitId, btnTxt, function()
            if self._IsChooseSuit then
                self:ExchangeSuit(cell, false)
            else
                self:EnterChooseSuitMode(cell)
            end
        end, handler(self, self.OnTipClose), cell.Transform)
    end
end

function XUiTheatre3SetBag:ShowEquipTip(cell, equipId)
    if self._Mode == Mode.ShowEquip then
        self._Control:OpenEquipmentTipByAlign(equipId, nil, nil, nil, cell.Transform)
        return
    end
    self:SignSrcSuit(cell)
    self._Control:OpenEquipmentTipByAlign(equipId, XUiHelper.GetText("Theatre3EquipRebuildEquipTipBtn"), function()
        self:EnterChooseEquipMode(cell, equipId)
    end, handler(self, self.OnTipClose), cell.Transform)
end

--region 选中标记

function XUiTheatre3SetBag:SignSrcEquip(equipId)
    self._SrcEquip = equipId
end

function XUiTheatre3SetBag:SignSrcSuit(cell)
    if self._SrcSuit and self._SrcSuit ~= cell then
        self._SrcSuit:ResetState()
    end
    if cell then
        cell:MarkSelected()
    end
    self._SrcSuit = cell
end

function XUiTheatre3SetBag:SignDitSuit(cell)
    if self._DstSuit and self._DstSuit ~= cell then
        self._DstSuit:ResetState()
    end
    if cell then
        cell:MarkSelected()
    end
    self._DstSuit = cell
end

--endregion

--region 选择套装

---进入选择套装模式
---@param cell XUiTheatre3EquipmentSuit
function XUiTheatre3SetBag:EnterChooseSuitMode(cell)
    self._IsChooseSuit = true
    self:SignSrcSuit(cell)
    self:UpdateSuitList(true, cell.SlotId)
    local listCells = self._Pool[cell.SlotId] or {}
    for _, v in pairs(listCells) do
        if v ~= cell then
            v:SetState(CS.UiButtonState.Disable)
        end
    end
    cell:MarkSuitSelected()
end

---退出选择套装模式
function XUiTheatre3SetBag:CancelChooseSuitMode()
    self._IsChooseSuit = false
    self:SignSrcSuit(nil)
    self:SignDitSuit(nil)
    self:UpdateSuitList()
end

---@param cell XUiTheatre3EquipmentSuit
function XUiTheatre3SetBag:ExchangeSuit(cell, isEmpty)
    self:SignDitSuit(cell)
    local desc
    if isEmpty then
        desc = XUiHelper.GetText("Theatre3EquipExchangeEmptySuitTip", self._SrcSuit.SuitConfig.SuitName, self._DstSuit.SlotId)
    else
        desc = XUiHelper.GetText("Theatre3EquipExchangeSuitTip", self._SrcSuit.SuitConfig.SuitName, self._DstSuit.SuitConfig.SuitName)
    end
    self._Control:OpenTextTip(handler(self, self.OnConfirmCb),
            XUiHelper.GetText("TipTitle"),
            desc, nil, nil,
            {
                SureText = XUiHelper.GetText("Theatre3SetBagBtnName")
            })
end

function XUiTheatre3SetBag:OnConfirmCb()
    if self._IsChooseSuit then
        local dstSuit = self._DstSuit.SuitConfig and self._DstSuit.SuitConfig.Id or 0
        self._Control:RequestChangeSuitPos(self._SrcSuit.SuitConfig.Id, self._SrcSuit.SlotId, dstSuit, self._DstSuit.SlotId)
        self:CancelChooseSuitMode()
    elseif self._IsChooseEquip then
        self._Control:RequestRebuildEquip(self._SrcEquip, self._DstSuit.SuitConfig.Id, self._DstSuit.SlotId, function(res)
            XLuaUiManager.Open("UiTheatre3RecastSettlement", self._SrcEquip, res.DstEquipId)
        end)
        self:CancelChooseEquipMode()
    end
end

--endregion

--region 重铸

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
function XUiTheatre3SetBag:EnterChooseEquipMode(cell, equipId)
    self._IsChooseEquip = true
    self:SignSrcEquip(equipId)
    cell:SetState(CS.UiButtonState.Disable)
    for _, cells in pairs(self._Pool) do
        for _, v in pairs(cells) do
            if self._Control:IsSuitComplete(v.SuitConfig.Id) then
                v:SetState(CS.UiButtonState.Disable)
            end
            v:ShowHideBtnOpen(false)
        end
    end
    self.PanelRecast.gameObject:SetActiveEx(true)
    self._RebuildEquip:ShowEquip(equipId)
    self:ChangeListWidth()
end

function XUiTheatre3SetBag:CancelChooseEquipMode()
    self._IsChooseEquip = false
    self:SignDitSuit(nil)
    self.PanelRecast.gameObject:SetActiveEx(false)
    self:UpdateSuitList()
    self:ChangeListWidth()
end

function XUiTheatre3SetBag:RebuildEquip()
    self._Control:OpenTextTip(handler(self, self.OnConfirmCb),
            XUiHelper.GetText("TipTitle"),
            XUiHelper.GetText("Theatre3EquipRebuildEquipTip", self._Control:GetEquipById(self._SrcEquip).EquipName))
end

--endregion

function XUiTheatre3SetBag:OnTipClose()
    if self._IsChooseEquip and self._DstSuit then
        self._DstSuit:ResetState()
    end
end

function XUiTheatre3SetBag:SetExpandCell(go)
    if self._Mode == Mode.ShowEquip then
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
        scrollView.offsetMax = Vector2(self._IsChooseEquip and -300 or 0, scrollView.offsetMax.y)
    end
end

--region 详略按钮

function XUiTheatre3SetBag:InitSwitchBtn()
    if self._Mode == Mode.ShowEquip then
        self.IsCheck = self._Control:GetToggleValue(Key)
        self.BtnSwitch.gameObject:SetActiveEx(true)
        self.BtnSwitch:SetButtonState(self.IsCheck and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        self:ShowDetailOrSimpleView(self.IsCheck)
    else
        self.BtnSwitch.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3SetBag:OnClickBtnSwitch()
    self.IsCheck = not self.IsCheck
    self._Control:SaveToggleValue(Key, self.IsCheck)
    self:ShowDetailOrSimpleView(self.IsCheck)
end

function XUiTheatre3SetBag:ShowDetailOrSimpleView(isDetailView)
    for _, grids in pairs(self._Pool) do
        for _, grid in pairs(grids) do
            grid:DoExpand(isDetailView)
        end
    end
end

--endregion

return XUiTheatre3SetBag