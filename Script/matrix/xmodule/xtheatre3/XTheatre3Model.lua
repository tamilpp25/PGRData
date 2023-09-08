local XTheatre3Activity = require("XModule/XTheatre3/XEntity/XTheatre3Activity")
--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local TableKey = {
    Theatre3Activity = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre3Chapter = {},
    Theatre3ChapterGroup = {},
    Theatre3CharacterGroup = {},
    Theatre3CharacterLevel = {},
    Theatre3CharacterRecruit = {},
    Theatre3CharacterEnding = {},
    Theatre3StrengthenTree = {},
    Theatre3Difficulty = {},
    Theatre3BattlePass = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "Level" },
    Theatre3Config = { ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    Theatre3Task = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client },
    Theatre3EquipSuit = {},
    Theatre3EquipSuitEffectGroup = {CacheType = XConfigUtil.CacheType.Temp},
    Theatre3Equip = {},
    Theatre3Item = {},
    Theatre3Ending = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre3SettleFactor = {},
    Theatre3Event = {},
    Theatre3EventOptionGroup = {},
    Theatre3FightStageTemplate = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre3FightNode = {},
    Theatre3NodeShop = {},
    Theatre3Reboot = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre3EventNode = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "EventId" },
    Theatre3ItemType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type" },
    Theatre3EquipSuitType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type" },
    Theatre3ClientConfig = { CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.String, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key" },
    Theatre3ItemBox = {},
    Theatre3EquipBox = {},
    Theatre3Gold = {},
    Theatre3EnergyUnused = {},
    Theatre3EffectGroupDesc = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "EffectGroupId" },
}

---@class XTheatre3Model : XModel
---@field ActivityData XTheatre3Activity
local XTheatre3Model = XClass(XModel, "XTheatre3Model")
function XTheatre3Model:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    self._ConfigUtil:InitConfigByTableKey("Theatre3", TableKey)
    -- BP最高等级
    self.MaxBattlePassLevel = 0
    -- BPId列表
    self.BattlePassIdList = {}
    self.IsInitBattlePassConfig = false
    -- 任务列表
    self.TaskConfigIdList = {}
    -- 参与主界面任务显示逻辑的Id列表
    self.TaskMainShowIdList = {}
    self.IsInitTaskConfig = false
    -- 天赋树Id列表
    self.StrengthenTreeIdList = {}
    self.IsInitStrengthenTreeConfig = false
    -- 精通-角色组Id列表
    self.CharacterGroupIdList = {}
    -- 角色组对应的角色Id列表 Key：GroupId；value：CharacterIdList
    self.CharacterGroupIdToCharacterIdList = {}
    -- 角色Id对应的角色等级列表 Key：CharacterId；value：CharacterLevelIdList
    self.CharacterIdToCharacterLevelIdList = {}
    -- 角色Id和等级对应的角色等级配置的Id Key1：CharacterId key2：Level Value：Id
    self.CharacterIdAndLevelToCharacterLevelId = {}
    -- 角色最高等级字典 Key：CharacterId；value：MaxLevel
    self.CharacterIdToMaxLevel = {}
    -- 角色Id对应的角色加成列表 Key：CharacterId；value：CharacterEndingIdList
    self.CharacterIdToCharacterEndingIdList = {}
    self.IsInitCharacterConfig = false
    -- 图鉴-道具类型Id列表
    self.ItemTypeIdList = {}
    -- 图鉴-道具类型对应的道具Id列表  Key：TypeId；value：ItemIdList
    self.ItemTypeIdToItemIdList = {}
    self.IsInitItemConfig = false
    -- 图鉴-套装类型Id列表
    self.EquipSuitTypeIdList = {}
    -- 图鉴-套装类型对应的套装Id列表 Key：TypeId；value：EquipSuitIdList
    self.EquipSuitTypeToEquipSuitIdList = {}
    self.IsInitEquipSuitConfig = false
    -- 每个套装包含的装备
    self.SuitToEquipsMap = {}
    -- 招募角色消耗列表
    self.CharacterCostMap = {}
    -- 机器人对应角色列表
    self.CharacterRobotMap = {}
end

function XTheatre3Model:ClearPrivate()
    --这里执行内部数据清理
end

function XTheatre3Model:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
end

--region 服务端信息更新和获取

function XTheatre3Model:NotifyTheatre3Activity(data)
    if not data or not XTool.IsNumberValid(data.CurActivityId) then
        return
    end
    if not self.ActivityData then
        self.ActivityData = XTheatre3Activity.New()
    end
    self.ActivityData:NotifyTheatre3Activity(data)
end

function XTheatre3Model:NotifyTheatre3AdventureSettle(data)
    if not data or not self.ActivityData then
        return
    end
    self.ActivityData:UpdateSettle(data.SettleData)
end

function XTheatre3Model:NotifyTheatre3AddStep(data)
    self.ActivityData:NotifyTheatre3AddStep(data)
end

function XTheatre3Model:UpdateGetRewardId(rewardType, data, id)
    if rewardType == XEnumConst.THEATRE3.GetBattlePassRewardType.GetOnce then
        self.ActivityData:AddGetRewardId(id)
    else
        self.ActivityData:UpdateGetRewardIdData(data)
    end
end

-- 获取BP经验值
function XTheatre3Model:GetBattlePassTotalExp()
    if not self.ActivityData then
        return 0
    end
    return self.ActivityData:GetTotalBattlePassExp()
end

--endregion

--region 活动表相关

function XTheatre3Model:GetActivityConfig()
    if not self.ActivityData then
        return {}
    end
    local curActivityId = self.ActivityData:GetCurActivityId()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Activity, curActivityId)
end

--endregion

--region BP奖励相关

function XTheatre3Model:GetBattlePassConfigs()
    local config = self._ConfigUtil:GetByTableKey(TableKey.Theatre3BattlePass)
    return config or {}
end

function XTheatre3Model:GetBattlePassConfig(level)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3BattlePass, level)
    return config or {}
end

function XTheatre3Model:GetBattlePassNeedExp(level)
    local config = self:GetBattlePassConfig(level)
    return config.NeedExp or 0
end

function XTheatre3Model:InitBattlePassConfig()
    if self.IsInitBattlePassConfig then
        return
    end
    local configs = self:GetBattlePassConfigs()
    for id, _ in pairs(configs) do
        table.insert(self.BattlePassIdList, id)
        if id > self.MaxBattlePassLevel then
            self.MaxBattlePassLevel = id
        end
    end
    self.IsInitBattlePassConfig = true
end

function XTheatre3Model:GetMaxBattlePassLevel()
    self:InitBattlePassConfig()
    return self.MaxBattlePassLevel
end

function XTheatre3Model:GetBattlePassIdList()
    self:InitBattlePassConfig()
    return self.BattlePassIdList
end

-- 根据经验获取BP的等级
function XTheatre3Model:GetBattlePassLevelByExp(totalExp)
    local configs = self:GetBattlePassConfigs()
    local curLevel = 0
    local curScore = 0
    for id, config in pairs(configs) do
        curScore = curScore + config.NeedExp
        if totalExp >= curScore then
            curLevel = id
        else
            break
        end
    end
    return curLevel
end

function XTheatre3Model:GetEnergyUnusedConfig()
    local config = self._ConfigUtil:GetByTableKey(TableKey.Theatre3EnergyUnused)
    return config or {}
end

--endregion

--region Config表相关

-- 获取Share路径下的Config配置信息
function XTheatre3Model:GetShareConfig(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Config, key)
    return config and config.Value or ""
end

-- 获取Client路径下的Config配置信息
function XTheatre3Model:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3ClientConfig, key)
    if not config then
        return ""
    end
    return config.Values and config.Values[index] or ""
end

--endregion

--region 任务相关配置

function XTheatre3Model:InitTaskConfig()
    if self.IsInitTaskConfig then
        return
    end

    local configs = self:GetTaskConfigs()
    for id, config in pairs(configs) do
        local mainShowOrder = config.MainShowOrder
        if XTool.IsNumberValid(mainShowOrder) then
            table.insert(self.TaskMainShowIdList, id)
        end

        table.insert(self.TaskConfigIdList, id)
    end

    table.sort(self.TaskMainShowIdList, function(a, b)
        local orderA = self:GetTaskMainShowOrder(a)
        local orderB = self:GetTaskMainShowOrder(b)
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a < b
    end)

    self.IsInitTaskConfig = true
end

function XTheatre3Model:GetTaskConfigIdList()
    self:InitTaskConfig()
    return self.TaskConfigIdList
end

function XTheatre3Model:GetTaskMainShowIdList()
    self:InitTaskConfig()
    return self.TaskMainShowIdList
end

function XTheatre3Model:GetTaskConfigs()
    local config = self._ConfigUtil:GetByTableKey(TableKey.Theatre3Task)
    return config or {}
end

function XTheatre3Model:GetTaskConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Task, id)
    return config or {}
end

function XTheatre3Model:GetTaskIdsById(id)
    local config = self:GetTaskConfig(id)
    return config.TaskId or {}
end

function XTheatre3Model:GetTaskMainShowOrder(id)
    local config = self:GetTaskConfig(id)
    return config.MainShowOrder or 0
end

--endregion

--region 编队相关

function XTheatre3Model:GetCharacterCost(id)
    if XTool.IsTableEmpty(self.CharacterCostMap) then
        self:InitMemberConfig()
    end
    return self.CharacterCostMap[id]
end

function XTheatre3Model:GetCharacterByRobot(id)
    if XTool.IsTableEmpty(self.CharacterRobotMap) then
        self:InitMemberConfig()
    end
    return self.CharacterRobotMap[id]
end

function XTheatre3Model:InitMemberConfig()
    local configs = self:GetCharacterRecruitConfig()
    for _, v in pairs(configs) do
        local cost = self:GetCharacterGroupById(v.GroupId).EnergyCost
        self.CharacterCostMap[v.CharacterId] = cost
        self.CharacterRobotMap[v.RobotId] = v.CharacterId
    end
end

--endregion

--region 装备相关

---@return XTableTheatre3Equip[]
function XTheatre3Model:GetEquipConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3Equip)
end

---@return XTableTheatre3Equip
function XTheatre3Model:GetEquipById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Equip, id)
end

---@return XTableTheatre3EquipSuit[]
function XTheatre3Model:GetEquipSuitConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3EquipSuit)
end

---@return XTableTheatre3EquipSuit
function XTheatre3Model:GetSuitById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3EquipSuit, id)
end

---@return XTableTheatre3EquipSuitEffectGroup
function XTheatre3Model:GetSuitEffectGroupById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3EquipSuitEffectGroup, id)
end

---@return XTableTheatre3Equip[]
function XTheatre3Model:GetSameSuitEquip(suitId)
    local data = self.SuitToEquipsMap[suitId]
    if not data then
        data = {}
        local config = self:GetEquipConfig()
        for _, v in pairs(config) do
            if v.SuitId == suitId then
                table.insert(data, v)
            end
        end
        table.sort(data, function(a, b)
            return a.Id < b.Id
        end)
        self.SuitToEquipsMap[suitId] = data
    end
    return data
end

--endregion

--region 精通-成员相关

function XTheatre3Model:InitCharacterConfig()
    if self.IsInitCharacterConfig then
        return
    end

    local recruitConfigs = self:GetCharacterRecruitConfig()
    for _, config in pairs(recruitConfigs or {}) do
        if not self.CharacterGroupIdToCharacterIdList[config.GroupId] then
            self.CharacterGroupIdToCharacterIdList[config.GroupId] = {}
        end
        table.insert(self.CharacterGroupIdToCharacterIdList[config.GroupId], config.CharacterId)
    end

    local levelConfig = self:GetCharacterLevelConfig()
    local characterId, level
    for id, config in pairs(levelConfig or {}) do
        characterId = config.CharacterId
        level = config.Level
        if not self.CharacterIdToCharacterLevelIdList[characterId] then
            self.CharacterIdToCharacterLevelIdList[characterId] = {}
        end
        table.insert(self.CharacterIdToCharacterLevelIdList[characterId], id)

        if not self.CharacterIdAndLevelToCharacterLevelId[characterId] then
            self.CharacterIdAndLevelToCharacterLevelId[characterId] = {}
        end
        self.CharacterIdAndLevelToCharacterLevelId[characterId][level] = id

        if not self.CharacterIdToMaxLevel[characterId] or level > self.CharacterIdToMaxLevel[characterId] then
            self.CharacterIdToMaxLevel[characterId] = level
        end
    end

    local characterEnding = self:GetCharacterEndingConfigs()
    for _, config in pairs(characterEnding or {}) do
        if not self.CharacterIdToCharacterEndingIdList[config.CharacterId] then
            self.CharacterIdToCharacterEndingIdList[config.CharacterId] = {}
        end
        table.insert(self.CharacterIdToCharacterEndingIdList[config.CharacterId], config.Id)
    end

    local groupConfig = self:GetCharacterGroupConfig()
    for id, _ in pairs(groupConfig or {}) do
        table.insert(self.CharacterGroupIdList, id)
    end

    self.IsInitCharacterConfig = true
end

function XTheatre3Model:GetCharacterGroupIdList()
    self:InitCharacterConfig()
    return self.CharacterGroupIdList
end

function XTheatre3Model:GetCharacterIdListByGroupId(groupId)
    self:InitCharacterConfig()
    return self.CharacterGroupIdToCharacterIdList[groupId] or {}
end

function XTheatre3Model:GetCharacterLevelIdListByCharacterId(characterId)
    self:InitCharacterConfig()
    return self.CharacterIdToCharacterLevelIdList[characterId] or {}
end

-- 获取角色最高等级
function XTheatre3Model:GetCharacterMaxLevel(characterId)
    self:InitCharacterConfig()
    return self.CharacterIdToMaxLevel[characterId] or 0
end

-- 获取角色等级表的Id
function XTheatre3Model:GetCharacterLevelId(characterId, level)
    self:InitCharacterConfig()
    if not self.CharacterIdAndLevelToCharacterLevelId[characterId] then
        XLog.Error("Theatre3CharacterLevel表找不到数据 CharacterId:", characterId)
        return
    end
    return self.CharacterIdAndLevelToCharacterLevelId[characterId][level]
end

function XTheatre3Model:GetCharacterEndingIdList(characterId)
    self:InitCharacterConfig()
    return self.CharacterIdToCharacterEndingIdList[characterId] or {}
end

---@return XTableTheatre3CharacterGroup[]
function XTheatre3Model:GetCharacterGroupConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3CharacterGroup)
end

---@return XTableTheatre3CharacterGroup
function XTheatre3Model:GetCharacterGroupById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3CharacterGroup, id)
end

---@return XTableTheatre3CharacterRecruit[]
function XTheatre3Model:GetCharacterRecruitConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3CharacterRecruit)
end

---@return XTableTheatre3CharacterRecruit
function XTheatre3Model:GetCharacterRecruitConfigById(recruitId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3CharacterRecruit, recruitId)
end

---@return XTableTheatre3CharacterLevel[]
function XTheatre3Model:GetCharacterLevelConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3CharacterLevel)
end

---@return XTableTheatre3CharacterLevel
function XTheatre3Model:GetCharacterLevelConfigById(levelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3CharacterLevel, levelId)
end

---@return XTableTheatre3CharacterEnding[]
function XTheatre3Model:GetCharacterEndingConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3CharacterEnding)
end

---@return XTableTheatre3CharacterEnding
function XTheatre3Model:GetCharacterEndingConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3CharacterEnding, id)
end

--endregion

--region 精通-天赋相关
function XTheatre3Model:InitStrengthenTreeConfig()
    if self.IsInitStrengthenTreeConfig then
        return
    end

    local configs = self:GetStrengthenTreeConfig()
    for id, _ in pairs(configs or {}) do
        table.insert(self.StrengthenTreeIdList, id)
    end

    XTool.SortIdTable(self.StrengthenTreeIdList)
    self.IsInitStrengthenTreeConfig = true
end

function XTheatre3Model:GetStrengthenTreeIdList()
    self:InitStrengthenTreeConfig()
    return self.StrengthenTreeIdList
end

---@return XTableTheatre3StrengthenTree[]
function XTheatre3Model:GetStrengthenTreeConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3StrengthenTree)
end

---@return XTableTheatre3StrengthenTree
function XTheatre3Model:GetStrengthenTreeConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3StrengthenTree, id)
end
--endregion

--region 图鉴-道具相关

function XTheatre3Model:InitItemConfig()
    if self.IsInitItemConfig then
        return
    end

    local itemConfigs = self:GetItemConfigs()
    for id, config in pairs(itemConfigs or {}) do
        if not self.ItemTypeIdToItemIdList[config.Type] then
            self.ItemTypeIdToItemIdList[config.Type] = {}
        end
        table.insert(self.ItemTypeIdToItemIdList[config.Type], id)
    end

    local itemTypeConfigs = self:GetItemTypeConfigs()
    for _, config in pairs(itemTypeConfigs or {}) do
        if config.ShowInArchive == 1 then
            table.insert(self.ItemTypeIdList, config.Type)
        end
    end

    self.IsInitItemConfig = true
end

function XTheatre3Model:GetItemTypeIdList()
    self:InitItemConfig()
    return self.ItemTypeIdList
end

function XTheatre3Model:GetItemIdListByTypeId(typeId)
    self:InitItemConfig()
    return self.ItemTypeIdToItemIdList[typeId] or {}
end

---@return XTableTheatre3Item[]
function XTheatre3Model:GetItemConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3Item)
end

---@return XTableTheatre3Item
function XTheatre3Model:GetItemConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Item, id)
end

---@return XTableTheatre3ItemType[]
function XTheatre3Model:GetItemTypeConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3ItemType)
end

function XTheatre3Model:GetItemTypeConfigByTypeId(typeId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3ItemType, typeId)
end

--endregion

--region 图鉴-套装相关

function XTheatre3Model:InitEquipSuitConfig()
    if self.IsInitEquipSuitConfig then
        return
    end

    local equipSuitConfigs = self:GetEquipSuitConfigs()
    for id, config in pairs(equipSuitConfigs or {}) do
        if not self.EquipSuitTypeToEquipSuitIdList[config.UseType] then
            self.EquipSuitTypeToEquipSuitIdList[config.UseType] = {}
        end
        table.insert(self.EquipSuitTypeToEquipSuitIdList[config.UseType], id)
    end

    local equipSuitTypeConfigs = self:GetEquipSuitTypeConfigs()
    for typeId, _ in pairs(equipSuitTypeConfigs) do
        table.insert(self.EquipSuitTypeIdList, typeId)
    end

    self.IsInitEquipSuitConfig = true
end

function XTheatre3Model:GetEquipSuitTypeIdList()
    self:InitEquipSuitConfig()
    return self.EquipSuitTypeIdList
end

function XTheatre3Model:GetEquipSuitIdListByTypeId(typeId)
    self:InitEquipSuitConfig()
    return self.EquipSuitTypeToEquipSuitIdList[typeId] or {}
end

function XTheatre3Model:GetEquipSuitTypeConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3EquipSuitType)
end

function XTheatre3Model:GetEquipSuitTypeConfigByTypeId(typeId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3EquipSuitType, typeId)
end

--endregion

--region 结算相关

---@return XTableTheatre3Ending
function XTheatre3Model:GetEndingById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Ending, id)
end

function XTheatre3Model:GetSettleFactor()
    local config = self._ConfigUtil:GetByTableKey(TableKey.Theatre3SettleFactor)
    return config or {}
end

---@return XTableTheatre3ItemBox
function XTheatre3Model:GetItemBoxById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3ItemBox, id)
end

---@return XTableTheatre3EquipBox
function XTheatre3Model:GetEquipBoxById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3EquipBox, id)
end

function XTheatre3Model:GetGoldBoxById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Gold, id)
end

--endregion

--region Cache
function XTheatre3Model:GetLocalCacheKey(key)
    return string.format("Theatre3_%s_%s_%s", XPlayer.Id, self.ActivityData:GetCurActivityId(), key)
end

function XTheatre3Model:GetAddEnergyLimitRedPoint()
    local value = XSaveTool.GetData(self:GetLocalCacheKey("EnergyLimitRedPoint"))
    if value == nil then
        return false
    else
        return value
    end
end

function XTheatre3Model:SetAddEnergyLimitRedPoint(value)
    if self:GetAddEnergyLimitRedPoint() == value then
        return
    end
    XSaveTool.SaveData(self:GetLocalCacheKey("EnergyLimitRedPoint"), value)
end
--endregion

--region Difficulty
---@return XTableTheatre3Difficulty[]
function XTheatre3Model:GetDifficultyConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3Difficulty)
end

---@return XTableTheatre3Difficulty
function XTheatre3Model:GetDifficultyById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Difficulty, id)
end
--endregion

--region Chapter
---@return XTableTheatre3Chapter[]
function XTheatre3Model:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3Chapter)
end

---@return XTableTheatre3Chapter
function XTheatre3Model:GetChapterCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Chapter, id)
end
--endregion

--region EventNode
---@return XTableTheatre3Event[]
function XTheatre3Model:GetEventConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3Event)
end

---@return XTableTheatre3EventNode
function XTheatre3Model:GetEventNodeCfgById(eventId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3EventNode, eventId)
end

---@return XTableTheatre3EventOptionGroup[]
function XTheatre3Model:GetEventOptionGroupConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3EventOptionGroup)
end

---@return XTableTheatre3EventOptionGroup
function XTheatre3Model:GetEventOptionCfgById(optionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3EventOptionGroup, optionId)
end
--endregion

--region FightNode
---@return XTableTheatre3FightNode
function XTheatre3Model:GetFightNodeCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3FightNode, id)
end

---@return XTableTheatre3FightStageTemplate[]
function XTheatre3Model:GetFightStageTemplateConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre3FightStageTemplate)
end

---@return XTableTheatre3FightStageTemplate
function XTheatre3Model:GetFightStageTemplateCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3FightStageTemplate, id)
end
--endregion

--region ShopNode
---@return XTableTheatre3NodeShop
function XTheatre3Model:GetShopNodeCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3NodeShop, id)
end
--endregion

--region Reboot
---@return XTable.XTableTheatre3Reboot
function XTheatre3Model:GetRebootCfg(rebootId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3Reboot, rebootId)
end

function XTheatre3Model:GetRebootCost(rebootId)
    local cfg = self:GetRebootCfg(rebootId)
    return cfg and cfg.RebootCost or 0
end

function XTheatre3Model:GetMaxRebootCount(rebootId)
    local cfg = self:GetRebootCfg(rebootId)
    return cfg and cfg.MaxRebootCount or 0
end

function XTheatre3Model:GetFubenRestartCost(rebootId)
    local cfg = self:GetRebootCfg(rebootId)
    return cfg and cfg.FubenRestartCost or 0
end

function XTheatre3Model:GetFubenClashCost(rebootId)
    local cfg = self:GetRebootCfg(rebootId)
    return cfg and cfg.FubenClashCost or 0
end
--endregion

--region EffectGroup
---@return XTableTheatre3EffectGroupDesc
function XTheatre3Model:_GetEffectGroupDescCfg(effectGroupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre3EffectGroupDesc, effectGroupId, true)
end

---@param paramList number[]
---@return string
function XTheatre3Model:GetEffectGroupDescByIndex(effectGroupId, paramList, index)
    local cfg = self:_GetEffectGroupDescCfg(effectGroupId)
    if not cfg then
        return ""
    end
    local value = 0
    index = index and index or 1
    local baseValueList = string.Split(cfg.BaseValueList[index], "|")
    for i = 1, #baseValueList do
        if baseValueList[i] ~= "" then
            value = value + tonumber(baseValueList[i]) * (paramList[i] and paramList[i] or 1)
        end
    end
    return XUiHelper.FormatText(cfg.DescList[index], value)
end

---@return number 
function XTheatre3Model:GetEffectGroupDescCfgType(effectGroupId)
    local cfg = self:_GetEffectGroupDescCfg(effectGroupId)
    if not cfg then
        return
    end
    return cfg.Type
end
--endregion

return XTheatre3Model