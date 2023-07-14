--[[
stageData = XPivotCombatStageData
class XPivotCombatStageData
{
       // 关卡数据
       public int StageId;
       // 关卡历史最高积分(中心区域关卡 > 0, 次级区域关卡 = 0)
       public int Score;
       // 历史最高评分等级
       public int HightestRatingLevel;
       // 使用的角色信息
       public List<XPivotCombatRankPlayerFightCharacterInfo> CharacterInfoList = new List<XPivotCombatRankPlayerFightCharacterInfo>();
}
]]


local XPivotCombatStageItem = XClass(nil, "XPivotCombatStageItem")

function XPivotCombatStageItem:Ctor(stageId, stageLibId)
    --关卡Id
    self.StageId = stageId
    --关卡库Id
    self.StageLibId = stageLibId
    --历史最高分数
    self.MaxScore = XDataCenter.PivotCombatManager.GetMaxScore()
    --是否通关
    self.Passed = false
    --参战角色字典-方便查找
    self.CharacterDict = {}
    --列表，可能存在0
    self.CharacterIds = {}
    --历史最高评分等级
    self.HightestRatingLevel = 0
    --通关队伍角色信息
    self.CharacterInfoList = {}
end

--===========================================================================
 ---@desc 根据配置表初始化数据
--===========================================================================
function XPivotCombatStageItem:InitData(config)
    --关卡序号
    self.GridIndex = config.GridIndex
    --关卡名
    self.GridName = config.GridName
    --关卡图标
    self.GridIcon = config.GridIcon
    --关卡提供的能源
    self.SupplyEnergyLevelReward = config.SupplyEnergyLevelReward
    --是否积分关
    self.IsScoreStage = config.IsScoreStage
    --是否锁角色关
    self.IsLockCharacterStage = config.IsLockCharacterStage
    --词缀
    self.AffixIds = config.AffixIds
    --环境描述
    self.Tips = config.Tips
    --供能效率
    self.Efficiency = config.Efficiency
end

--===========================================================================
 ---@desc 刷新关卡数据
--===========================================================================
function XPivotCombatStageItem:RefreshStageData(stageData)
    self:SetPassed(true)
    --刷新最高关卡最高分数
    self:RefreshMaxScore(stageData)
    self:RefreshHightestRatingLevel(stageData.HightestRatingLevel)
    local characterInfos = stageData.CharacterInfoList or {}
    self.CharacterInfoList = characterInfos
    self.CharacterIds = {} -- 置空
    if self:CheckIsLockCharacterStage() then
        self:ClearCharacterDict()
    end
    for _, info in ipairs(characterInfos) do
        local id = info.CharacterId
        local characterId = id
        if XRobotManager.CheckIsRobotId(id) then
            characterId = XRobotManager.GetCharacterId(id)
        end
        if XTool.IsNumberValid(id) then
            table.insert(self.CharacterIds, id)
        end
        --key为角色id，一个队伍中不可能存在同一个角色id，value为机器人id或者角色id
        self.CharacterDict[characterId] = id
    end
    if self:CheckIsLockCharacterStage() then
        XDataCenter.PivotCombatManager.RefreshLockCharacterDict(self.CharacterDict)
    end
end

--===========================================================================
 ---@desc 获取关卡格子名
--===========================================================================
function XPivotCombatStageItem:GetGridName()
    return self.GridName
end

--===========================================================================
 ---@desc 关卡格子图标
--===========================================================================
function XPivotCombatStageItem:GetGridIcon()
    return self.GridIcon
end

--===========================================================================
 ---@desc 关卡名
--===========================================================================
function XPivotCombatStageItem:GetStageName()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if stageCfg then
        return stageCfg.Name
    end
    return self:GetGridName()
end

--===========================================================================
 ---@desc 关卡排序
--===========================================================================
function XPivotCombatStageItem:GetIndex()
    return self.GridIndex
end

--===========================================================================
 ---@desc 是否解锁
--===========================================================================
function XPivotCombatStageItem:CheckIsUnlock()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if not stageCfg then
        return false
    end

    for _,preStageId in ipairs(stageCfg.PreStageId or {}) do
        if not XDataCenter.PivotCombatManager.CheckPassedByStageId(preStageId) then
            return false
        end
    end
    return true
end

--===========================================================================
 ---@desc 是否通关
--===========================================================================
function XPivotCombatStageItem:GetPassed()
    return self.Passed
end

--===========================================================================
 ---@desc 设置通关状态
--===========================================================================
function XPivotCombatStageItem:SetPassed(isPass)
    self.Passed = isPass
end

--===========================================================================
 ---@desc 最大分数
--===========================================================================
function XPivotCombatStageItem:GetMaxScore()
    return self.MaxScore
end

--===========================================================================
 ---@desc 刷新关卡最高积分,同步刷新通关时间积分
--===========================================================================
function XPivotCombatStageItem:RefreshMaxScore(stageData)
    local score = stageData.Score
    if score < self.MaxScore then return end
    self.MaxScore = score
    self.FightTimeScore = stageData.FightTimeScore
    XDataCenter.PivotCombatManager.RefreshMaxScore(self.MaxScore, self.FightTimeScore)
end

--===========================================================================
 ---@desc 历史最高评级
--===========================================================================
function XPivotCombatStageItem:GetHightestRatingLevel()
    return self.HightestRatingLevel
end

--===========================================================================
 ---@desc 刷新历史最高评级
--===========================================================================
function XPivotCombatStageItem:RefreshHightestRatingLevel(level)
    if level < self.HightestRatingLevel then return end
    self.HightestRatingLevel = level
    XDataCenter.PivotCombatManager.RefreshHightestRankingLevel(level)
end

--===========================================================================
 ---@desc 通过可提供的能量
--===========================================================================
function XPivotCombatStageItem:GetSupplyEnergyLevel()
    return self.SupplyEnergyLevelReward
end

--===========================================================================
 ---@desc 进入战备界面
--===========================================================================
function XPivotCombatStageItem:EnterBattleRoleRoom(regionId)
    XLuaUiManager.Open("UiBattleRoleRoom"
    , self.StageId
    , XDataCenter.PivotCombatManager.GetTeam(regionId)
    , require("XUi/XUiPivotCombat/XUiProxy/XUiPivotCombatBattleRoleRoom")
    )
end

--===========================================================================
 ---@desc 关卡Id
--===========================================================================
function XPivotCombatStageItem:GetStageId()
    return self.StageId
end

--===========================================================================
 ---@desc 获取字段描述
--===========================================================================
function XPivotCombatStageItem:GetAffixes()
    local affixes = {}
    for idx, eventId in ipairs(self.AffixIds or {}) do
        affixes[idx] = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)
    end
    return affixes
end

--===========================================================================
 ---@desc 获取环境描述
--===========================================================================
function XPivotCombatStageItem:GetTips()
    return self.Tips
end

--===========================================================================
 ---@desc 供能效率
--===========================================================================
function XPivotCombatStageItem:GetEfficiency()
    return self.Efficiency
end

--===========================================================================
 ---@desc 获取参战角色字典
--===========================================================================
function XPivotCombatStageItem:GetCharacterDict()
    return self.CharacterDict
end

--===========================================================================
 ---@desc 获取参战角色列表
--===========================================================================
function XPivotCombatStageItem:GetCharacterList()
    return self.CharacterIds
end

--===========================================================================
 ---@desc 清除通关队伍角色字典
--===========================================================================
function XPivotCombatStageItem:ClearCharacterDict()
    XDataCenter.PivotCombatManager.RemoveLockCharacterDict(self.CharacterDict)
    self.CharacterDict = {}
    self.CharacterIds = {}
end

--===========================================================================
 ---@desc 检查是否是积分关
--===========================================================================
function XPivotCombatStageItem:CheckIsScoreStage()
    return self.IsScoreStage
end

--===========================================================================
 ---@desc 检测是否是锁角色关卡
--===========================================================================
function XPivotCombatStageItem:CheckIsLockCharacterStage()
    return self.IsLockCharacterStage
end

--===========================================================================
 ---@desc 取消锁角色设定
--===========================================================================
function XPivotCombatStageItem:CancelLockCharacter()
    self.Passed = false
    self.Score = 0
    self:ClearCharacterDict()
end

--===========================================================================
 ---@desc 获取通关角色信息
--===========================================================================
function XPivotCombatStageItem:GetCharacterInfoList()
    return self.CharacterInfoList
end


return XPivotCombatStageItem