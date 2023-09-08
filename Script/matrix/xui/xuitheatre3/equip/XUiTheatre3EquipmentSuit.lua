local XUiTheatre3EquipmentCell = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCell")

local ShowType = { Open = 1, Close = 2, Cancel = 3, Empty = 4 }

---@class XUiTheatre3EquipmentSuit : XUiNode 套装
---@field Parent XUiTheatre3SetBag
---@field _Control XTheatre3Control
---@field SlotId number
local XUiTheatre3EquipmentSuit = XClass(XUiNode, "XUiTheatre3EquipmentSuit")

function XUiTheatre3EquipmentSuit:OnStart(callBack)
    self._Cb = callBack
    self:Init()
end

function XUiTheatre3EquipmentSuit:Init()
    self.SetGrid.CallBack = handler(self, self.OnShowSuitTip)
    self.BtnCancel.CallBack = handler(self, self.OnBtnCancel)
    XUiHelper.RegisterClickEvent(self, self.PanelEmpty, self.OnBtnWear)
    XUiHelper.RegisterClickEvent(self, self.BtnOpen, self.OnExpand)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnExpand)
    XUiHelper.RegisterClickEvent(self, self.ImgMask, self.OnBtnDisableMask)
    self:DoExpand(false)
    self:IsShowTip(false)
    self:ShowHideCompleteBg(false)
    self:ShowHideBtnOpen(true)
end

function XUiTheatre3EquipmentSuit:SetSuitId(suitId, slotId, isShowBg, isShowBtn)
    isShowBg = isShowBg == nil and true or isShowBg
    isShowBtn = isShowBtn == nil and true or isShowBtn
    self.SlotId = slotId == nil and self._Control:GetSuitBelong(suitId) or slotId
    self.SuitConfig = self._Control:GetSuitById(suitId)
    self.TxtName.text = self.SuitConfig.SuitName
    self.RImgSet:SetRawImage(self.SuitConfig.Icon)
    self._Equips = self._Control:GetAllSuitEquip(suitId)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    self.PanelCancel.gameObject:SetActiveEx(false)
    self:ShowHideCompleteBg(isShowBg and self._Control:IsSuitComplete(suitId) or false)
    self:ShowHideBtnOpen(isShowBtn)
    self:ResetState()
    self.ImgType1.gameObject:SetActiveEx(self.SuitConfig.UseType == 1)
    self.ImgType2.gameObject:SetActiveEx(self.SuitConfig.UseType == 2)
    self:ShowSuitAllPos()
end

function XUiTheatre3EquipmentSuit:ShowSuitAllPos()
    if not self.SuitConfig then
        return
    end
    local equips = self._Control:GetAllSuitEquip(self.SuitConfig.Id)
    local poolName = "Theatre3Suit" .. self.Transform:GetInstanceID()
    ---@param data XTableTheatre3Equip
    self.Parent:RefreshTemplateGrids(self.GridNumber, equips, self.GridNumber.parent, nil, poolName, function(grid, data)
        grid.BgType1.gameObject:SetActiveEx(data.UseType == 1)
        grid.BgType2.gameObject:SetActiveEx(data.UseType == 2)
        grid.TxtNum.text = XTool.ConvertRomanNumberString(data.PosType)
        grid.BgDisable.gameObject:SetActiveEx(not self._Control:IsWearEquip(data.Id))
    end)
end

---是否需要显示满编背景
function XUiTheatre3EquipmentSuit:ShowHideCompleteBg(bo)
    --self.ImgCompleteBg.gameObject:SetActiveEx(bo)
end

---是否需要显示展开按钮
function XUiTheatre3EquipmentSuit:ShowHideBtnOpen(bo)
    self._IsShowOpen = bo
    self.ImgOpen.gameObject:SetActiveEx(bo)
    self.BtnOpen.gameObject:SetActiveEx(bo)
    self.ImgNo.gameObject:SetActiveEx(not bo)
end

function XUiTheatre3EquipmentSuit:SetEquip(index)
    local go = self["EquipmentGrid" .. index]
    if #self._Equips >= index then
        local equipId = self._Equips[index].Id
        go.gameObject:SetActiveEx(true)
        ---@type XUiTheatre3EquipmentCell
        local equip = self["_Equipment" .. index]
        if not equip then
            equip = XUiTheatre3EquipmentCell.New(go, self.Parent, equipId)
            self["_Equipment" .. index] = equip
        else
            equip:ShowEquip(equipId)
        end
        equip:SetState(not self._Control:IsWearEquip(equipId))
        equip:AddClick(function()
            self:OnShowEquipTip(equipId)
        end)
    else
        go.gameObject:SetActiveEx(false)
    end
end

---是否显示Tip，默认关闭
function XUiTheatre3EquipmentSuit:IsShowTip(bo)
    self._IsShowTip = bo
end

function XUiTheatre3EquipmentSuit:DoExpand(isExpand)
    self._IsExpand = isExpand
    self:UpdateShowState(self._IsExpand and ShowType.Open or ShowType.Close, CS.UiButtonState.Normal)
end

function XUiTheatre3EquipmentSuit:OnShowSuitTip()
    if self._IsShowTip then
        if self.Parent.ShowSuitTip then
            self.Parent:ShowSuitTip(self, self.SuitConfig.Id)
        else
            self._Control:OpenSuitTip(self.SuitConfig.Id, nil, nil, nil, self.Transform)
        end
        return
    end
    if self._Cb then
        self._Cb(self)
    end
end

function XUiTheatre3EquipmentSuit:OnShowEquipTip(equipId)
    if self._IsShowTip and self._IsExpand then
        if self.Parent.ShowEquipTip then
            self.Parent:ShowEquipTip(self, equipId)
        else
            self._Control:OpenEquipmentTipByAlign(equipId, nil, nil, nil, self.Transform)
        end
        return
    end
    if not self._IsShowTip and self._Cb then
        self._Cb(self)
    end
end

function XUiTheatre3EquipmentSuit:OnExpand()
    if not self._IsShowOpen then
        return
    end
    self._IsExpand = not self._IsExpand
    self:DoExpand(self._IsExpand)
    if self.Parent.SetExpandCell then
        self.Parent:SetExpandCell(self._IsExpand and self or nil)
    end
end

function XUiTheatre3EquipmentSuit:SetState(state)
    if state == CS.UiButtonState.Disable then
        self:IsShowTip(false)
    end
    self:UpdateShowState(self._CurShowType, state)
    self:ShowSuitAllPos()
end

function XUiTheatre3EquipmentSuit:UpdateShowState(showType, state)
    self._CurShowType = showType or self._CurShowType or ShowType.Close
    self._CurState = state or self._CurState or CS.UiButtonState.Normal

    self.PanelClose.gameObject:SetActiveEx(self._CurShowType == ShowType.Close)
    self.PanelOpen.gameObject:SetActiveEx(self._CurShowType == ShowType.Open)
    self.PanelEmpty.gameObject:SetActiveEx(self._CurShowType == ShowType.Empty)
    self.PanelCancel.gameObject:SetActiveEx(self._CurShowType == ShowType.Cancel)
    if self._CurShowType == ShowType.Open then
        self:SetEquip(1)
        self:SetEquip(2)
        self:SetEquip(3)
    end

    self.ImgBgSelect.gameObject:SetActiveEx(self._CurState == CS.UiButtonState.Select)
    self.ImgSelectOpen.gameObject:SetActiveEx(self._CurState == CS.UiButtonState.Select and self._IsShowOpen)
    self.TxtBgSelect.gameObject:SetActiveEx(self._CurState == CS.UiButtonState.Select)
    self.ImgMask.gameObject:SetActiveEx(self._CurState == CS.UiButtonState.Disable)
    self.ImgSelect.gameObject:SetActiveEx(self._CurState == CS.UiButtonState.Select)
end

function XUiTheatre3EquipmentSuit:ResetState()
    if self._CurShowType == ShowType.Empty then
        return
    end
    self._CurShowType = ShowType.Close
    self:SetState(CS.UiButtonState.Normal)
end

function XUiTheatre3EquipmentSuit:MarkSuitSelected()
    self:UpdateShowState(ShowType.Cancel)
end

function XUiTheatre3EquipmentSuit:MarkSelected()
    self:UpdateShowState(self._CurShowType, CS.UiButtonState.Select)
end

function XUiTheatre3EquipmentSuit:SetEmptySuit(slotId)
    self.SlotId = slotId
    self:UpdateShowState(ShowType.Empty)
end

function XUiTheatre3EquipmentSuit:OnBtnCancel()
    if self.Parent.CancelChooseSuitMode then
        self.Parent:CancelChooseSuitMode()
    end
end

function XUiTheatre3EquipmentSuit:OnBtnWear()
    if self.Parent.ExchangeSuit then
        self.Parent:ExchangeSuit(self, true)
    end
end

function XUiTheatre3EquipmentSuit:OnBtnDisableMask()
    if not self._Control:IsWorkshopHasTimes() then
        XUiManager.TipMsg(XUiHelper.GetText("Theatre3EquipRebuildNoTimes"))
        return
    end
    if self._Control:IsSuitComplete(self.SuitConfig.Id) then
        XUiManager.TipMsg(XUiHelper.GetText("Theatre3EquipRebuildSuitComplete"))
    end
end

return XUiTheatre3EquipmentSuit