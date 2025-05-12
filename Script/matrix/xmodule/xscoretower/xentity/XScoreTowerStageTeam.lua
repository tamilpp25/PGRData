local XTeam = require("XEntity/XTeam/XTeam")
---@class XScoreTowerStageTeam : XTeam
local XScoreTowerStageTeam = XClass(XTeam, "XScoreTowerStageTeam")

function XScoreTowerStageTeam:Ctor()
    -- 最大角色数量
    self._MaxEntityLimit = 3
    -- 当前角色上限
    self._CurrentEntityLimit = 3
    -- 章节Id
    self._ChapterId = 0
    -- 塔Id
    self._TowerId = 0
    -- 塔层Id
    self._FloorId = 0
    -- 关卡配置ID ScoreTowerStage表的ID
    self._StageCfgId = 0
end

--region 数据更新

-- 设置当前角色数量
function XScoreTowerStageTeam:SetCurrentEntityLimit(currentEntityLimit)
    if currentEntityLimit < 0 or currentEntityLimit > self._MaxEntityLimit then
        XLog.Error(string.format("error: currentEntityLimit is invalid, currentEntityLimit is %d", currentEntityLimit))
        return
    end
    self._CurrentEntityLimit = currentEntityLimit
    self:Clear()
end

-- 同步记录的编队数据
---@param recordTeamData XScoreTowerTeam 记录的编队数据
---@param recordCharacterIds number[] 记录的角色Id列表
function XScoreTowerStageTeam:SyncRecordTeamData(recordTeamData, recordCharacterIds)
    if not recordTeamData then
        return
    end

    recordCharacterIds = recordCharacterIds or {}
    local posIds = recordTeamData:GetPosIds() or {}
    for index, pos in ipairs(posIds) do
        self.EntitiyIds[index] = XTool.IsNumberValid(pos) and recordCharacterIds[pos] or 0
    end

    if self:GetEntityCount() > self._CurrentEntityLimit then
        XLog.Warning(string.format("error: characterIds count (%s) is more than limit (%s), teamId: %s",
            self:GetEntityCount(), self._CurrentEntityLimit, self:GetId()))
    end

    self.CaptainPos = recordTeamData:GetCaptainIndex()
    self.FirstFightPos = recordTeamData:GetFirstFightPos()
    self.EnterCgIndex = recordTeamData:GetEnterCgIndex()
    self.SettleCgIndex = recordTeamData:GetSettleCgIndex()
    self.SelectedGeneralSkill = recordTeamData:GetGeneralSkill()
    self:RefreshGeneralSkills(true)
    self:Save()
end

-- 过滤掉无效的实体Id
---@param characterIds number[] 角色Id
function XScoreTowerStageTeam:FilterInvalidEntityIds(characterIds)
    local tempEntityIds = self:GetEntityIds()
    local hasChanges = false
    for pos, entityId in pairs(tempEntityIds) do
        if XTool.IsNumberValid(entityId) and not table.contains(characterIds, entityId) then
            tempEntityIds[pos] = 0
            hasChanges = true
        end
    end
    if hasChanges then
        self:UpdateEntityIds(tempEntityIds)
    end
end

-- 设置章节Id
---@param chapterId number 章节Id
function XScoreTowerStageTeam:SetChapterId(chapterId)
    self._ChapterId = chapterId
end

-- 设置塔Id
---@param towerId number 塔Id
function XScoreTowerStageTeam:SetTowerId(towerId)
    self._TowerId = towerId
end

-- 设置塔层Id
---@param floorId number 塔层Id
function XScoreTowerStageTeam:SetFloorId(floorId)
    self._FloorId = floorId
end

-- 设置关卡配置ID
---@param stageCfgId number 关卡配置ID
function XScoreTowerStageTeam:SetStageCfgId(stageCfgId)
    self._StageCfgId = stageCfgId
end

-- 获取可用的队伍下标列表
---@return table<number> 可用的队伍下标列表
function XScoreTowerStageTeam:GetAvailableTeamPosList()
    local teamPos = {}
    for pos, entityId in ipairs(self:GetEntityIds()) do
        if not XTool.IsNumberValid(entityId) then
            table.insert(teamPos, pos)
        end
    end
    return teamPos
end

-- 添加实体Id
---@param entityId number 实体Id
---@param indexMapping table<number, number> 下标映射
function XScoreTowerStageTeam:AddStageEntityId(entityId, indexMapping)
    local posList = self:GetAvailableTeamPosList()
    if XTool.IsTableEmpty(posList) then
        return 0
    end
    local teamPos = posList[1]
    for _, pos in ipairs(indexMapping) do
        if XTool.IsNumberValid(pos) and table.contains(posList, pos) then
            teamPos = pos
            break
        end
    end
    self:UpdateEntityTeamPos(entityId, teamPos, true)
    return teamPos
end

-- 移除实体Id
---@param entityId number 实体Id
---@param teamPos number 下标
function XScoreTowerStageTeam:RemoveStageEntityId(entityId, teamPos)
    self:UpdateEntityTeamPos(entityId, teamPos, false)
end

--endregion

--region 数据获取

-- 获取章节Id
function XScoreTowerStageTeam:GetChapterId()
    return self._ChapterId
end

-- 获取塔Id
function XScoreTowerStageTeam:GetTowerId()
    return self._TowerId
end

-- 获取塔层Id
function XScoreTowerStageTeam:GetFloorId()
    return self._FloorId
end

-- 获取关卡配置ID
function XScoreTowerStageTeam:GetStageCfgId()
    return self._StageCfgId
end

-- 获取当前角色上限
function XScoreTowerStageTeam:GetCurrentEntityLimit()
    return self._CurrentEntityLimit
end

-- 获取队伍平均战力
function XScoreTowerStageTeam:GetTeamAverageAbility()
    local totalAbility, count = 0, 0
    for _, entityId in pairs(self:GetEntityIds()) do
        if XTool.IsNumberValid(entityId) then
            totalAbility = totalAbility + XMVCA.XScoreTower:GetCharacterPower(entityId)
            count = count + 1
        end
    end
    return count > 0 and totalAbility / count or 0
end

-- 获取所有角色Id
function XScoreTowerStageTeam:GetAllCharacterIds()
    local characterIds = {}
    for _, entityId in pairs(self:GetEntityIds()) do
        if XTool.IsNumberValid(entityId) then
            table.insert(characterIds, XEntityHelper.GetCharacterIdByEntityId(entityId))
        end
    end
    return characterIds
end

-- 获取下标映射
---@return table<number, number> key是上限下标 value是角色Id下标
function XScoreTowerStageTeam:GetIndexMapping()
    local teamPos = {}
    local entityIds = self:GetEntityIds()
    for pos, entityId in ipairs(entityIds) do
        if XTool.IsNumberValid(entityId) then
            table.insert(teamPos, pos)
        end
    end

    local count = self._CurrentEntityLimit - #teamPos
    if count > 0 then
        for index = 1, self._MaxEntityLimit do
            if count <= 0 then
                break
            end
            if not table.contains(teamPos, index) then
                table.insert(teamPos, index)
                count = count - 1
            end
        end
    elseif count < 0 then
        XLog.Warning(string.format("error: teamPos count (%s) is more than limit (%s), teamId: %s",
            #teamPos, self._CurrentEntityLimit, self:GetId()))
    end

    table.sort(teamPos)
    return teamPos
end

-- 获取实体Id通过上限下标
function XScoreTowerStageTeam:GetEntityIdByIndex(index)
    local indexMapping = self:GetIndexMapping()
    local teamPos = indexMapping[index] or 0
    return self:GetEntityIdByTeamPos(teamPos)
end

--endregion

--region 重载XTeam方法

-- 是否满员 角色数量等于当前角色上限 返回true
function XScoreTowerStageTeam:GetIsFullMember()
    return self:GetEntityCount() == self._CurrentEntityLimit
end

--endregion

return XScoreTowerStageTeam
