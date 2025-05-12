local XTeam = require("XEntity/XTeam/XTeam")
---@class XScoreTowerTowerTeam : XTeam
local XScoreTowerTowerTeam = XClass(XTeam, "XScoreTowerTowerTeam")

function XScoreTowerTowerTeam:Ctor()
    -- 队伍槽位数量 默认为3
    self._SlotCount = 3
    -- 章节Id
    self._ChapterId = 0
    -- 塔Id
    self._TowerId = 0
end

--region 数据更新

-- 设置队伍槽位数量
---@param slotCount number 槽位数量
function XScoreTowerTowerTeam:SetSlotCount(slotCount)
    if not XTool.IsNumberValid(slotCount) then
        return
    end
    self._SlotCount = slotCount
    self:ClearEntityIds()
end

-- 同步服务器数据
---@param characterInfos XScoreTowerCharacterInfo[]
function XScoreTowerTowerTeam:SyncServerData(characterInfos)
    if XTool.IsTableEmpty(characterInfos) then
        return
    end
    if #characterInfos > self._SlotCount then
        XLog.Warning(string.format("error: characterInfos count (%s) is more than slot count (%s), teamId: %s",
            #characterInfos, self._SlotCount, self:GetId()))
    end
    local tempEntityIds = self:GetEntityIds()
    local hasChanges = false
    for _, info in ipairs(characterInfos) do
        local pos = info:GetPos()
        if pos > 0 and pos <= self._SlotCount and tempEntityIds[pos] ~= info:GetEntityId() then
            tempEntityIds[pos] = info:GetEntityId()
            hasChanges = true
        end
    end
    if hasChanges then
        self:UpdateEntityIds(tempEntityIds)
    end
end

-- 过滤掉无效的实体Id
---@param robotIds number[] 机器人Id列表
function XScoreTowerTowerTeam:FilterInvalidEntityIds(robotIds)
    local tempEntityIds = self:GetEntityIds()
    local hasChanges = false
    for pos, entityId in pairs(tempEntityIds) do
        if XTool.IsNumberValid(entityId) and XRobotManager.CheckIsRobotId(entityId) and not table.contains(robotIds, entityId) then
            tempEntityIds[pos] = 0
            hasChanges = true
        end
    end
    if hasChanges then
        self:UpdateEntityIds(tempEntityIds)
    end
end

-- 重置槽位
function XScoreTowerTowerTeam:ResetSlot()
    self.EntitiyIds = {}
    for i = 1, self._SlotCount do
        self.EntitiyIds[i] = 0
    end
end

-- 设置章节Id
---@param chapterId number 章节Id
function XScoreTowerTowerTeam:SetChapterId(chapterId)
    self._ChapterId = chapterId
end

-- 设置塔Id
---@param towerId number 塔Id
function XScoreTowerTowerTeam:SetTowerId(towerId)
    self._TowerId = towerId
end

-- 添加实体Id
---@param entityId number 实体Id
function XScoreTowerTowerTeam:AddTowerEntityId(entityId)
    if not XTool.IsNumberValid(entityId) then
        return 0
    end
    for pos, id in ipairs(self:GetEntityIds()) do
        if not XTool.IsNumberValid(id) then
            self:UpdateEntityTeamPos(entityId, pos, true)
            return pos
        end
    end
    return 0
end

-- 移除实体Id
---@param entityId number 实体Id
---@param teamPos number 位置
function XScoreTowerTowerTeam:RemoveTowerEntityId(entityId, teamPos)
    self:UpdateEntityTeamPos(entityId, teamPos, false)
end

-- 一键上阵角色
---@param suggestEntityIds number[] 推荐上阵实体Id列表
function XScoreTowerTowerTeam:OneKeyAddTowerEntityIds(suggestEntityIds)
    if XTool.IsTableEmpty(suggestEntityIds) then
        return
    end
    self:ClearEntityIds()
    for index, entityId in pairs(suggestEntityIds) do
        if XTool.IsNumberValid(entityId) then
            self:UpdateEntityTeamPos(entityId, index, true)
        end
    end
end

--endregion

--region 数据获取

-- 获取章节Id
function XScoreTowerTowerTeam:GetChapterId()
    return self._ChapterId
end

-- 获取塔Id
function XScoreTowerTowerTeam:GetTowerId()
    return self._TowerId
end

-- 获取所有角色Id
---@return number[]
function XScoreTowerTowerTeam:GetAllCharacterIds()
    local characterIds = {}
    for _, entityId in ipairs(self:GetEntityIds()) do
        if XTool.IsNumberValid(entityId) then
            table.insert(characterIds, XEntityHelper.GetCharacterIdByEntityId(entityId))
        end
    end
    return characterIds
end

---@return table<number, { ChatacterId: number, RobotId: number, Pos: number }>
function XScoreTowerTowerTeam:GetCharacterInfos()
    local characterInfos = {}
    for index, entityId in ipairs(self:GetEntityIds()) do
        if XTool.IsNumberValid(entityId) then
            local isRobot = XRobotManager.CheckIsRobotId(entityId)
            table.insert(characterInfos, { ChatacterId = isRobot and 0 or entityId, RobotId = isRobot and entityId or 0, Pos = index })
        end
    end
    return characterInfos
end

--endregion

--region 重载XTeam方法

function XScoreTowerTowerTeam:Clear()
    self:ResetSlot()
    self.FirstFightPos = 1
    self.CaptainPos = 1
    self:ClearGeneralSkill()
    self:Save()
end

function XScoreTowerTowerTeam:ClearEntityIds()
    self:ResetSlot()
    self:ClearGeneralSkill()
    self:Save()
end

--endregion

return XScoreTowerTowerTeam
