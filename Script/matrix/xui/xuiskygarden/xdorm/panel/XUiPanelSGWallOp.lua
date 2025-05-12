---@class XUiPanelSGWallOp : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGWall
local XUiPanelSGWallOp = XClass(XUiNode, "XUiPanelSGWallOp")

local OpType = {
    Moving = 1,
    Rotating = 2,
    StateChange = 3,
    Click = 4,
}

---@type XDormitory.XFurnitureSlotState
local CsFurnitureSlotState = CS.XDormitory.XFurnitureSlotState

function XUiPanelSGWallOp:InitUi()
    self._OpDict = {}
    self:CreateContainer()
    
    self.PanelWarning.gameObject:SetActiveEx(false)
    self.GridItem.gameObject:SetActiveEx(false)
    self.Select.gameObject:SetActiveEx(false)
    self._IsEditMode = false
    self._IsSafe = true
end

function XUiPanelSGWallOp:InitCb()
    self._OpFunc = {
        [OpType.Moving] = function(param1, param2, param3, param4) self:OnFurnitureSlotMoving(param1, param2, param3, param4) end,
        [OpType.Rotating] = function(param1, param2, param3, param4) self:OnFurnitureRotating(param1, param2, param3, param4) end,
        [OpType.StateChange] = function(param1, param2, param3, param4) self:OnFurnitureSlotStateChange(param1, param2, param3, param4) end,
        [OpType.Click] = function(param1, param2, param3, param4) self:OnFurnitureSlotClick(param1, param2, param3, param4) end,
    }
end

--- 刷新全部操作框
function XUiPanelSGWallOp:RefreshAllGridOp()
    local count = self._Container:GetSlotCount()
    for i = 0, count - 1 do
        ---@type XDormitory.XFurnitureSlot
        local slot = self._Container:GetSlot(i)
        local grid = self:GetOrCreateGridOp(slot)
        if grid then
            grid:Refresh(slot.Index, slot:GetFurnitureId(), grid:IsVisible())
        end
    end
end

--- 应用新预设
function XUiPanelSGWallOp:ApplyNewLayout()
    self:RevertDecoration()
    self:SwitchContainer()
    self._Container:ClearLastSelect()
end

function XUiPanelSGWallOp:OnOpFurniture(type, param1, param2, param3, param4)
    local func = self._OpFunc[type]
    if not func then
        XLog.Error("不存在对应的操作类型：type = " .. type)
        return
    end
    func(param1, param2, param3, param4)
end

function XUiPanelSGWallOp:OnCancelSelect(index, id)
    ---@type XDormitory.XFurnitureSlot
    local slot = self._Container:GetSlot(index)
    if slot then
        slot:RemoveState(CsFurnitureSlotState.Select)
    end
    self._Container:ClearLastSelect()
end

--- 获取家具槽上的家具Id
---@param index number
---@return number
function XUiPanelSGWallOp:TryGetSlotFurnitureId(index)
    ---@type XDormitory.XFurnitureSlot
    local slot = self._Container:GetSlot(index)
    if not slot then
        return 0
    end
    return slot:GetFurnitureId()
end

--- 根据Id点击家具
function XUiPanelSGWallOp:TryClickSlot(id)
    if not id or id <= 0 then
        return
    end
    
    local count = self._Container:GetSlotCount()
    if count <= 0 then
        return
    end
    
    for i = 0, count - 1 do
        ---@type XDormitory.XFurnitureSlot
        local slot = self._Container:GetSlot(i)
        if slot:GetFurnitureId() == id then
            slot:OnPointerClick(nil)
            break
        end
    end
end

function XUiPanelSGWallOp:TryGetSlotIndexById(id)
    local index = -1
    local count = self._Container:GetSlotCount()
    if count <= 0 then
        return index
    end
    for i = 0, count - 1 do
        ---@type XDormitory.XFurnitureSlot
        local slot = self._Container:GetSlot(i)
        if slot and slot:GetFurnitureId() == id then
            index = i
            break
        end
    end
    return index
end

function XUiPanelSGWallOp:OnFurnitureSlotMoving(index, id, x, y)
    local furniture = self._Control:CloneContainerFurnitureData(self._AreaType):GetFurniture(id)
    if furniture then
        furniture:SetPos(x, y)
    end
end

function XUiPanelSGWallOp:OnFurnitureRotating(index, id, angle, _)
    local furniture = self._Control:CloneContainerFurnitureData(self._AreaType):GetFurniture(id)
    if furniture then
        furniture:SetAngle(angle)
    end
end

function XUiPanelSGWallOp:OnFurnitureSlotStateChange(index, id, state, addParam)
end

function XUiPanelSGWallOp:OnFurnitureSlotClick(index, id, selectParam)
end

function XUiPanelSGWallOp:GetPutWallContainerData()
    return self._Control:CloneContainerFurnitureData(self._AreaType)
end

function XUiPanelSGWallOp:FullUpdateView()
    self.Parent.Parent:UpdateView()
end

function XUiPanelSGWallOp:EnterEditMode()
    self._IsEditMode = true
end

function XUiPanelSGWallOp:ExitEditMode()
    self._IsEditMode = false
end

function XUiPanelSGWallOp:IsSafe()
    return true
end

function XUiPanelSGWallOp:TryCheckOpIsSafe(tips)
    local isSafe = self:IsSafe()
    if not isSafe and tips then
        XUiManager.TipMsg(self._Control:GetInvalidPutText())
        return isSafe
    end
    return isSafe
end

return XUiPanelSGWallOp