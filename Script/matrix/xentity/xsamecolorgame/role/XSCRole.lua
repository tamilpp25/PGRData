local XSCRoleSkill = require("XEntity/XSameColorGame/Skill/XSCRoleSkill")
local XCharacterViewModel = require("XEntity/XCharacter/XCharacterViewModel")
local XSCBall = require("XEntity/XSameColorGame/Battle/XSCBall")
---@class XSCRole
local XSCRole = XClass(nil, "XSCRole")

function XSCRole:Ctor(id)
    self.Id = id
    ---@type XTableSameColorGameRole
    self.Config = XSameColorGameConfigs.GetRoleConfig(id)
    ---@type XCharacterViewModel
    self.CharacterViewModel = nil
    ---@type XSCBall[]
    self.BallDic = {}
    -- 正在使用中的技能
    self.UsingSkillGroupIds = {}
    self.AutoEnergyDic = {}
    self:LoadLocalData()
    self:CreateAutoEnergyDic()
end

function XSCRole:GetId()
    return self.Config.Id
end

function XSCRole:GetModelId()
    return self.Config.ModelId
end

function XSCRole:GetBattleModelId()
    return self.Config.BattleModelId
end

function XSCRole:GetRow()
    return self.Config.Row
end

function XSCRole:GetCol()
    return self.Config.Col
end

function XSCRole:GetMainSkillGroupId()
    return self.Config.SkillId
end

function XSCRole:GetPassiveSkillId()
    return self.Config.PassiveSkillId
end

function XSCRole:GetEnergyInit()
    return self.Config.EnergyInit
end

function XSCRole:GetEnergyLimit()
    return self.Config.EnergyLimit
end

function XSCRole:GetRoundAddEnergyType()
    return self.Config.RoundAddEnergyType
end

function XSCRole:GetRoundAddEnergyCount()
    return self.Config.RoundAddEnergyCount
end

function XSCRole:GetAddEnergyStartRound()
    return self.Config.AddEnergyStartRound
end

function XSCRole:GetNameIcon()
    return self.Config.NameIcon
end

function XSCRole:GetNameEnIcon()
    return self.Config.NameEnIcon
end

function XSCRole:GetAttributeFactorId()
    return self.Config.AttributeFactorId
end

function XSCRole:GetSkillEnergyCost()
    local skill = self:GetMainSkill()
    if skill then
        return skill:GetEnergyCost(skill:GetSkillId())
    end
end

function XSCRole:GetAutoEnergyDic()
    return self.AutoEnergyDic
end

function XSCRole:GetAutoEnergyByRound(round)
    return self.AutoEnergyDic[round]
end

---@return XCharacterViewModel
function XSCRole:GetCharacterViewModel()
    if self.CharacterViewModel == nil then
        self.CharacterViewModel = XCharacterViewModel.New(self.Config.CharacterId)
    end
    return self.CharacterViewModel
end

-- 是否已在解锁时间内
function XSCRole:GetIsInUnlockTime()
    return XFunctionManager.CheckInTimeByTimeId(self.Config.TimerId)
end

function XSCRole:GetIsLock()
    return not self:GetIsInUnlockTime()
end

function XSCRole:GetOpenTimeTipStr()
    local startTime = XFunctionManager.GetStartTimeByTimeId(self.Config.TimerId)
    return XUiHelper.GetTimeYearMonthDay(startTime)
end

function XSCRole:GetOpenTimeStr()
    local startTime = XFunctionManager.GetStartTimeByTimeId(self.Config.TimerId)
    return XUiHelper.GetTime(startTime - XTime.GetServerNowTimestamp()
    , XUiHelper.TimeFormatType.ACTIVITY)
end


-- 获得角色的球的数据
---@return XSCBall[]
function XSCRole:GetBalls()
    local result = {}
    for _, ballId in ipairs(self.Config.BallId) do
        table.insert(result, self:GetBall(ballId))
    end
    return result
end

---@return XSCBall
function XSCRole:GetBall(id)
    local result = self.BallDic[id] 
    if result == nil then
        result = XSCBall.New(id)
        self.BallDic[id] = result
    end
    return result
end

function XSCRole:CreateAutoEnergyDic()
    local roundList = self:GetAddEnergyStartRound()
    for index,round in pairs(roundList) do
        local type = self:GetRoundAddEnergyType()[index]
        local count = self:GetRoundAddEnergyCount()[index]
        if type and count then
            self.AutoEnergyDic[round] = {Type = type,Count = count}
        end
    end
end

-- 装备技能
-- index : 装备技能指定位置，如果传nil，先取空余位置(0)再取尾巴
function XSCRole:AddSkillGroupId(skillGroupId, equipIndex)
    -- 已经有装备，不处理
    if table.contains(self.UsingSkillGroupIds, skillGroupId) then
        return 
    end
    if equipIndex == nil then
        local zeroIndex = table.indexof(self.UsingSkillGroupIds, 0)
        if zeroIndex then 
            equipIndex = zeroIndex 
        else
            equipIndex = #self.UsingSkillGroupIds + 1
        end
    end
    for i = 1, equipIndex - 1 do
        if self.UsingSkillGroupIds[i] == nil then
            self.UsingSkillGroupIds[i] = 0
        end
    end
    self.UsingSkillGroupIds[equipIndex] = skillGroupId
    self:SaveLocalData()
end

function XSCRole:RemoveSkillGroupId(skillGroupId)
    local index = table.indexof(self.UsingSkillGroupIds, skillGroupId)
    -- 找不到直接不处理
    if not index then return end
    self.UsingSkillGroupIds[index] = 0
    -- table.remove(self.UsingSkillGroupIds, index)
    self:SaveLocalData()
end

function XSCRole:SaveLocalData()
    XSaveTool.SaveData(self:GetLocalSaveKey(), {
        UsingSkillGroupIds = self.UsingSkillGroupIds
    })
end

function XSCRole:GetUsingSkillGroupIds(isExcludeZero, isTimeType)
    -- 限时模式下，部分技能禁止使用
    if isTimeType then
        for i, skillGroupId in ipairs(self.UsingSkillGroupIds) do
            if skillGroupId > 0 then
                local skill = XDataCenter.SameColorActivityManager.GetRoleShowSkill(skillGroupId)
                if skill:IsForbidInTime()  then
                    self.UsingSkillGroupIds[i] = 0
                end
            end
        end
    end

    if isExcludeZero == nil then isExcludeZero = false end
    if isExcludeZero then
        local result = {}
        for _, skillGroupId in ipairs(self.UsingSkillGroupIds) do
            if skillGroupId > 0 then
                table.insert(result, skillGroupId)
            end
        end
        return result
    end
    return self.UsingSkillGroupIds
end

function XSCRole:ContainSkillGroupId(id)
    return table.contains(self.UsingSkillGroupIds, id)
end

function XSCRole:LoadLocalData()
    local initData = XSaveTool.GetData(self:GetLocalSaveKey())
    if not initData then return end
    for key, value in pairs(initData) do
        self[key] = value
    end
end

function XSCRole:GetLocalSaveKey()
    return XDataCenter.SameColorActivityManager.GetLocalSaveKey() .."New".. self.Config.Id
end

function XSCRole:GetMainSkill()
    if self.MainSkill == nil then
        self.MainSkill = XSCRoleSkill.New(self:GetMainSkillGroupId())
    end
    return self.MainSkill
end

return XSCRole