
--[[
regionData = XPivotCombatRegionData

class XPivotCombatRegionData 
{
    // 区域id
    int RegionId;
     // 供能等级
    int SupplyEnergyLevel;
    // 通关关卡数据列表
    List<XPivotCombatStageData> StageDataList = new List<XPivotCombatStageData>();
}

class XPivotCombatStageData
{
       // 关卡数据
       public int StageId;
       // 关卡历史最高积分(中心区域关卡 > 0, 次级区域关卡 = 0)
       public int Score;
       // 参战角色列表
       public List<int> CharacterIds = new List<int>();
}
]]



local XPivotCombatRegionItem = XClass(nil, "XPivotCombatRegionItem")
local XPivotCombatStageItem = require("XEntity/XPivotCombat/XPivotCombatStageItem")

function XPivotCombatRegionItem:Ctor(regionId)
    self.RegionId = regionId
end 

--===========================================================================
 ---@desc 根据配置表初始化数据
--===========================================================================
function XPivotCombatRegionItem:InitData(regionConfig)
    --最大可提供能源
    self.MaxSupplyEnergy = 0
    --当前提供的能源
    self.CurSupplyEnergy = 0
    --小图标路径
    self.SmallIcon = regionConfig.SmallIcon
    --特效库id
    self.EffectLibId = regionConfig.EffectLibId
    --关卡库Id
    self.StageLibId = regionConfig.StageLibId
    --名称
    self.RegionName = regionConfig.RegionName
    --开放时间
    self.OpenTime = regionConfig.OpenTime
    --区域难度
    self.Difficulty = regionConfig.Difficulty
    --任务组
    self.TaskGroupId = regionConfig.TaskGroupId
    --区域下标
    self.SecondaryRegionIndex = regionConfig.SecondaryRegionIndex
    --区域背景
    self.SecondaryRegionBackground = regionConfig.SecondaryRegionBackground
    --区域开放能量限制
    self.TotalSupplyEnergyLevelLimit = regionConfig.TotalSupplyEnergyLevelLimit
    --当前区域下的关卡
    self.StageDict = {}
    
    self:InitStageDict()
end

--===========================================================================
 ---@desc 初始化该区域下的关卡配置
--===========================================================================
function XPivotCombatRegionItem:InitStageDict()
    --当前区域下的关卡库配置，已经排好序
    local libConfig = XDataCenter.PivotCombatManager.GetStageConfigs(self.StageLibId)
    for _, config in ipairs(libConfig) do
        local stageId = config.StageId
        local item = XPivotCombatStageItem.New(stageId, config.StageLibId)
        item:InitData(config)
        self.StageDict[stageId] = item
        XDataCenter.PivotCombatManager.RefreshStageInfo(stageId, item)
    end

    for _, stage in pairs(self.StageDict) do
        self.MaxSupplyEnergy = self.MaxSupplyEnergy + stage:GetSupplyEnergyLevel()
    end
end

--===========================================================================
 ---@desc 通关后更新区域供能情况
 ---@param {regionData}  class XPivotCombatRegionData
--===========================================================================
function XPivotCombatRegionItem:RefreshRegionData(regionData)
    --当前提供的能源
    self.CurSupplyEnergy = regionData.SupplyEnergyLevel
    local stageDataList = regionData.StageDataList
    for _, stageData in ipairs(stageDataList or {}) do
        local stageId = stageData.StageId
        local item = self.StageDict[stageId]
        if item then
            item:RefreshStageData(stageData)
            XDataCenter.PivotCombatManager.RefreshStageInfo(stageId, item)
        else
            XLog.Error("Can`t Found the Stage Where StageId = ", stageId)
        end
    end
end

--===========================================================================
 ---@desc 刷新单个关卡
--===========================================================================
function XPivotCombatRegionItem:RefreshSingleStage(regionData)
    --
    self.CurSupplyEnergy = regionData.SupplyEnergyLevel
    local stageData = regionData.StageData
    local stageId = stageData.StageId
    local stage = self.StageDict[stageId]
    if stage then
        stage:RefreshStageData(stageData)
        XDataCenter.PivotCombatManager.RefreshStageInfo(stageId, stage)
    else
        XLog.Error("Can`t Found the Stage Where StageId = ", stageId)
    end
end

--===========================================================================
 ---@desc 取消角色锁定
--===========================================================================
function XPivotCombatRegionItem:CancelLockCharacter(supplyEnergyLevel, stageId)
    self.CurSupplyEnergy = supplyEnergyLevel
    local stage = self.StageDict[stageId]
    if stage then
        stage:CancelLockCharacter()
        XDataCenter.PivotCombatManager.RefreshStageInfo(stageId, stage)

    else
        XLog.Error("Can`t Found the Stage Where StageId = ", stageId)
    end
end

--===========================================================================
 ---@desc 特效库Id
--===========================================================================
function XPivotCombatRegionItem:GetEffectId()
    return self.EffectLibId or 0
end

--===========================================================================
 ---@desc 区域名
--===========================================================================
function XPivotCombatRegionItem:GetRegionName()
    return self.RegionName
end

--===========================================================================
 ---@desc 获取区域距离开放的时间 : xxx天
--===========================================================================
function XPivotCombatRegionItem:GetRegionOpenTime()
    if not self.OpenTime then
        return ""
    end
    local timeOfNow = XTime.GetServerNowTimestamp()
    --local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(self.OpenTime)
    local timeOfBgn = XDataCenter.PivotCombatManager.GetActivityBeginTime()
    return XUiHelper.GetTime(timeOfBgn + self.OpenTime - timeOfNow, XUiHelper.TimeFormatType.PIVOT_COMBAT)
end

--===========================================================================
 ---@desc 获取区域距离关闭剩下的时间
--===========================================================================
function XPivotCombatRegionItem:GetRegionLeftTime()
    if not self.OpenTime then
        return ""
    end
    local timeOfNow = XTime.GetServerNowTimestamp()
    --local timeOfEnd = XFunctionManager.GetEndTimeByTimeId(self.OpenTime)
    local timeOfEnd = XDataCenter.PivotCombatManager.GetActivityEndTime()
    return XUiHelper.GetTime(timeOfEnd - timeOfNow, XUiHelper.TimeFormatType.PIVOT_COMBAT)
end

--===========================================================================
 ---@desc 区域是否开放，如果未开放，同时返回未开放的描述
--===========================================================================
function XPivotCombatRegionItem:IsOpen()
    --活动未开放
    if not XDataCenter.PivotCombatManager.IsOpen() then
        return false, CSXTextManagerGetText("CommonActivityNotStart")
    end
    
    if not self.OpenTime then
        return false, CSXTextManagerGetText("CommonActivityNotStart")
    end

    --时间是否满足
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfBgn = XDataCenter.PivotCombatManager.GetActivityBeginTime()
    local timeOfEnd = XDataCenter.PivotCombatManager.GetActivityEndTime()

    --区域未开放
    if timeOfNow < timeOfBgn + self.OpenTime then
        return false, CSXTextManagerGetText("ActivityRepeatChallengeChapterLock", self:GetRegionOpenTime())
    end
    --活动已结束
    if timeOfNow > timeOfEnd then
        return false, CSXTextManagerGetText("CommonActivityEnd")
    end
    
    local isEnergyEnough = true
    --该区域开放需供能
    if self.TotalSupplyEnergyLevelLimit > 0 then
        isEnergyEnough = XDataCenter.PivotCombatManager.IsSecondaryEnergySupplyEnough()
    end
    --供能不满足
    if not isEnergyEnough then
        return false, CSXTextManagerGetText("PivotCombatAreaEnergyNotEnough")
    end
    
    return true
end

--===========================================================================
 ---@desc 区域id
--===========================================================================
function XPivotCombatRegionItem:GetRegionId()
    return self.RegionId
end

--===========================================================================
 ---@desc 根据供能需求判断是否是中枢区域
--===========================================================================
function XPivotCombatRegionItem:IsCenterRegion()
    return self.TotalSupplyEnergyLevelLimit > 0
end

--===========================================================================
 ---@desc 关卡库Id
--===========================================================================
function XPivotCombatRegionItem:GetStageLibId()
    return self.StageLibId
end

--===========================================================================
 ---@desc 当前供能
--===========================================================================
function XPivotCombatRegionItem:GetCurSupplyEnergy()
    return self.CurSupplyEnergy
end

--===========================================================================
 ---@desc 最大可提供能源
--===========================================================================
function XPivotCombatRegionItem:GetMaxSupplyEnergy()
    return self.MaxSupplyEnergy
end

--===========================================================================
 ---@desc 获取区域图标
 ---@return {string} 图标路径
--===========================================================================
function XPivotCombatRegionItem:GetIcon()
    return self.SmallIcon
end

--===========================================================================
 ---@desc 获取区域难度
--===========================================================================
function XPivotCombatRegionItem:GetDifficulty()
    return self.Difficulty
end

--===========================================================================
 ---@desc 根据供能等级获取buff描述
 ---@param {level} 供能等级
--===========================================================================
function XPivotCombatRegionItem:GetBuffDesc(level)
    --还未提供能量
    if level <= 0 then
        return CSXTextManagerGetText("PivotCombatAreaEnergyNotActive")
    end
    --供能大于最大供能等级
    if level > self.MaxSupplyEnergy then
        level = self.MaxSupplyEnergy
    end
    local effectCfg = XPivotCombatConfigs.GetEffectConfig(self.EffectLibId, level)
    local buffDesc = ""
    if effectCfg then
        --buffDesc = XRoomSingleManager.GetEvenDesc(effectCfg.FightEventId)
        buffDesc = effectCfg.BuffDesc
    end
    return buffDesc
end

--===========================================================================
 ---@desc 获取当前区域的积分加成
--===========================================================================
function XPivotCombatRegionItem:GetScoreAddition()
    if self.CurSupplyEnergy <= 0 then
        return 0
    end

    if self.CurSupplyEnergy > self.MaxSupplyEnergy then
        self.CurSupplyEnergy = self.MaxSupplyEnergy
    end

    local effectCfg = XPivotCombatConfigs.GetEffectConfig(self.EffectLibId, self.CurSupplyEnergy)
    if effectCfg then
        return effectCfg.ScoreAddition
    end
    return 0
end

--===========================================================================
 ---@desc 计算当前供能与区域总供能比值
 ---@return {float}
--===========================================================================
function XPivotCombatRegionItem:GetPercentEnergy()
    if self.MaxSupplyEnergy <= 0 then
        XLog.Error("XPivotCombat Region:"..self.RegionId.."MaxSupplyEnergy Calculate Error:", self.MaxSupplyEnergy)
        return "0/0"
    end

    if self.CurSupplyEnergy > self.MaxSupplyEnergy then
        self.CurSupplyEnergy = self.MaxSupplyEnergy
    end
    return self.CurSupplyEnergy / self.MaxSupplyEnergy
end

--===========================================================================
 ---@desc 获取区域的关卡数据
--===========================================================================
function  XPivotCombatRegionItem:GetStageList()
    local stageList = {}
    for _, stage in pairs(self.StageDict) do
        table.insert(stageList, stage)
    end
    
    table.sort(stageList, function(a, b) 
        return a:GetIndex() < b:GetIndex()
    end)
    return stageList
end

--===========================================================================
 ---@desc 获取中枢关卡配置，中枢关卡只有一个，如果有多个默认拿到第一个
--===========================================================================
function XPivotCombatRegionItem:GetCenterStage()
    if not self:IsCenterRegion() then
        XLog.Error("This Region is Not Center Region, Do Not Call This Function")
        return {}
    end
    for stageId, stage in pairs(self.StageDict) do
        if stage then
            return stage
        end
    end
    return {}
end

--===========================================================================
 ---@desc 获取次级区域锁角色的关卡
--===========================================================================
function XPivotCombatRegionItem:GetLockCharacterStage()
    if not self.LockCharacterStage then
        for _, stage in pairs(self.StageDict) do
            if stage:CheckIsLockCharacterStage() then
                self.LockCharacterStage = stage
            end
        end
    end
    return self.LockCharacterStage
end

--===========================================================================
 ---@desc 是否是相同的次级区域
--===========================================================================
function XPivotCombatRegionItem:IsSameRegion(region)
    if not region then
        return false
    end
    return self.RegionId == region:GetRegionId()
end

--==============================
 ---@desc 区域类型
 ---@return number 
--==============================
function XPivotCombatRegionItem:GetSecondaryRegionIndex()
    return self.SecondaryRegionIndex
end

--==============================
 ---@desc 区域背景
 ---@return string
--==============================
function XPivotCombatRegionItem:GetSecondaryRegionBg()
    return self.SecondaryRegionBackground
end

--==============================
 ---@desc 任务组
 ---@return number
--==============================
function XPivotCombatRegionItem:GetTaskGroupId()
    return self.TaskGroupId
end

return XPivotCombatRegionItem