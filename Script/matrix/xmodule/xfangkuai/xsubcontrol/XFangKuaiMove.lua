---@class XFangKuaiMove : XControl 方块移动
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
local XFangKuaiMove = XClass(XControl, "XFangKuaiMove")

function XFangKuaiMove:OnInit()
    self._SpeedX = tonumber(self._MainControl:GetClientConfig("BlockMoveXSpeed"))
    self._SpeedY = tonumber(self._MainControl:GetClientConfig("BlockMoveYSpeed"))
    self._BlockWidth = tonumber(self._MainControl:GetClientConfig("BlockWidth"))
    self._BlockHeight = tonumber(self._MainControl:GetClientConfig("BlockHeight"))
end

function XFangKuaiMove:AddAgencyEvent()

end

function XFangKuaiMove:RemoveAgencyEvent()

end

function XFangKuaiMove:OnRelease()

end

function XFangKuaiMove:GetPosByGridX(index)
    return (index - 1) * self._BlockWidth
end

function XFangKuaiMove:GetPosByGridY(index)
    return (index - 1) * self._BlockHeight
end

---@param block XFangKuaiBlock
---@return number,number
function XFangKuaiMove:GetPosByBlock(block)
    local gird = block:GetHeadGrid()
    return self:GetPosByGridX(gird.x), self:GetPosByGridY(gird.y)
end

---水平移动
---@param block XUiGridFangKuaiBlock
function XFangKuaiMove:MoveX(block, gridX, updateCb, completeCb, moveTime)
    if block then
        local time = moveTime or self:GetMoveXTime(block.BlockData, gridX)
        return block.Transform:DOLocalMoveX(self:GetPosByGridX(gridX), time):OnUpdate(updateCb):OnComplete(completeCb)
    end
    return nil
end

---垂直移动
---@param block XUiGridFangKuaiBlock
function XFangKuaiMove:MoveY(block, gridY)
    if block then
        local time = self:GetMoveYTime()
        block.Transform:DOLocalMoveY(self:GetPosByGridY(gridY), time):SetEase(CS.DG.Tweening.Ease.OutQuad)
    end
end

---@param block XUiGridFangKuaiBlock
function XFangKuaiMove:AutoMoveUp(block)
    if block and block.BlockData:CheckMoveUp() then
        self:MoveY(block, block.BlockData:GetNextUpGrid())
    end
end

---将点击坐标转换为格子索引
---@param block XUiGridFangKuaiBlock
function XFangKuaiMove:GetMouseClickGrid(block)
    local offsetX = XUiHelper.GetScreenClickPosition(block.Transform.parent, CS.XUiManager.Instance.UiCamera).x
    offsetX = offsetX + self._BlockWidth / 2
    local gridIndex = math.floor(offsetX / self._BlockWidth) + 1
    return math.max(1, math.min(block.BlockData:GetMaxWidth(), gridIndex))
end

---@param blockData XFangKuaiBlock
function XFangKuaiMove:GetMoveXTime(blockData, dimGridX)
    return blockData:GetDistanceX(dimGridX) * self._SpeedX
end

function XFangKuaiMove:GetMoveYTime()
    return self._SpeedY
end

return XFangKuaiMove