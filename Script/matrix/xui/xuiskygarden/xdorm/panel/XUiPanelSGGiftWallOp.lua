local XUiGridSGFurnitureOp = require("XUi/XUiSkyGarden/XDorm/Grid/XUiGridSGFurnitureOp")
---@type XDormitory.XFurnitureSlotState
local CsFurnitureSlotState = CS.XDormitory.XFurnitureSlotState
local SelectState = CsFurnitureSlotState.Select:GetHashCode()

local SgFurnitureType = XMVCA.XSkyGardenDorm.XSgFurnitureType

---@class XUiGridSGFurnitureGiftOp : XUiGridSGFurnitureOp
---@field Parent XUiPanelSGGiftWallOp
local XUiGridSGFurnitureGiftOp = XClass(XUiGridSGFurnitureOp, "XUiGridSGFurnitureGiftOp")

function XUiGridSGFurnitureGiftOp:InitUi()
    self.GridName.gameObject:SetActiveEx(false)
    self.BtnRotate.gameObject:SetActiveEx(false)
    self.BtnCancel.gameObject:SetActiveEx(false)
    self.Disable.gameObject:SetActiveEx(false)
end

function XUiGridSGFurnitureGiftOp:InitCb()
    self.BtnPackUp.CallBack = function()
        self:OnBtnPackUpClick()
    end
end

function XUiGridSGFurnitureGiftOp:Refresh(index, id)
    self._Id = id
    self._Index = index
    local selectIndex = self.Parent.Parent:GetSelectIndex()
    local hasFurniture = id and id > 0
    local select = self._Slot:HasState(CsFurnitureSlotState.Select) or selectIndex == index
    self.Empty.gameObject:SetActiveEx(not hasFurniture)
    if self.NonEmpty then
        self.NonEmpty.gameObject:SetActiveEx(hasFurniture)
    end
    self.Select.gameObject:SetActiveEx(select)
    self.BtnPackUp.gameObject:SetActiveEx(id > 0)
    self:SetVisible(self.Parent:GetSelectMajorType() == SgFurnitureType.Gift)
end

function XUiGridSGFurnitureGiftOp:OnBtnPackUpClick()
    if not self:IsVisible() then
        return
    end
    self.Parent:RemoveFurniture(self._Index, self._Id)
end


local XUiPanelSGWallOp = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWallOp")
---@class XUiPanelSGGiftWallOp : XUiPanelSGWallOp
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGGiftWall
---@field _Container XDormitory.XStaticContainer
local XUiPanelSGGiftWallOp = XClass(XUiPanelSGWallOp, "XUiPanelSGGiftWallOp")


---@type X3CCommand
local X3C_CMD = CS.X3CCommand

function XUiPanelSGGiftWallOp:OnStart(areaType)
    self._AreaType = areaType
    self:InitCb()
    self:InitUi()
end

function XUiPanelSGGiftWallOp:Refresh()
end

function XUiPanelSGGiftWallOp:InitUi()
    self._SelectMajorType = SgFurnitureType.Gift
    XUiPanelSGWallOp.InitUi(self)

end

function XUiPanelSGGiftWallOp:InitCb()
    XUiPanelSGWallOp.InitCb(self)
    self._RemoveFunc = {
        [SgFurnitureType.Gift] = function(id, cfgId) self:OnRemoveGift(id, cfgId) end,
        [SgFurnitureType.GiftShelf] = function(id, cfgId) self:OnRemoveGiftShelf(id, cfgId) end,
    }
end

function XUiPanelSGGiftWallOp:CreateContainer()
    self._Container = self._Control:CreateStaticContainer(self.PanelMaterial, self.GridItem)
    local giftWall = self._Control:GetGiftShelfFightData()
    local minList, maxList = {}, {}
    local index = 1
    while true do
        local data = giftWall:GetSize(index)
        if not data then
            break
        end
        minList[index] = data.MinPos
        maxList[index] = data.MaxPos
        index = index + 1
    end
    self._Container:CreateSlots(minList, maxList)
    self._Container:SetOpFurniture(handler(self, self.OnOpFurniture))
    local slotCount = self._Container:GetSlotCount()
    for i = 0, slotCount - 1 do
        local slot = self._Container:GetSlot(i)
        self:RefreshGridOp(slot, i, 0, false, true)
    end
    --默认选中第0个
    local slot = self._Container:GetSlot(0)
    slot:OnPointerClick(nil)
end

function XUiPanelSGGiftWallOp:CreateFurniture(index, id, visible, ignoreUpdate)
    local fightData = self._Control:GetFightFurnitureData(id)
    if not fightData then
        XLog.Error("【摆件架】不存在家具：" .. id)
        return
    end
    if id and id > 0 then
        local data = self:GetPutWallContainerData()
        local f = data:GetFurniture(id)
        if not f then
            data:AddFurniture(id, self._Control:GetFurnitureConfigIdById(id), index, 0)
        end
    end
    local slot = self._Container:CreateFurniture(index, id, fightData:GetComponent())
    self:RefreshGridOp(slot, slot.Index, id, visible, ignoreUpdate)
end

function XUiPanelSGGiftWallOp:RemoveFurniture(index, id, ignoreUpdate)
    if not id or id <= 0 then
        return
    end
    local cfgId = self._Control:GetFurnitureConfigIdById(id)
    local majorType = self._Control:GetFurnitureMajorType(cfgId)
    local func = self._RemoveFunc[majorType]
    if not func then
        XLog.Error(string.format("【摆件架】不支持类型：%s的家具移除!", majorType))
    else
        func(id, cfgId)
    end
    local slot = self._Container:GetSlot(index)
    slot:SetFurnitureObj(nil)
    
    self:GetPutWallContainerData():RemoveFurniture(id)
    self:FullUpdateView()
    self:RefreshAllGridOp()
end

function XUiPanelSGGiftWallOp:ClearDecoration()
    local count = self._Container:GetSlotCount()
    for i = 0, count - 1 do
        ---@type XDormitory.XFurnitureSlot
        local slot = self._Container:GetSlot(i)
        slot:SetFurnitureObj(nil)
        local grid = self:GetOrCreateGridOp(slot)
        if grid then
            grid:Refresh(slot.Index, slot:GetFurnitureId(), false)
        end
    end
    self._Control:ClearDecoration(self._AreaType)
end

--- 重置装饰
function XUiPanelSGGiftWallOp:RevertDecoration()
    local count = self._Container:GetSlotCount()
    for i = 0, count - 1 do
        ---@type XDormitory.XFurnitureSlot
        local slot = self._Container:GetSlot(i)
        slot:SetFurnitureObj(nil)
        local grid = self:GetOrCreateGridOp(slot)
        if grid then
            grid:Refresh(slot.Index, slot:GetFurnitureId(), true)
        end
    end
    local currentData = self._Control:CloneContainerFurnitureData(self._AreaType)
    local serverData = self._Control:GetContainerFurnitureData(self._AreaType)
    self._Control:RevertDecoration(self._AreaType, currentData, serverData)
    self:SwitchContainer()
    self.Parent:InitFurniture()
end

function XUiPanelSGGiftWallOp:SwitchContainer()
    for _, grid in pairs(self._OpDict) do
        grid:SetVisible(false)
    end
    local wall = self._Control:GetGiftShelfFightData()
    local minList, maxList = {}, {}
    local index = 1
    while true do
        local data = wall:GetSize(index)
        if not data then
            break
        end
        minList[index] = data.MinPos
        maxList[index] = data.MaxPos
        index = index + 1
    end
    self._Container:ChangeContainer(wall:GetTransform(), minList, maxList)
    self:RefreshAllGridOp()
end

function XUiPanelSGGiftWallOp:OnRemoveGift(id, cfgId)
    XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_DESTROY_FRAME_GOODS, {
        Id = id
    })
    self._Control:RemoveFightFurnitureData(id)
end

function XUiPanelSGGiftWallOp:OnRemoveGiftShelf(id, cfgId)
    self.Parent:SetSelectIndex(-1)
end

function XUiPanelSGGiftWallOp:OnFurnitureSlotStateChange(index, id, state, addParam)
    if state == SelectState then
        self:OnFurnitureSelectStateChange(index, id, addParam > 0)
    end
end

function XUiPanelSGGiftWallOp:OnFurnitureSelectStateChange(index, id, isSelect)
    local grid = self:TryGetGridPhotoOpByIndex(index)
    if grid then
        grid:Refresh(index, id)
    end
end

function XUiPanelSGGiftWallOp:OnFurnitureSlotClick(index, id, selectParam, _)
    local isSelect = selectParam > 0
    if isSelect then
        self.Parent:SetSelectIndex(index)
        self.Parent:OnSelectFurnitureGridOp(id, 2)
    end
end

function XUiPanelSGGiftWallOp:OnSelectTab(typeId, furnitureId)
    local majorType = self._Control:GetMajorType(typeId)
    local selIndex = self.Parent:GetSelectIndex()
    self._SelectMajorType = majorType
    ---@type XDormitory.XFurnitureSlot
    local slot = self._Container:GetSlot(selIndex)
    if majorType == SgFurnitureType.Gift then
        slot:AddState(CsFurnitureSlotState.Select)
        self:RefreshAllGridOp()
    elseif majorType == SgFurnitureType.GiftShelf then
        slot:RemoveState(CsFurnitureSlotState.Select)
        self:RefreshAllGridOp()
    end
end

function XUiPanelSGGiftWallOp:GetSelectMajorType()
    return self._SelectMajorType
end

--- 获取或者创建家具操作框
---@param slot XDormitory.XFurnitureSlot
---@return XUiGridSGFurnitureGiftOp
function XUiPanelSGGiftWallOp:GetOrCreateGridOp(slot)
    if not slot then
        XLog.Error("【摆件架】创建家具操作框失败: 家具节点无效！")
        return
    end
    local insId = slot:GetInstanceID()
    local grid = self._OpDict[insId]
    if not grid then
        grid = XUiGridSGFurnitureGiftOp.New(slot, self, slot)
        self._OpDict[insId] = grid
    end
    return grid
end

--- 获取家具操作框
---@param index number
---@return XUiGridSGFurnitureGiftOp
function XUiPanelSGGiftWallOp:TryGetGridPhotoOpByIndex(index)
    local slot = self._Container:GetSlot(index)
    if not slot then
        return
    end
    return self:GetOrCreateGridOp(slot)
end

---@param slot XDormitory.XFurnitureSlot
function XUiPanelSGGiftWallOp:RefreshGridOp(slot, index, id, visible, ignoreUpdate)
    local grid = self:GetOrCreateGridOp(slot)
    if grid then
        grid:Refresh(index, id)
    end

    if not ignoreUpdate then
        self:FullUpdateView()
    end
end

return XUiPanelSGGiftWallOp