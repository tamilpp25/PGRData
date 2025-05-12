--[[
轮盘选择器：类似鸣潮里的Tab功能。不同的是，只显示一半，支持翻页操作。
--]]

---@alias DataID number

local CSXInputManager = CS.XInputManager
local CSXNpcOperationClickKey = CS.XNpcOperationClickKey
local Input = CS.UnityEngine.Input
local CSXKeyCode = CS.XKeyCode
local CSXOperationClickType = CS.XOperationClickType
local CSXInputMapId = CS.XInputMapId

local XUiFightWheelPickerSlotData = require("XUi/XUiFightWheelPicker/XUiFightWheelPickerSlotData")
local XUiFightWheelPickerSlot = require("XUi/XUiFightWheelPicker/XUiFightWheelPickerSlot")

---@class XUiFightWheelPicker : XLuaUi
---@field BtnGroup XUiButtonGroup
---@field BtnNext XUiComponent.XUiButton
---@field BtnWheel XUiComponent.XUiButton
local XUiFightWheelPicker = XLuaUiManager.Register(XLuaUi, "UiFightWheelPicker")

local PC_KEY = {
    REDUCE_BTN_OPTION = 100001,
    ADD_BTN_OPTION = 100002
}

function XUiFightWheelPicker:OnAwake()
    ---@type XUiFightWheelPickerSlot[]
    self.Slots = {}
    ---@type XUiFightWheelPickerSlotData[]
    self.SlotsDataList = {}

    self.isActive = false
    self.isExpand = false
    self.OnPcClickCb = handler(self, self.OnPcClick)
    self.anim = false

    self.CurPage = -1                    -- 当前页码（C#下标格式）
    self.CurOptionIndexInOnePage = -1    -- 当前页内的索引（C#下标格式）

    self.SLOT_COUNT_PER_PAGE = 4
end

function XUiFightWheelPicker:OnStart()
    local buttons = self.BtnGroup.transform:GetComponentsInChildren(typeof(CS.XUiComponent.XUiButton))
    for i = 0, self.BtnGroup.transform.childCount - 1 do
        local slot = XUiFightWheelPickerSlot.New(self, self.BtnGroup.transform:GetChild(i).gameObject)
        table.insert(self.Slots, slot)
    end

    XUiHelper.RegisterClickEvent(self, self.BtnWheel, self.OnBtnToggleClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNextClick)

    self:RefreshSlots()
end

function XUiFightWheelPicker:OnEnable()
    if CSXInputManager.GetJoystickType() == XSetConfigs.InputDeviceType.Xbox then
        CSXInputManager.RegisterOnClick(CSXKeyCode.Axis7P, handler(self, self.MoveUp))
        CSXInputManager.RegisterOnClick(CSXKeyCode.Axis7M, handler(self, self.MoveDown))

    elseif CSXInputManager.GetJoystickType() == XSetConfigs.InputDeviceType.Ps then
        CSXInputManager.RegisterOnClick(CSXKeyCode.Axis8P, handler(self, self.MoveUp))
        CSXInputManager.RegisterOnClick(CSXKeyCode.Axi87M, handler(self, self.MoveDown))
    end

    CSXInputManager.RegisterOnClick(CSXKeyCode.UpArrow, handler(self, self.MoveUp))
    CSXInputManager.RegisterOnClick(CSXKeyCode.DownArrow, handler(self, self.MoveDown))
    CSXInputManager.RegisterOnClick(CS.XInputManager.XOperationType.Fight, self.OnPcClickCb)

    self.Timer = XScheduleManager.ScheduleForever(handler(self, self.Update), 0)
    CS.XRLManager.Camera.InputScaleEnable = not XDataCenter.UiPcManager.IsPc()
end

function XUiFightWheelPicker:OnDisable()
    CSXInputManager.UnregisterOnClick(CSXKeyCode.Axis7P)
    CSXInputManager.UnregisterOnClick(CSXKeyCode.Axis7M)
    CSXInputManager.UnregisterOnClick(CSXKeyCode.Axis8P)
    CSXInputManager.UnregisterOnClick(CSXKeyCode.Axis8M)
    CSXInputManager.UnregisterOnClick(CSXKeyCode.UpArrow)
    CSXInputManager.UnregisterOnClick(CSXKeyCode.DownArrow)
    CSXInputManager.UnregisterOnClick(CS.XInputManager.XOperationType.Fight, self.OnPcClickCb)
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
    CS.XRLManager.Camera.InputScaleEnable = true
end

function XUiFightWheelPicker:Update()

end

function XUiFightWheelPicker:Expand()
    self.isExpand = true

    for i = 1, #self.Slots do
        self.Slots[i]:GetXUiButton().TempState = CS.UiButtonState.Press
    end
    self.BtnGroup.gameObject:SetActiveEx(true)
    self.BtnNext.gameObject:SetActiveEx(#self.SlotsDataList > self.SLOT_COUNT_PER_PAGE)
end

function XUiFightWheelPicker:Collapse()
    self.isExpand = false
    self.BtnGroup.gameObject:SetActiveEx(false)
    self.BtnNext.gameObject:SetActiveEx(false)
end

function XUiFightWheelPicker:AddSlot(...)
    local datum = {...}

    local id = datum[1]
    -- 不允许添加相同Id
    for _, v in ipairs(self.SlotsDataList) do
        if v.Id == id then
            return
        end
    end

    local order = datum[4]

    local slotDatum = XUiFightWheelPickerSlotData.Create(datum[1], datum[2], datum[3], datum[4], datum[5], false)
    table.insert(self.SlotsDataList, slotDatum)
    table.sort(self.SlotsDataList, function(a, b)
        if a.Order ~= b.Order then
            return a.Order < b.Order
        end
    end)

    self.CurPage = 0
    self.CurOptionIndexInOnePage = 0

    self:RefreshSlots()
end

function XUiFightWheelPicker:RemoveSlot(id)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local index = 0
    for i = 1, #self.SlotsDataList do
        if self.SlotsDataList[i].Id == id then
            index = i
            break
        end
    end

    if index == 0 then return end
    table.remove(self.SlotsDataList, index)

    local pageMaxIndex = self:GetPageCount() - 1
    if self.CurPage > pageMaxIndex then
        self.CurPage = pageMaxIndex
        self.CurOptionIndexInOnePage = 0
    else
        self.CurOptionIndexInOnePage = math.min(self:GetCurPageValidDataCount() - 1, self.CurOptionIndexInOnePage)
    end

    self:RefreshSlots()
end

function XUiFightWheelPicker:BanWheelSlot(id, ban)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local index = 0
    for i = 1, #self.SlotsDataList do
        if self.SlotsDataList[i].Id == id then
            self.SlotsDataList[i].IsDisable = ban
            index = i
            break
        end
    end

    if index == 0 then return end

    -- 如果禁用的选项是当前选中的，那么就要上移一项
    if self.CurOptionIndexInOnePage == index - 1 then
        self.CurOptionIndexInOnePage = self.CurOptionIndexInOnePage - 1
    end

    if not ban and self.CurOptionIndexInOnePage < 0 then
        self.CurOptionIndexInOnePage = 0
    end

    self:RefreshSlots()
end

---@param active boolean
---@param toggleCoverKey number
function XUiFightWheelPicker:SetActiveWheelPicker(active, toggleCoverKey, nextPageCoverKey, icon)
    if self.anim then
        return
    end

    local OpType = CSXInputManager.XOperationType.Fight
    if active then
        if not string.IsNilOrEmpty(icon) then
            self.BtnWheel:SetRawImageEx(icon)
        end

        CSXInputManager.InputMapper:SetKeyMappingsCover(OpType, handler(self, self.OnBtnToggleLKeyboardClick), toggleCoverKey);
        CSXInputManager.InputMapper:SetKeyMappingsCover(OpType, handler(self, self.OnBtnNextLKeyboardClick), nextPageCoverKey);

        ---@type XUiPc.XUiPcCustomKey
        local customKey = self.BtnWheel:GetComponentInChildren(typeof(CS.XUiPc.XUiPcCustomKey))
        if not XTool.UObjIsNil(customKey) then
            customKey:SetKey(CSXInputMapId.Fight, toggleCoverKey, OpType)
        end

        customKey = self.BtnNext:GetComponent(typeof(CS.XUiPc.XUiPcCustomKey))
        if not XTool.UObjIsNil(customKey) then
            customKey:SetKey(CSXInputMapId.Fight, nextPageCoverKey, OpType)
        end

        for i = 1, #self.Slots do
            self.Slots[i]:GetXUiButton().TempState = CS.UiButtonState.Press
        end

        self:RefreshExpand()
    else
        CSXInputManager.InputMapper:ClearKeyMappingsCover(OpType, toggleCoverKey);
        CSXInputManager.InputMapper:ClearKeyMappingsCover(OpType, nextPageCoverKey);
    end

    if active == self.isActive then
        self:SetActive(active)
    else
        self.anim = true
        if active then
            self:SetActive(true)
            self:PlayOpenAnim()
        else
            self:PlayCloseAnim(function() self:SetActive(false) end)
        end
    end

    self.isActive = active
end

function XUiFightWheelPicker:RefreshSlots()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local from, to = self:GetCurPageRangePos()
    local slotPos = 0
    for i = from, to do
        slotPos = slotPos + 1
        local data = self.SlotsDataList[i]
        self.Slots[slotPos]:RefreshWithData(data)
    end

    local buttons = {}
    for i = 1, #self.Slots do
        table.insert(buttons, self.Slots[i]:GetXUiButton())
    end

    self.BtnGroup:Init(buttons, nil, self.CurOptionIndexInOnePage)

    self:UpdateOptions()
    self:RefreshExpand()
end

---@private
---@param playAnim boolean
function XUiFightWheelPicker:RefreshExpand(playAnim)
    if self.isExpand then
        self:Expand()
        if playAnim then
            self:PlayOpenAnim()
        end
    else
        if playAnim then
            self:PlayCloseAnim(handler(self, self.Collapse))
        else
            self:Collapse()
        end
    end
end

function XUiFightWheelPicker:UpdateOptions()
    if self.CurOptionIndexInOnePage >= 0 then
        local index = self.CurOptionIndexInOnePage % self.SLOT_COUNT_PER_PAGE
        self.BtnGroup:SelectIndex(index + 1)
    end
end

---@param slot XUiFightWheelPickerSlot
function XUiFightWheelPicker:UpdateOptionWithSlot(slot)
    local flatIndex = 0
    for i = 1, #self.SlotsDataList do
        if self.SlotsDataList[i] == slot.Data then
            flatIndex = i
            break
        end
    end

    if flatIndex > 0 then
        self.CurPage, self.CurOptionIndexInOnePage = self:FlatIndexToPageAndPos(flatIndex - 1)
        self:UpdateOptions()
    end
end

-- 上移（找到一个没有被禁用的）
function XUiFightWheelPicker:MoveUp(operationKey)
    if operationKey ~= nil and operationKey ~= PC_KEY.REDUCE_BTN_OPTION then
        return
    end
    
    local curIndex = self:GetCurFlatIndex() + 1

    local from, _ = self:GetCurPageRangePos()
    local targetIndex = 0
    for i = curIndex - 1, from, -1 do
        local data = self.SlotsDataList[i]
        if data and not data.IsDisable and not data.IsEmpty then
            targetIndex = i
            break
        end
    end

    if targetIndex > 0 then
        local page, pos = self:FlatIndexToPageAndPos(targetIndex - 1)
        self.CurOptionIndexInOnePage = pos
        self:UpdateOptions()
    end
end

-- 下移（找到一个没有被禁用的）
function XUiFightWheelPicker:MoveDown(operationKey)
    if operationKey ~= nil and operationKey ~= PC_KEY.REDUCE_BTN_OPTION then
        return
    end
    
    local curIndex = self:GetCurFlatIndex() + 1

    local _, to = self:GetCurPageRangePos()
    local targetIndex = 0
    for i = curIndex + 1, to do
        local data = self.SlotsDataList[i]
        if data and not data.IsDisable and not data.IsEmpty then
            targetIndex = i
            break
        end
    end

    if targetIndex > 0 then
        local page, pos = self:FlatIndexToPageAndPos(targetIndex - 1)
        self.CurOptionIndexInOnePage = pos
        self:UpdateOptions()
    end
end

---@private
function XUiFightWheelPicker:OnPcClick(inputDeviceType, key, clickType, operationType)
    if not XDataCenter.UiPcManager.IsPc() then
        return
    end

    local fight = CS.XFight.Instance
    if not fight then
        return
    end

    --XLog.Debug(key, clickType, operationType)

    local keyCode = CSXNpcOperationClickKey.__CastFrom(key)
    if keyCode == CSXNpcOperationClickKey.InteractKey then
        local slot = self.Slots[self.CurOptionIndexInOnePage + 1]
        if not slot then
            return
        end

        local flatIndex = self:GetCurFlatIndex() + 1
        if not self.SlotsDataList[flatIndex] then
            return
        end

        fight.InputControl:OnClick(slot:GetKey(), clickType)
    end
end

---@private
---@param clickType XOperationClickType
function XUiFightWheelPicker:OnBtnToggleLKeyboardClick(clickType)
    if clickType == CSXOperationClickType.KeyDown then
        self:CollapseOrExpand()
    end
end

---@private
---@param clickType XOperationClickType
function XUiFightWheelPicker:OnBtnNextLKeyboardClick(clickType)
    if clickType == CSXOperationClickType.KeyDown then
        self:NextPage()
        self:RefreshSlots()
    end
end

---@private
function XUiFightWheelPicker:OnBtnToggleClick()
    self:CollapseOrExpand()
end

---@private
function XUiFightWheelPicker:OnBtnNextClick()
    self:NextPage()
    self:RefreshSlots()
end

---页码 + 当页索引 => 顺序索引（C#下标格式）
---@private
function XUiFightWheelPicker:GetCurFlatIndex()
    return self.CurPage * self.SLOT_COUNT_PER_PAGE + self.CurOptionIndexInOnePage
end

---顺序索引(C#下标格式) => 页码 + 当页索引（C#下标格式）
---@private
---@param flatIndex number @顺序索引(C#下标格式)
function XUiFightWheelPicker:FlatIndexToPageAndPos(flatIndex)
    local page = flatIndex // self.SLOT_COUNT_PER_PAGE
    local index = flatIndex % self.SLOT_COUNT_PER_PAGE
    return page, index
end

---获取当前页码的索引范围（Lua下标格式）
---@private
function XUiFightWheelPicker:GetCurPageRangePos()
    local from = self.CurPage * self.SLOT_COUNT_PER_PAGE
    local to = from + self.SLOT_COUNT_PER_PAGE - 1
    return from + 1, to + 1
end

---下拨一页（C#下标格式）
---@private
function XUiFightWheelPicker:NextPage()
    if self.anim then
        return
    end

    local pageCount = self:GetPageCount()
    self.CurPage = (self.CurPage + 1) % pageCount
    self.CurOptionIndexInOnePage = self.CurPage * self.SLOT_COUNT_PER_PAGE
    self:PlayNextAnim()
end

function XUiFightWheelPicker:GetPageCount()
    return math.ceil(#self.SlotsDataList / self.SLOT_COUNT_PER_PAGE)
end

function XUiFightWheelPicker:GetCurPageValidDataCount()
    local from, to = self:GetCurPageRangePos()
    local result = 0
    for i = from, to do
        if self.SlotsDataList[i] ~= nil then
            result = result + 1
        end
    end

    return result
end

---@private
function XUiFightWheelPicker:CollapseOrExpand()
    if self.anim then
        return
    end

    self.isExpand = not self.isExpand
    self:RefreshExpand(true)
end

function XUiFightWheelPicker:PlayOpenAnim()
    self.anim = true
    self:PlayAnimation("Open", function()
        self.anim = false
    end)
end

function XUiFightWheelPicker:PlayCloseAnim(callback)
    self.anim = true
    self:PlayAnimation("Close", function()
        if callback then
            callback()
        end
        self.anim = false
    end)
end

function XUiFightWheelPicker:PlayNextAnim()
    self.anim = true
    self:PlayAnimation("Qiehuan", function()
        self.anim = false
    end)
end

return XUiFightWheelPicker
