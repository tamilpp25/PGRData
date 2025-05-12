local XTransfiniteMember = require("XEntity/XTransfinite/XTransfiniteMember")

---@class XTransfiniteTeam
local XTransfiniteTeam = XClass(nil, "XTransfiniteTeam")

function XTransfiniteTeam:Ctor(stageGroupId)
    ---@type XTransfiniteMember[]
    self._Members = {}
    for i = 1, XTeamConfig.MEMBER_AMOUNT do
        self._Members[i] = XTransfiniteMember.New()
    end
    self._CaptainPos = 1
    self._FirstPos = 1
    self._EnterCgIndex = 0
    self._SettleCgIndex = 0

    if stageGroupId then
        self._SaveKey = "TransfiniteTeam" .. XPlayer.Id .. stageGroupId
    end
    
    self:RefreshGeneralSkills(true)
end

function XTransfiniteTeam:Save()
    if not self._SaveKey then
        return
    end
    XSaveTool.SaveData(self._SaveKey, {
        EntitiyIds = self:GetEntityIds(),
        FirstFightPos = self._FirstPos,
        CaptainPos = self._CaptainPos,
        SelectedGeneralSkill = self.SelectedGeneralSkill,
        EnterCgIndex = self._EnterCgIndex,
        SettleCgIndex = self._SettleCgIndex,
    })
end

function XTransfiniteTeam:Load()
    if not self._SaveKey then
        return
    end
    local data = XSaveTool.GetData(self._SaveKey)
    if data then
        self:SetFirstPos(data.FirstFightPos)
        self:SetCaptainPos(data.CaptainPos)
        self:SetEnterCgIndex(data.EnterCgIndex)
        self:SetSettleCgIndex(data.SettleCgIndex)
        self:UpdateByEntityIds(data.EntitiyIds)
        self:UpdateGenernalSkillsByEntityIdList(data.EntitiyIds)
        self:RefreshGeneralSkills(true)
    end
end

function XTransfiniteTeam:GetEntityIds()
    local entityIds = {}
    for i = 1, #self._Members do
        local member = self._Members[i]
        entityIds[i] = member:GetId()
    end
    return entityIds
end

---@return XTransfiniteMember[]
function XTransfiniteTeam:GetMembers()
    return self._Members
end

function XTransfiniteTeam:UpdateByEntityIds(value)
    for i = 1, XTeamConfig.MEMBER_AMOUNT do
        local member = self._Members[i]
        member:SetId(value[i])
    end
    self:RefreshGeneralSkills(true)
end

function XTransfiniteTeam:FindAliveMember()
    for i = 1, #self._Members do
        local member = self._Members[i]
        if member:IsValid() and not member:IsDead() then
            return i
        end
    end
end

function XTransfiniteTeam:GetCaptainPos()
    local pos = self._CaptainPos
    local member = self._Members[pos]
    if member:IsDead() then
        pos = self:FindAliveMember()
    end
    return pos
end

function XTransfiniteTeam:GetFirstPos()
    local pos = self._FirstPos
    local member = self._Members[pos]
    if member:IsDead() then
        pos = self:FindAliveMember()
    end
    return pos
end

function XTransfiniteTeam:SetFirstPos(value)
    self._FirstPos = value
end

function XTransfiniteTeam:SetCaptainPos(value)
    self._CaptainPos = value
end

function XTransfiniteTeam:GetMemberByCharacterId(id)
    for i = 1, #self._Members do
        local member = self._Members[i]
        if member:GetId() == id then
            return member
        end
    end
    return false
end

function XTransfiniteTeam:SetCharacterData(characterList)
    for i = 1, #characterList do
        local data = characterList[i]
        local id = data.CharacterId
        local member = self:GetMemberByCharacterId(id)
        if member then
            member:SetHp(data.HpPercent)
            member:SetSp(data.Energy)
        end
    end
end

function XTransfiniteTeam:IsFull()
    for i = 1, #self._Members do
        local member = self._Members[i]
        if not member:IsValid() then
            return false
        end
    end
    return true
end

function XTransfiniteTeam:IsCaptainSelected()
    local member = self._Members[self._CaptainPos]
    if not member then
        return false
    end
    if member:IsValid() then
        return true
    end
    return false
end

---@param team XTeam
function XTransfiniteTeam:UpdateXTeam(team)
    team:UpdateEntityIds(self:GetEntityIds())
    team:UpdateFirstFightPos(self:GetFirstPos())
    team:UpdateCaptainPos(self:GetCaptainPos())
    team:UpdateSelectGeneralSkill(self:GetCurGeneralSkill())
end

function XTransfiniteTeam:Reset()
    for i = 1, #self._Members do
        local member = self._Members[i]
        member:SetDefault()
    end
end

function XTransfiniteTeam:IsEmpty()
    for i = 1, #self._Members do
        local member = self._Members[i]
        if member:IsValid() then
            return false
        end
    end
    return true
end

function XTransfiniteTeam:IsFirstPosValid()
    local firstPos = self:GetFirstPos()
    local member = self._Members[firstPos]
    if member and member:IsValid() then
        return true
    end
    return false
end

--region 效应选择
function XTransfiniteTeam:GetCurGeneralSkill()
    return self.SelectedGeneralSkill or 0
end

function XTransfiniteTeam:UpdateSelectGeneralSkill(skillId)
    self.SelectedGeneralSkill = skillId
    self:Save()
end

---技能汇总表仅加载时缓存，不会存储到本地
function XTransfiniteTeam:UpdateGenernalSkillsByEntityId(entityId, isRemove)
    if not XTool.IsNumberValid(entityId) then
        return
    end

    local fixedEntityId = entityId

    --如果是机器人则需要转变一下
    local characterId = XMVCA.XCharacter:CheckIsCharOrRobot(fixedEntityId) and XRobotManager.GetCharacterId(fixedEntityId) or fixedEntityId

    -- 获取角色已激活的效应技能列表（自机和机器人）
    local skillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(characterId)

    if XTool.IsTableEmpty(skillIds) then
        return
    end

    if self._GenernalSkills == nil then
        self._GenernalSkills = {}
    end

    for index, value in ipairs(skillIds) do
        if isRemove then
            if not XTool.IsTableEmpty(self._GenernalSkills[value]) then
                self._GenernalSkills[value][characterId] = nil
            end

            if XTool.IsTableEmpty(self._GenernalSkills[value]) then
                self._GenernalSkills[value] = nil
                if self.SelectedGeneralSkill == value then
                    self:UpdateSelectGeneralSkill(0)
                end
            end
        else
            if self._GenernalSkills[value] == nil then
                self._GenernalSkills[value] = {}
            end
            self._GenernalSkills[value][characterId] = true
        end

        :: continue ::
    end
end

--- 刷新队伍的效应技能
function XTransfiniteTeam:UpdateGenernalSkillsByEntityIdList(entities)
    if XTool.IsTableEmpty(entities) then
        return
    end

    self._GenernalSkills = {}

    for index, value in ipairs(entities) do
        self:UpdateGenernalSkillsByEntityId(value)
    end
end

function XTransfiniteTeam:ClearGeneralSkill()
    self.SelectedGeneralSkill = nil
    self._GenernalSkills = nil
end

function XTransfiniteTeam:RefreshGeneralSkills(autoSelect)
    -- 刷新需要保证已经选择的效应不被重置（还存在的情况下）
    local lastSelectGeneralSkill = self.SelectedGeneralSkill or 0
    self:ClearGeneralSkill()
    self:UpdateGenernalSkillsByEntityIdList(self:GetEntityIds())
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

function XTransfiniteTeam:CheckHasGeneralSkills()
    return not XTool.IsTableEmpty(self._GenernalSkills)
end

function XTransfiniteTeam:AutoSelectGeneralSkill(defaultSkillIds)
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
--endregion

--region 入场结算动画角色自选

function XTransfiniteTeam:SetEnterCgIndex(index)
    self._EnterCgIndex = index
end

function XTransfiniteTeam:SetSettleCgIndex(index)
    self._SettleCgIndex = index
end

function XTransfiniteTeam:GetEnterCgIndex()
    return self._EnterCgIndex
end

function XTransfiniteTeam:GetSettleCgIndex()
    return self._SettleCgIndex
end

--endregion

return XTransfiniteTeam
