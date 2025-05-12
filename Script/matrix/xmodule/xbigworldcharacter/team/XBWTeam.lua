local pairs = pairs
local tableRemove = table.remove
local tableInsert = table.insert

---@class XBWTeam 空花编队
local XBWTeam = XClass(nil, "XBWTeam")

local FullTeamEntityCount = XMVCA.XBigWorldCharacter:GetFullTeamEntityCount()

function XBWTeam:Ctor(teamId)
    self._Id = teamId
    --队伍中角色Id
    self._EntityIds = { 0, 0, 0 }
    --临时缓存数据
    self._EntityIdsCache = { 0, 0, 0 }
end

--- 同步服务器数据
--------------------------
function XBWTeam:Sync()
    for index, entityId in pairs(self._EntityIds) do
        self._EntityIdsCache[index] = entityId
    end
end

--- 队伍数据异常时，还原上次记录
--------------------------
function XBWTeam:Restore()
    for index, entityId in pairs(self._EntityIdsCache) do
        self._EntityIds[index] = entityId
    end
end

function XBWTeam:IsChanged()
    for index, entityId in pairs(self._EntityIdsCache) do
        local cur = self._EntityIds[index]
        if cur ~= entityId then
            return true
        end
    end
    return false
end

function XBWTeam:UpdateTeam(entityList)
    if XTool.IsTableEmpty(entityList) then
        return
    end
    for _, entity in pairs(entityList) do
        local pos = entity.Pos + 1
        self._EntityIds[pos] = entity.CharacterId
    end
end

--- 更新队伍数据，只更新单个位置，不会对其他位置造成影响
---@param pos number 位置  
---@param entityId number 队员Id  
---@param offTeamCb fun(number) 队员离队回调
--------------------------
function XBWTeam:UpdateTeamByPos(pos, entityId, offTeamCb)
    if pos <= 0 then
        XLog.Error("不能更新小于0号位编队数据")
        return
    end
    local oldEntityId = self._EntityIds[pos]
    --这个位置有人
    if oldEntityId and oldEntityId > 0 then
        if offTeamCb then
            offTeamCb(oldEntityId)
        end
    end

    local hasSame = false
    if entityId and entityId > 0 then
        hasSame = self:HasSameEntity(entityId)
    end
    if hasSame then
        return
    end
    self._EntityIds[pos] = entityId
end

--- 往队尾插入一名队员
---@param entityId number 队员Id
---@param limit boolean 是否限制最大人数 
--------------------------
function XBWTeam:AddLast(entityId, limit)
    local pos = self:GetFirstEmptyPos()
    if limit and pos > FullTeamEntityCount then
        XLog.Warning("队伍已满!")
        return
    end
    if pos <= 0 then
        return
    end
    self._EntityIds[pos] = entityId
end

--- 根据位置移除一名队员，同时后面的队员向前移
---@param pos number 位置  
--------------------------
function XBWTeam:RemoveByPos(pos)
    if not pos or pos <= 0 then
        return
    end
    tableRemove(self._EntityIds, pos)
    local count = #self._EntityIds
    if count < FullTeamEntityCount then
        self._EntityIds[count + 1] = 0
    end
end

--- 将队伍中的数据整体前移，占用空余的位置
--------------------------
function XBWTeam:MoveForward()
    local count = #self._EntityIds

    for i = 1, count - 1 do
        local entityId = self._EntityIds[i]
        if not entityId or entityId <= 0 then
            local next = i + 1
            while true do
                self:SwitchPos(i, next)
                local entityId = self._EntityIds[i]
                --更换了有效角色
                if entityId and entityId > 0 then
                    break
                end
                --更换了位置之后，仍然是无效位置，往后移
                next = next + 1
                --移动到队尾了
                if next > count then
                    break
                end
            end
        end
    end
end

--- 交换两个位置
---@param dstPos number
---@param srcPos number
--------------------------
function XBWTeam:SwitchPos(dstPos, srcPos)
    if dstPos <= 0 or srcPos <= 0 then
        XLog.Error("不能跟小于0的位置进行交换!")
        return
    end
    local dstId = self._EntityIds[dstPos]
    local srcId = self._EntityIds[srcPos]
    self._EntityIds[dstPos] = srcId
    self._EntityIds[srcPos] = dstId
end

--- 获取队伍Id
---@return number
--------------------------
function XBWTeam:GetId()
    return self._Id
end

--- 根据位置获取Id
---@param pos number
---@return number
--------------------------
function XBWTeam:GetEntityId(pos)
    return self._EntityIds[pos]
end

--- 获取成员在队伍的位置
---@param entityId number 成员Id  
---@return number
--------------------------
function XBWTeam:GetEntityPos(entityId)
    if not XTool.IsNumberValid(entityId) then
        return 0
    end
    for pos, eId in pairs(self._EntityIds) do
        if eId == entityId then
            return pos
        end
    end
    return 0
end

--- 获取队伍中指挥官的位置
---@return number
--------------------------
function XBWTeam:GetCommandantPos()
    for pos, eId in pairs(self._EntityIds) do
        if eId and eId > 0 and XMVCA.XBigWorldCharacter:IsCommandant(eId) then
            return pos
        end
    end
    return 0
end

--- 获取首个空缺的位置
---@return number
--------------------------
function XBWTeam:GetFirstEmptyPos()
    if XTool.IsTableEmpty(self._EntityIds) then
        return 1
    end
    local target = 1
    for pos, entityId in pairs(self._EntityIds) do
        if not entityId or entityId <= 0 then
            return pos
        end
        target = target + 1
    end

    return target
end

--- 队伍是否为空
---@return boolean
--------------------------
function XBWTeam:IsEmpty()
    if XTool.IsTableEmpty(self._EntityIds) then
        return true
    end

    for _, entityId in pairs(self._EntityIds) do
        if entityId and entityId > 0 then
            return false
        end
    end
    return true
end

--- 获取队伍角色数量
---@return number
--------------------------
function XBWTeam:GetCount()
    if XTool.IsTableEmpty(self._EntityIds) then
        return 0
    end
    local count = 0
    for _, entityId in pairs(self._EntityIds) do
        if entityId and entityId > 0 then
            count = count + 1
        end
    end

    return count
end

--- 队伍里是否有相同的角色
---@param entityId number
---@return boolean
--------------------------
function XBWTeam:HasSameEntity(entityId)
    if not XTool.IsNumberValid(entityId) then 
        return false
    end
    local realId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    for _, eId in pairs(self._EntityIds) do
        if XEntityHelper.GetCharacterIdByEntityId(eId) == realId then
            return true
        end
    end
    return false
end

--- 清空队伍
--------------------------
function XBWTeam:Clear()
    self._EntityIds = { 0, 0, 0 }
end

--- 转成服务器需要的数据结构
---@return table
--------------------------
function XBWTeam: ToServerEntityIds()
    local entityIds = {}
    for pos, entityId in pairs(self._EntityIds) do
        if pos <= 0 then
            goto continue
        end
        
        if entityId and entityId > 0 then
            entityIds[#entityIds + 1] = {
                Pos = pos - 1,
                CharacterId = entityId
            }
        end
        ::continue::
    end

    return entityIds
end

--- 转成服务器需要的数据结构
---@return table
--------------------------
function XBWTeam:ToServerTeam()
    return {
        Index = self:GetId(),
        CharacterList = self:ToServerEntityIds(),
    }
end

--- 转换成战斗需要的数据
---@return table
--------------------------
function XBWTeam:ToFightData()
    local npcList = {}
    local ctor = CS.XBigWorldHelper.CreateWorldNpcData
    local index = 0
    for pos, entityId in pairs(self._EntityIds) do
        if entityId and entityId > 0 then
            local realId = XEntityHelper.GetCharacterIdByEntityId(entityId)
            local data = ctor()
            data.Id = XMVCA.XBigWorldCharacter:GetCharacterNpcId(realId)
            data.Index = index --Lua 从1开始
            data.Character = {
                Id = realId,
                FashionId = XMVCA.XBigWorldCharacter:GetFashionId(realId)
            }
            local isCommandant = false
            if XMVCA.XBigWorldCharacter:IsCommandant(realId) then
                data.PartData = XMVCA.XBigWorldCommanderDIY:GetNpcPartData()
                isCommandant = true
            end
            data.IsPlayerSelf = isCommandant
            npcList[#npcList + 1] = data
            index = index + 1
        end
    end

    return npcList
end

function XBWTeam:MarkIsSyncFight()
    self._IsSyncFight = true
end

--- 是否需要同步到战斗
---@return boolean
--------------------------
function XBWTeam:IsSyncFight()
    return self._IsSyncFight
end

function XBWTeam:SyncFight()
    self._IsSyncFight = false
end

return XBWTeam