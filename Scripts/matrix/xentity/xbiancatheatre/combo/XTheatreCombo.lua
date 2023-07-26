-- 肉鸽二期羁绊对象
local XTheatreCombo = XClass(nil, "XTheatreCombo")
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
    return a.EChara:GetLevel() < b.EChara:GetLevel()
end

local SortByLevelAndBaseIdFunc = function(a, b)
    if a.IsBlank then return false end
    if b.IsBlank then return true end
    if not a.IsActive and b.IsActive then return false end
    if not b.IsActive and a.IsActive then return true end
    local rankA = a.EChara:GetLevel()
    local rankB = b.EChara:GetLevel()
    if rankA ~= rankB then
        return rankA < rankB
    else
        return a.EChara:GetBaseId() < b.EChara:GetBaseId()
    end
end

local SortByBaseIdAndActiveFunc = function(a, b)
    if a.IsActive ~= b.IsActive then
        return a.IsActive
    end
    return a.EChara:GetBaseId() < b.EChara:GetBaseId()
end
--================
--构造函数
--@param childComboCfg: BiancaTheatreChildCombo表
--================
function XTheatreCombo:Ctor(childComboCfg, team)
    self.Team = team
    self:InitCombo(childComboCfg)
    self.Phase = 1
    self.IsActive = false
end
--================
--初始化羁绊
--================
function XTheatreCombo:InitCombo(childComboCfg)
    self.ComboCfg = childComboCfg
    local phaseCombo = XBiancaTheatreConfigs.GetComboByChildComboId(childComboCfg.Id)
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
function XTheatreCombo:GetComboId()
    return self.ComboCfg and self.ComboCfg.Id
end
--================
--获取羁绊名称
--================
function XTheatreCombo:GetName()
    return self.ComboCfg and self.ComboCfg.Name or "UnNamed"
end
--================
--获取羁绊有效层数
--================
function XTheatreCombo:GetPhase()
    return self.Phase
end
--================
--获取羁绊阶段详细
--================
function XTheatreCombo:GetPhaseCombo()
    return self.PhaseCombo
end
--================
--获取羁绊品质颜色
--================
function XTheatreCombo:GetQualityColor(isNextLevel)
    local phaseLevel = self:GetPhaseLevel(isNextLevel)
    local qualityColor = self.PhaseCombo[phaseLevel] and
            XBiancaTheatreConfigs.GetClientConfig("QualityTextColor", self.PhaseCombo[phaseLevel].Quality) or
            XBiancaTheatreConfigs.GetClientConfig("NotActiveQualityColor")
    if qualityColor then
        return XUiHelper.Hexcolor2Color(qualityColor)
    end
end

--==============================
 ---@desc 羁绊阶段
 ---@return number
--==============================
function XTheatreCombo:GetPhaseLevel(isNextLevel)
    local totalRank = self:GetTotalRank()
    totalRank = isNextLevel and totalRank + 1 or totalRank
    local level = 0
    for index, cfg in ipairs(self.PhaseCombo or {}) do
        local isDecayCombo = self:GetPhaseComboEffectIsDecay(index)
        if totalRank >= cfg.ConditionLevel and (not isDecayCombo or (isDecayCombo and self:GetDisplayReferenceListIsHaveDecay())) then
            level = level + 1
        end
    end
    return math.min(level, self.PhaseNum)
end
--================
--获取预览羁绊是否提升
--================
--function XTheatreCombo:GetPreviewUp()
--    return ((not self:GetComboActive()) and self:GetPreviewActive()) or (self.PreviewPhase > self:GetPhase())
--end
--================
--获取预览羁绊是否有效
--================
--function XTheatreCombo:GetPreviewActive()
--    return self.PreviewActive
--end
--================
--获取羁绊是否有效
--================
function XTheatreCombo:GetComboActive()
    local totalRank = self:GetTotalRank()
    return totalRank >= self:GetConditionLevel(1)
end
--================
--获取羁绊总层数
--================
function XTheatreCombo:GetPhaseNum()
    return self.PhaseNum
end
--================
--获取羁绊分类
--================
function XTheatreCombo:GetComboTypeId()
    return self.ComboCfg and self.ComboCfg.ComboTypeId or 1
end
--================
--获取羁绊现层数展示字符串(格式例子:"1/4") 当满级时显示MAX
--================
function XTheatreCombo:GetCurrentPhaseStr()
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
--获取羁绊当前的星级
--================
function XTheatreCombo:GetTotalRank(adventureRoles)
    local totalRank = 0
    local curAdventureRoles = adventureRoles or XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentRoles()
    for _, eChara in pairs(curAdventureRoles) do
        if eChara:IsCombo(self:GetComboId()) then
            totalRank = totalRank + eChara:GetLevel()
        end
    end
    return totalRank
end
--================
--获取羁绊等级
--================
function XTheatreCombo:GetCurrentPhaseLevelStr()
    return ComboLevel[self.Phase]
end
--================
--获取羁绊图标路径
--================
function XTheatreCombo:GetIconPath()
    return self.ComboCfg and self.ComboCfg.IconPath
end
--================
--获取组合需求条件数量
--================
function XTheatreCombo:GetConditionCharaNum()
    return self:GetConditionNum(self:GetPhase())
end
--================
--获取达成的条件数
--================
function XTheatreCombo:GetReachConditionNum()
    return self.ReachConditionNum or 0
end
--================
--获取达成的条件数展示字符串(格式例子:"1/4") 
--================
function XTheatreCombo:GetReachConditionNumStr()
    return string.format("%d/%d", self:GetReachConditionNum(), self:GetConditionCharaNum())
end
--================
--根据阶段获取组合的要求人数
--@param phaseIndex:阶段
--================
function XTheatreCombo:GetConditionNum(phaseIndex)
    if not self.PhaseCombo[phaseIndex] then return 0 end
    return self.PhaseCombo[phaseIndex].ConditionNum
end
--================
--根据阶段获取组合的要求等级
--@param phaseIndex:阶段
--================
function XTheatreCombo:GetConditionLevel(phaseIndex)
    if not self.PhaseCombo[phaseIndex] then return 0 end
    return self.PhaseCombo[phaseIndex].ConditionLevel
end
--================
--根据阶段获取阶段效果描述
--@param phaseIndex:阶段
--================
function XTheatreCombo:GetPhaseComboEffectDes(phaseIndex)
    local des = self.PhaseCombo[phaseIndex] and self.PhaseCombo[phaseIndex].EffectDescription or ""
    des = string.gsub(des, "\\n", "\n")
    return des
end
--================
--根据是否为腐化阶段效果
--@param phaseIndex:阶段
--================
function XTheatreCombo:GetPhaseComboEffectIsDecay(phaseIndex)
    local isDecay = self.PhaseCombo[phaseIndex] and self.PhaseCombo[phaseIndex].IsDecay or 0
    return XTool.IsNumberValid(isDecay)
end
--================
--根据是否有腐化阶段效果
--@param phaseIndex:阶段
--================
function XTheatreCombo:GetComboIsHaveDecay()
    for _, Combo in ipairs(self.PhaseCombo) do
        if XTool.IsNumberValid(Combo.IsDecay) then
            return true
        end
    end
    return false
end
--================
--根据阶段获取阶段条件描述
--@param phaseIndex:阶段
--================
function XTheatreCombo:GetPhaseComboConditionDes(phaseIndex)
    return self.PhaseCombo[phaseIndex] and self.PhaseCombo[phaseIndex].ConditionDesc or ""
end
--================
--设置固有成员列表(暂仅对条件3类型)
--@param eBaseId:玩法基础角色ID(BiancaTheatreBaseCharacter表的CharacterId)
--================
function XTheatreCombo:SetDefaultReferenceCharaList(eBaseId)
    if not self.DefaultReferenceList then self.DefaultReferenceList = {} end
    if not self.DefaultReferenceList[eBaseId] then self.DefaultReferenceList[eBaseId] = true end
end
--================
--获取固有成员列表(暂仅对条件3类型)
--================
function XTheatreCombo:GetDefaultReferenceCharaList(isShowDisplay)
    if not self.DefaultReferenceList then return {} end
    self.DefaultReferenceECharList = {}
    local XChara = require("XEntity/XBiancaTheatre/Adventure/XAdventureRole")
    for charaId in pairs(self.DefaultReferenceList) do
        local curRecruitRole = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetRoleByCharacterId(charaId)
        local eChara = not isShowDisplay and curRecruitRole or XChara.New(charaId)
        local displayData = {
            EChara = eChara,
            IsActive = isShowDisplay or curRecruitRole ~= nil,
            IsBlank = false
        }
        table.insert(self.DefaultReferenceECharList, displayData)
    end
    table.sort(self.DefaultReferenceECharList, SortByBaseIdAndActiveFunc)
    return self.DefaultReferenceECharList
end
--================
--新增关联成员
--@param eChara:新增成员(XAdventureRole)
--================
function XTheatreCombo:AddCheckList(eChara)
    if not self.CheckList[eChara:GetBaseId()] then
        self.CheckListLength = self.CheckListLength + 1
    end
    self.CheckList[eChara:GetBaseId()] = eChara
end
--================
--清空关联成员
--================
function XTheatreCombo:ResetCheckList()
    self.CheckList = {}
    self.CheckListLength = 0
    self.IsActive = false
    self.ReachConditionNum = 0
end
--================
--检查组合状态
--================
function XTheatreCombo:Check()
    self.Phase, self.ReachConditionNum, self.IsActive = self:CheckActiveStatus()
end
--================
--预览组合有效状态，返回状态结果
--@param eChara:玩法角色
--================
function XTheatreCombo:PreviewCheckNew(eChara)
    local preList = XTool.Clone(self.CheckList)
    if preList[eChara:GetBaseId()] then
        preList[eChara:GetBaseId()]:RankUp(eChara:GetLevel())
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
function XTheatreCombo:GetPrePhaseUp()
    return self.PrePhaseUp
end
--================
--获取预览组合的激活状态
--================
function XTheatreCombo:GetPreActive()
    return self.PreActive
end
--================
--获取预览组合是否变成激活
--================
function XTheatreCombo:GetIsWillActive()
    return (not self:GetComboActive()) and self:GetPreActive()
end
--================
--检查组合有效状态，返回状态结果
--@return phase:有效层数
--@return reachConditionNum:达到下一层有效的关联角色数
--================
function XTheatreCombo:CheckActiveStatus(tempList)
    local phase = 1
    local reachConditionNum = 0
    local isActive = false
    local conditionPass
    for index = 1, self:GetPhaseNum() do
        local functionName = FunctionName[self.ComboCfg.ActivationType]
        conditionPass, reachConditionNum = self["Condition" .. functionName](self, index, tempList)
        if conditionPass then
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
function XTheatreCombo:CheckDefaultTeamCombo()
    --local defaultId = self:GetDefaultTeamId()
    --if defaultId == 0 then return true end
    --if self.Team:CheckIsPlayer() then
    --    return self.Team:CheckOtherPlayerDefaultTeam(self:GetDefaultTeamId())
    --end
    --return XDataCenter.ExpeditionManager.CheckDefaultTeam(defaultId)
end
--================
--检查列表角色的个数
--@param index:层数
--@param tempList:临时检查列表，省略则表示检查玩家现有队伍
--================
function XTheatreCombo:ConditionMemberNum(index, tempList)
    return self.CheckListLength >= self:GetConditionNum(index), self.CheckListLength
end
--================
--检查列表角色的总等级
--@param index:层数
--@param tempList:临时检查列表，省略则表示检查玩家现有队伍
--================
function XTheatreCombo:ConditionTotalRank(index, tempList)
    local checkList = tempList or self.CheckList
    local totalRank = 0
    for _, eChara in pairs(checkList) do
        totalRank = totalRank + eChara:GetLevel()
    end
    return totalRank >= self:GetConditionLevel(index), self.CheckListLength
end
--================
--检查列表角色各自的级数
--@param index:层数
--@param tempList:临时检查列表，省略则表示检查玩家现有队伍
--================
function XTheatreCombo:ConditionTargetRank(index, tempList)
    local checkList = tempList or self.CheckList
    local count = 0
    for _, eChara in pairs(checkList) do
        if eChara:GetLevel() >= self:GetConditionLevel(index) then
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
function XTheatreCombo:ConditionMemberNumAndTotalRank(index, tempList)
    local isMemberNum = self:ConditionMemberNum(index, tempList)
    if not isMemberNum then
        return false, self.CheckListLength
    end
    return self:ConditionTotalRank(index, tempList)
end
--================
--获取成员展示界面
--@param isShowDisplay:是否展示羁绊图鉴列表（不判断是否有角色）
--================
function XTheatreCombo:GetDisplayReferenceList(isShowDisplay)
    if self.DefaultReferenceList then 
        return self:GetDefaultReferenceCharaList(isShowDisplay)
    end
end
--================
--获取成员展示列表有没有腐化的成员
--================
function XTheatreCombo:GetDisplayReferenceListIsHaveDecay()
    if self.DefaultReferenceList then
        for charId, _ in pairs(self.DefaultReferenceList) do
            local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
            local curRecruitRole = adventureManager:CheckRoleIsDecayByCharacterId(charId)
            if curRecruitRole then
                return true
            end
        end
    end
    return false
end
--================
--获取成员组合页面成员展示列表
--================
function XTheatreCombo:DisplayReferenceMemberNum()
    local tempList = {}
    local count = 0
    for _, v in pairs(self.CheckList) do
        --if count > self:GetConditionNum(self:GetPhase()) then break end
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
function XTheatreCombo:DisplayReferenceTotalRank()
    local tempList = {}
    local tempRank = 0
    local targetRank = self:GetConditionLevel(self:GetPhase())
    for _, v in pairs(self.CheckList) do
        tempRank = tempRank + v:GetLevel()
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
function XTheatreCombo:DisplayReferenceTargetRank()
    local tempList = {}
    local targetRank = self:GetConditionLevel(self:GetPhase())
    for _, v in pairs(self.CheckList) do
        if v:GetLevel() >= targetRank then
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
function XTheatreCombo:DisplayReferenceMemberNumAndTotalRank() 
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

function XTheatreCombo:GetDefaultTeamId()
    return 0
end
return XTheatreCombo