---@class XRiftModel : XModel
---@field ActivityData XRiftActivity
---@field _NewLayerIdTrigger number 层结算后是否确认跳转到下一层
---@field _IsFirstPassChapterTrigger number 区域首通后是否弹提示
---@field _MaxLayerId number 最大层数
---@field _MaxUnLockFightLayerOrder number 当前解锁的最高层作战层
---@field _MaxPassFightLayerOrder number 当前通过的最高层作战层
---@field _LastStageIndex number 当前战斗的stage在父节点stageList的顺序下标
---@field _LastStageId number
---@field _CurrSelectStaegGroupData RiftStageGroupData 全局数据，最后一次点击过的关卡节点，用来作为进入战斗时传入的参数
local XRiftModel = XClass(XModel, "XRiftModel")

local TableKey = {
    RiftActivity = { CacheType = XConfigUtil.CacheType.Normal },
    RiftChapter = { CacheType = XConfigUtil.CacheType.Normal },
    RiftLayer = { CacheType = XConfigUtil.CacheType.Normal },
    RiftNodeRandomItem = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "GroupId" }, -- 关卡库
    RiftStage = { CacheType = XConfigUtil.CacheType.Normal },
    RiftMonsterBuffRandomItem = {}, -- 词缀库
    RiftCharacterAndRobot = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "RobotId", CacheType = XConfigUtil.CacheType.Normal },
    RiftTeamAttribute = { CacheType = XConfigUtil.CacheType.Normal }, -- 队伍加点表
    RiftTeamAttributeCost = { CacheType = XConfigUtil.CacheType.Normal }, -- 队伍加点消耗表
    RiftTeamAttributeEffect = {}, -- 队伍加点效果表
    RiftTeamAttributeEffectType = { DirPath = XConfigUtil.DirectoryType.Client }, -- 队伍加点效果类型表
    RiftPlugin = { CacheType = XConfigUtil.CacheType.Normal }, -- 插件表（这里不能用Temp 否则每次调用完就会销毁 然后再次调用再次加载 这个表有300Kb）
    RiftPluginAttrFix = { CacheType = XConfigUtil.CacheType.Normal }, -- 插件补正表
    RiftPluginQuality = { DirPath = XConfigUtil.DirectoryType.Client }, -- 插件品质表
    RiftTask = { DirPath = XConfigUtil.DirectoryType.Client }, -- 任务表
    RiftLayerDetail = { DirPath = XConfigUtil.DirectoryType.Client },
    RiftFuncUnlock = { CacheType = XConfigUtil.CacheType.Normal }, -- 功能解锁表
    RiftShop = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal }, -- 商店表
    RiftSystemAttributeEffectType = { DirPath = XConfigUtil.DirectoryType.Client },
    RiftFilterTag = {},
    RiftClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    RiftOneKeyEquip = {},
    RiftCollectAttributeEffect = { CacheType = XConfigUtil.CacheType.Normal },
    -- 由工具生成的自定义表
    RiftPluginGroupToFixAttr = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "GroupId" },
    RiftSystemEffectTypeMap = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SystemEffectType" },
    RiftAttributeGroupMap = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "GroupId" },
    RiftChapterPluginShow = { DirPath = XConfigUtil.DirectoryType.Client },
    RiftStory = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client },
    RiftRandomAffix = {}, -- 插件随机词缀表
    RiftPluginWords = { DirPath = XConfigUtil.DirectoryType.Client },
}

function XRiftModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fuben/Rift", TableKey)
end

function XRiftModel:ClearPrivate()
    self._OneKeyRecommend = nil
    self._LayerIdChapterMap = nil
    self._RobotDic = nil
    self._SystemAttrAttrIdDic = nil
    self._SystemAttrsDic = nil
    self._PluginShopGoodList = nil
    self._HandbookEffectMap = nil
    self._NodeRandomItemMap = nil
    self._RandomAffixLvMap = nil
    self._ChapterStoryMap = nil
end

function XRiftModel:ResetAll()
    self.ActivityData = nil
    self._MaxPassFightLayerOrder = 0
    self._MaxUnLockFightLayerOrder = 0
    self._NewLayerIdTrigger = nil
    self._IsFirstPassChapterTrigger = nil
    self._LastStageIndex = nil
    self._LastStageId = nil
    self._CurrSelectStaegGroupData = nil
    self._AutoOpenChapterDetail = nil
end

----------public start----------

--region 活动

function XRiftModel:GetMaxChapterId()
    if not self._MaxChapterId then
        local configs = self:GetChapterConfigs()
        self._MaxChapterId = configs[#configs].Id
    end
    return self._MaxChapterId
end

function XRiftModel:IsFuncUnlock(unlockCfgId)
    local funcUnlockCfg = self:GetFuncUnlockById(unlockCfgId)
    local isOpen = true
    if XTool.IsNumberValid(funcUnlockCfg.Condition) then
        isOpen = XConditionManager.CheckCondition(funcUnlockCfg.Condition)
    end
    return isOpen, funcUnlockCfg.Desc
end

-- 活动主界面长动效只会在从活动外进入时播放 战斗结束后返回不播 所以这里使用一个引用类型作为参数
function XRiftModel:GetMainPanelParem()
    if not self._MainParam then
        self._MainParam = {}
    end
    self._MainParam.IsPlayScreenTween = true
    return self._MainParam
end

--endregion

--region 插件

function XRiftModel:GetOwnPluginIds()
    return self.ActivityData:GetOwnPluginIds()
end

function XRiftModel:UnlockedPluginByDrop(pluginDropRecords)
    if XTool.IsTableEmpty(pluginDropRecords) then
        return
    end
    local isRed = false
    for _, dropPlugin in ipairs(pluginDropRecords) do
        local xPluginDrop = self:GetRiftPluginConfigById(dropPlugin.PluginId)
        -- 1 先检测生成蓝点
        local charId = xPluginDrop.CharacterId
        if dropPlugin.DecomposeCount <= 0 and XTool.IsNumberValid(charId) then
            -- 通用插件不会显示蓝点,已获得的插件也不会显示蓝点
            isRed = true
        end
        -- 2 再设置掉落获取
        self.ActivityData:SetPluginHave(dropPlugin.PluginId)
    end
    if isRed then
        self:SetCharacterRedPoint(true)
    end
end

---通过类型获取已拥有的能穿戴的最高级插件
function XRiftModel:GetPluginByType(pluginType, residue)
    ---@type XTableRiftPlugin[]
    local sameTypePlugins = {}
    local ownPluginIds = self.ActivityData:GetOwnPluginIds()
    if not XTool.IsTableEmpty(ownPluginIds) then
        for pluginId, _ in pairs(ownPluginIds) do
            local plugin = self:GetRiftPluginConfigById(pluginId)
            if plugin.Type == pluginType then
                table.insert(sameTypePlugins, plugin)
            end
        end
    end

    table.sort(sameTypePlugins, function(a, b)
        return a.Quality > b.Quality
    end)

    for _, v in pairs(sameTypePlugins) do
        local num = residue - v.Load
        if num >= 0 then
            return v.Id, num
        end
    end
    return nil, residue
end

function XRiftModel:SaveFilterSertting(setting, data)
    if not self._PluginFilterSetting then
        self._PluginFilterSetting = {}
    end
    self._PluginFilterSetting[setting] = data or {}
end

function XRiftModel:GetFilterSertting(setting)
    return self._PluginFilterSetting and self._PluginFilterSetting[setting] or {}
end

---@return XTableRiftOneKeyEquip[]
function XRiftModel:GetRecommendSetting(characterId)
    if not self._OneKeyRecommend then
        self._OneKeyRecommend = {}
    end
    if not self._OneKeyRecommend[characterId] then
        local data = {}
        local configs = self:GetRiftOneKeyEquipConfigs()
        for _, v in pairs(configs) do
            if v.CharacterId == characterId then
                table.insert(data, v)
            end
        end
        table.sort(data, function(a, b)
            return a.Sort < b.Sort
        end)
        self._OneKeyRecommend[characterId] = data
    end
    return self._OneKeyRecommend[characterId]
end

---@param role XBaseRole
function XRiftModel:GetCurrentLoad(role)
    local load = 0
    local pluginIds = self:GetRolePlugInIdList(role)
    if pluginIds then
        for _, pluginId in pairs(pluginIds) do
            local plugin = self:GetRiftPluginConfigById(pluginId)
            load = load + plugin.Load
        end
    end
    return load
end

---@param role XBaseRole
function XRiftModel:GetRolePlugInIdList(role)
    return self.ActivityData:GetCharacterPluginData(role:GetId())
end

function XRiftModel:IsHavePlugin(pluginId)
    return self.ActivityData:IsHavePlugin(pluginId)
end

---获取插件总的战力值 不传属性加点模板xAttrTemplate，则用默认的
function XRiftModel:GetPluginAbility(pluginId, xAttrTemplate)
    local plugin = self:GetRiftPluginConfigById(pluginId)
    local ability = plugin.Ability
    local attrFixCfgList = self:GetAttrFixConfigList(pluginId, xAttrTemplate)
    for _, attrFixCfg in ipairs(attrFixCfgList) do
        ability = ability + attrFixCfg.Ability
    end
    return ability
end

---获取补正的configList（根据当前默认加点模板属性值） 不传属性加点模板xAttrTemplate，则用默认的
---@return XTableRiftPluginAttrFix[]
function XRiftModel:GetAttrFixConfigList(pluginId, xAttrTemplate)
    if xAttrTemplate == nil then
        xAttrTemplate = self:GetAttrTemplate(XEnumConst.Rift.DefaultAttrTemplateId)
    end
    local attrFixCfgList = {}
    local plugin = self:GetRiftPluginConfigById(pluginId)
    for _, groupId in ipairs(plugin.AttrFixGroupIds) do
        local attrId = self:GetRiftPluginGroupToFixAttrById(groupId)
        local attrLevel = xAttrTemplate:GetAttrLevel(attrId)
        local attrFixCfg = self:GetPluginAttrFixConfig(groupId, attrLevel)
        table.insert(attrFixCfgList, attrFixCfg)
    end

    return attrFixCfgList
end

---插件补正配置多个groupId，每个groupId只受一种属性加成影响，以当前加点方案该属性点值 组成唯一的key
---@return XTableRiftPluginAttrFix
function XRiftModel:GetPluginAttrFixConfig(groupId, fixAttrLevel)
    local id = groupId * 1000 + fixAttrLevel -- 利用新导表工具导出的特殊表
    return self:GetRiftPluginAttrFixById(id)
end

function XRiftModel:GetPluginCount(star)
    local cur, all = 0, 0
    local configs = self:GetRiftPluginConfigs()
    for _, plugin in pairs(configs) do
        if plugin.IsDisplay ~= 1 and (not star or plugin.Star == star) then
            all = all + 1
            if self:IsHavePlugin(plugin.Id) then
                cur = cur + 1
            end
        end
    end
    return cur, all
end

function XRiftModel:GetRandomAffixMaxLevel(type)
    if not self._RandomAffixLvMap then
        self._RandomAffixLvMap = {}
        for _, cfg in pairs(self:GetRandomAffixConfigs()) do
            if not self._RandomAffixLvMap[cfg.Type] or self._RandomAffixLvMap[cfg.Type] < cfg.Level then
                self._RandomAffixLvMap[cfg.Type] = cfg.Level
            end
        end
    end
    return self._RandomAffixLvMap[type]
end

--endregion

--region 结算

function XRiftModel:UpdateChapterData(chapterData)
    self.ActivityData:UpdateChapterData(chapterData)
    self:UpdateChapterState()
end

function XRiftModel:UpdateLuckyReward(winData)
    local riftSettleResult = winData.SettleData.RiftSettleResult
    self:UpdateChapterData(riftSettleResult.ChapterData)
    self.ActivityData:SetLuckPassTime(riftSettleResult.PassTime)
    -- 记录插件掉落
    self.ActivityData:AddFightLayerDropPlugin(self.ActivityData.LayerId, riftSettleResult.PluginDropRecords)
end

---@return number,number 下一个节点（现在其实都是单节点）,同个节点里的下一个关卡
function XRiftModel:UpdateReward(winData)
    local riftSettleResult = winData.SettleData.RiftSettleResult
    -- 刷新当前Stage的信息
    self.ActivityData:UpdateStagePass(self.ActivityData.LayerId, self._LastStageIndex, true, riftSettleResult.PassTime, riftSettleResult.Wave)
    -- 刷新战斗结算后的区域信息
    self:UpdateChapterData(riftSettleResult.ChapterData)
    -- 记录当前层累计的插件掉落
    self.ActivityData:AddFightLayerDropPlugin(self.ActivityData.LayerId, riftSettleResult.PluginDropRecords)
end

function XRiftModel:UpdateLose(loseData)
    self.ActivityData:UpdateStagePass(self.ActivityData.LayerId, self._LastStageIndex, false, loseData.PassTime, loseData.Wave)
end

--endregion

--region 关卡

function XRiftModel:CheckChapterUnlock(chapterId)
    local layerId = self:GetLayerIdsByChapterId(chapterId)[1]
    return self:GetMaxUnLockFightLayerOrder() >= layerId
end

---关卡是否首次通关 [关卡可以重复挑战 可能通关后再次挑战 关卡状态变成了未通过]
function XRiftModel:CheckLayerFirstPassed(layerId)
    local order = self:GetLayerConfigById(layerId).Order
    return self:GetMaxPassFightLayerOrder() >= order
end

function XRiftModel:CheckLayerPassed(layerId)
    local data = self.ActivityData:GetFightLayerDataById(layerId)
    for _, stage in pairs(data.StageGroup.StageDatas) do
        if not stage.IsPassed then
            return false
        end
    end
    return true
end

---@param xTeam XRiftTeam
function XRiftModel:EnterFight(xTeam)
    local CurrSelectStageGroup = self:GetCurrSelectRiftStageGroup()
    local layerId = CurrSelectStageGroup.FightLayerId
    if not xTeam then
        -- 如果没传xteam，则根据上一次点击的stageGroup，判断当前层类型，选择对应的队伍自动进入该stageGroup的第一个stage
        xTeam = self.ActivityData:GetSingleTeamData()
    end
    local layerConfig = self:GetLayerConfigById(layerId)
    if layerConfig.Order > self:GetMaxUnLockFightLayerOrder() then
        if layerConfig.ChapterId >= self:GetMaxChapterId() then
            XUiManager.TipError(XUiHelper.GetText("RiftFightError1"))
        else
            XUiManager.TipError(XUiHelper.GetText("RiftFightError2"))
        end
        return
    end

    local index = math.abs(xTeam:GetId()) --由于单关卡的队伍id是-1，但是它仅有1个关卡，所以如果是-1也传1

    if xTeam:IsLuckyStage() then
        self._LastStageIndex = nil
        self._LastStageId = XMVCA.XRift:GetLuckStageId()
        self._IsLoseGenericSettle = true
    else
        self._LastStageIndex = index
        self._LastStageId = self:GetStageIdByStageGroup(CurrSelectStageGroup, index)
        self._IsLoseGenericSettle = layerConfig.Type == XEnumConst.Rift.LayerType.Challenge
    end

    self.CurFightCharCount = xTeam:GetEntityCount()
    self:SaveFirstEnter(layerId)
    XDataCenter.FubenManager.EnterRiftFight(xTeam, CurrSelectStageGroup, index)
end

---@param stageGroupData RiftStageGroupData
function XRiftModel:GetStageIdByStageGroup(stageGroupData, index)
    local stageData = stageGroupData.StageDatas[index]
    local stageConfig = self:GetStageConfigById(stageData.RiftStageId)
    return stageConfig.StageId
end

function XRiftModel:GetCurrFightLayerId()
    return self.ActivityData.LayerId
end

function XRiftModel:GetCurrStageId()
    return self._LastStageId
end

function XRiftModel:IsLoseGenericSettle()
    return self._IsLoseGenericSettle
end

---@param xStageGroup XRiftStageGroup
function XRiftModel:SetCurrSelectRiftStage(xStageGroup)
    if xStageGroup then
        self._CurrSelectStaegGroupData = self.ActivityData:GetStageGroupByLayerId(xStageGroup:GetParent():GetFightLayerId())
    else
        self._CurrSelectStaegGroupData = nil
    end
end

function XRiftModel:GetCurrSelectRiftStageGroup()
    return self._CurrSelectStaegGroupData
end

function XRiftModel:GetMaxLayerId()
    if not self._MaxLayerId then
        local configs = self:GetLayerConfigs()
        self._MaxLayerId = configs[#configs].Id
    end
    return self._MaxLayerId
end

-- 获取章节所属所有层
function XRiftModel:GetLayerIdsByChapterId(chapterId)
    if not self._LayerIdChapterMap then
        self._LayerIdChapterMap = {}
        ---@type XTableRiftLayer[]
        local configs = self:GetLayerConfigs()
        for _, v in pairs(configs) do
            if not self._LayerIdChapterMap[v.ChapterId] then
                self._LayerIdChapterMap[v.ChapterId] = {}
            end
            table.insert(self._LayerIdChapterMap[v.ChapterId], v.Id)
        end
    end
    return self._LayerIdChapterMap[chapterId]
end

function XRiftModel:UpdateChapterState()
    -- 【已解锁】和【通关】的作战层
    local num = 0
    local maxPassOrder = 0
    local maxUnlockOrder = 0
    for _, chapter in pairs(self.ActivityData:GetChapterDatas()) do
        num = num + 1
        maxUnlockOrder = chapter.UnlockedLayerOrderMax > maxUnlockOrder and chapter.UnlockedLayerOrderMax or maxUnlockOrder
        maxPassOrder = chapter.PassedLayerOrderMax > maxPassOrder and chapter.PassedLayerOrderMax or maxPassOrder
    end
    -- 对unlock【已解锁】做特殊处理，因为当A区域完成所有作战层后下发同步的数据，服务器是不会下发下一区域的unlock的信息的，因此必须检查前置区域是否全部通关来设置下一关区域的第一个作战层解锁
    for i = num, 1, -1 do
        local currChapterLastLayerId = self:GetChapterConfigById(i).UnlockLayerId
        -- 进入这个判断说明, 当前区域已全部通关, 且该区域是全部通关区域的最高区域。如果还有下一区域，需要设置下一区域的第一个作战层为已解锁状态
        if i < num and maxPassOrder == currChapterLastLayerId then
            local nextChapter = self:GetChapterConfigById(i + 1)
            if nextChapter then
                maxUnlockOrder = currChapterLastLayerId + 1
            end
            break
        end
    end
    self._MaxUnLockFightLayerOrder = maxUnlockOrder
    self._MaxPassFightLayerOrder = maxPassOrder
end

function XRiftModel:GetMaxUnLockFightLayerOrder()
    return self._MaxUnLockFightLayerOrder or 0
end

function XRiftModel:GetMaxPassFightLayerOrder()
    return self._MaxPassFightLayerOrder or 0
end

---【保存】首次进入(跃升领奖也调用一次，功能相似)
function XRiftModel:SaveFirstEnter(layerId)
    local key = "RiftFightLayer" .. XPlayer.Id .. layerId
    XSaveTool.SaveData(key, true)
end

function XRiftModel:SetAutoOpenChapterDetail(chapterId)
    self._AutoOpenChapterDetail = chapterId
end

function XRiftModel:GetAutoOpenChapterDetail()
    return self._AutoOpenChapterDetail
end

--endregion

--region 触发

--(Trigger)触发后关闭
function XRiftModel:GetIsNewLayerIdTrigger()
    if self._NewLayerIdTrigger then
        local tempId = self._NewLayerIdTrigger
        self._NewLayerIdTrigger = nil
        return tempId
    end
end

function XRiftModel:SetNewLayerTrigger(newFightLayerId)
    self._NewLayerIdTrigger = newFightLayerId
end

--(Trigger)触发后关闭
function XRiftModel:GetIsFirstPassChapterTrigger()
    if self._IsFirstPassChapterTrigger then
        local tempId = self._IsFirstPassChapterTrigger
        self._IsFirstPassChapterTrigger = nil
        return tempId
    end
end

function XRiftModel:SetFirstPassChapterTrigger(fightLayerId)
    self._IsFirstPassChapterTrigger = fightLayerId
end

---设置每日提示
function XRiftModel:SetDayTip(isSelect)
    local key = "RiftDayTipLuckValue" .. XPlayer.Id
    if not isSelect then
        XSaveTool.RemoveData(key)
    else
        local updateTime = XTime.GetSeverTomorrowFreshTime()
        XSaveTool.SaveData(key, updateTime)
    end
end

---今天是否可以弹每日提示
function XRiftModel:GetIsNewDayUpdate()
    local key = "RiftDayTipLuckValue" .. XPlayer.Id
    local data = XSaveTool.GetData(key)
    if not data then
        return true
    end
    return data ~= XTime.GetSeverTomorrowFreshTime()
end

--endregion

--region 编队

---检查该队伍是否有关卡进度
function XRiftModel:CheckRoleInMultiTeamLock(xTeam)
    if not xTeam or not self._CurrSelectStaegGroupData then
        return
    end
    if XTool.IsTableEmpty(self._CurrSelectStaegGroupData.StageDatas) then
        -- 没有战斗数据
        return false
    end
    local index = xTeam:GetId()
    local stage = self._CurrSelectStaegGroupData.StageDatas[index]
    if stage then
        return stage.IsPassed
    end
    return false
end

---@return XRobot[]
function XRiftModel:GetRobot()
    if not self._RobotDic then
        self._RobotDic = {}
        local configs = self:GetRiftCharacterAndRobotConfigs()
        for _, v in pairs(configs) do
            table.insert(self._RobotDic, XRobotManager.GetRobotById(v.RobotId))
        end
    end
    return self._RobotDic
end

---@param role XBaseRole
function XRiftModel:GetFinalShowAbility(role)
    if not role then
        return 0
    end
    local orgAbility = role:GetAbility() --角色初始战力
    local pluginAbility = 0 -- 插件加成战力
    local pluginIds = self:GetRolePlugInIdList(role)
    if pluginIds then
        for _, pluginId in pairs(pluginIds) do
            pluginAbility = pluginAbility + self:GetPluginAbility(pluginId) --插件基础战力
        end
    end
    local xAttrTemplate = self:GetAttrTemplate(XEnumConst.Rift.DefaultAttrTemplateId)
    return orgAbility + pluginAbility + self:GetAbility(xAttrTemplate)
end

---@return XCharacter|XRobot
function XRiftModel:GetRoleData(entityId)
    if not XTool.IsNumberValid(entityId) then
        return nil
    end
    -- 自有机
    local owner = XMVCA.XCharacter:GetCharacter(entityId)
    if owner then
        return owner
    end
    -- 机器人
    local config = self:GetRiftCharacterAndRobotById(entityId)
    if config then
        return require("XEntity/XRobot/XRobot").New(entityId)
    else
        XLog.Error("大秘境未找到该角色：" .. entityId)
        return nil
    end
end

--endregion

--region 加点

---@return XRiftAttributeTemplate
function XRiftModel:GetAttrTemplate(id)
    return self.ActivityData:GetAttrTemplate(id)
end

function XRiftModel:GetAttributeCost(attrLevel)
    local totalAttrLevel = self.ActivityData:GetTotalAttrLevel()
    if attrLevel <= totalAttrLevel then
        return 0
    end
    local cost = 0
    local configs = self:GetRiftTeamAttributeCostConfigs()
    for i = totalAttrLevel + 1, attrLevel do
        local config = configs[i]
        if config then
            cost = cost + config.Cost
        end
    end
    return cost
end

---获取可预览加点的总等级:当前已购买等级 + 可购买等级
function XRiftModel:GetCanPreviewAttrAllLevel()
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    local attrIndex = self.ActivityData:GetTotalAttrLevel()
    local const = 0
    local configs = self:GetRiftTeamAttributeCostConfigs()
    while (true) do
        local nextIndex = attrIndex + 1
        local config = configs[nextIndex]
        if config and (ownCnt >= const + config.Cost) then
            const = const + config.Cost
            attrIndex = nextIndex
        else
            break
        end
    end
    return attrIndex
end

function XRiftModel:IsAttributeCanBuy()
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    local nextAttrLevel = self.ActivityData:GetTotalAttrLevel() + 1
    local maxLevel = self.ActivityData:GetAttrLevelMax() * 4
    if nextAttrLevel > maxLevel then
        return false
    end
    local configs = self:GetRiftTeamAttributeCostConfigs()
    local config = configs[nextAttrLevel]
    return config and (ownCnt >= config.Cost)
end

---获取系统属性（XEnumConst.Rift.SystemBuffType）对应的组Id
function XRiftModel:GetGroupIdBySystemAttr(systemAttr)
    return self:GetRiftSystemEffectTypeMapById(systemAttr).GroupId
end

function XRiftModel:GetAttributeEffectConfig(groupId, level)
    local id = groupId * 1000 + level -- 利用新导表工具导出的特殊表
    return self:GetRiftTeamAttributeEffectById(id)
end

function XRiftModel:GetSystemAttr(groupId)
    if not self._SystemAttrsDic then
        self._SystemAttrsDic = {}
    end
    local data = self._SystemAttrsDic[groupId]
    if not data then
        local config = self:GetRiftAttributeGroupMapById(groupId)
        data = {}
        data.Config = self:GetSystemAttributeEffectConfigById(config.SystemEffectType)
        data.Values = {}
        for i = 1, #config.SystemEffectParam do
            data.Values[config.SystemEffectParam[i]] = config.MaxLevel[i]
        end
        self._SystemAttrsDic[groupId] = data
    end
    return data
end

function XRiftModel:GetAttrGroupId(attrId)
    return self:GetTeamAttributeByAttrId(attrId).EffectGroupIds
end

---@param attrTemplate XRiftAttributeTemplate
function XRiftModel:GetEffectList(attrTemplate)
    local effectCfgList = self:GetEffectCfgList(attrTemplate)

    -- 读取效果属性详情
    local effectList = {}
    for _, effectCfg in ipairs(effectCfgList) do
        local showValue = effectCfg.EffectValue
        if showValue > 0 then
            local isPercent
            if effectCfg.PropType == XEnumConst.Rift.PropType.Battle then
                local effectTypeCfg = self:GetTeamAttributeEffectConfigById(effectCfg.EffectType)
                isPercent = effectTypeCfg.ShowType == XEnumConst.Rift.AttributeFixEffectType.Percent
            elseif effectCfg.PropType == XEnumConst.Rift.PropType.System then
                local effectTypeCfg = self:GetSystemAttributeEffectConfigById(effectCfg.EffectType)
                isPercent = effectTypeCfg.ShowType == XEnumConst.Rift.AttributeFixEffectType.Percent
            end
            if isPercent then
                showValue = string.format("%.1f", effectCfg.EffectValue / 100)
                showValue = self:FormatNum(showValue)
            end
            local effect = { EffectType = effectCfg.EffectType, EffectValue = showValue, PropType = effectCfg.PropType }
            table.insert(effectList, effect)
        end
    end
    return effectList
end

---@param attrTemplate XRiftAttributeTemplate
function XRiftModel:GetEffectCfgList(attrTemplate)
    local effectCfgList = {}
    for _, attr in ipairs(attrTemplate.AttrList) do
        if attr.Level > 0 then
            local effectGroupIds = self:GetAttrGroupId(attr.Id)
            for _, groupId in ipairs(effectGroupIds) do
                local effectCfg = self:GetAttributeEffectConfig(groupId, attr.Level)
                local battleData = {}
                battleData.PropType = XEnumConst.Rift.PropType.Battle
                battleData.EffectType = effectCfg.EffectType
                battleData.EffectValue = effectCfg.EffectValue
                battleData.Ability = effectCfg.Ability
                table.insert(effectCfgList, battleData)

                if XTool.IsNumberValid(effectCfg.SystemEffectType) then
                    local sysData = {}
                    sysData.PropType = XEnumConst.Rift.PropType.System
                    sysData.EffectType = effectCfg.SystemEffectType
                    sysData.EffectValue = self:GetSystemAttrValue(effectCfg.SystemEffectType, attr.Level)
                    sysData.Ability = 0
                    table.insert(effectCfgList, sysData)
                end
            end
        end
    end
    return effectCfgList
end

function XRiftModel:GetSystemAttrValue(id, level)
    local groupId = self:GetGroupIdBySystemAttr(id)
    local config = self:GetAttributeEffectConfig(groupId, level)
    return config.SystemEffectParam
end

-- 小数如果为0，则去掉
function XRiftModel:FormatNum(num)
    num = tonumber(num)
    local t1, t2 = math.modf(num)
    if t2 > 0 then
        return num
    else
        return t1
    end
end

---@param attrTemplate XRiftAttributeTemplate
function XRiftModel:UpdateAttrSet(attrTemplate, attrList)
    -- 更新本地模板
    self.ActivityData:UpdateAttrSet(attrTemplate.Id, attrList, attrTemplate.CustomName)
    -- 更新已购买点数
    local allLevel = attrTemplate:GetAllLevel()
    if allLevel > self.ActivityData:GetTotalAttrLevel() then
        self.ActivityData:SetTotalAttrLevel(allLevel)
    end
end

---@param attrTemplate XRiftAttributeTemplate
function XRiftModel:GetAbility(attrTemplate)
    local effectCfgList = self:GetEffectCfgList(attrTemplate)
    local allAbility = 0
    for _, effectCfg in ipairs(effectCfgList) do
        allAbility = allAbility + effectCfg.Ability
    end
    return allAbility
end

--endregion

--region 图鉴

---@return table<number, XTableRiftCollectAttributeEffect>
function XRiftModel:GetHandbookEffect(star)
    if not self._HandbookEffectMap then
        self:InitHandbookEffect()
    end
    return self._HandbookEffectMap[star] or {}
end

function XRiftModel:InitHandbookEffect()
    self._HandbookEffectMap = {}
    ---@type XTableRiftCollectAttributeEffect[]
    local configs = self._ConfigUtil:GetByTableKey(TableKey.RiftCollectAttributeEffect)
    for _, v in pairs(configs) do
        for _, condition in pairs(v.ConditionIds) do
            local temp = XConditionManager.GetConditionTemplate(condition)
            if temp.Type == XEnumConst.Rift.StarConditionType then
                local star = temp.Params[1]
                local count = temp.Params[2]
                if not self._HandbookEffectMap[star] then
                    self._HandbookEffectMap[star] = {}
                end
                table.insert(self._HandbookEffectMap[star], { Count = count, Config = v })
            end
        end
    end
    for _, map in ipairs(self._HandbookEffectMap) do
        table.sort(map, function(a, b)
            return a.Count < b.Count
        end)
    end
end

---@return XTableRiftCollectAttributeEffect[]
function XRiftModel:GetHandbookTakeEffectList()
    local datas = {}
    ---@type XTableRiftCollectAttributeEffect[]
    local configs = self._ConfigUtil:GetByTableKey(TableKey.RiftCollectAttributeEffect)
    for _, v in pairs(configs) do
        local isTakeEffect = true
        for _, condition in pairs(v.ConditionIds) do
            if not XConditionManager.CheckCondition(condition) then
                isTakeEffect = false
                break
            end
        end
        if isTakeEffect then
            if not datas[v.Attr] then
                datas[v.Attr] = v.Value
            else
                datas[v.Attr] = v.Value + datas[v.Attr]
            end
        end
    end
    local results = {}
    for attrId, value in pairs(datas) do
        table.insert(results, { AttrId = attrId, Value = value })
    end
    table.sort(results, function(a, b)
        local aAttr = self:GetTeamAttributeEffectConfigById(a.AttrId)
        local bAttr = self:GetTeamAttributeEffectConfigById(b.AttrId)
        return aAttr.Order < bAttr.Order
    end)
    return results
end

--endregion

--region 幸运关

function XRiftModel:GetLuckStageId()
    local riftStageId = self.ActivityData:GetLuckRiftStageId()
    if XTool.IsNumberValid(riftStageId) then
        return self:GetStageConfigById(riftStageId).StageId
    end
    -- 开始战斗前服务端不会下发
    local maxPass = self:GetMaxPassFightLayerOrder()
    local layer = self:GetLayerConfigById(maxPass)
    return self:GetLuckyStageIdByGroupId(layer.LuckyNodeRandomGroupId)
end

-- 幸运关比较特殊
function XRiftModel:GetLuckyStageIdByGroupId(groupId)
    local config = self:GetRiftNodeRandomItemById(groupId)
    return config.RiftStageId
end

--endregion

--region 红点

---检查所有任务是否有奖励可领取
function XRiftModel:CheckTaskCanReward()
    local activity = self:GetActivityById(self.ActivityData.ActivityId)
    if activity and activity.TaskGroupId then
        for _, groupId in pairs(activity.TaskGroupId) do
            if XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
                return true
            end
        end
    end
    --local groupId = activity.SeasonTaskGroupId
    --if XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
    --    return true
    --end
    return false
end

---是否显示购买属性红点
function XRiftModel:IsBuyAttrRed()
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    local recordCnt = XSaveTool.GetData(self:GetBuyAttrRedSaveKey())
    if recordCnt == nil or ownCnt > recordCnt then
        return self:IsAttributeCanBuy()
    elseif ownCnt < recordCnt then
        self:CloseBuyAttrRed()
    end
    return false
end

---关闭购买属性红点
function XRiftModel:CloseBuyAttrRed()
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    XSaveTool.SaveData(self:GetBuyAttrRedSaveKey(), ownCnt)
end

function XRiftModel:GetBuyAttrRedSaveKey()
    return XPlayer.Id .. "_XRiftManager_BuyAttrRed_Key"
end

function XRiftModel:CheckIsHasFightLayerRedPoint()
    local configs = self:GetLayerConfigs()
    for _, config in pairs(configs) do
        if config.Order <= self:GetMaxUnLockFightLayerOrder() and not self:CheckHadFightLayerFirstEntered(config.Id) then
            return true
        end
    end
    return false
end

function XRiftModel:CheckHadFightLayerFirstEntered(layerId)
    local key = "RiftFightLayer" .. XPlayer.Id .. layerId
    return XSaveTool.GetData(key)
end

---有足够加一级的货币and至少一个属性的加点没有达到上限
function XRiftModel:IsMemberAddPointRed()
    local template = self:GetAttrTemplate(XEnumConst.Rift.DefaultAttrTemplateId)
    local attrLevelMax = 0
    local totalLevel = 0
    for attrId = 1, 4 do
        totalLevel = totalLevel + template:GetAttrLevel(attrId)
        attrLevelMax = attrLevelMax + self.ActivityData:GetAttrLevelMax()
    end
    if totalLevel >= attrLevelMax then
        return false
    end
    local const = self:GetAttributeCost(totalLevel)
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    local goldEnough = ownCnt >= const
    local buyAttrLevel = self.ActivityData:GetTotalAttrLevel()
    if totalLevel == buyAttrLevel then
        local nextLvCost = self:GetAttributeCost(buyAttrLevel + 1)
        if nextLvCost > 0 then
            goldEnough = ownCnt >= nextLvCost
        end
    end
    return goldEnough
end

function XRiftModel:SetCharacterRedPoint(isRed)
    self._IsCharacterRedPoint = isRed
end

function XRiftModel:GetCharacterRedPoint()
    return self._IsCharacterRedPoint
end

--endregion

--region 剧情

---@return XTableRiftStory[]
function XRiftModel:GetChapterStory(id)
    if not self._ChapterStoryMap then
        self._ChapterStoryMap = {}
        local storys = self:GetRiftStoryConfigs()
        for _, v in pairs(storys) do
            if not self._ChapterStoryMap[v.Chapter] then
                self._ChapterStoryMap[v.Chapter] = {}
            end
            table.insert(self._ChapterStoryMap[v.Chapter], v)
        end
    end
    return self._ChapterStoryMap[id]
end

--endregion

--region 客户端配置

---获取Client路径下的Config配置信息
function XRiftModel:GetClientConfig(key, index)
    index = index or 1
    ---@type XTableRiftClientConfig
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftClientConfig, key)
    if not config then
        return ""
    end
    return config.Values and config.Values[index] or ""
end

function XRiftModel:GetPluginShowBg(quality)
    return self:GetClientConfig("PluginQualityBg", quality)
end

---获取角色专属标签Id
function XRiftModel:GetCharacterExclusiveTagId()
    return tonumber(self:GetClientConfig("CharacterExclusiveTagId"))
end

--endregion

----------public end----------

----------private start----------

function XRiftModel:NotifyRiftData(data)
    if not data or not XTool.IsNumberValid(data.ActivityId) then
        return
    end
    local activity = self:GetActivityById(data.ActivityId)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XRift/XEntity/XRiftActivity").New()
    end
    self.ActivityData:NotifyRiftData(data, activity.AttrLevelSetCount)
    self:UpdateChapterState()
    XEventManager.DispatchEvent(XEventId.EVENT_RIFT_DATA_UPDATE)
end

function XRiftModel:NotifyRiftNewPlugin(data)
    self.ActivityData:UnlockedPlugin(data)
end

function XRiftModel:NotifyRiftPluginPeakLoadChanged(data)
    self.ActivityData:UpdateMaxLoad(data)
end

function XRiftModel:NotifyRiftAttrLevelMaxChanged(data)
    self.ActivityData:UpdateAttrLevelMax(data)
end

function XRiftModel:NotifyRiftDailyReset(data)
    self.ActivityData:UpdateSweepTimes(data)
end

function XRiftModel:NotifyRiftAffixUpdate(data)
    self.ActivityData:UpdateAffix(data.PluginId, data.Slot, data.AffixId)
    XEventManager.DispatchEvent(XEventId.EVENT_RIFT_PLUGIN_AFFIX_UPDATE)
end

----------private end----------

----------config start----------

---@return XTableRiftActivity
function XRiftModel:GetActivityById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftActivity, id)
end

---@return XTableRiftFuncUnlock
function XRiftModel:GetFuncUnlockById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftFuncUnlock, id)
end

---@return XTableRiftTask
function XRiftModel:GetTaskConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftTask, id)
end

---@return XTableRiftLayerDetail
function XRiftModel:GetLayerDetailConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftLayerDetail, id)
end

---@return XTableRiftLayer
function XRiftModel:GetLayerConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftLayer, id)
end

---@return XTableRiftChapter
function XRiftModel:GetChapterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftChapter, id)
end

---@return XTableRiftStage
function XRiftModel:GetStageConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftStage, id)
end

---@return XTableRiftTeamAttributeEffectType
function XRiftModel:GetTeamAttributeEffectConfigById(attrId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftTeamAttributeEffectType, attrId)
end

---@return XTableRiftSystemAttributeEffectType
function XRiftModel:GetSystemAttributeEffectConfigById(attrId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftSystemAttributeEffectType, attrId)
end

---@return XTableRiftPlugin
function XRiftModel:GetRiftPluginConfigById(pluginId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftPlugin, pluginId)
end

---@return XTableRiftPluginQuality
function XRiftModel:GetRiftPluginQualityConfigById(quality)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftPluginQuality, quality)
end

---@return XTableRiftFilterTag
function XRiftModel:GetRiftFilterTagConfigById(tagId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftFilterTag, tagId)
end

---@return XTableRiftTeamAttribute
function XRiftModel:GetTeamAttributeByAttrId(attrId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftTeamAttribute, attrId)
end

---@return XTableRiftShop
function XRiftModel:GetRiftShopById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftShop, id)
end

---@return XTableRiftTeamAttributeCost
function XRiftModel:GetRiftTeamAttributeCostById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftTeamAttributeCost, id)
end

---@return XTableRiftPluginAttrFix
function XRiftModel:GetRiftPluginAttrFixById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftPluginAttrFix, id)
end

---@return XTableRiftPluginGroupToFixAttr
function XRiftModel:GetRiftPluginGroupToFixAttrById(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftPluginGroupToFixAttr, groupId)
end

---@return XTableRiftCharacterAndRobot
function XRiftModel:GetRiftCharacterAndRobotById(robotId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftCharacterAndRobot, robotId)
end

---@return XTableRiftNodeRandomItem
function XRiftModel:GetRiftNodeRandomItemById(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftNodeRandomItem, groupId)
end

---@return XTableRiftTeamAttributeEffect
function XRiftModel:GetRiftTeamAttributeEffectById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftTeamAttributeEffect, id)
end

---@return XTableRiftSystemEffectTypeMap
function XRiftModel:GetRiftSystemEffectTypeMapById(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftSystemEffectTypeMap, type)
end

---@return XTableRiftAttributeGroupMap
function XRiftModel:GetRiftAttributeGroupMapById(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftAttributeGroupMap, groupId)
end

---@return XTableRiftStory
function XRiftModel:GetRiftStoryById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftStory, id)
end

---@return XTableRiftRandomAffix
function XRiftModel:GetRandomAffixById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftRandomAffix, id)
end

---@return XTableRiftPluginWords
function XRiftModel:GetPluginWordsById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RiftPluginWords, id)
end

---@return XTableRiftChapter[]
function XRiftModel:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftChapter)
end

---@return XTableRiftLayer[]
function XRiftModel:GetLayerConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftLayer)
end

---@return XTableRiftPlugin[]
function XRiftModel:GetRiftPluginConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftPlugin)
end

---@return XTableRiftFuncUnlock[]
function XRiftModel:GetFuncUnlockConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftFuncUnlock)
end

---@return XTableRiftFilterTag[]
function XRiftModel:GetRiftFilterTagConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftFilterTag)
end

---@return XTableRiftOneKeyEquip[]
function XRiftModel:GetRiftOneKeyEquipConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftOneKeyEquip)
end

---@return XTableRiftCharacterAndRobot[]
function XRiftModel:GetRiftCharacterAndRobotConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftCharacterAndRobot)
end

---@return XTableRiftTeamAttribute[]
function XRiftModel:GetRiftTeamAttributeConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftTeamAttribute)
end

---@return XTableRiftChapterPluginShow[]
function XRiftModel:GetChapterPluginShow()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftChapterPluginShow)
end

---@return XTableRiftStory[]
function XRiftModel:GetRiftStoryConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftStory)
end

---@return XTableRiftRandomAffix[]
function XRiftModel:GetRandomAffixConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftRandomAffix)
end

---@return XTableRiftTeamAttributeCost[]
function XRiftModel:GetRiftTeamAttributeCostConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RiftTeamAttributeCost)
end

----------config end----------

--region Debug

---通过比较tab文件和xlsm文件的修改时间来确定tab文件是否是由python工具生成的
function XRiftModel:CheckTabPythonCreate()
    if not XMain.IsWindowsEditor then
        return
    end
    local files = {
        {
            "RiftCharacterAndRobot.xlsm",
            "Client/Fuben/Rift/RiftCharacterAndRobot.tab",
            "Share/Fuben/Rift/RiftCharacterAndRobot.tab",
        }, {
            "RiftNodeRandomItem.xlsm",
            "Client/Fuben/Rift/RiftNodeRandomItem.tab",
            "Share/Fuben/Rift/RiftNodeRandomItem.tab",
        }, {
            "RiftPluginAttrFix.xlsm",
            "Client/Fuben/Rift/RiftPluginGroupToFixAttr.tab",
            "Share/Fuben/Rift/RiftPluginAttrFix.tab",
        }, {
            "RiftTeamAttributeEffect.xlsm",
            "Client/Fuben/Rift/RiftSystemEffectTypeMap.tab",
            "Client/Fuben/Rift/RiftAttributeGroupMap.tab",
            "Share/Fuben/Rift/RiftTeamAttributeEffect.tab",
        },
    }
    local pythonTab = CS.UnityEngine.Application.dataPath .. "/../../../Doc/Table/"
    local tab = CS.UnityEngine.Application.dataPath .. "/../../../Product/Table/"
    for _, tb in pairs(files) do
        local pythonTabTime = CS.XFileTool.GetFileLastWriteTime(pythonTab .. tb[1])
        for i = 2, #tb do
            local tbTime = CS.XFileTool.GetFileLastWriteTime(tab .. tb[i])
            if XTool.IsNumberValid(pythonTabTime) and XTool.IsNumberValid(tbTime) and tbTime > pythonTabTime then
                XLog.Warning(string.format("%s的修改时间比母表晚 策划确认下是否没使用母表导出而是直接修改了tab表.", tb[i]))
            end
        end
    end
end

--endregion


return XRiftModel