local MAX_PARTNER_MEMBER = 3 --最大携带的辅助机数量

--辅助机主动技能类型
local MAIN_SKILL_TYPE = XPartnerConfigs.SkillType.MainSkill
--辅助机被动技能类型
local PASSIVE_SKILL_TYPE = XPartnerConfigs.SkillType.PassiveSkill

--==============================
---@desc 辅助机预设类
--==============================
local XPartnerPrefab = XClass(nil, "XPartnerPrefab")

function XPartnerPrefab:Ctor(teamId, data)
	self.TeamId = teamId
    self.TeamPartnerData = data and data or {}
end 

--==============================
 ---@desc 初始化技能数据
--==============================
function XPartnerPrefab:InitSkillCache(teamData)
    self.TeamData = teamData
    if XTool.IsTableEmpty(self.TeamPartnerData) then
        for pos = 1, MAX_PARTNER_MEMBER do
            self.TeamPartnerData[pos] = {}
        end
        return
    end
    local partnerData = self.TeamPartnerData
    for _, data in pairs(partnerData or {}) do
        self:__RefreshSkillData(data)
    end
end

--==============================
 ---@desc 根据站位获取辅助机id
 ---@pos 站位 
 ---@return number
--==============================
function XPartnerPrefab:GetPartnerIdByPos(pos)
    local partnerId = 0
    if not pos or pos <= 0 then return partnerId end

    if XTool.IsTableEmpty(self.TeamPartnerData) then return partnerId end
    
    local data = self.TeamPartnerData[pos]
    return data and data.PartnerId or partnerId
end

--==============================
 ---@desc 根据id获取携带者的下标
 ---@param nil 
 ---@return nil{type}
--==============================
function XPartnerPrefab:GetPosByPartnerId(partnerId)
    local pos = 0
    for idx, data in pairs(self.TeamPartnerData or {}) do
        local pId = data.PartnerId
        if pId == partnerId then
            pos = idx
        end
    end
    return pos
end

--==============================
 ---@desc 获取id与站位的对应关系
 ---@return table
--==============================
function XPartnerPrefab:GetCarriedDict()

    local carriedDict = {}
    for pos, data in pairs(self.TeamPartnerData or {}) do
        local partnerId = data.PartnerId
        if XTool.IsNumberValid(partnerId) then
            carriedDict[partnerId] = pos
        end
    end
    return carriedDict
end

--==============================
 ---@desc 获取携带者的角色Id
 ---@partnerId 辅助机Id 
 ---@return number
--==============================
function XPartnerPrefab:GetCharacterId(partnerId)

    if not XTool.IsNumberValid(partnerId) then return 0 end
    
    local teamData = self.TeamData
    if XTool.IsTableEmpty(teamData) then return 0 end

    local carriedDict = self:GetCarriedDict()
    local pos = carriedDict[partnerId]
    return teamData.TeamData[pos]
end

--==============================
 ---@desc 当前辅助机是否被携带
 ---@partnerId 辅助机Id 
 ---@return boolean
--==============================
function XPartnerPrefab:GetIsCarry(partnerId)
    local isCarried = false

    if not XTool.IsNumberValid(partnerId) then return isCarried end
    
    local characterId = self:GetCharacterId(partnerId)
    isCarried = XTool.IsNumberValid(characterId) and true or false
    
    return isCarried
end

--==============================
 ---@desc 当前队伍携带的辅助机数量
 ---@return number
--==============================
function XPartnerPrefab:GetCarriedCount()
    local count = 0
    for _, data in pairs(self.TeamPartnerData or {}) do
        local partnerId = data.PartnerId
        if XTool.IsNumberValid(partnerId) then
            count = count + 1
        end
    end
    return count > MAX_PARTNER_MEMBER and MAX_PARTNER_MEMBER or count
end

--==============================
 ---@desc 装备辅助机
 ---@pos 站位 
--==============================
function XPartnerPrefab:Equip(pos, newPartnerId)
    if not XTool.IsNumberValid(newPartnerId) then return end
    if not self.TeamPartnerData[pos] then
        self.TeamPartnerData[pos] = {}
    end
    self.TeamPartnerData[pos].PartnerId = newPartnerId
    self:UpdateSkillData(pos, newPartnerId)
end

--==============================
 ---@desc 卸下辅助机
 ---@pos 站位 
--==============================
function XPartnerPrefab:Unload(pos, isKeepCache)
    local partnerId = self:GetPartnerIdByPos(pos)
    if not XTool.IsNumberValid(partnerId) then
        return
    end
    if not isKeepCache then
        XDataCenter.PartnerManager.ClearPresetSkillCache(partnerId)
    end
    
    self.TeamPartnerData[pos] = {
        PartnerId = 0,
        SkillData = {}
    }
end

--==============================
 ---@desc 队伍覆盖
 ---@roleList 角色列表 
--==============================
function XPartnerPrefab:CoverByTeam(roleList)
    for pos, chrId in ipairs(roleList or {}) do
        local partnerId = XDataCenter.PartnerManager.GetCarryPartnerIdByCarrierId(chrId)
        if XTool.IsNumberValid(chrId) and XTool.IsNumberValid(partnerId) then
            self:Equip(pos, partnerId)
        else
            self:Unload(pos)
        end
    end
end

--==============================
 ---@desc 更新技能数据
 ---@partnerId 辅助机Id 
 ---@return table
--==============================
function XPartnerPrefab:GetSkillData(partnerId)
    if not XTool.IsNumberValid(partnerId) then return {} end
    
    for _, data in pairs(self.TeamPartnerData) do
        local pId = data.PartnerId
        if pId == partnerId then
            local skillData = data.SkillData
            XMessagePack.MarkAsTable(skillData)
            return skillData
        end
    end
    return {}
end

--==============================
 ---@desc 更新技能数据到队伍缓存中
 ---@partnerId 辅助机Id 
--==============================
function XPartnerPrefab:UpdateSkillData(pos, partnerId)
    if not XTool.IsNumberValid(partnerId) then return end
    
    local mainSkillGroups    = XDataCenter.PartnerManager.GetPresetSkillList(partnerId, MAIN_SKILL_TYPE)
    local passiveSkillGroups = XDataCenter.PartnerManager.GetPresetSkillList(partnerId, PASSIVE_SKILL_TYPE)
    
    --更新回调
    local updateFunc = function(groups)
        local skills = {}
        for _, group in ipairs(groups) do
            if XTool.IsTableEmpty(group) then
                goto Continue
            end
            local skillId = group:GetDefaultActiveSkillId()
            if XTool.IsNumberValid(skillId) then
                table.insert(skills, skillId)
            end
            ::Continue::
        end
        return skills
    end

    local skill = {
        [MAIN_SKILL_TYPE]    = updateFunc(mainSkillGroups),
        [PASSIVE_SKILL_TYPE] = updateFunc(passiveSkillGroups)
    }
    XMessagePack.MarkAsTable(skill)
    self.TeamPartnerData[pos].SkillData = skill
    --刷新到缓存中
    self:__RefreshSkillData(self.TeamPartnerData[pos])
    return skill
end

--==============================
 ---@desc 获取辅助机数据
 ---@return table
--==============================
function XPartnerPrefab:GetPartnerData()
    local partnerData = {}
    for pos = 1, MAX_PARTNER_MEMBER do
        local pId = self:GetPartnerIdByPos(pos)
        if XTool.IsNumberValid(pId) then
            partnerData[pos] = {
                PartnerId = pId,
                SkillData = self:GetSkillData(pId)
            }
        else
            partnerData[pos] = {}
        end
    end
    return partnerData
end

--==============================
 ---@desc 判断辅助机的预设技能与真实技能是否更改
 ---@partnerId 辅助机Id
 ---@return boolean
--==============================
function XPartnerPrefab:IsSkillChangeWithPrefab2Group(partnerId)
    if not XTool.IsNumberValid(partnerId) then
        return false
    end

    local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
    local skillData = self:GetSkillData(partnerId)
    local isCarried = self:GetIsCarry(partnerId)
    
    local prefabMainSkillList, prefabPassiveSkillList

    --辅助机预设的技能
    if isCarried then
        prefabMainSkillList    = skillData[MAIN_SKILL_TYPE]
        prefabPassiveSkillList = skillData[PASSIVE_SKILL_TYPE]
    else
        prefabMainSkillList    = XDataCenter.PartnerManager.GetPresetDefaultSkillIdList(partnerId, MAIN_SKILL_TYPE)
        prefabPassiveSkillList = XDataCenter.PartnerManager.GetPresetDefaultSkillIdList(partnerId, PASSIVE_SKILL_TYPE)
    end
    --辅助机真实携带的技能
    local groupMainSkillList    = partner:GetCarryMainSkillDefaultIdList()
    local groupPassiveSkillList = partner:GetCarryPassiveSkillDefaultIdList()
    
    --比较主动技能
    if self:__Compare(prefabMainSkillList, groupMainSkillList) then
        return true
    end
    
    --比较被动技能
    if self:__Compare(prefabPassiveSkillList, groupPassiveSkillList) then
        return true
    end

    return false
end

--==============================
---@desc 判断辅助机的预设技能与缓存技能是否更改
---@partnerId 辅助机Id
---@return boolean
--==============================
function XPartnerPrefab:IsSkillChangeWithPrefab2Cache(partnerId)
    if not XTool.IsNumberValid(partnerId) then
        return false
    end

    local skillData = self:GetSkillData(partnerId)
    local prefabMainSkillList    = skillData[MAIN_SKILL_TYPE]
    local prefabPassiveSkillList = skillData[PASSIVE_SKILL_TYPE]
    
    local cacheMainSkillList    = XDataCenter.PartnerManager.GetPresetDefaultSkillIdList(partnerId, MAIN_SKILL_TYPE, true)
    local cachePassiveSkillList = XDataCenter.PartnerManager.GetPresetDefaultSkillIdList(partnerId, PASSIVE_SKILL_TYPE, true)

    --比较主动技能
    if self:__Compare(prefabMainSkillList, cacheMainSkillList) then
        return true
    end

    --比较被动技能
    if self:__Compare(prefabPassiveSkillList, cachePassiveSkillList) then
        return true
    end

    return false
    
end

--region 私有方法
--判断函数
function XPartnerPrefab:__Compare(prefabSkillList, groupSkillList)
    prefabSkillList = prefabSkillList or {}
    groupSkillList  = groupSkillList or {}

    --技能数不一致
    if #prefabSkillList ~= #groupSkillList then
        return true
    end

    for i, id in ipairs(prefabSkillList) do
        if id ~= groupSkillList[i] then
            return true
        end
    end
    return false
end

--==============================
---@desc 刷新技能数据到缓中
---@data nil 
--==============================
function XPartnerPrefab:__RefreshSkillData(data)
    if not data then return end

    local skillData = data.SkillData or {}
    local partnerId = data.PartnerId
    local mainSkills = skillData[MAIN_SKILL_TYPE]
    local passiveSkills = skillData[PASSIVE_SKILL_TYPE]
    local mainSkillDict = {}
    local passiveSkillDict = {}
    for _, skillId in ipairs(mainSkills or {}) do
        mainSkillDict[skillId] = true
    end

    for _, skillId in ipairs(passiveSkills or {}) do
        passiveSkillDict[skillId] = true
    end

    XDataCenter.PartnerManager.RefreshPresetSkillCache(partnerId, mainSkillDict, MAIN_SKILL_TYPE)
    XDataCenter.PartnerManager.RefreshPresetSkillCache(partnerId, passiveSkillDict, PASSIVE_SKILL_TYPE)
end

--endregion


return XPartnerPrefab