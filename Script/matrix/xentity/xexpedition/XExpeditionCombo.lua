-- 虚像地平线组合对象
local XExpeditionCombo = XClass(nil, "XExpeditionCombo")
local FunctionName = {
    [1] = "MemberNum", -- 检查合计数量
    [2] = "TotalRank",  -- 检查合计等级
    [3] = "TargetRank", -- 高于指定等级
    [4] = "MemberNumAndTotalRank", -- 检查合计数量且检查合计等级
}
local ComboLevel = {
    [1] = "Ⅰ",
    [2] = "Ⅱ",
    [3] = "Ⅲ",
    [4] = "Ⅳ",
}

local SortByIdFunc = function(a, b)
    return a.Id < b.Id
end

local SortByBaseIdFunc = function(a, b)
    return a.EChara:GetBaseId() <= b.EChara:GetBaseId()
end

local SortByLevelFunc = function(a, b)
    return a.EChara:GetRank() < b.EChara:GetRank()
end

local SortByLevelAndBaseIdFunc = function(a, b)
    if a.IsBlank then return false end
    if b.IsBlank then return true end
    if not a.IsActive and b.IsActive then return false end
    if not b.IsActive and a.IsActive then return true end
    local rankA = a.EChara:GetRank()
    local rankB = b.EChara:GetRank()
    if rankA ~= rankB then
        return rankA < rankB
    else
        return a.EChara:GetBaseId() < b.EChara:GetBaseId()
    end
end

local SortByBaseIdAndActiveFunc = function(a, b)
    if not a.IsActive and b.IsActive then return true end
    return a.EChara:GetBaseId() < b.EChara:GetBaseId()
end
--================
--构造函数
--================
function XExpeditionCombo:Ctor(comboCfg, team)
    self.Team = team
    self:InitCombo(comboCfg)
    self.Phase = 1
    self.IsActive = false
end
--================
--初始化羁绊
--================
function XExpeditionCombo:InitCombo(comboCfg)
    self.ComboCfg = comboCfg
    local phaseCombo = XExpeditionConfig.GetComboByChildComboId(comboCfg.Id)
    self.PhaseCombo = {}
    for _, phaseCfg in pairs(phaseCombo) do
        table.insert(self.PhaseCombo, phaseCfg)
    end
    table.sort(self.PhaseCombo, SortByIdFunc)
    self.PhaseNum = #self.PhaseCombo
    self.CheckList = {}
    self.CheckListLength = 0
end
--================
--获取羁绊Id
--================
function XExpeditionCombo:GetComboId()
    return self.ComboCfg and self.ComboCfg.Id
end
--================
--获取羁绊名称
--================
function XExpeditionCombo:GetName()
    return self.ComboCfg and self.ComboCfg.Name or "UnNamed"
end
--================
--获取是否预设队伍羁绊
--================
function XExpeditionCombo:GetDefaultTeamId()
    return self.ComboCfg and self.ComboCfg.DefaultTeamId or 0
end
--================
--获取羁绊有效层数
--================
function XExpeditionCombo:GetPhase()
    return self.Phase
end
--================
--获取羁绊阶段详细
--================
function XExpeditionCombo:GetPhaseCombo()
    return self.PhaseCombo
end
--================
--获取预览羁绊是否提升
--================
function XExpeditionCombo:GetPreviewUp()
    return ((not self:GetComboActive()) and self:GetPreviewActive()) or (self.PreviewPhase > self:GetPhase())
end
--================
--获取预览羁绊是否有效
--================
function XExpeditionCombo:GetPreviewActive()
    return self.PreviewActive
end
--================
--获取羁绊是否有效
--================
function XExpeditionCombo:GetComboActive()
    return self.IsActive
end
--================
--获取羁绊总层数
--================
function XExpeditionCombo:GetPhaseNum()
    return self.PhaseNum
end
--================
--获取羁绊分类
--================
function XExpeditionCombo:GetComboTypeId()
    return self.ComboCfg and self.ComboCfg.ComboTypeId or 1
end
--================
--获取羁绊现层数展示字符串(格式例子:"1/4") 当满级时显示MAX
--================
function XExpeditionCombo:GetCurrentPhaseStr()
    if self.Phase >= self.PhaseNum then
        return "MAX"
    else
        -- 当前等级的星级
        local totalRank = self:GetTotalRank()
        -- 达到下一等级需要的星级
        local targetRank = self:GetConditionLevel(self.Phase + 1)
        return string.format("%d/%d", totalRank, targetRank)
    end
end
--================
--获取当前等级的星级
--================
function XExpeditionCombo:GetTotalRank()
    local totalRank = 0
    for _, eChara in pairs(self.CheckList) do
        totalRank = totalRank + eChara:GetRank()
    end
    return totalRank
end
--================
--获取羁绊等级
--================
function XExpeditionCombo:GetCurrentPhaseLevelStr()
    return ComboLevel[self.Phase]
end
--================
--获取羁绊图标路径
--================
function XExpeditionCombo:GetIconPath()
    return self.ComboCfg and self.ComboCfg.IconPath
end
--================
--获取组合需求条件数量
--================
function XExpeditionCombo:GetConditionCharaNum()
    return self:GetConditionNum(self:GetPhase())
end
--================
--获取达成的条件数
--================
function XExpeditionCombo:GetReachConditionNum()
    return self.ReachConditionNum or 0
end
--================
--获取达成的条件数展示字符串(格式例子:"1/4") 
--================
function XExpeditionCombo:GetReachConditionNumStr()
    return string.format("%d/%d", self:GetReachConditionNum(), self:GetConditionCharaNum())
end
--================
--根据阶段获取组合的要求人数
--@param phaseIndex:阶段
--================
function XExpeditionCombo:GetConditionNum(phaseIndex)
    if not self.PhaseCombo[phaseIndex] then return 0 end
    return self.PhaseCombo[phaseIndex].ConditionNum
end
--================
--根据阶段获取组合的要求等级
--@param phaseIndex:阶段
--================
function XExpeditionCombo:GetConditionLevel(phaseIndex)
    if not self.PhaseCombo[phaseIndex] then return 0 end
    return self.PhaseCombo[phaseIndex].ConditionLevel
end
--================
--根据阶段获取阶段效果描述
--@param phaseIndex:阶段
--================
function XExpeditionCombo:GetPhaseComboEffectDes(phaseIndex)
    local des = self.PhaseCombo[phaseIndex] and self.PhaseCombo[phaseIndex].EffectDescription or ""
    des = string.gsub(des, "\\n", "\n")
    return des
end
--================
--根据阶段获取阶段条件描述
--@param phaseIndex:阶段
--================
function XExpeditionCombo:GetPhaseComboConditionDes(phaseIndex)
    return self.PhaseCombo[phaseIndex] and self.PhaseCombo[phaseIndex].ConditionDesc or ""
end
--================
--设置固有成员列表(暂仅对条件3类型)
--@param eBaseId:玩法基础角色ID
--================
function XExpeditionCombo:SetDefaultReferenceCharaList(eBaseId)
    if not self.DefaultReferenceList then self.DefaultReferenceList = {} end
    if not self.DefaultReferenceList[eBaseId] then self.DefaultReferenceList[eBaseId] = true end
end
--================
--获取固有成员列表(暂仅对条件3类型)
--================
function XExpeditionCombo:GetDefaultReferenceCharaList()
    if not self.DefaultReferenceList then return nil end
    self.DefaultReferenceECharList = {}
    local XChara = require("XEntity/XExpedition/XExpeditionCharacter")
    for charaId, _ in pairs(self.DefaultReferenceList) do
        local eChara = self.Team and self.Team:GetCharaByEBaseId(charaId)
        local displayData = {
            EChara = eChara or XChara.New(charaId),
            IsActive = eChara ~= nil,
            IsBlank = false
        }
        table.insert(self.DefaultReferenceECharList, displayData)
    end
    table.sort(self.DefaultReferenceECharList, SortByBaseIdAndActiveFunc)
    return self.DefaultReferenceECharList
end
--================
--新增关联成员
--@param eChara:新增成员
--================
function XExpeditionCombo:AddCheckList(eChara)
    if not self.CheckList[eChara:GetBaseId()] then
        self.CheckListLength = self.CheckListLength + 1
    end
    self.CheckList[eChara:GetBaseId()] = eChara
end
--================
--清空关联成员
--================
function XExpeditionCombo:ResetCheckList()
    self.CheckList = {}
    self.CheckListLength = 0
    self.IsActive = false
    self.Phase = 1
    self.ReachConditionNum = 0
end
--================
--检查组合状态
--================
function XExpeditionCombo:Check()
    self.Phase, self.ReachConditionNum, self.IsActive = self:CheckActiveStatus()
end
--================
--预览组合有效状态，返回状态结果
--@param eChara:玩法角色
--================
function XExpeditionCombo:PreviewCheckNew(eChara)
    local preList = XTool.Clone(self.CheckList)
    if preList[eChara:GetBaseId()] then
        preList[eChara:GetBaseId()]:RankUp(eChara:GetRank())
    else
        preList[eChara:GetBaseId()] = eChara
    end
    local phase, num, result = self:CheckActiveStatus(preList)
    self.PrePhaseUp = phase > self:GetPhase() -- 是否升级
    self.PreActive = result -- 是否激活
end
--================
--获取预览组合是否升级
--================
function XExpeditionCombo:GetPrePhaseUp()
    return self.PrePhaseUp
end
--================
--获取预览组合的激活状态
--================
function XExpeditionCombo:GetPreActive()
    return self.PreActive
end
--================
--获取预览组合是否变成激活
--================
function XExpeditionCombo:GetIsWillActive()
    return (not self:GetComboActive()) and self:GetPreActive()
end
--================
--检查组合有效状态，返回状态结果
--@return phase:有效层数
--@return reachConditionNum:达到下一层有效的关联角色数
--================
function XExpeditionCombo:CheckActiveStatus(tempList)
    local phase = 1
    local reachConditionNum = 0
    local isActive = false
    local defaultActive = self:CheckDefaultTeamCombo()
    local conditionPass
    for index = 1, self:GetPhaseNum() do
        local functionName = FunctionName[self.ComboCfg.Condition]
        conditionPass, reachConditionNum = self["Condition" .. functionName](self, index, tempList)
        if conditionPass and defaultActive then
            isActive = true
            phase = index
        else
            break
        end
    end    
    return phase, reachConditionNum, isActive
end
--================
--检查是否通过预设技能条件（不是预设技能返回true，预设技能则比对当前预设队伍是否匹配）
--若队伍是非玩家队伍，则检查队伍本身的预设队伍ID
--================
function XExpeditionCombo:CheckDefaultTeamCombo()
    local defaultId = self:GetDefaultTeamId()
    if defaultId == 0 then return true end
    if self.Team:CheckIsPlayer() then
        return self.Team:CheckOtherPlayerDefaultTeam(self:GetDefaultTeamId())
    end
    return XDataCenter.ExpeditionManager.CheckDefaultTeam(defaultId)
end
--================
--检查是否是预设技能
--================
function XExpeditionCombo:CheckIsDefaultCombo()
    return self:GetDefaultTeamId() > 0
end
--================
--检查列表角色的个数
--@param index:层数
--@param tempList:临时检查列表，省略则表示检查玩家现有队伍
--================
function XExpeditionCombo:ConditionMemberNum(index, tempList)
    return self.CheckListLength >= self:GetConditionNum(index), self.CheckListLength
end
--================
--检查列表角色的总等级
--@param index:层数
--@param tempList:临时检查列表，省略则表示检查玩家现有队伍
--================
function XExpeditionCombo:ConditionTotalRank(index, tempList)
    local checkList = tempList or self.CheckList
    local totalRank = 0
    for _, eChara in pairs(checkList) do
        totalRank = totalRank + eChara:GetRank()
    end
    return totalRank >= self:GetConditionLevel(index), self.CheckListLength
end
--================
--检查列表角色各自的级数
--@param index:层数
--@param tempList:临时检查列表，省略则表示检查玩家现有队伍
--================
function XExpeditionCombo:ConditionTargetRank(index, tempList)
    local checkList = tempList or self.CheckList
    local count = 0
    for _, eChara in pairs(checkList) do
        if eChara:GetRank() >= self:GetConditionLevel(index) then
            count = count + 1
        end
    end
    return count >= self:GetConditionNum(index), count
end
--================
--检查列表角色的个数和列表角色的总等级
--@param index:层数
--@param tempList:临时检查列表，省略则表示检查玩家现有队伍
--================
function XExpeditionCombo:ConditionMemberNumAndTotalRank(index, tempList)
    local isMemberNum = self:ConditionMemberNum(index, tempList)
    if not isMemberNum then
        return false, self.CheckListLength
    end
    return self:ConditionTotalRank(index, tempList)
end
--================
--获取成员展示界面
--================
function XExpeditionCombo:GetDisplayReferenceList()
    if self.DefaultReferenceList then return self:GetDefaultReferenceCharaList() end
    local functionName = FunctionName[self.ComboCfg.Condition]
    local list = self["DisplayReference" .. functionName](self, self:GetPhase())
    return list
end
--================
--获取成员组合页面成员展示列表
--================
function XExpeditionCombo:DisplayReferenceMemberNum()
    local tempList = {}
    local count = 0
    for _, v in pairs(self.CheckList) do
        if count > self:GetConditionNum(self:GetPhase()) then break end
        local displayData = {
            EChara = v,
            IsActive = true,
            IsBlank = false
        }
        table.insert(tempList, displayData)
        count = count + 1
    end
    table.sort(tempList, SortByBaseIdFunc)
    return tempList
end
--================
--获取成员展示界面
--================
function XExpeditionCombo:DisplayReferenceTotalRank()
    local tempList = {}
    local tempRank = 0
    local targetRank = self:GetConditionLevel(self:GetPhase())
    for _, v in pairs(self.CheckList) do
        tempRank = tempRank + v:GetRank()
        local displayData = {
            EChara = v,
            IsActive = true,
            IsBlank = false
        }
        table.insert(tempList, displayData)
        if tempRank >= targetRank then break end
    end
    table.sort(tempList, SortByLevelFunc)
    return tempList
end
--================
--获取成员展示界面
--================
function XExpeditionCombo:DisplayReferenceTargetRank()
    local tempList = {}
    local targetRank = self:GetConditionLevel(self:GetPhase())
    for _, v in pairs(self.CheckList) do
        if v:GetRank() >= targetRank then
            local displayData = {
                EChara = v,
                IsActive = true,
                IsBlank = false
            }
            table.insert(tempList, displayData)
        else
            local displayData = {
                EChara = v,
                IsActive = false,
                IsBlank = false
            }
            table.insert(tempList, displayData)
        end
    end
    for i = #tempList + 1, self:GetConditionCharaNum() do
        local displayData = {
            IsActive = false,
            IsBlank = true
        }
        table.insert(tempList, displayData)
    end
    table.sort(tempList, SortByLevelAndBaseIdFunc)
    return tempList
end
--================
--获取成员展示界面
--================
function XExpeditionCombo:DisplayReferenceMemberNumAndTotalRank() 
    local tempList = {}
    for _, v in pairs(self.CheckList) do
        local displayData = {
            EChara = v,
            IsActive = true,
            IsBlank = false
        }
        table.insert(tempList, displayData)
    end
    for i = #tempList + 1, self:GetConditionCharaNum() do
        local displayData = {
            IsActive = false,
            IsBlank = true
        }
        table.insert(tempList, displayData)
    end
    table.sort(tempList, SortByLevelAndBaseIdFunc)
    return tempList
end
return XExpeditionCombo