local XTeam = require("XEntity/XTeam/XTeam")
---@class XAwarenessTeam:XTeam
local XAwarenessTeam = XClass(XTeam, "XAwarenessTeam")

local MemberData = require("XEntity/XAssign/XAssignMember")

function XAwarenessTeam:Ctor(id)
    self.Super.Ctor(self, id)
    self.Id = id
    self.MemberList = nil
    self.LeaderIndex = nil
    self.FirstFightIndex = nil
end

function XAwarenessTeam:GetCfg()
    return XFubenAwarenessConfigs.GetAllConfigs(XFubenAwarenessConfigs.TableKey.AwarenessTeamInfo)[self.Id]
end

function XAwarenessTeam:GetId() return self.Id end
function XAwarenessTeam:GetBuffId() return self:GetCfg().BuffId end
function XAwarenessTeam:GetNeedCharacter() return self:GetCfg().NeedCharacter end
function XAwarenessTeam:GetRequireAbility() return self:GetCfg().RequireAbility end
function XAwarenessTeam:GetCondition() return self:GetCfg().Condition end
function XAwarenessTeam:GetDesc() return self:GetCfg().Desc end

function XAwarenessTeam:CheckTeamEmpty()
    for k, member in pairs(self:GetMemberList()) do
        if XTool.IsNumberValid(member:GetCharacterId()) then
            return false
        end
    end
    return true
end

function XAwarenessTeam:CheckIsInTeam(characterId)
    for index, member in ipairs(self:GetMemberList() or {}) do
        local id = member:GetCharacterId()
        if id > 0 and id == characterId then
            return true, member, index
        end
    end
    return false
end

function XAwarenessTeam:GetMemberList()
    if not self.MemberList then
        self.MemberList = {}
        local count = self:GetNeedCharacter()
        for i = 1, count do
            self.MemberList[i] = MemberData.New(i)  -- 队伍位置
        end
        if count > 1 then -- 若是多人队伍则队长居中, 即队员索引为{2, 1, 3}
            self.MemberList[1], self.MemberList[2] = self.MemberList[2], self.MemberList[1]
        end
    end
    return self.MemberList
end

function XAwarenessTeam:GetObservationActiveCareer()
    if not self.MemberList then return end
    local tankCount = 0
    local tankPos = 0
    local amplifierCount = 0
    local amplifierPos = 0
    local physicalCount = 0
    local physicalPos = 0
    local obsCount = 0
    local obsPos = 0
    for i, memberData in pairs(self.MemberList) do
        local charId = memberData:GetCharacterId()
        
        if XTool.IsNumberValid(charId) then
            local career = XMVCA.XCharacter:GetCharacterCareer(charId)
            local charElement = XMVCA.XCharacter:GetCharacterElement(charId)
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

function XAwarenessTeam:ClearMemberList()
    if not self.MemberList then return end
    for _, memberData in pairs(self.MemberList) do
        memberData:SetCharacterId(0)
    end
end

function XAwarenessTeam:GetCharacterType()
    if not self.MemberList then return end
    for _, memberData in pairs(self.MemberList) do
        if memberData:HasCharacter() then
            return memberData:GetCharacterType()
        end
    end
end

function XAwarenessTeam:GetMember(index)
    for _, member in ipairs(self:GetMemberList()) do
        if member:GetIndex() == index then
            return member
        end
    end
    XLog.Error("XAwarenessTeam:GetMember函数无效参数index: " .. tostring(index))
    return nil
end

function XAwarenessTeam:SetLeaderIndex(index)
    self.LeaderIndex = index
end

function XAwarenessTeam:GetLeaderIndex()
    return self.LeaderIndex or XDataCenter.FubenAssignManager.CAPTIAN_MEMBER_INDEX
end

function XAwarenessTeam:SetFirstFightIndex(index)
    self.FirstFightIndex = index
end

---==========================================
--- 得到队伍首发位
--- 当首发位不为空时，直接返回首发位
--- 不然查看队长位是否为空，不为空则返回队长位
---（因为服务器在之前只有队长位，后面区分了队长位与首发位，存在有队长位数据，没有首发位数据的情况）
--- 如果队长位也为空，则返回默认首发位
---@return number
---==========================================
function XAwarenessTeam:GetFirstFightIndex()
    return self.FirstFightIndex or self.LeaderIndex or XDataCenter.FubenAssignManager.FIRSTFIGHT_MEMBER_INDEX
end

function XAwarenessTeam:GetLeaderSkillDesc()
    local memberData = self:GetMember(self:GetLeaderIndex())
    if memberData then
        local captianSkillInfo = memberData:GetCharacterSkillInfo()
        if captianSkillInfo then
            return captianSkillInfo.Level > 0 and captianSkillInfo.Intro or string.format("%s%s", captianSkillInfo.Intro, CS.XTextManager.GetText("CaptainSkillLock"))
        end
    end
    return ""
end

function XAwarenessTeam:IsEnoughAbility()
    local memberList = self:GetMemberList()
    local need = self:GetRequireAbility()
    for _, member in pairs(memberList) do
        if member:GetCharacterAbility() > need then
            return true
        end
    end
    return false
end

function XAwarenessTeam:SetMember(order, characterId)
    self:GetMemberList()[order]:SetCharacterId(characterId)
end

-- 获得角色在队伍中的排序
function XAwarenessTeam:GetCharacterOrder(characterId)
    for order, v in pairs(self:GetMemberList()) do
        if v:GetCharacterId() == characterId then
            return order
        end
    end
    return nil
end

function XAwarenessTeam:GetRealOrder(pos)
    local order = XDataCenter.FubenAssignManager.GetMemberOrderByIndex(pos, #self:GetMemberList())
    return order
end

-- server api
function XAwarenessTeam:SetMemberList(characterIdList)
    if characterIdList then
        local memberList = self:GetMemberList()
        local memberCount = #memberList
        for index, v in pairs(memberList) do
            local order = XDataCenter.FubenAssignManager.GetMemberOrderByIndex(index, memberCount)
            v:SetCharacterId(characterIdList[order])
        end
    else
        for _, v in pairs(self:GetMemberList()) do
            v:SetCharacterId(nil)
        end
    end
end

---@overload
---@param keepOldData @是否需要保持旧数据，如果没有发生成员变动，这时可能是需要检查成员新解锁的效应，数据只增不减，可以选择不清空数据
function XAwarenessTeam:RefreshGeneralSkills(autoSelect, keepOldData)
    -- 刷新需要保证已经选择的效应不被重置（还存在的情况下）
    local lastSelectGeneralSkill = self.SelectedGeneralSkill or 0

    local memberList = self:GetMemberList()
    local entityIds = {}
    for i, v in ipairs(memberList) do
        table.insert(entityIds, v:GetCharacterId())
    end

    self:UpdateGenernalSkillsByEntityIdList(entityIds, keepOldData)
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

return XAwarenessTeam