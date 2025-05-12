---@class XGoldenMinerSystemMove:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemMove = XClass(XEntityControl, "XGoldenMinerSystemMove")

--region Override
function XGoldenMinerSystemMove:OnUpdate(time)
    local stoneUidDir = self._MainControl:GetStoneEntityUidDirByType()
    if XTool.IsTableEmpty(stoneUidDir) then
        return
    end
    for entityUid, _ in pairs(stoneUidDir) do
        local stoneEntity = self._MainControl:GetStoneEntityByUid(entityUid)
        -- 是定春且处于定春静止时定春不动
        if stoneEntity:IsMove() and stoneEntity:GetComponentMove()
                and (not stoneEntity:GetComponentMouse() or self:_CheckMouseCanMove()) then
            stoneEntity:GetComponentMove():UpdateMove(time)
        end
    end
end

function XGoldenMinerSystemMove:OnRelease()
end
--endregion

--region Check
function XGoldenMinerSystemMove:_CheckMouseCanMove()
    return not self._MainControl:CheckBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.MOUSE_STOP)
end
--endregion

return XGoldenMinerSystemMove