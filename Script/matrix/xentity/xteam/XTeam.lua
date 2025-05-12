local tableInsert = table.insert
---@class XTeam
local XTeam = XClass(nil, "XTeam")

function XTeam:Ctor(id, isStandAlone)
    self.Id = id or -1
    self.IsStandAlone = isStandAlone
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
    -- 数据初始化是没有收集数据的，因此无需做清空处理
    self:RefreshGeneralSkills(false, true)
end

function XTeam:UpdateSaveCallback(callback)
    self.SaveCallback = callback
end

function XTeam:UpdateEntityTeamPos(entityId, teamPos, isJoin)
    if isJoin then
        if self:CheckHasSameCharacterId(entityId, teamPos) and XTool.IsNumberValid(entityId) then
            XLog.CustomReport(XEnumConst.CustomReportModuleId.XTeam, "UpdateEntityTeamPos JoinId:", entityId, "AllEntityIdInTeam", self.EntitiyIds)
            return
        end
        
        --如果是替换，需要先移除前一个角色的效应统计
        if XTool.IsNumberValid(self.EntitiyIds[teamPos]) then
            self:UpdateGenernalSkillsByEntityId(self.EntitiyIds[teamPos], true, true)
        end

        self:UpdateGenernalSkillsByEntityId(entityId, false)
        
        self.EntitiyIds[teamPos] = entityId or 0
    else
        for pos, id in ipairs(self.EntitiyIds) do
            if id == entityId then
                self.EntitiyIds[pos] = 0
                break
            end
        end
        self:UpdateGenernalSkillsByEntityId(entityId, true, true)
    end
    self:Save()
end

-- teamData : 旧系统的队伍数据
function XTeam:UpdateFromTeamData(teamData)
    if not self.IsStandAlone then
        local isSameEntityId, index = XMVCA.XCharacter:HasDuplicateCharId(teamData.TeamData)
        if isSameEntityId then
            teamData.TeamData[index] = 0
        end
    end

    self.FirstFightPos = teamData.FirstFightPos
    self.CaptainPos = teamData.CaptainPos
    self.EnterCgIndex = teamData.EnterCgIndex
    self.SettleCgIndex = teamData.SettleCgIndex
    for pos, characterId in ipairs(teamData.TeamData) do
        self.EntitiyIds[pos] = characterId
    end
    self.TeamName = teamData.TeamName
    self.SelectedGeneralSkill = teamData.SelectedGeneralSkill
    self:RefreshGeneralSkills(true)
    self:Save()
end

function XTeam:UpdateEntityIds(value)
    if not self.IsStandAlone then
        local isSameEntityId, index = XMVCA.XCharacter:HasDuplicateCharId(value)
        if isSameEntityId then
            value[index] = 0
        end
    end

    self.EntitiyIds = value
    self:RefreshGeneralSkills(true)
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

function XTeam:UpdateCaptainPosAndFirstFightPos(cPos,fPos)
    self.FirstFightPos = fPos
    self.CaptainPos = cPos
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
        return nil
    end
    local characterId = nil
    if XRobotManager.CheckIsRobotId(entityId) then
        local robotConfig = XRobotManager.GetRobotTemplate(entityId)
        characterId = robotConfig.CharacterId
    else
        characterId = entityId
    end
    return XMVCA.XCharacter:GetCharacterType(characterId)
end

function XTeam:SetCustomCharacterType(value)
    self.CustomCharacterType = value
end

-- -- 获取队伍限制角色类型
-- function XTeam:GetCharacterLimitType()
--     return self.CharacterLimitType
-- end

-- 按key顺序返回机器人列表，pos上没有的话就全为0
function XTeam:GetRobotIdsOrder()
    local robotIds = {}
    for k, id in pairs(self:GetEntityIds()) do
        if XRobotManager.CheckIsRobotId(id) then
            robotIds[k] = id
        else
            robotIds[k] = 0
        end
    end
    return robotIds
end

function XTeam:GetSaveKey()
    return self.Id .. XPlayer.Id
end

function XTeam:GetEntityIds()
    return self.EntitiyIds
end

-- 按顺序返回对应位置的charId，下标即是pos，如果对应pos上的角色是机器人或者位空则为0
function XTeam:GetCharacterIdsOrder()
    local res = {}
    for k, id in pairs(self.EntitiyIds) do
        if XRobotManager.CheckIsRobotId(id) then
            res[k] = 0
        else
            res[k] = id
        end
    end
    return res
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

function XTeam:CheckHasSameCharacterId(entityId, position)
    if self.IsStandAlone then
        return false
    end

    local checkCharacterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    for pos, entityId in pairs(self:GetEntityIds()) do
        if XEntityHelper.GetCharacterIdByEntityId(entityId) == checkCharacterId then
            if position == pos then
                -- 相同位置的可以忽略
                return false, -1
            end
            return true, pos
        end
    end
    return false, -1
end

-- 检查自机和机器人是否有相同的角色id
function XTeam:CheckHasSameCharacterIdButNotEntityId(entityId)
    if self.IsStandAlone then
        return false
    end
    
    local checkCharacterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    for pos, entityIdInTeam in pairs(self:GetEntityIds()) do
        if XEntityHelper.GetCharacterIdByEntityId(entityIdInTeam) == checkCharacterId and entityIdInTeam ~= entityId then
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

function XTeam:GetEntityCount()
    local count = 0
    for _, v in ipairs(self.EntitiyIds) do
        if v ~= 0 then
            count = count + 1
        end
    end
    return count
end

function XTeam:GetExtraData()
    return self.ExtraData
end

function XTeam:Clear()
    self.EntitiyIds = {0, 0, 0}
    self.FirstFightPos = 1
    self.CaptainPos = 1
    self:ClearGeneralSkill()
    self:Save()
end

function XTeam:ClearEntityIds()
    self.EntitiyIds = {0, 0, 0}
    self:ClearGeneralSkill()
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
                CaptainPos = self.CaptainPos,
                SelectedGeneralSkill = self.SelectedGeneralSkill,
                EnterCgIndex = self.EnterCgIndex,
                SettleCgIndex = self.SettleCgIndex,
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
            ability = XRobotManager.CheckIsRobotId(entityId) and XRobotManager.GetRobotAbility(entityId) or XMVCA.XCharacter:GetCharacterAbilityById(entityId)
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
        TeamId = self.Id,
        SelectedGeneralSkill = self.SelectedGeneralSkill,
        EnterCgIndex = self.EnterCgIndex,
        SettleCgIndex = self.SettleCgIndex,
    }
end

-- 检查队伍角色的有效性，包含在传入列表中的角色即为有效
function XTeam:CheckEntitiesValid(validEntities)
    -- 克隆表预防外部直接修改原表可能产生的问题
    local tempEntityIds = XTool.Clone(self.EntitiyIds)
    local entityChanged, needChangeCaptainPos, newEntityIds = XDataCenter.TeamManager.GetValidEntitiesByLimitEntityIds(tempEntityIds, validEntities, self.CaptainPos)
    
    if entityChanged then
        -- 使用新队伍
        self.EntitiyIds = newEntityIds
        -- 刷新效应技能选择
        self:RefreshGeneralSkills(true)
        -- 刷新队长位置
        if needChangeCaptainPos then
            for i = 1, #self.EntitiyIds do
                if XTool.IsNumberValid(self.EntitiyIds[i]) then
                    self.CaptainPos = i
                    break
                end
            end
        end

        -- 触发保存
        self:Save()
    end
end

--region 角色效应技能相关
function XTeam:GetCurGeneralSkill()
    return self.SelectedGeneralSkill or 0
end

function XTeam:UpdateSelectGeneralSkill(skillId, noAutoSave)
    self.SelectedGeneralSkill = skillId or 0
    if not noAutoSave then
        self:Save()
    end
end

function XTeam:GetGeneralSkillList()
    local list = {}

    for id, characters in pairs(self._GenernalSkills) do
        table.insert(list,{Id = id, Characters = characters})
    end
    
    return list
end

---技能汇总表仅加载时缓存，不会存储到本地
---@param autoSave @传递参数控制是否保存效应选择（如果发生成员变动，成员变动本身会触发一次保存）
function XTeam:UpdateGenernalSkillsByEntityId(entityId, isRemove, noAutoSave)
    if not XTool.IsNumberValid(entityId) then
        return
    end
    
    -- 对特殊Id进行修正，得到的id为 robotId or characterId
    local fixedEntityId = self:GetSpecialEntityId(entityId)
    fixedEntityId = XTool.IsNumberValid(fixedEntityId) and fixedEntityId or entityId
    
    -- 获取角色已激活的效应技能列表（自机和机器人）
    local skillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(fixedEntityId)

    self:SetGeneralSkills(fixedEntityId, skillIds, isRemove, noAutoSave)
end

function XTeam:SetGeneralSkills(entityId, skillIds, isRemove, noAutoSave)
    if XTool.IsTableEmpty(skillIds) then
        return
    end

    if self._GenernalSkills == nil then
        self._GenernalSkills = {}
    end

    for index, value in ipairs(skillIds) do
        if isRemove then
            if not XTool.IsTableEmpty(self._GenernalSkills[value]) then
                self._GenernalSkills[value][entityId] = nil
            end

            if XTool.IsTableEmpty(self._GenernalSkills[value]) then
                self._GenernalSkills[value] = nil
                if self.SelectedGeneralSkill == value then
                    self:UpdateSelectGeneralSkill(0, noAutoSave)
                end
            end
        else
            if self._GenernalSkills[value] == nil then
                self._GenernalSkills[value] = {}
            end
            self._GenernalSkills[value][entityId] = true
        end

        :: continue ::
    end
end

--- 刷新队伍的效应技能
function XTeam:UpdateGenernalSkillsByEntityIdList(entities, keepOldData)
    if XTool.IsTableEmpty(entities) then
        return
    end

    if not keepOldData then
        self:ClearGeneralSkill()
    end

    for index, value in ipairs(entities) do
        self:UpdateGenernalSkillsByEntityId(value)
    end
end

function XTeam:ClearGeneralSkill()
    self.SelectedGeneralSkill = nil
    self._GenernalSkills = nil
end

---@param keepOldData @是否需要保持旧数据，如果没有发生成员变动，这时可能是需要检查成员新解锁的效应，数据只增不减，可以选择不清空数据
function XTeam:RefreshGeneralSkills(autoSelect, keepOldData)
    -- 刷新需要保证已经选择的效应不被重置（还存在的情况下）
    local lastSelectGeneralSkill = self.SelectedGeneralSkill or 0
    self:UpdateGenernalSkillsByEntityIdList(self.EntitiyIds, keepOldData)
    -- 判断刷新过后，当前队伍的效应技能里还有没有之前选择的
    local hasLastSelecedGeneralSkill = false
    if not XTool.IsTableEmpty(self._GenernalSkills) then
        for generalSkillId, linkCharaList in pairs(self._GenernalSkills) do
            if generalSkillId == lastSelectGeneralSkill then
                hasLastSelecedGeneralSkill = true
                break
            end
        end
    end

    if hasLastSelecedGeneralSkill then
        self.SelectedGeneralSkill = lastSelectGeneralSkill
    end
    
    if not XTool.IsNumberValid(self.SelectedGeneralSkill) and autoSelect then
        self:AutoSelectGeneralSkill()
    end
end

function XTeam:CheckHasGeneralSkills()
    return not XTool.IsTableEmpty(self._GenernalSkills)
end

function XTeam:AutoSelectGeneralSkill(defaultSkillIds)
    if not XTool.IsTableEmpty(defaultSkillIds) then
        local aimSkillId = 0
        for index, value in ipairs(defaultSkillIds) do
            if not XTool.IsTableEmpty(self._GenernalSkills[value]) then
                if aimSkillId == 0 then
                    aimSkillId = value
                else
                    local newCount = XTool.GetTableCount(value)
                    local oldCount = XTool.GetTableCount(self._GenernalSkills[aimSkillId])
                    if newCount > oldCount then -- 如果新的技能角色数最多，则选新技能
                        aimSkillId = value
                    end
                end
            end
        end
        if XTool.IsNumberValid(aimSkillId) then
            self:UpdateSelectGeneralSkill(aimSkillId)
            return
        end
    end

    if XTool.IsTableEmpty(self._GenernalSkills) then
        return
    end
    --找出关联角色最多且Id最小的技能
    local aimSkillId = 0
    for key, value in pairs(self._GenernalSkills) do
        if aimSkillId == 0 then
            aimSkillId = key
        else
            local newCount = XTool.GetTableCount(value)
            local oldCount = XTool.GetTableCount(self._GenernalSkills[aimSkillId])
            if newCount > oldCount then -- 如果新的技能角色数最多，则选新技能
                aimSkillId = key
            elseif newCount == oldCount then -- 如果两个技能角色数量相等，则选Id小的那一个
                if key < aimSkillId then
                    aimSkillId = key
                end
            end
        end
    end
    self:UpdateSelectGeneralSkill(aimSkillId)
end

function XTeam:GetObservationActiveCareer()
    local tankCount = 0
    local tankPos = 0
    local amplifierCount = 0
    local amplifierPos = 0
    local physicalCount = 0
    local physicalPos = 0
    local obsCount = 0
    local obsPos = 0
    for i, entityId in pairs(self.EntitiyIds) do
        if XTool.IsNumberValid(entityId) then
            local fixedEntityId = self:GetSpecialEntityId(entityId)
            fixedEntityId = XTool.IsNumberValid(fixedEntityId) and fixedEntityId or entityId
            entityId = fixedEntityId

            local career = XMVCA.XCharacter:GetCharacterCareer(entityId)
            local charElement = XMVCA.XCharacter:GetCharacterElement(entityId)
            local isPhysical = charElement == XEnumConst.CHARACTER.Element.Physical
            if isPhysical then
                physicalCount = physicalCount + 1
                physicalPos = i
            end
            if career == XEnumConst.CHARACTER.Career.Tank then
                tankCount = tankCount + 1
                tankPos = i
            elseif (career == XEnumConst.CHARACTER.Career.Amplifier or career == XEnumConst.CHARACTER.Career.Support) then
                amplifierCount = amplifierCount + 1
                amplifierPos = i
            elseif career == XEnumConst.CHARACTER.Career.Observation then
                obsCount = obsCount + 1
                obsPos = i
            end

        end
    end

    local res = XEnumConst.CHARACTER.Career.None
    if tankCount + amplifierCount >=2 then
        return res
    end
    if obsCount ~= 1 then
        return res
    end
    if physicalCount > 1 then
        return res
    end
    if physicalCount == 1 then
        if self:GetEntityCount() == 2  then
            return res
        elseif self:GetEntityCount() == 3 and (physicalPos == tankPos or physicalPos == amplifierPos) then
            return res
        end
    end

    if tankCount == 1 and amplifierCount == 0 then
        res = XEnumConst.CHARACTER.Career.Amplifier
    elseif tankCount == 0 and amplifierCount == 1 then
        res = XEnumConst.CHARACTER.Career.Tank
    end

    return res, obsPos
end

--肉鸽特殊实体Id处理
function XTeam:GetSpecialEntityId(entityId)
    local tmpId = self:CheckIsRouge1EntityId(entityId)
    -- 实体Id可能是自定义Id
    if not XTool.IsNumberValid(tmpId) then
        tmpId = self:CheckIsRouge2EntityId(entityId)
        if not XTool.IsNumberValid(tmpId) then

        else
            return tmpId
        end
    else
        return tmpId
    end
end

function XTeam:CheckIsRouge1EntityId(entityId)
    local advMng = XDataCenter.TheatreManager.GetCurrentAdventureManager()

    if advMng then
        local role = advMng:GetRole(entityId)
        if role then
            return role:GetRawDataId()
        end
    end
    
    return 0
end

function XTeam:CheckIsRouge2EntityId(entityId)
    local advMng = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()

    if advMng then
        local role = advMng:GetRole(entityId)
        if role then
            return role:GetRawDataId()
        end
    end

    return 0
end
--endregion

--region 入场结算动画角色自选

---入场NPC索引 0跟随首发角色 1红色位置 2蓝色位置 3黄色位置
function XTeam:GetEnterCgIndex()
    return self.EnterCgIndex or 0
end

---结算NPC索引 0跟随退场角色 1红色位置 2蓝色位置 3黄色位置
function XTeam:GetSettleCgIndex()
    return self.SettleCgIndex or 0
end

function XTeam:SetEnterCgIndex(index)
    self.EnterCgIndex = index
end

function XTeam:SetSettleCgIndex(index)
    self.SettleCgIndex = index
end

--endregion

return XTeam
