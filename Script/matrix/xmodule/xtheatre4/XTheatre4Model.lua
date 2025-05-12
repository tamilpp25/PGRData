local XTheatre4ConfigModel = require("XModule/XTheatre4/XTheatre4ConfigModel")
---@class XTheatre4Model : XTheatre4ConfigModel
---@field ActivityData XTheatre4Activity
local XTheatre4Model = XClass(XTheatre4ConfigModel, "XTheatre4Model")
function XTheatre4Model:OnInit()
    self:_InitTableKey()

    ---@type XTheatre4Set
    self._Set = nil
    -- 地图建造数据
    ---@type XTheatre4MapBuildData
    self.MapBuildData = nil
    -- 编队数据
    ---@type XTheatre4Team
    self.Theatre4Team = nil
    -- 弹框数据
    self.PopupData = nil
    -- 当前正在打开的弹框类型列表
    ---@type number[] 弹框类型列表
    self.CurrentOpenPopupList = {}
    -- 是否正在日结算
    self.IsDailySettling = false
    -- 日结算信息
    ---@type XTheatre4DailySettleResult
    self.DailySettleResult = nil
    -- 冒险结算信息
    ---@type XTheatre4Adventure
    self.AdventureSettleResult = nil
    -- 是否是新开一局冒险
    self.IsNewAdventure = false

    self._BattlePassRewardIdMap = nil
    self._ActivedTechIdMap = nil
    self._UnlockItemMap = nil
    self._UnlockColorTalentMap = nil
    self._UnlockMapIndexMap = nil

    self._LocalUnlockMapIndexMap = nil
    self._LocalUnlockColorTalentMap = nil
    self._LocalUnlockItemMap = nil

    self._IsBattlePassLvUp = false
    self._OldExp = 0
    self._NewExp = 0

    -- 是否初始化天赋等级
    self.IsInitTalentLevel = false
    -- 颜色和等级对应的天赋档位Id
    self.ColorAndLevelToTalentSlotId = {}
    -- 是否初始化天赋关联
    self.IsInitTalentRelated = false
    -- 天赋Id对应的关联天赋Ids
    self.TalentIdToRelatedTalentIds = {}
    -- 是否初始化地图组
    self.IsInitMapGroup = false
    -- 地图组和地图Id对应的Index
    self.MapGroupAndMapIdToIndex = {}
    -- 是否是手动结束战斗
    self.IsManualEndBattle = false
    -- 是否初始化难度星级
    self.IsInitDifficultyStar = false
    -- 组Id对应的难度星级Id
    self.GroupIdToDifficultyStarId = {}

    -- 是否不显示进攻预警弹框 （本次登录有效）
    self.IsNotShowAttackWarning = false
    -- 查看地图数据
    ---@type XTheatre4ViewMapData
    self.ViewMapData = nil
    -- 聚焦到格子前的相机位置
    self.FocusGridBeforeCameraPos = nil
end

function XTheatre4Model:ClearPrivate()
    --这里执行内部数据清理
    self._Set = nil
    self.MapBuildData = nil
    self.PopupData = nil
    self.CurrentOpenPopupList = {}
    self.IsDailySettling = false
    self.DailySettleResult = nil
    self.IsNewAdventure = false
    self.IsManualEndBattle = false
    self.ViewMapData = nil
    self.FocusGridBeforeCameraPos = nil

    self:ClearAllCacheMap()
    self:SaveLocalUnlockMapIndexMap()
    self:SaveLocalUnlockColorTalentMap()
    self:SaveLocalUnlockItemMap()
end

function XTheatre4Model:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
    self._Set = nil
    self.MapBuildData = nil
    self.Theatre4Team = nil
    self.PopupData = nil
    self.CurrentOpenPopupList = {}
    self.IsDailySettling = false
    self.DailySettleResult = nil
    self.AdventureSettleResult = nil
    self.IsNewAdventure = false
    self.IsManualEndBattle = false
    self.IsNotShowAttackWarning = false
    self.ViewMapData = nil
    self.FocusGridBeforeCameraPos = nil
end

--region 服务端信息更新和获取

-- 更新活动信息
function XTheatre4Model:NotifyActivityData(data)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XTheatre4/XEntity/XTheatre4Activity").New()
    end
    self.ActivityData:NotifyActivityData(data)
    self:ClearAllCacheMap()
end

-- 获取冒险数据
---@return XTheatre4Adventure
function XTheatre4Model:GetAdventureData()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetAdventureData()
end

-- 获取上一次冒险结算数据
---@return XTheatre4AdventureSettle
function XTheatre4Model:GetPreAdventureSettleData()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetPreAdventureSettleData()
end

-- 获取所有的章节数据
---@return XTheatre4ChapterData[]
function XTheatre4Model:GetAllChapterData()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetChapters()
end

-- 获取章节数据
---@return XTheatre4ChapterData
function XTheatre4Model:GetChapterData(mapId)
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil, 0
    end
    return adventureData:GetChapterData(mapId)
end

-- 获取最后一个章节数据
---@return XTheatre4ChapterData
function XTheatre4Model:GetLastChapterData()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetLastChapterData()
end

-- 获取倒数第二个章节数据
---@return XTheatre4ChapterData
function XTheatre4Model:GetPreLastChapterData()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetPreLastChapterData()
end

-- 获取单个格子数据
---@return XTheatre4Grid
function XTheatre4Model:GetGridData(mapId, gridId)
    local chapterData = self:GetChapterData(mapId)
    if not chapterData then
        return nil
    end
    return chapterData:GetGridData(gridId)
end

-- 获取所有格子数据
---@return table<number, XTheatre4Grid>
function XTheatre4Model:GetAllGridData(mapId)
    local chapterData = self:GetChapterData(mapId)
    if not chapterData then
        return nil
    end
    return chapterData:GetAllGridData()
end

-- 获取事务数据
---@return XTheatre4Transaction
function XTheatre4Model:GetTransactionData(transactionId)
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetTransactionData(transactionId)
end

-- 根据类型获取事务数据
---@return XTheatre4Transaction
function XTheatre4Model:GetTransactionDataByType(transactionType)
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetTransactionDataByType(transactionType)
end

-- 根据类型获取事务数据的数量
function XTheatre4Model:GetTransactionDataCountByType(transactionType)
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetTransactionDataCountByType(transactionType)
end

function XTheatre4Model:GetItemsAtlas()
    if self.ActivityData then
        return self.ActivityData.ItemsAtlas
    end

    return nil
end

function XTheatre4Model:SetItemsAtlas(itemsAtlas)
    if self.ActivityData then
        self.ActivityData.ItemsAtlas = itemsAtlas
    end
end

function XTheatre4Model:GetTalentAtlas()
    if self.ActivityData then
        return self.ActivityData.TalentAtlas
    end

    return nil
end

function XTheatre4Model:SetTalentAtlas(talentAtlas)
    if self.ActivityData then
        self.ActivityData.TalentAtlas = talentAtlas
    end
end

function XTheatre4Model:GetMapAtlas()
    if self.ActivityData then
        return self.ActivityData.MapAtlas
    end

    return nil
end

function XTheatre4Model:SetMapAtlas(mapAtlas)
    if self.ActivityData then
        self.ActivityData.MapAtlas = mapAtlas
    end

    return nil
end

function XTheatre4Model:GetBattlePassGotRewardIds()
    if self.ActivityData then
        return self.ActivityData:GetBattlePassGotRewardIds()
    end

    return nil
end

function XTheatre4Model:SetBattlePassGotRewardIds(rewardIds)
    if self.ActivityData then
        self.ActivityData:SetBattlePassGotRewardIds(rewardIds)
    end
end

function XTheatre4Model:AddBattlePassGotRewardId(rewardId)
    if self.ActivityData then
        self.ActivityData:AddBattlePassGotRewardId(rewardId)
    end
end

function XTheatre4Model:AddUnlockTechId(techId)
    if self.ActivityData then
        self.ActivityData:AddTechs(techId)
    end
end

function XTheatre4Model:GetFateList()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetFateList()
end

-- 获取已招募角色的配置Ids
function XTheatre4Model:GetRecruitedCharacterConfigIds()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetCharacterIds()
end

-- 获取队伍数据
---@return XTheatre4TeamData
function XTheatre4Model:GetTeamData()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetTeamData()
end

-- 获取颜色天赋数据
---@return XTheatre4ColorTalent
function XTheatre4Model:GetColorTalentData(color)
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetColorData(color)
end

-- 获取角色数据
---@return XTheatre4CharacterData
function XTheatre4Model:GetCharacterData(characterId)
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetCharacterData(characterId)
end

--endregion

--region 活动表相关

function XTheatre4Model:GetActivityId()
    if not self.ActivityData then
        return 0
    end

    return self.ActivityData:GetActivityId()
end

---@return XTableTheatre4Activity
function XTheatre4Model:GetActivityConfig()
    if not self.ActivityData then
        return nil
    end
    local curActivityId = self.ActivityData:GetActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return nil
    end
    return self:GetActivityConfigById(curActivityId)
end

-- 获取活动时间Id
function XTheatre4Model:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

--endregion

--region set
---@return XTheatre4Set
function XTheatre4Model:GetSet()
    if not self._Set then
        self._Set = require("XModule/XTheatre4/XEntity/Set/XTheatre4Set").New()
        self:InitAllDifficulty(self._Set)
        self:InitAllAffix(self._Set)
    end
    return self._Set
end

---@param set XTheatre4Set
function XTheatre4Model:InitAllDifficulty(set)
    local XTheatre4Difficulty = require("XModule/XTheatre4/XEntity/Set/XTheatre4Difficulty")
    local difficultyConfigs = self:GetDifficultyConfigs()
    local allDifficulty = {}
    for _, config in pairs(difficultyConfigs) do
        ---@type XTheatre4Difficulty
        local difficulty = XTheatre4Difficulty.New()
        difficulty:SetFromConfig(config)
        allDifficulty[#allDifficulty + 1] = difficulty
    end
    set:InitAllDifficulty(allDifficulty)
end

---@param set XTheatre4Set
function XTheatre4Model:InitAllAffix(set)
    local XTheatre4Affix = require("XModule/XTheatre4/XEntity/Set/XTheatre4Affix")
    local affixConfigs = self:GetAffixConfigs()
    local allAffix = {}
    for _, config in pairs(affixConfigs) do
        ---@type XTheatre4Affix
        local affix = XTheatre4Affix.New()
        affix:SetFromConfig(config)
        allAffix[#allAffix + 1] = affix
    end
    table.sort(allAffix, function(a, b)
        return a:GetId() < b:GetId()
    end)
    set:InitAllAffix(allAffix)
end

-- 角色是否已招募
function XTheatre4Model:IsCharacterHired(memberId)
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return false
    end
    local characters = adventureData:GetCharacterData(memberId)
    return characters and true or false
end

--endregion set

--region 结算信息

-- 获取日结算信息
---@return XTheatre4DailySettleResult
function XTheatre4Model:GetDailySettleResult()
    return self.DailySettleResult
end

-- 清空日结算信息
function XTheatre4Model:ClearDailySettleResult()
    self.IsDailySettling = false
    self.DailySettleResult = nil
end

-- 记录日结算前的数据
function XTheatre4Model:RecordPreDailySettleData()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return
    end
    if not self.DailySettleResult then
        self.DailySettleResult = require("XModule/XTheatre4/XEntity/XTheatre4DailySettleResult").New()
    end
    self.DailySettleResult:SetProsperityBefore(adventureData:GetProsperity())
    local colorDataBefore = {}
    for _, colorId in pairs(XEnumConst.Theatre4.ColorType) do
        local colorData = adventureData:GetColorData(colorId)
        if colorData then
            local colorTalentLevel = self:GetColorTalentLevel(colorId, colorData:GetPoint())
            local resource = colorData:GetResource() + colorData:GetDailyResource()
            colorDataBefore[colorId] = { Id = colorId, Level = colorData:GetLevel(), Resource = resource, TalentLevel = colorTalentLevel }
        end
    end
    self.DailySettleResult:SetColorInfoBefore(colorDataBefore)
end

-- 记录日结算信息
function XTheatre4Model:RecordDailySettleResult(data)
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return
    end
    self.DailySettleResult:NotifyDailySettleResult(data)
    self.DailySettleResult:SetProsperityAfter(adventureData:GetProsperity())
    local colorDataAfter = {}
    for _, colorId in pairs(XEnumConst.Theatre4.ColorType) do
        local colorData = adventureData:GetColorData(colorId)
        if colorData then
            local colorTalentLevel = self:GetColorTalentLevel(colorId, colorData:GetPoint())
            colorDataAfter[colorId] = { Id = colorId, Level = 0, Resource = 0, TalentLevel = colorTalentLevel }
        end
    end
    self.DailySettleResult:SetColorInfoAfter(colorDataAfter)
end

-- 记录日结算藏品信息
function XTheatre4Model:RecordDailySettleItemDataList()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return
    end
    -- 记录藏品信息
    local itemDataList = {}
    local itemEffectData = {}
    ---@type table<number, XTheatre4Item>[]
    local allItems = { adventureData:GetItems(), adventureData:GetProps() }
    for _, items in pairs(allItems) do
        if not XTool.IsTableEmpty(items) then
            for _, item in pairs(items) do
                local uid = item:GetUid()
                local itemId = item:GetItemId()
                if self:GetItemIsShowById(itemId) == 1 then
                    local isPlay = self:GetItemIsPlayById(itemId) == 1
                    table.insert(itemDataList, { UId = uid, ItemId = itemId, IsPlay = isPlay })
                    if isPlay then
                        itemEffectData[uid] = self:GetDailySettleItemEffectData(item:GetEffects(), adventureData)
                    end
                end
            end
        end
    end
    self.DailySettleResult:SetItemDataList(itemDataList)
    self.DailySettleResult:SetItemEffectData(itemEffectData)
end

-- 获取藏品日结算时效果信息
---@param effects table<number, XTheatre4Effect> 效果集
---@param adventureData XTheatre4Adventure
---@return table<number, { ColorLevel:number, ColorResource:number, MarkupRate:number }> key:颜色Id value:效果信息
function XTheatre4Model:GetDailySettleItemEffectData(effects, adventureData)
    local data = {}
    -- 初始化数据
    for _, colorId in pairs(XEnumConst.Theatre4.ColorType) do
        data[colorId] = { ColorLevel = 0, ColorResource = 0, MarkupRate = 0 }
    end
    -- 累加数据
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local type = self:GetEffectTypeById(id)
        local addLevel = type == XEnumConst.Theatre4.EffectType.Type8 and adventureData:GetCharacterMaxStar() or 0
        local markupRate = effect:GetMarkupRate()
        for _, colorId in pairs(XEnumConst.Theatre4.ColorType) do
            data[colorId].ColorLevel = data[colorId].ColorLevel + addLevel
            data[colorId].ColorResource = data[colorId].ColorResource + (effect:GetColorResource(colorId) or 0)
            data[colorId].MarkupRate = data[colorId].MarkupRate + markupRate
        end
    end
    return data
end

-- 获取冒险结算类型
function XTheatre4Model:GetAdventureSettleType()
    local preAdventureSettleData = self:GetPreAdventureSettleData()
    if not preAdventureSettleData then
        return 0
    end
    return preAdventureSettleData:GetSettleType()
end

-- 获取冒险结算结局Id
function XTheatre4Model:GetAdventureEndingId()
    local preAdventureSettleData = self:GetPreAdventureSettleData()
    if not preAdventureSettleData then
        return 0
    end
    return preAdventureSettleData:GetEndingId()
end

-- 刷新冒险结算信息
function XTheatre4Model:RecordAdventureSettleResult(data)
    if not data then
        self.AdventureSettleResult = nil
        return
    end
    if not self.AdventureSettleResult then
        self.AdventureSettleResult = require("XModule/XTheatre4/XEntity/XTheatre4Adventure").New()
    end
    self.AdventureSettleResult:NotifyAdventureData(data)
end

-- 获取冒险结算信息
---@return XTheatre4Adventure
function XTheatre4Model:GetAdventureSettleResult()
    return self.AdventureSettleResult
end

-- 检查冒险结算信息是否为空
function XTheatre4Model:CheckAdventureSettleResultEmpty()
    return not self.AdventureSettleResult
end

-- 清空冒险结算信息
function XTheatre4Model:ClearAdventureSettleResult()
    self.AdventureSettleResult = nil
end

--endregion

--region System

function XTheatre4Model:SetIsBattlePassLvUp(isLvUp, newExp)
    self._IsBattlePassLvUp = isLvUp
    self._NewExp = newExp
end

function XTheatre4Model:RecordOldExp()
    if self.ActivityData then
        self._OldExp = self.ActivityData:GetTotalBattlePassExp()
    end
end

function XTheatre4Model:GetIsBattlePassLvUp()
    return self._IsBattlePassLvUp
end

function XTheatre4Model:GetBattlePassOldAndNewExp()
    return self._OldExp or 0, self._NewExp or 0
end

function XTheatre4Model:GetLocalUnlockItemMap()
    if not self._LocalUnlockItemMap then
        self:LoadLocalUnlockItemMap()
    end

    return self._LocalUnlockItemMap
end

function XTheatre4Model:AddLocalUnlockItemMap(value)
    self._LocalUnlockItemMap[value] = true
    self:SaveLocalUnlockItemMap()
end

function XTheatre4Model:SaveLocalUnlockItemMap()
    if self._LocalUnlockItemMap then
        local valueStr = ""
        local isFirst = true

        for index, _ in pairs(self._LocalUnlockItemMap) do
            if isFirst then
                valueStr = valueStr .. tostring(index)
                isFirst = false
            else
                valueStr = valueStr .. "|" .. tostring(index)
            end
        end

        XSaveTool.SaveData(self:GetSaveUnlockItemMapKey(), valueStr)
    end
end

function XTheatre4Model:LoadLocalUnlockItemMap()
    local valueStr = XSaveTool.GetData(self:GetSaveUnlockItemMapKey())

    self._LocalUnlockItemMap = {}
    if not string.IsNilOrEmpty(valueStr) then
        local values = string.Split(valueStr, "|")

        for _, value in pairs(values) do
            self._LocalUnlockItemMap[tonumber(value)] = true
        end
    end

    return self._LocalUnlockItemMap
end

function XTheatre4Model:GetSaveUnlockItemMapKey()
    return "THEATRE4_UNLOCK_ITEM_" .. XPlayer.Id
end

function XTheatre4Model:GetLocalUnlockColorTalentMap()
    if not self._LocalUnlockColorTalentMap then
        self:LoadLocalUnlockColorTalentMap()
    end

    return self._LocalUnlockColorTalentMap
end

function XTheatre4Model:AddLocalUnlockColorTalentMap(value)
    self._LocalUnlockColorTalentMap[value] = true
    self:SaveLocalUnlockColorTalentMap()
end

function XTheatre4Model:SaveLocalUnlockColorTalentMap()
    if self._LocalUnlockColorTalentMap then
        local valueStr = ""
        local isFirst = true

        for index, _ in pairs(self._LocalUnlockColorTalentMap) do
            if isFirst then
                valueStr = valueStr .. tostring(index)
                isFirst = false
            else
                valueStr = valueStr .. "|" .. tostring(index)
            end
        end

        XSaveTool.SaveData(self:GetSaveUnlockColorTalentMapKey(), valueStr)
    end
end

function XTheatre4Model:LoadLocalUnlockColorTalentMap()
    local valueStr = XSaveTool.GetData(self:GetSaveUnlockColorTalentMapKey())

    self._LocalUnlockColorTalentMap = {}
    if not string.IsNilOrEmpty(valueStr) then
        local values = string.Split(valueStr, "|")

        for _, value in pairs(values) do
            self._LocalUnlockColorTalentMap[tonumber(value)] = true
        end
    end

    return self._LocalUnlockColorTalentMap
end

function XTheatre4Model:GetSaveUnlockColorTalentMapKey()
    return "THEATRE4_UNLOCK_COLOR_TALENT_" .. XPlayer.Id
end

function XTheatre4Model:GetLocalUnlockMapIndexMap()
    if not self._LocalUnlockMapIndexMap then
        self:LoadLocalUnlockMapIndexMap()
    end

    return self._LocalUnlockMapIndexMap
end

function XTheatre4Model:AddLocalUnlockMapIndexMap(value)
    self._LocalUnlockMapIndexMap[value] = true
    self:SaveLocalUnlockMapIndexMap()
end

function XTheatre4Model:SaveLocalUnlockMapIndexMap()
    if self._LocalUnlockMapIndexMap then
        local valueStr = ""
        local isFirst = true

        for index, _ in pairs(self._LocalUnlockMapIndexMap) do
            if isFirst then
                valueStr = valueStr .. tostring(index)
                isFirst = false
            else
                valueStr = valueStr .. "|" .. tostring(index)
            end
        end

        XSaveTool.SaveData(self:GetSaveUnlockMapIndexMapKey(), valueStr)
    end
end

function XTheatre4Model:LoadLocalUnlockMapIndexMap()
    local valueStr = XSaveTool.GetData(self:GetSaveUnlockMapIndexMapKey())

    self._LocalUnlockMapIndexMap = {}
    if not string.IsNilOrEmpty(valueStr) then
        local values = string.Split(valueStr, "|")

        for _, value in pairs(values) do
            self._LocalUnlockMapIndexMap[tonumber(value)] = true
        end
    end

    return self._LocalUnlockMapIndexMap
end

function XTheatre4Model:GetSaveUnlockMapIndexMapKey()
    return "THEATRE4_UNLOCK_MAP_INDEX_" .. XPlayer.Id
end

function XTheatre4Model:UpdateBattlePassRewardMap()
    local rewardIds = self:GetBattlePassGotRewardIds()

    self._BattlePassRewardIdMap = {}
    if not XTool.IsTableEmpty(rewardIds) then
        for _, rewardId in pairs(rewardIds) do
            self._BattlePassRewardIdMap[rewardId] = true
        end
    end
end

function XTheatre4Model:AddBattlePassRewardIdMap(rewardId)
    if not self._BattlePassRewardIdMap then
        self:UpdateBattlePassRewardMap()
    end

    self._BattlePassRewardIdMap[rewardId] = true
end

function XTheatre4Model:GetBattlePassRewardIdMap()
    if not self._BattlePassRewardIdMap then
        self:UpdateBattlePassRewardMap()
    end

    return self._BattlePassRewardIdMap
end

function XTheatre4Model:UpdateActivedTechIdMap()
    local unlockTechs = self.ActivityData:GetTechs()

    self._ActivedTechIdMap = {}
    if not XTool.IsTableEmpty(unlockTechs) then
        for _, techId in pairs(unlockTechs) do
            self._ActivedTechIdMap[techId] = true
        end
    end
end

function XTheatre4Model:AddActivedTechIdMap(techId)
    if not self._ActivedTechIdMap then
        self:UpdateActivedTechIdMap()
    end

    self._ActivedTechIdMap[techId] = true
end

function XTheatre4Model:GetActivedTechIdMap()
    if not self._ActivedTechIdMap then
        self:UpdateActivedTechIdMap()
    end

    return self._ActivedTechIdMap
end

function XTheatre4Model:UpdateUnlockItemMap()
    local unlockItems = self:GetItemsAtlas()

    self._UnlockItemMap = {}
    if not XTool.IsTableEmpty(unlockItems) then
        for _, itemId in pairs(unlockItems) do
            self._UnlockItemMap[itemId] = true
        end
    end
end

function XTheatre4Model:GetUnlockItemMap()
    if not self._UnlockItemMap then
        self:UpdateUnlockItemMap()
    end

    return self._UnlockItemMap
end

function XTheatre4Model:UpdateUnlockColorTalentMap()
    local unlockTalents = self:GetTalentAtlas()

    self._UnlockColorTalentMap = {}
    if not XTool.IsTableEmpty(unlockTalents) then
        for _, talentId in pairs(unlockTalents) do
            self._UnlockColorTalentMap[talentId] = true
        end
    end
end

function XTheatre4Model:GetUnlockColorTalentMap()
    if not self._UnlockColorTalentMap then
        self:UpdateUnlockColorTalentMap()
    end

    return self._UnlockColorTalentMap
end

function XTheatre4Model:UpdateUnlockMapIndexMap()
    local unlockMapIndexs = self:GetMapAtlas()

    self._UnlockMapIndexMap = {}
    if not XTool.IsTableEmpty(unlockMapIndexs) then
        for _, mapIndex in pairs(unlockMapIndexs) do
            self._UnlockMapIndexMap[mapIndex] = true
        end
    end
end

function XTheatre4Model:GetUnlockMapIndexMap()
    if not self._UnlockMapIndexMap then
        self:UpdateUnlockMapIndexMap()
    end

    return self._UnlockMapIndexMap
end

function XTheatre4Model:ClearAllCacheMap()
    self:ClearActivedTechCacheMap()
    self:ClearBattlePassCacheMap()
    self:ClearAtlasCacheMap()
end

function XTheatre4Model:ClearAtlasCacheMap()
    self._UnlockItemMap = nil
    self._UnlockColorTalentMap = nil
    self._UnlockMapIndexMap = nil
end

function XTheatre4Model:ClearBattlePassCacheMap()
    self._BattlePassRewardIdMap = nil
end

function XTheatre4Model:ClearActivedTechCacheMap()
    self._ActivedTechIdMap = nil
end

--endregion

--region 编队信息

-- 获取编队缓存key
function XTheatre4Model:GetTeamCacheKey()
    local activityId = self.ActivityData:GetActivityId()
    return string.format("XTheatre4_Team_%s_%s", XPlayer.Id, activityId)
end

-- 获取编队
---@return XTheatre4Team
function XTheatre4Model:GetTeam()
    if not self.Theatre4Team then
        self.Theatre4Team = require("XModule/XTheatre4/XEntity/Team/XTheatre4Team").New(self:GetTeamCacheKey())
        -- 取消本地缓存
        self.Theatre4Team:UpdateLocalSave(false)
    end
    return self.Theatre4Team
end

--endregion

--region 弹框相关

-- 初始化弹框属性信息
-- 一种类型弹框只能存在一个 纯表现的弹框不需要记录
function XTheatre4Model:InitPopupAttribute()
    self.PopupAttribute = {
        [XEnumConst.Theatre4.PopupType.RecruitMember] = { UiName = "UiTheatre4Recruit", MethodName = "OpenRecruitMemberPopup", IsRecord = true },
        [XEnumConst.Theatre4.PopupType.ItemReplace] = { UiName = "UiTheatre4PopupReplace", MethodName = "OpenItemReplacePopup", IsRecord = true },
        [XEnumConst.Theatre4.PopupType.ItemSelect] = { UiName = "UiTheatre4PopupChooseProp", MethodName = "OpenItemSelectPopup", IsRecord = true },
        [XEnumConst.Theatre4.PopupType.RewardSelect] = { UiName = "UiTheatre4PopupChooseReward", MethodName = "OpenRewardSelectPopup", IsRecord = true },
        [XEnumConst.Theatre4.PopupType.FightReward] = { UiName = "UiTheatre4ReceiveReward", MethodName = "OpenFightRewardPopup", IsRecord = true },
        [XEnumConst.Theatre4.PopupType.AssetReward] = { UiName = "UiTheatre4PopupGetReward", MethodName = "OpenAssetRewardPopup", IsRecord = true },
        [XEnumConst.Theatre4.PopupType.TalentSelect] = { UiName = "UiTheatre4PopupChooseGenius", MethodName = "OpenTalentSelectPopup", IsRecord = true },
        [XEnumConst.Theatre4.PopupType.TalentLevelUp] = { UiName = "UiTheatre4PopupGeniusLvUp", MethodName = "OpenTalentLevelUpPopup", IsRecord = true },
        [XEnumConst.Theatre4.PopupType.ArriveNewArea] = { UiName = "UiTheatre4PopupNewArea", MethodName = "OpenArriveNewAreaPopup", IsRecord = false },
        [XEnumConst.Theatre4.PopupType.BloodEffect] = { MethodName = "PlayBloodEffect", IsRecord = false },
    }
end

-- 获取弹框属性信息
---@return {UiName:string, MethodName:string, IsRecord:boolean}
function XTheatre4Model:GetPopupAttribute(typePopup)
    if not self.PopupAttribute then
        self:InitPopupAttribute()
    end
    return self.PopupAttribute[typePopup] or nil
end

-- 获取当前最新的弹框类型
function XTheatre4Model:GetCurrentPopupType()
    return self.CurrentOpenPopupList[#self.CurrentOpenPopupList] or 0
end

-- 添加当前正在打开的弹框类型
function XTheatre4Model:AddCurrentPopupType(popupType)
    if not self:HasCurrentPopupType(popupType) and self:GetPopupIsRecord(popupType) then
        table.insert(self.CurrentOpenPopupList, popupType)
    end
end

-- 移除当前正在打开的弹框类型
function XTheatre4Model:RemoveCurrentPopupType(popupType)
    local isHas, index = self:HasCurrentPopupType(popupType)
    if isHas then
        table.remove(self.CurrentOpenPopupList, index)
    end
end

-- 移除当前正在打开的弹框类型通过ui名称
function XTheatre4Model:RemoveCurrentPopupTypeByUiName(uiName)
    local popupType = self:GetPopupTypeByUiName(uiName)
    if popupType == XEnumConst.Theatre4.PopupType.None then
        return
    end
    self:RemoveCurrentPopupType(popupType)
end

-- 是否存在当前正在打开的弹框类型
function XTheatre4Model:HasCurrentPopupType(popupType)
    for i, v in ipairs(self.CurrentOpenPopupList) do
        if v == popupType then
            return true, i
        end
    end
    return false, 0
end

-- 检查是否有弹框正在打开中
function XTheatre4Model:HasPopupOpening()
    return #self.CurrentOpenPopupList > 0
end

-- 清理当前正在打开的弹框类型
function XTheatre4Model:ClearCurrentPopupType()
    self.CurrentOpenPopupList = {}
end

-- 获取弹框UI名称
function XTheatre4Model:GetPopupUiName(popupType)
    local attribute = self:GetPopupAttribute(popupType)
    return attribute and attribute.UiName or nil
end

-- 获取弹框打开方法名称
function XTheatre4Model:GetPopupMethodName(popupType)
    local attribute = self:GetPopupAttribute(popupType)
    return attribute and attribute.MethodName or nil
end

-- 获取弹框是否记录
function XTheatre4Model:GetPopupIsRecord(popupType)
    local attribute = self:GetPopupAttribute(popupType)
    return attribute and attribute.IsRecord or false
end

-- 通过弹框名称获取弹框类型
function XTheatre4Model:GetPopupTypeByUiName(uiName)
    for _, v in pairs(XEnumConst.Theatre4.PopupType) do
        if self:GetPopupUiName(v) == uiName then
            return v
        end
    end
    return 0
end

-- 获取所有当前打开的弹框Ui名称
---@param isReverse boolean 是否反转
function XTheatre4Model:GetAllCurrentPopupUiName(isReverse)
    local uiNames = {}
    for _, popupType in ipairs(self.CurrentOpenPopupList) do
        local uiName = self:GetPopupUiName(popupType)
        if uiName then
            table.insert(uiNames, uiName)
        end
    end
    if isReverse then
        table.reverse(uiNames)
    end
    return uiNames
end

-- 初始化弹框类型事务类型映射
function XTheatre4Model:InitPopupTypeTransactionType()
    self.PopupTypeTransactionType = {
        [XEnumConst.Theatre4.PopupType.RecruitMember] = XEnumConst.Theatre4.TransactionType.Recruit,
        [XEnumConst.Theatre4.PopupType.ItemSelect] = XEnumConst.Theatre4.TransactionType.Item,
        [XEnumConst.Theatre4.PopupType.RewardSelect] = XEnumConst.Theatre4.TransactionType.Reward,
        [XEnumConst.Theatre4.PopupType.FightReward] = XEnumConst.Theatre4.TransactionType.FightReward,
    }
end

-- 按弹出窗口类型获取交易类型
function XTheatre4Model:GetTransactionTypeByPopupType(popupType)
    if not self.PopupTypeTransactionType then
        self:InitPopupTypeTransactionType()
    end
    return self.PopupTypeTransactionType[popupType] or nil
end

-- 根据弹框类型入队弹框数据
function XTheatre4Model:EnqueuePopupData(popupType, ...)
    self.PopupData = self.PopupData or {}
    self.PopupData[popupType] = self.PopupData[popupType] or {}
    local args = { ... }
    if popupType == XEnumConst.Theatre4.PopupType.AssetReward then
        self:AddAssetRewardPopupData(popupType, args[1])
    end
    if popupType == XEnumConst.Theatre4.PopupType.TalentLevelUp then
        if args[1] then
            self:AddTalentLevelPopupData(popupType, args[2], args[3], args[4])
        else
            self:AddTalentIdsPopupData(popupType, args[2])
        end
    end
    if popupType == XEnumConst.Theatre4.PopupType.ArriveNewArea then
        self.PopupData[popupType] = { MapGroup = args[1], MapId = args[2] }
    end
    if popupType == XEnumConst.Theatre4.PopupType.BloodEffect then
        local popupData = self.PopupData[popupType]
        if args[1] then
            popupData.IsBoss = true
            popupData.MapId = args[2]
            popupData.PunishCountdown = args[3] or -1
        else
            popupData.IsHp = true
        end
    end
end

-- 添加资源奖励弹框数据
---@param rewards XTheatre4Asset[]
function XTheatre4Model:AddAssetRewardPopupData(popupType, rewards)
    if not rewards then
        return
    end
    local popupData = self.PopupData[popupType]
    for _, reward in pairs(rewards) do
        -- 过滤掉藏品箱和招募券
        if reward.Type == XEnumConst.Theatre4.AssetType.ItemBox or reward.Type == XEnumConst.Theatre4.AssetType.Recruit then
            goto continue
        end
        -- 过滤掉觉醒值
        if reward.Type == XEnumConst.Theatre4.AssetType.AwakeningPoint or 
            reward.Type == XEnumConst.Theatre4.AssetType.ColorCostPoint then
            if not XMVCA.XTheatre4:GetEffectRedBuyDeadAvailable() then
                goto continue
            end
        end
        local key = reward.Type .. "_" .. reward.Id
        if popupData[key] then
            popupData[key].Count = popupData[key].Count + reward.Num
        else
            popupData[key] = { Type = reward.Type, Id = reward.Id, Count = reward.Num }
        end
        :: continue ::
    end
end

-- 删除资源奖励弹框数据
function XTheatre4Model:RemoveAssetRewardPopupData(popupType, rewardId, rewardType)
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    local popupData = self.PopupData[popupType]
    local key = rewardType .. "_" .. rewardId

    if popupData[key] then
        popupData[key].Count = popupData[key].Count - 1
        if popupData[key].Count <= 0 then
            popupData[key] = nil
        end
    end
end

-- 添加天赋升级弹框数据
function XTheatre4Model:AddTalentLevelPopupData(popupType, color, newLevel, oldLevel)
    if not color then
        return
    end
    local popupData = self.PopupData[popupType]
    if popupData.Color and popupData.Color[color] then
        -- 保留老等级，更新新等级
        popupData.Color[color].NewLevel = newLevel
        return
    end
    popupData.Color = popupData.Color or {}
    popupData.Color[color] = popupData.Color[color] or {}
    popupData.Color[color].Color = color
    popupData.Color[color].NewLevel = newLevel
    popupData.Color[color].OldLevel = oldLevel
end

-- 添加天赋Id数据
function XTheatre4Model:AddTalentIdsPopupData(popupType, talentIds)
    if not talentIds then
        return
    end
    local popupData = self.PopupData[popupType]
    if not popupData.Color then
        return
    end
    popupData.TalentIds = popupData.TalentIds or {}
    for _, talentId in pairs(talentIds) do
        if XTool.IsNumberValid(talentId) and not table.contains(popupData.TalentIds, talentId) then
            table.insert(popupData.TalentIds, talentId)
        end
    end
end

-- 根据弹框类型出队弹框数据
function XTheatre4Model:DequeuePopupData(popupType)
    -- 事务类型弹框数据
    local transactionType = self:GetTransactionTypeByPopupType(popupType)
    if transactionType then
        return self:GetTransactionDataByType(transactionType)
    end
    -- 藏品替换弹框数据
    if popupType == XEnumConst.Theatre4.PopupType.ItemReplace then
        return self:GetItemReplacePopupData()
    end
    -- 天赋选择弹框数据
    if popupType == XEnumConst.Theatre4.PopupType.TalentSelect then
        return self:GetTalentPopupData()
    end
    -- 其他类型弹框数据
    if not self.PopupData or not self.PopupData[popupType] then
        return nil
    end
    if popupType == XEnumConst.Theatre4.PopupType.AssetReward
        or popupType == XEnumConst.Theatre4.PopupType.TalentLevelUp
        or popupType == XEnumConst.Theatre4.PopupType.ArriveNewArea
        or popupType == XEnumConst.Theatre4.PopupType.BloodEffect then
        local popupData = self.PopupData[popupType]
        self.PopupData[popupType] = nil
        return popupData
    end
    return nil
end

-- 获取藏品替换弹框数据
function XTheatre4Model:GetItemReplacePopupData()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetLastWaitItemId()
end

-- 获取天赋弹框数据
---@return { Color: number, TalentIds: number[] }
function XTheatre4Model:GetTalentPopupData()
    local adventureData = self:GetAdventureData()
    if not adventureData then
        return nil
    end
    local waitSlotData = adventureData:GetAllWaitSlotTalentIds()
    if XTool.IsTableEmpty(waitSlotData) then
        return nil
    end
    -- 只取一个
    return waitSlotData[1]
end

-- 检查弹框数据是否为空
function XTheatre4Model:CheckPopupDataEmpty(popupType)
    -- 事务类型弹框数据
    local transactionType = self:GetTransactionTypeByPopupType(popupType)
    if transactionType then
        return self:GetTransactionDataCountByType(transactionType) <= 0
    end
    -- 藏品替换弹框数据
    if popupType == XEnumConst.Theatre4.PopupType.ItemReplace then
        return self:GetItemReplacePopupData() <= 0
    end
    -- 天赋选择弹框数据
    if popupType == XEnumConst.Theatre4.PopupType.TalentSelect then
        return XTool.IsTableEmpty(self:GetTalentPopupData())
    end
    -- 其他类型弹框数据
    if not self.PopupData or not self.PopupData[popupType] then
        return true
    end
    return XTool.IsTableEmpty(self.PopupData[popupType])
end

-- 根据类型清空弹框数据
function XTheatre4Model:ClearPopupDataByType(popupType)
    if not self.PopupData then
        return
    end
    self.PopupData[popupType] = nil
end

-- 清空弹框数据
function XTheatre4Model:ClearAllPopupData()
    self.PopupData = nil
    self:ClearCurrentPopupType()
end

--endregion

--region 配置表数据转换

-- 初始化天赋等级
function XTheatre4Model:InitTalentLevel()
    if self.IsInitTalentLevel then
        return
    end
    local talentSlotConfigs = self:GetColorTalentSlotConfigs()
    for _, config in pairs(talentSlotConfigs) do
        if not self.ColorAndLevelToTalentSlotId[config.Color] then
            self.ColorAndLevelToTalentSlotId[config.Color] = {}
        end
        self.ColorAndLevelToTalentSlotId[config.Color][config.Level] = config.Id
    end
    self.IsInitTalentLevel = true
end

-- 获取天赋档位Id
function XTheatre4Model:GetTalentSlotIdByColorAndLevel(color, level)
    self:InitTalentLevel()
    return self.ColorAndLevelToTalentSlotId[color] and self.ColorAndLevelToTalentSlotId[color][level] or 0
end

-- 获取天赋档位等级列表
function XTheatre4Model:GetTalentSlotLevelListByColor(color)
    self:InitTalentLevel()
    return self.ColorAndLevelToTalentSlotId[color] or {}
end

-- 获取颜色天赋等级
function XTheatre4Model:GetColorTalentLevel(color, point)
    local levelToSlotIdList = self:GetTalentSlotLevelListByColor(color)
    local colorTalentLevel = 0
    for level, slotId in pairs(levelToSlotIdList) do
        local config = self:GetColorTalentSlotConfigById(slotId)
        if point >= config.UnlockPoint and level > colorTalentLevel then
            colorTalentLevel = level
        end
    end
    return colorTalentLevel
end

-- 获取颜色天赋解锁点数
function XTheatre4Model:GetColorTalentUnlockPoint(color, level)
    if not XTool.IsNumberValid(level) then
        return 0
    end
    local slotId = self:GetTalentSlotIdByColorAndLevel(color, level)
    local config = self:GetColorTalentSlotConfigById(slotId)
    if not config then
        XLog.Warning("[XTheatre4Model] 获取天赋解锁配置失败, slotId:", slotId)
    end
    return config and config.UnlockPoint or 0
end

-- 检查颜色天赋是否已满级
function XTheatre4Model:CheckColorTalentIsMaxLevel(color, curLevel)
    if not XTool.IsNumberValid(curLevel) then
        return false
    end
    local levelToSlotIdList = self:GetTalentSlotLevelListByColor(color)
    -- 获取最大等级
    local maxLevel = 0
    for level, _ in pairs(levelToSlotIdList) do
        if level > maxLevel then
            maxLevel = level
        end
    end
    return curLevel >= maxLevel
end

-- 初始化天赋关联
function XTheatre4Model:InitTalentRelated()
    if self.IsInitTalentRelated then
        return
    end
    local talentConfigs = self:GetColorTalentConfigs()
    for _, config in pairs(talentConfigs) do
        for _, relatedId in pairs(config.ParentNode) do
            if not self.TalentIdToRelatedTalentIds[relatedId] then
                self.TalentIdToRelatedTalentIds[relatedId] = {}
            end
            table.insert(self.TalentIdToRelatedTalentIds[relatedId], config.Id)
        end
    end
    self.IsInitTalentRelated = true
end

-- 获取关联天赋Ids
function XTheatre4Model:GetRelatedTalentIds(talentId)
    self:InitTalentRelated()
    return self.TalentIdToRelatedTalentIds[talentId] or {}
end

-- 初始化地图组
function XTheatre4Model:InitMapGroup()
    if self.IsInitMapGroup then
        return
    end
    local mapGroupConfigs = self:GetMapGroupConfigs()
    for _, config in pairs(mapGroupConfigs) do
        if XTool.IsNumberValid(config.Index) then
            self.MapGroupAndMapIdToIndex[config.MapGroup] = self.MapGroupAndMapIdToIndex[config.MapGroup] or {}
            self.MapGroupAndMapIdToIndex[config.MapGroup][config.MapId] = config
        end
    end
    self.IsInitMapGroup = true
end

-- 获取地图组和地图Id对应的Index
function XTheatre4Model:GetMapIndexByMapGroupAndMapId(mapGroup, mapId)
    self:InitMapGroup()
    local config = self.MapGroupAndMapIdToIndex[mapGroup] and self.MapGroupAndMapIdToIndex[mapGroup][mapId]
    if not config then
        return -1
    end
    return config.Index
end

function XTheatre4Model:GetMapGroupConfigByMapGroupAndMapId(mapGroup, mapId)
    self:InitMapGroup()
    local config = self.MapGroupAndMapIdToIndex[mapGroup] and self.MapGroupAndMapIdToIndex[mapGroup][mapId]
    return config
end

-- 初始化难度星级
function XTheatre4Model:InitDifficultyStar()
    if self.IsInitDifficultyStar then
        return
    end
    local difficultyStarConfigs = self:GetDifficultyStarConfigs()
    for _, config in pairs(difficultyStarConfigs) do
        self.GroupIdToDifficultyStarId[config.GroupId] = self.GroupIdToDifficultyStarId[config.GroupId] or {}
        table.insert(self.GroupIdToDifficultyStarId[config.GroupId], config.Id)
    end
    self.IsInitDifficultyStar = true
end

-- 获取难度星级Ids
---@param groupId number 组Id
function XTheatre4Model:GetDifficultyStarIds(groupId)
    self:InitDifficultyStar()
    local difficultyStarIds = self.GroupIdToDifficultyStarId[groupId] or {}
    -- 过滤条件不满足的星级
    difficultyStarIds = XTool.FilterList(difficultyStarIds, function(difficultyStarId)
        local conditionId = self:GetDifficultyStarConditionById(difficultyStarId) or 0
        return not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId)
    end)
    -- 排序
    table.sort(difficultyStarIds, function(a, b)
        return a < b
    end)
    return difficultyStarIds
end

--endregion

return XTheatre4Model
