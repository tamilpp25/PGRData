local tableInsert = table.insert

local XTeam = XClass(nil, "XTeam")

function XTeam:Ctor(id)
    self.Id = id or -1
    -- CharacterId | RobotId
    self.EntitiyIds = {0, 0, 0}
    self.FirstFightPos = 1
    self.CaptainPos = 1
    -- 队伍额外携带的自定义数据
    self.ExtraData = nil
    self.AutoSave = id ~= nil
    self.LocalSave = true
    -- 队伍名字
    self.TeamName = nil
    -- 保存回调
    self.SaveCallback = nil
    -- -- 默认不限制
    -- self.CharacterLimitType = XFubenConfigs.CharacterLimitType.All
    self.CustomCharacterType = nil
    self:LoadTeamData()
end

function XTeam:LoadTeamData()
    local initData = XSaveTool.GetData(self:GetSaveKey())
    if not initData then
        return
    end
    for key, value in pairs(initData) do
        self[key] = value
    end
end

function XTeam:UpdateSaveCallback(callback)
    self.SaveCallback = callback
end

function XTeam:UpdateEntityTeamPos(entityId, teamPos, isJoin)
    if isJoin then
        self.EntitiyIds[teamPos] = entityId or 0
    else
        for pos, id in ipairs(self.EntitiyIds) do
            if id == entityId then
                self.EntitiyIds[pos] = 0
                break
            end
        end
    end
    self:Save()
end

-- teamData : 旧系统的队伍数据
function XTeam:UpdateFromTeamData(teamData)
    self.FirstFightPos = teamData.FirstFightPos
    self.CaptainPos = teamData.CaptainPos
    for pos, characterId in ipairs(teamData.TeamData) do
        self.EntitiyIds[pos] = characterId
    end
    self.TeamName = teamData.TeamName
    self:Save()
end

function XTeam:UpdateEntityIds(value)
    self.EntitiyIds = value
    self:Save()
end

function XTeam:UpdateFirstFightPos(value)
    self.FirstFightPos = value
    self:Save()
end

function XTeam:UpdateCaptainPos(value)
    self.CaptainPos = value
    self:Save()
end

function XTeam:UpdateExtraData(data)
    self.ExtraData = data
end

function XTeam:SwitchEntityPos(posA, posB)
    local entityIdA = self.EntitiyIds[posA]
    local entityIdB = self.EntitiyIds[posB]
    self.EntitiyIds[posB] = entityIdA
    self.EntitiyIds[posA] = entityIdB
    self:Save()
end

function XTeam:GetId()
    return self.Id
end

function XTeam:GetName()
    return self.TeamName or ""
end

-- 获取当前队伍的角色类型
function XTeam:GetCharacterType()
    if self.CustomCharacterType then
        return self.CustomCharacterType
    end
    local entityId = nil
    for _, value in pairs(self.EntitiyIds) do
        if value > 0 then
            entityId = value
            break
        end
    end
    if entityId == nil then
        return XCharacterConfigs.CharacterType.Normal
    end
    local characterId = nil
    if XRobotManager.CheckIsRobotId(entityId) then
        local robotConfig = XRobotManager.GetRobotTemplate(entityId)
        characterId = robotConfig.CharacterId
    else
        characterId = entityId
    end
    return XCharacterConfigs.GetCharacterType(characterId)
end

function XTeam:SetCustomCharacterType(value)
    self.CustomCharacterType = value
end

-- -- 获取队伍限制角色类型
-- function XTeam:GetCharacterLimitType()
--     return self.CharacterLimitType
-- end

function XTeam:GetSaveKey()
    return self.Id .. XPlayer.Id
end

function XTeam:GetEntityIds()
    return self.EntitiyIds
end

function XTeam:GetEntityIdByTeamPos(pos)
    return self.EntitiyIds[pos] or 0
end

function XTeam:GetEntityIdIsInTeam(entityId)
    for pos, v in ipairs(self.EntitiyIds) do
        if v == entityId then
            return true, pos
        end
    end
    return false, -1
end

function XTeam:GetEntityIdPos(entityId)
    for pos, v in ipairs(self.EntitiyIds) do
        if v == entityId then
            return pos
        end
    end
    return -1
end

function XTeam:CheckHasSameCharacterId(entityId)
    local checkCharacterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    for pos, entityId in pairs(self:GetEntityIds()) do
        if XEntityHelper.GetCharacterIdByEntityId(entityId) == checkCharacterId then
            return true, pos
        end
    end
    return false, -1
end

function XTeam:GetFirstFightPos()
    return self.FirstFightPos > 0 and self.FirstFightPos or 1
end

function XTeam:GetCaptainPos()
    return self.CaptainPos > 0 and self.CaptainPos or 1
end

function XTeam:GetCaptainPosEntityId()
    return self.EntitiyIds[self:GetCaptainPos()]
end

function XTeam:GetFirstFightPosEntityId()
    return self.EntitiyIds[self:GetFirstFightPos()]
end

function XTeam:GetIsEmpty()
    for _, v in ipairs(self.EntitiyIds) do
        if v ~= 0 then
            return false
        end
    end
    return true
end

function XTeam:GetIsFullMember()
    for _, v in ipairs(self.EntitiyIds) do
        if v == 0 then
            return false
        end
    end
    return true
end

function XTeam:GetExtraData()
    return self.ExtraData
end

function XTeam:Clear()
    self.EntitiyIds = {0, 0, 0}
    self.FirstFightPos = 1
    self.CaptainPos = 1
    self:Save()
end

function XTeam:ClearEntityIds()
    self.EntitiyIds = {0, 0, 0}
    self:Save()
end

function XTeam:CopyData(OutTeam)
    for i = 1, #self.EntitiyIds do
        self:UpdateEntityTeamPos(OutTeam:GetEntityIdByTeamPos(i), i, true)
    end
    self:UpdateFirstFightPos(OutTeam:GetFirstFightPos())
    self:UpdateCaptainPos(OutTeam:GetCaptainPos())
    self:Save()
end

function XTeam:UpdateAutoSave(value)
    self.AutoSave = value
end

function XTeam:UpdateLocalSave(value)
    self.LocalSave = value
end

function XTeam:Save()
    if not self.AutoSave then
        return
    end
    -- XTool.CallFunctionOnNextFrame(self._Save, self)
    self:_Save()
end

-- 外部调用保存
function XTeam:ManualSave()
    -- XTool.CallFunctionOnNextFrame(self._Save, self)
    self:_Save()
end

function XTeam:_Save()
    if self.LocalSave then
        -- 默认本地缓存，后面可扩展使用原本的服务器保存方式
        XSaveTool.SaveData(
            self:GetSaveKey(),
            {
                Id = self.Id,
                EntitiyIds = self.EntitiyIds,
                FirstFightPos = self.FirstFightPos,
                CaptainPos = self.CaptainPos
            }
        )
    end
    if self.SaveCallback then
        self.SaveCallback(self)
    end
end

function XTeam:GetIsShowRoleDetailInfo()
    local key = self:GetRoleDetailSaveKey()
    if not CS.UnityEngine.PlayerPrefs.HasKey(key) then
        return false
    end
    return CS.UnityEngine.PlayerPrefs.GetInt(key) == 1
end

function XTeam:SaveIsShowRoleDetailInfo(value)
    CS.UnityEngine.PlayerPrefs.SetInt(self:GetRoleDetailSaveKey(), value)
end

function XTeam:GetRoleDetailSaveKey()
    -- 和之前的通用界面保持统一的key
    if self.RoleDetailSaveKey == nil then
        self.RoleDetailSaveKey = "NewRoomShowInfoToggle" .. tostring(XPlayer.Id)
    end
    return self.RoleDetailSaveKey
end

--获取分离的队伍中上阵的成员Id,机器人Id列表
function XTeam:SpiltCharacterAndRobotIds()
    local characterIds = {}
    local robotIds = {}
    for _, entityId in pairs(self.EntitiyIds) do
        if XTool.IsNumberValid(entityId) then
            if XRobotManager.CheckIsRobotId(entityId) then
                tableInsert(robotIds, entityId)
            else
                tableInsert(characterIds, entityId)
            end
        end
    end
    return characterIds, robotIds
end

--获得队伍总战力
function XTeam:GetAbility()
    local addAbility = 0
    local ability
    for _, entityId in pairs(self.EntitiyIds) do
        if XTool.IsNumberValid(entityId) then
            ability = XRobotManager.CheckIsRobotId(entityId) and XRobotManager.GetRobotAbility(entityId) or XDataCenter.CharacterManager.GetCharacterAbilityById(entityId)
            addAbility = addAbility + math.ceil(ability)
        end
    end
    return addAbility
end

-- 转换回旧队伍数据，为了兼容旧系统
function XTeam:SwithToOldTeamData()
    return {
        TeamData = self.EntitiyIds,
        CaptainPos = self.CaptainPos,
        FirstFightPos = self.FirstFightPos,
        TeamId = self.Id
    }
end

return XTeam
