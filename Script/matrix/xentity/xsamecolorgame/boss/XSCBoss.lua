local XSCBossSkill = require("XEntity/XSameColorGame/Skill/XSCBossSkill")
local XSCBoss = XClass(nil, "XSCBoss")

function XSCBoss:Ctor(id)
    self.Config = XSameColorGameConfigs.GetBossConfig(id)
    self.MaxScore = 0
    self.MaxCombo = 0
    -- 该boss最后挑战的角色id
    self.LastRoleId = 0
    -- self.LastRoleSkillIds = {}
    self.ShowDic = {}
    self.AllSkillList = {}
    self.Id = id
    self:CreateAllSkillList()
    self:LoadLocalData()
end

function XSCBoss:GetLocalSaveKey()
    -- v1.31 三期要求选择角色后每个boss统一角色
    return XDataCenter.SameColorActivityManager.GetLocalSaveKey() .. "Boss"--self.Config.Id
end

function XSCBoss:LoadLocalData()
    local initData = XSaveTool.GetData(self:GetLocalSaveKey())
    if not initData then return end
    for key, value in pairs(initData) do
        self[key] = value
    end
end

function XSCBoss:SaveLocalData()
    XSaveTool.SaveData(self:GetLocalSaveKey(), {
        LastRoleId = self.LastRoleId
    })
end

function XSCBoss:InitWithServerData(data)
    self.MaxScore = data.MaxPoint
    self.MaxCombo = data.MaxCombo or 0
    -- self.LastRoleId = data.LastRoleId or 0
    -- self.LastRoleSkillIds = data.LastRoleSkillId or {}
end

function XSCBoss:UpdateMaxScore(value)
    self.MaxScore = math.max(value or 0, self.MaxScore)
end

function XSCBoss:UpdateMaxCombo(value)
    self.MaxCombo = math.max(value or 0, self.MaxCombo)
end

function XSCBoss:GetId()
    return self.Config.Id
end

function XSCBoss:GetLastRoleId()
    -- v1.31 三期要求选择角色后每个boss统一角色
    self:LoadLocalData()
    return self.LastRoleId
end

function XSCBoss:SetLastRoleId(value)
    self.LastRoleId = value
    self:SaveLocalData()
end

function XSCBoss:GetName()
    return self.Config.Name
end

-- 获取boss行动点数
function XSCBoss:GetMaxRound()
    return self.Config.MaxRound
end

-- 是否回合类型
function XSCBoss:IsRoundType()
    return self.Config.MaxRound ~= 0
end

-- 获取boss行动时间
function XSCBoss:GetMaxTime()
    return self.Config.MaxTime
end

-- 是否时间类型
function XSCBoss:IsTimeType()
    return self.Config.MaxTime ~= 0
end

-- 获取boss全身像图标
function XSCBoss:GetFullBodyIcon()
    return self.Config.FullBodyIcon
end

function XSCBoss:GetModelId()
    return self.Config.ModelId
end

function XSCBoss:GetBattleModelId()
    return self.Config.BattleModelId
end

function XSCBoss:GetNameIcon()
    return self.Config.NameIcon
end

-- 获取最高记录分数
function XSCBoss:GetMaxScore()
    return self.MaxScore
end

-- 获取最高记录combo数
function XSCBoss:GetMaxCombo()
    return self.MaxCombo
end

-- 获取分数评级字典
function XSCBoss:GetBossGradeDic()
    return XSameColorGameConfigs.GetBossGradeDic(self.Config.Id)
end

-- 获取分数评级
function XSCBoss:GetScoreGradeName(score)
    return XSameColorGameConfigs.GetBossGradeName(self.Config.Id, score)
end

-- 获取分数评级序号
function XSCBoss:GetScoreGradeIndex(score)
    return XSameColorGameConfigs.GetBossGradeIndex(self.Config.Id, score)
end

-- 获取分数下一评级以及分差
function XSCBoss:GetScoreNextGradeNameAndDamageGap(score)
    return XSameColorGameConfigs.GetScoreNextGradeNameAndDamageGap(self.Config.Id, score)
end

-- 获取历史最高评级图标
function XSCBoss:GetMaxGradeIcon()
    return XSameColorGameConfigs.GetActivityConfigValue(string.format("GradeIcon%s", self:GetScoreGradeName(self.MaxScore)))[1]
end

-- 获取当前分数评级图标
function XSCBoss:GetCurGradeIcon(score)
    return XSameColorGameConfigs.GetActivityConfigValue(string.format("GradeIcon%s", self:GetScoreGradeName(score)))[1]
end

function XSCBoss:GetIsOpen()
    if XDataCenter.SameColorActivityManager.DEBUG then
        return true
    end
    if not self:GetIsInTime() then
        return false, self:GetOpenTimeStr()
    end

    if self.Config.PreBossId ~= 0 then
        local bossManager = XDataCenter.SameColorActivityManager.GetBossManager()
        local boss = bossManager:GetBoss(self.Config.PreBossId)
        if not boss:IsPass() then
            return false, self.Config.PreBossUnlockTips
        end 
    end
    return self:CheckCondition()
end

-- 获取boss是否在开启时间内
function XSCBoss:GetIsInTime()
    return XFunctionManager.CheckInTimeByTimeId(self.Config.TimerId)
end

function XSCBoss:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self.Config.TimerId)
end

function XSCBoss:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self.Config.TimerId)
end

-- 获取boss开启时间描述
function XSCBoss:GetOpenTimeStr()
    local timeStr = XUiHelper.GetTime(self:GetStartTime() - XTime.GetServerNowTimestamp()
    , XUiHelper.TimeFormatType.ACTIVITY)
    return XUiHelper.GetText("SCBossOpenTimeTips", timeStr)
end

-- 检查是否符合开放条件
function XSCBoss:CheckCondition()
    if self.Config.ConditionId <= 0 then
        return true
    end
    return XConditionManager.CheckCondition(self.Config.ConditionId, self.Config.Id)
end

-- 检查角色id是否为推荐角色
function XSCBoss:CheckRoleIdIsSuggest(roleId)
    for _, value in ipairs(self.Config.SuggestRoleIds) do
        if tonumber(value) == roleId then
            return true
        end
    end
    return false
end

function XSCBoss:GetShowSkills()
    local result = {}
    for _, skillId in ipairs(self.Config.ShowSkillIds) do
        table.insert(result, self:GetSkill(skillId))
    end
    return result
end

function XSCBoss:GetSkill(id)
    local result = self.ShowDic[id]
    if not result then
        result = XSCBossSkill.New(id)
        self.ShowDic[id] = result
    end
    return result
end

function XSCBoss:GetSkillByRound(round)
    for _, skill in pairs(self.AllSkillList) do
        if skill:GetTriggerRound() > round then
            return skill
        end
    end
    return nil
end

function XSCBoss:CreateAllSkillList()
    self.AllSkillList = {}
    local skillConfigDic = XSameColorGameConfigs.GetBossSkillConfigDic()
    for _, cfg in pairs(skillConfigDic) do
        if cfg.BossId == self:GetId() then
            table.insert(self.AllSkillList, self:GetSkill(cfg.Id))
        end
    end
    table.sort(self.AllSkillList,function (a, b)
        return a:GetTriggerRound() < b:GetTriggerRound()
    end)
end

function XSCBoss:IsPass()
    return self.MaxScore ~= 0
end

-- function XSCBoss:GetSkillManager()
--     if self.SkillManager == nil then
--         self.SkillManager = XSCSkillManager.New()
--     end
--     return self.SkillManager
-- end

return XSCBoss