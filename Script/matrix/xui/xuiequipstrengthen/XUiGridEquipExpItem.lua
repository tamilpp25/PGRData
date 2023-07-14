local mathFloor = math.floor
local XMathClamp = XMath.Clamp
local stringFormat = string.format

local LongClickIntervel = 100
local AddCountPerPressTime = 1 / 150

local XUiGridEquipExpItem = XClass(nil, "XUiGridEquipExpItem")

function XUiGridEquipExpItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AddBtnListener()
end

function XUiGridEquipExpItem:Init(rootUi, addCountCb, addCountCheckCb)
    self.RootUi = rootUi
    self.AddCountCb = addCountCb
    self.AddCountCheckCb = addCountCheckCb
end

function XUiGridEquipExpItem:Refresh(itemId, selectCount)
    selectCount = selectCount or 0
    self.ItemId = itemId
    self.ItemCount = XDataCenter.ItemManager.GetCount(itemId)

    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    self.TxtName.text = XDataCenter.ItemManager.GetItemName(itemId)
    self.TxtCount.text = self.ItemCount
    local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgIconBg, quality)

    self:OnSelectCountChange(selectCount)
end

function XUiGridEquipExpItem:OnSelectCountChange(newCount)
    self.SelectCount = newCount
    if newCount > 0 then
        self.TxtSelectNum.text = stringFormat("x%d", newCount)
        self.ImgSelect.gameObject:SetActiveEx(true)
        self.BtnMinus.gameObject:SetActiveEx(true)
    else
        self.ImgSelect.gameObject:SetActiveEx(false)
        self.BtnMinus.gameObject:SetActiveEx(false)
    end
end

function XUiGridEquipExpItem:AddBtnListener()
    self.BtnMax.CallBack = function() self:OnClickBtnMax() end
    self.BtnMinus.CallBack = function() self:OnClickBtnMinus() end
    self.BtnAdd.CallBack = function() self:OnClickBtnAdd() end
    XUiButtonLongClick.New(self.PointerAdd, LongClickIntervel, self, nil, self.OnLongClickBtnAdd, nil, true)
    XUiButtonLongClick.New(self.PointerMinus, LongClickIntervel, self, nil, self.OnLongClickBtnMinus, nil, true)
end

function XUiGridEquipExpItem:OnClickBtnAdd()
    local addCount = 1
    local newCount = self.SelectCount + addCount
    local itemId = self.ItemId

    if not self:CheckItemCount(newCount) then
        return
    end

    if not self.AddCountCheckCb() then
        return
    end

    self:OnSelectCountChange(newCount)
    self.AddCountCb(itemId, addCount)
end

function XUiGridEquipExpItem:OnLongClickBtnAdd(pressingTime)
    local addCount = 1
    local totalCount = XMathClamp(mathFloor(pressingTime * AddCountPerPressTime), 0, self.ItemCount)
    local newCount = self.SelectCount
    local itemId = self.ItemId

    local doNotTip = true
    for _ = 1, totalCount do
        if not self.AddCountCheckCb(doNotTip) then
            break
        end

        newCount = newCount + addCount
        if not self:CheckItemCount(newCount) then
            newCount = newCount - addCount
            break
        end

        self.AddCountCb(itemId, addCount)
    end

    self:OnSelectCountChange(newCount)
end

function XUiGridEquipExpItem:OnClickBtnMinus()
    local addCount = -1
    addCount = addCount + self.SelectCount < 0 and -self.SelectCount or addCount
    local newCount = self.SelectCount + addCount
    local itemId = self.ItemId

    self:OnSelectCountChange(newCount)
    self.AddCountCb(itemId, addCount)
end

function XUiGridEquipExpItem:OnLongClickBtnMinus(pressingTime)
    local addCount = -mathFloor(pressingTime * AddCountPerPressTime)
    addCount = addCount + self.SelectCount < 0 and -self.SelectCount or addCount
    local newCount = self.SelectCount + addCount
    local itemId = self.ItemId

    self:OnSelectCountChange(newCount)
    self.AddCountCb(itemId, addCount)
end

function XUiGridEquipExpItem:OnClickBtnMax()
    local addCount = 1
    local totalCount = self.ItemCount
    local newCount = self.SelectCount
    local itemId = self.ItemId

    local doNotTip = true
    for _ = 1, totalCount do
        if not self.AddCountCheckCb(doNotTip) then
            break
        end

        newCount = newCount + addCount
        if not self:CheckItemCount(newCount) then
            newCount = newCount - addCount
            break
        end

        self.AddCountCb(itemId, addCount)
    end

    self:OnSelectCountChange(newCount)
end

function XUiGridEquipExpItem:CheckItemCount(checkCount)
    return checkCount >= 0 and checkCount <= self.ItemCount
end

return XUiGridEquipExpItem