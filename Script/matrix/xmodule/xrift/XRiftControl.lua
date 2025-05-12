---@class XRiftControl : XEntityControl
---@field _Model XRiftModel
---@field _FightLayerMap XRiftFightLayer[] 作战层
---@field _ChapterMap XRiftChapter[] 章节信息
---@field _StageGroupMap table<number, XRiftStageGroup> 节点信息
---@field _StageMap table<number,table<number,XRiftStage>> 关卡信息
---@field _RoleMap XBaseRole[] 角色信息
local XRiftControl = XClass(XEntityControl, "XRiftControl")

function XRiftControl:OnInit()
    self._Model:CheckTabPythonCreate()
end

function XRiftControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_ADD_SYNC, self.OnCharacterAdd, self) --玩家角色增加时，增加成员
end

function XRiftControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_ADD_SYNC, self.OnCharacterAdd, self)
end

function XRiftControl:OnRelease()

end

--region 活动

function XRiftControl:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("RiftFinish"))
end

function XRiftControl:GetCurrentConfig()
    if not self._Model.ActivityData then
        return nil
    end
    return self._Model:GetActivityById(self._Model.ActivityData.ActivityId)
end

function XRiftControl:IsInActivity()
    local activity = self:GetCurrentConfig()
    if activity then
        return XFunctionManager.CheckInTimeByTimeId(activity.TimeId)
    end
    return false
end

function XRiftControl:GetTime()
    local activity = self:GetCurrentConfig()
    if activity then
        return XFunctionManager.GetEndTimeByTimeId(activity.TimeId)
    end
    return 0
end

---检测每日提示并继续
function XRiftControl:CheckDayTipAndDoFun(xChapter, doFun)
    if self:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.LuckyStage) and self:GetLuckValueProgress() >= 1 and self._Model:GetIsNewDayUpdate() then
        local titile = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("RiftLuckValueTip")
        local hitInfo = { SetHintCb = handler(self._Model, self._Model.SetDayTip), Status = false }
        XUiManager.DialogHintTip(titile, content, nil, nil, doFun, hitInfo)
    else
        doFun()
    end
end

function XRiftControl:IsFuncUnlock(unlockCfgId)
    return self._Model:IsFuncUnlock(unlockCfgId)
end

function XRiftControl:GetActivityEndTime()
    local activity = self:GetCurrentConfig()
    return activity and XFunctionManager.GetEndTimeByTimeId(activity.TimeId) or 0
end

function XRiftControl:GetActivityStartTime()
    local activity = self:GetCurrentConfig()
    return activity and XFunctionManager.GetStartTimeByTimeId(activity.TimeId) or 0
end

function XRiftControl:GetFuncUnlockById(id)
    return self._Model:GetFuncUnlockById(id)
end

function XRiftControl:GetFuncUnlockConfigs()
    return self._Model:GetFuncUnlockConfigs()
end

--endregion

--region 关卡

function XRiftControl:GetNewUnlockChapterId()
    local id = 0
    local isAllUnlock = true
    local chapters = self:GetEntityChapter()
    for _, chapter in pairs(chapters) do
        if chapter:GetConfig().ActivityId == self._Model.ActivityData.ActivityId then
            if chapter:CheckHasLock() then
                isAllUnlock = false
            else
                id = math.max(id, chapter:GetChapterId())
            end
        end
    end
    return isAllUnlock and 0 or id
end

function XRiftControl:GetProgressSpeed()
    return tonumber(self._Model:GetClientConfig("ProgressSpeed"))
end

function XRiftControl:GetChapterPluginShow(chapterId)
    local pluginIds = {}
    local configs = self._Model:GetChapterPluginShow()
    for _, config in pairs(configs) do
        if config.Chapter == chapterId then
            table.insert(pluginIds, config.PluginId)
        end
    end
    return pluginIds
end

function XRiftControl:GetMopupCountDown()
    local tick = self._Model.ActivityData:GetSweepTick()
    local now = XTime.GetServerNowTimestamp()
    local today = XTime.GetSeverTodayFreshTime()

    if XTool.IsNumberValid(tick) then
        if tick < today then
            return today - now
        else
            return XTime.GetSeverTomorrowFreshTime() - now
        end
    else
        return 0
    end
end

function XRiftControl:CheckChapterPass(chapterId)
    local chapter = self:GetEntityChapterById(chapterId)
    return chapter and chapter:CheckHasPassed()
end

function XRiftControl:CheckChapterUnlock(chapterId)
    return self._Model:CheckChapterUnlock(chapterId)
end

function XRiftControl:CheckLayerFirstPassed(layerId)
    return self._Model:CheckLayerFirstPassed(layerId)
end

function XRiftControl:CheckLayerPassed(layerId)
    return self._Model:CheckLayerPassed(layerId)
end

function XRiftControl:GetChapterData(chapterId)
    return self._Model.ActivityData:GetChapterData(chapterId)
end

function XRiftControl:GetFightLayerDataById(layerId)
    return self._Model.ActivityData:GetFightLayerDataById(layerId)
end

function XRiftControl:GetStageGroupByLayerId(layerId)
    return self._Model.ActivityData:GetStageGroupByLayerId(layerId)
end

function XRiftControl:GetStageData(layerId, stageIndex)
    return self._Model.ActivityData:GetStageData(layerId, stageIndex)
end

function XRiftControl:GetEntityFightLayer()
    if not self._FightLayerMap then
        self._FightLayerMap = {}
        local configs = self._Model:GetLayerConfigs()
        for _, config in pairs(configs) do
            ---@type XRiftFightLayer
            local layer = self:AddEntity(require("XModule/XRift/XEntity/XRiftFightLayer"))
            layer:SetConfig(config)
            self:UpdateStageGroup(config.Id)
            self._FightLayerMap[config.Id] = layer
        end
    end
    return self._FightLayerMap
end

function XRiftControl:GetEntityFightLayerById(layerId)
    local layers = self:GetEntityFightLayer()
    return layers[layerId]
end

function XRiftControl:GetEntityChapter()
    if not self._ChapterMap then
        self._ChapterMap = {}
        local configs = self._Model:GetChapterConfigs()
        for _, config in pairs(configs) do
            if config.ActivityId == self._Model.ActivityData.ActivityId then
                self._ChapterMap[config.Id] = self:AddEntity(require("XModule/XRift/XEntity/XRiftChapter"))
                self._ChapterMap[config.Id]:SetConfig(config)
            end
        end
    end
    return self._ChapterMap
end

function XRiftControl:GetEntityChapterById(id)
    local chapter = self:GetEntityChapter()
    return chapter[id]
end

---@return XRiftChapter,XRiftFightLayer
function XRiftControl:GetCurrPlayingChapter()
    local chapter, fightLayer
    if XTool.IsNumberValid(self._Model.ActivityData.ChapterId) then
        chapter = self:GetEntityChapterById(self._Model.ActivityData.ChapterId)
    end
    if XTool.IsNumberValid(self._Model.ActivityData.LayerId) then
        fightLayer = self:GetEntityFightLayerById(self._Model.ActivityData.LayerId)
    end
    return chapter, fightLayer
end

function XRiftControl:GetStageGroup(layerId)
    if not self._StageGroupMap then
        self._StageGroupMap = {}
    end
    if not self._StageGroupMap[layerId] then
        local layer = self:GetFightLayerDataById(layerId)
        if layer and layer.StageGroup then
            self._StageGroupMap[layerId] = {}
            ---@type XRiftStageGroup
            local stageGroup = self:AddEntity(require("XModule/XRift/XEntity/XRiftStageGroup"))
            stageGroup:SetLayer(layerId)
            stageGroup:UpdateData()
            self._StageGroupMap[layerId] = stageGroup
        end
    end
    return self._StageGroupMap[layerId]
end

function XRiftControl:UpdateStageGroup(layerId)
    if not self._StageGroupMap or not self._StageGroupMap[layerId] then
        return
    end
    self._StageGroupMap[layerId]:UpdateData()
end

-- stageId会重复 所以这里使用layerId和stageIndex作为key
function XRiftControl:GetStage(layerId, stageIndex)
    if not self._StageMap then
        self._StageMap = {}
    end
    if not self._StageMap[layerId] then
        self._StageMap[layerId] = {}
    end
    if not self._StageMap[layerId][stageIndex] then
        local riftStageId = self:GetStageData(layerId, stageIndex).RiftStageId
        local stageConfig = self._Model:GetStageConfigById(riftStageId)
        self._StageMap[layerId][stageIndex] = self:AddEntity(require("XModule/XRift/XEntity/XRiftStage"))
        self._StageMap[layerId][stageIndex]:SetConfig(layerId, stageConfig, stageIndex)
    end
    return self._StageMap[layerId][stageIndex]
end

function XRiftControl:SetCurrSelectRiftStage(xStageGroup)
    self._Model:SetCurrSelectRiftStage(xStageGroup)
end

function XRiftControl:GetCurrSelectRiftStageGroup()
    local data = self._Model:GetCurrSelectRiftStageGroup()
    if data then
        return self:GetStageGroup(data.FightLayerId)
    end
end

function XRiftControl:GetMaxUnLockFightLayerId()
    return self._Model:GetMaxUnLockFightLayerOrder()
end

function XRiftControl:GetMaxPassFightLayerId()
    return self._Model:GetMaxPassFightLayerOrder()
end

---关卡是否未解锁
function XRiftControl:IsLayerLock(layerId)
    return layerId > self:GetMaxUnLockFightLayerId()
end

---关卡是否已通关
function XRiftControl:IsLayerPass(layerId)
    return layerId <= self:GetMaxPassFightLayerId()
end

function XRiftControl:IsAllPass()
    return self:GetMaxPassFightLayerId() >= self._Model:GetMaxLayerId()
end

function XRiftControl:GetIsNewLayerIdTrigger()
    return self._Model:GetIsNewLayerIdTrigger()
end

function XRiftControl:SetNewLayerTrigger(newFightLayerId)
    self._Model:SetNewLayerTrigger(newFightLayerId)
end

function XRiftControl:GetIsFirstPassChapterTrigger()
    return self._Model:GetIsFirstPassChapterTrigger()
end

function XRiftControl:SetFirstPassChapterTrigger(fightLayerId)
    self._Model:SetFirstPassChapterTrigger(fightLayerId)
end

function XRiftControl:IsCurrPlayingChapter(chapterId)
    return self._Model.ActivityData.ChapterId == chapterId
end

function XRiftControl:IsCurrPlayingLayer(layerId)
    return self._Model.ActivityData.LayerId == layerId
end

function XRiftControl:IsOtherLayerPlaying(layerId)
    local _, curLayer = self:GetCurrPlayingChapter()
    return curLayer and curLayer:GetFightLayerId() ~= layerId
end

function XRiftControl:EnterFight(xTeam)
    self._Model:EnterFight(xTeam)
end

---获取章节所属所有层
function XRiftControl:GetLayerIdsByChapterId(chapterId)
    return self._Model:GetLayerIdsByChapterId(chapterId)
end

function XRiftControl:CheckHadFightLayerFirstEntered(layerId)
    return self._Model:CheckHadFightLayerFirstEntered(layerId)
end

function XRiftControl:GetCurrFightLayerId()
    return self._Model:GetCurrFightLayerId()
end

---【保存】首次进入(跃升领奖也调用一次，功能相似)
function XRiftControl:SaveFirstEnter(layerId)
    self._Model:SaveFirstEnter(layerId)
end

function XRiftControl:SetAutoOpenChapterDetail(chapterId)
    self._Model:SetAutoOpenChapterDetail(chapterId)
end

function XRiftControl:GetAutoOpenChapterDetail()
    return self._Model:GetAutoOpenChapterDetail()
end

--endregion

--region 角色

function XRiftControl:AddNewRole(entityId)
    if self._RoleMap[entityId] then
        return
    end
    local roleData = self._Model:GetRoleData(entityId)
    self._RoleMap[entityId] = require("XEntity/XRole/XBaseRole").New(roleData)
end

function XRiftControl:GetEntityRoleById(entityId)
    if not XTool.IsNumberValid(entityId) then
        return nil
    end
    if not self._RoleMap then
        self._RoleMap = {}
    end
    if not self._RoleMap[entityId] then
        self:AddNewRole(entityId)
    end
    return self._RoleMap[entityId]
end

---玩家角色增加时
function XRiftControl:OnCharacterAdd(character)
    if character == nil then
        return
    end
    self:AddNewRole(character)
end

---获取角色身上的插件
---@param role XBaseRole
function XRiftControl:GetRolePlugInIdList(role)
    return self._Model:GetRolePlugInIdList(role)
end

---角色是否有某个插件
---@param role XBaseRole
function XRiftControl:CheckHasPlugin(role, pluginId)
    local pluginIds = self:GetRolePlugInIdList(role)
    if XTool.IsTableEmpty(pluginIds) then
        return false
    end
    return table.contains(pluginIds, pluginId)
end

function XRiftControl:GetMaxLoad()
    return self._Model.ActivityData:GetMaxLoad()
end

---加上是否达到插件负载上限
---@param role XBaseRole
function XRiftControl:CheckLoadLimitAddPlugin(role, pluginId)
    local addXPlugin = self:GetPlugin(pluginId)
    return self:GetCurrentLoad(role) + addXPlugin.Load > self:GetMaxLoad()
end

---当前装备的总插件负载
---@param role XBaseRole
function XRiftControl:GetCurrentLoad(role)
    return self._Model:GetCurrentLoad(role)
end

--endregion

--region 插件

function XRiftControl:GetPluginQualityColor(quality)
    return self._Model:GetClientConfig("PluginQualityColor", quality)
end

function XRiftControl:GetPluginRandomAffixs(pluginId)
    return self._Model.ActivityData:GetAffix(pluginId)
end

function XRiftControl:GetPluginRandomAffixByIdx(pluginId, index)
    local affixs = self:GetPluginRandomAffixs(pluginId)
    return affixs and affixs[index] or nil
end

function XRiftControl:IsPluginRandomAffixUnlock(pluginId, index)
    local affix = self:GetPluginRandomAffixByIdx(pluginId, index)
    return XTool.IsNumberValid(affix)
end

function XRiftControl:IsRandomAffixMaxLevel(pluginId, index)
    local affix = self:GetPluginRandomAffixByIdx(pluginId, index)
    if affix then
        return self:IsRandomAffixMaxLevelById(affix)
    else
        return false
    end
end

function XRiftControl:IsRandomAffixMaxLevelById(affix)
    local cfg = self:GetRandomAffixById(affix)
    return cfg.Level >= self._Model:GetRandomAffixMaxLevel(cfg.Type)
end

function XRiftControl:GetUnlockRandomAffixCount(pluginId)
    local unlock = 0
    local total = self:GetPlugin(pluginId).SlotCount
    for i = 1, total do
        if self:IsPluginRandomAffixUnlock(pluginId, i) then
            unlock = unlock + 1
        end
    end
    return unlock
end

function XRiftControl:GetLockRandomAffixCount(pluginId)
    local unlock = 0
    local total = self:GetPlugin(pluginId).SlotCount
    for i = 1, total do
        if not self:IsPluginRandomAffixUnlock(pluginId, i) then
            unlock = unlock + 1
        end
    end
    return unlock
end

function XRiftControl:GetRandomAffixById(id)
    return self._Model:GetRandomAffixById(id)
end

function XRiftControl:GetMaxLevelPluginAffixColor()
    return self._Model:GetClientConfig("MaxLevelPluginAffixColor")
end

function XRiftControl:GetPlugin(id)
    return self._Model:GetRiftPluginConfigById(id)
end

---构界突破
function XRiftControl:IsPluginStageUpgrade(id)
    local plugin = self:GetPlugin(id)
    return plugin.Type == tonumber(self._Model:GetClientConfig("BreakType"))
end

function XRiftControl:IsPluginUnlock(id)
    local plugin = self:GetPlugin(id)
    local needChapter = plugin.Chapter
    if not XTool.IsNumberValid(needChapter) or self:CheckChapterUnlock(needChapter) then -- 章节解锁
        return true, ""
    end
    return false, self:GetPluginLockTxt(id)
end

function XRiftControl:GetPluginLockTxt(id)
    local plugin = self:GetPlugin(id)
    return XUiHelper.GetText("RiftPluginLock", self._Model:GetChapterConfigById(plugin.Chapter).Name)
end

function XRiftControl:IsPluginBuy(id)
    local plugin = self:GetPlugin(id)
    local needChapter = plugin.Chapter
    return XTool.IsNumberValid(needChapter) and self:CheckChapterPass(needChapter) -- 章节通关
end

function XRiftControl:GetPluginBuyTxt(id)
    local plugin = self:GetPlugin(id)
    if XTool.IsNumberValid(plugin.Chapter) then
        return XUiHelper.GetText("RiftPluginBuy", self._Model:GetChapterConfigById(plugin.Chapter).Name)
    end
    XLog.Error("插件" .. plugin.Id .. "没有配置Chapter字段")
    return ""
end

---检测该插件是否有角色条件限制
function XRiftControl:CheckCharacterWearLimit(id, characterId)
    local plugin = self:GetPlugin(id)
    if not XTool.IsNumberValid(plugin.CharacterId) then
        return false
    end
    return plugin.CharacterId ~= characterId
end

---检测当前插件是有相同类型穿戴限制
function XRiftControl:CheckCurPluginTypeLimit(pluginType, xRole)
    local pluginIds = self:GetRolePlugInIdList(xRole)
    if not XTool.IsTableEmpty(pluginIds) then
        for _, id in pairs(pluginIds) do
            local plugin = self:GetPlugin(id)
            if plugin.Type == pluginType then
                return true
            end
        end
    end
    return false
end

function XRiftControl:GetPluginQuality(quality)
    return self._Model:GetRiftPluginQualityConfigById(quality)
end

function XRiftControl:UnlockedPluginByDrop(pluginDropRecords)
    self._Model:UnlockedPluginByDrop(pluginDropRecords)
end

function XRiftControl:SortDropPlugin(aDrop, bDrop)
    if aDrop.IsExtraDrop ~= bDrop.IsExtraDrop then
        return not aDrop.IsExtraDrop
    end
    return self:SortDropPluginBase(aDrop, bDrop)
end

function XRiftControl:SortDropPluginBase(aDrop, bDrop)
    local aPlugin = self:GetPlugin(aDrop.PluginId)
    local bPlugin = self:GetPlugin(bDrop.PluginId)
    if aPlugin.Quality ~= bPlugin.Quality then
        return aPlugin.Quality > bPlugin.Quality
    end
    if aPlugin.Sort ~= bPlugin.Sort then
        return aPlugin.Sort < bPlugin.Sort
    end
    return aPlugin.Id < bPlugin.Id
end

function XRiftControl:GetAttrLevelMax()
    return self._Model.ActivityData:GetAttrLevelMax()
end

---@return XTableRiftPlugin[]
function XRiftControl:GetOwnPluginList(element, roleId)
    local pluginList = {}
    local filterSetting = self._Model:GetFilterSertting(XEnumConst.Rift.FilterSetting.PluginChoose)
    local propTagId = tonumber(self._Model:GetClientConfig("PropStrengthTagId"))
    local characterTagId = self._Model:GetCharacterExclusiveTagId()

    local CheckStar = function(datas, plugin)
        local star = plugin.Star
        return datas[star]
    end

    local CheckTag = function(datas, plugin)
        local tags = plugin.Tags
        for tag, _ in pairs(datas) do
            local isPluginHasTag = table.indexof(tags, tag)
            if tag == characterTagId then
                -- 保留通用插件，去掉其他角色的插件
                if isPluginHasTag and (plugin.CharacterId == 0 or plugin.CharacterId == roleId) then
                    return true
                end
            elseif tag == propTagId then
                -- 根据所选角色类型进行筛选
                if isPluginHasTag and element == plugin.Element then
                    return true
                end
            else
                if isPluginHasTag then
                    return true
                end
            end
        end
        return false
    end

    local starData = filterSetting[XEnumConst.Rift.Filter.Star] or {}
    local tagDatas = filterSetting[XEnumConst.Rift.Filter.Tag] or {}
    local isStarEmpty = XTool.IsTableEmpty(starData)
    local isTagEmpty = XTool.IsTableEmpty(tagDatas)

    local ownPluginIds = self._Model:GetOwnPluginIds()
    if ownPluginIds then
        for pluginId, _ in pairs(ownPluginIds) do
            local plugin = self:GetPlugin(pluginId)
            if plugin.IsDisplay ~= 1 then
                -- 同中筛选类型取交集，不同筛选类型取并集
                local star = isStarEmpty and true or CheckStar(starData, plugin)
                local tag = isTagEmpty and true or CheckTag(tagDatas, plugin)
                if not star or not tag then
                    goto CONTINUE
                end

                table.insert(pluginList, plugin)
                :: CONTINUE ::
            end
        end
    end

    return pluginList
end

function XRiftControl:GetAllPluginList(pluginStar)
    ---@type XTableRiftPlugin[]
    local pluginList = {}
    local configs = self._Model:GetRiftPluginConfigs()
    for _, plugin in pairs(configs) do
        if pluginStar == plugin.Star and plugin.IsDisplay ~= 1 then
            table.insert(pluginList, plugin)
        end
    end

    table.sort(pluginList, function(a, b)
        if a.Star ~= b.Star then
            return a.Star > b.Star
        end

        local customSortA = self:GetPluginSort(a.Id)
        local customSortB = self:GetPluginSort(b.Id)
        if customSortA ~= customSortB then
            return customSortA < customSortB
        end

        local aSort = a.Sort
        local bSort = b.Sort
        if aSort ~= bSort then
            return aSort < bSort
        end

        return a.Id < b.Id
    end)

    return pluginList
end

-- 已获得 > 可购买 > 可掉落 > 未解锁
function XRiftControl:GetPluginSort(id)
    if self:IsHavePlugin(id) then
        return 1
    end
    if self:IsPluginBuy(id) then
        return 2
    end
    if self:IsPluginUnlock(id) then
        return 3
    end
    return 4
end

function XRiftControl:GetPluginCount(star)
    return self._Model:GetPluginCount(star)
end

function XRiftControl:IsHavePlugin(pluginId)
    return self._Model:IsHavePlugin(pluginId)
end

function XRiftControl:GetPluginQualityImage(quality)
    local config = self:GetPluginQuality(quality)
    return config.Image, config.ImageBg
end

---是否暗金品质
function XRiftControl:IsPluginSpecialQuality(quality)
    return quality >= 5
end

function XRiftControl:GetPluginSaveKey(pluginId)
    return XPlayer.Id .. "_XRiftManager_PluginRed_" .. pluginId
end

function XRiftControl:GetFilterSertting(setting)
    return self._Model:GetFilterSertting(setting)
end

function XRiftControl:SaveFilterSertting(setting, data)
    self._Model:SaveFilterSertting(setting, data)
end

---插件总描述
function XRiftControl:GetPluginDesc(pluginId, isDetailTxt)
    if isDetailTxt == nil then
        isDetailTxt = true
    end
    local plugin = self:GetPlugin(pluginId)
    --local attrLevel = self:GetDefaultTemplateAttrLevel(plugin.DescFixAttrId)
    --local descInitValue = plugin.DescInitValue / 10000 -- DescInitValue配表按*10000填写
    --local descCoefficient = plugin.DescCoefficient / 10000 -- DescCoefficient配表按*10000填写
    --local attrAddValue = attrLevel * descCoefficient
    local descId = isDetailTxt and plugin.DescId or plugin.SimpleDescId
    local desc = ""
    if XTool.IsNumberValid(descId) then
        local word = self._Model:GetPluginWordsById(descId)
        desc = word.Desc
        for i, v in ipairs(plugin.DescParam) do
            local param = string.gsub(v, "%%", "%%%%")
            desc = string.gsub(desc, string.format("{%s}", i - 1), param)
        end
        if word.IsQualityColor == 1 then
            local color = self:GetPluginQualityColor(plugin.Quality)
            desc = string.format("<color=%s>%s</color>", color, desc)
        end
    end
    --if string.find(desc, "{0}") then
    --    desc = string.gsub(desc, "{0}", self._Model:FormatNum(descInitValue + attrAddValue))
    --end
    --if string.find(desc, "{1}") then
    --    desc = string.gsub(desc, "{1}", self._Model:FormatNum(descInitValue))
    --end
    --if string.find(desc, "{2}") then
    --    desc = string.gsub(desc, "{2}", self._Model:FormatNum(attrAddValue))
    --end
    --if string.find(desc, "{3}") then
    --    desc = string.gsub(desc, "{3}", attrLevel)
    --end
    --if string.find(desc, "{4}") then
    --    desc = string.gsub(desc, "{4}", self._Model:FormatNum(descCoefficient))
    --end
    if XTool.IsNumberValid(plugin.DescTipsId) then
        desc = desc .. self._Model:GetPluginWordsById(plugin.DescTipsId).Desc
    end
    return desc
end

---获取属性标签
function XRiftControl:GetPluginPropTag(pluginId)
    local tagNames = {}
    local plugin = self:GetPlugin(pluginId)
    local element = plugin.Element
    local specialTagId = tonumber(self._Model:GetClientConfig("PropStrengthTagId"))
    for _, tagId in pairs(plugin.Tags) do
        local config = self._Model:GetRiftFilterTagConfigById(tagId)
        if tagId == specialTagId then
            --【属性强化】要根据Element替换成【火属性强化】等
            table.insert(tagNames, config.Params[element])
        elseif config then
            table.insert(tagNames, config.Name)
        end
    end
    -- 暗金装备额外显示【暗金】标签
    if self:IsPluginSpecialQuality(plugin.Quality) then
        table.insert(tagNames, XUiHelper.GetText("RiftGoldTagName"))
    end
    return tagNames
end

function XRiftControl:GetRiftFilterTagConfigs()
    return self._Model:GetRiftFilterTagConfigs()
end

--endregion

--region 模板

function XRiftControl:GetTotalAttrLevel()
    return self._Model.ActivityData:GetTotalAttrLevel()
end

-- 获取默认模板属性加点的属性等级
function XRiftControl:GetDefaultTemplateAttrLevel(attrId)
    local attrTemplate = self._Model:GetAttrTemplate()
    return attrTemplate:GetAttrLevel(attrId)
end

function XRiftControl:GetAttributeCost(attrLevel)
    return self._Model:GetAttributeCost(attrLevel)
end

function XRiftControl:GetCanPreviewAttrAllLevel()
    return self._Model:GetCanPreviewAttrAllLevel()
end

function XRiftControl:GetSystemAttr(attrId)
    local groupIds = self._Model:GetAttrGroupId(attrId)
    for _, group in pairs(groupIds) do
        local results = self._Model:GetSystemAttr(group)
        if not XTool.IsTableEmpty(results) then
            return results
        end
    end
    return {}
end

function XRiftControl:GetAttrTemplate(id)
    return self._Model:GetAttrTemplate(id)
end

function XRiftControl:GetTemplateName(id)
    local template = self:GetAttrTemplate(id)
    local name = template and template:GetName()
    if not name then
        return XUiHelper.GetText("RiftAttributeTemplateName" .. id)
    end
    return name
end

---@param attrTemplate XRiftAttributeTemplate
function XRiftControl:GetEffectList(attrTemplate)
    return self._Model:GetEffectList(attrTemplate)
end

function XRiftControl:GetTeamAttributeConfig(attrId)
    return self._Model:GetTeamAttributeByAttrId(attrId)
end

function XRiftControl:GetTeamAttributeEffectConfigById(attrId)
    return self._Model:GetTeamAttributeEffectConfigById(attrId)
end

function XRiftControl:GetSystemAttributeEffectConfigById(attrId)
    return self._Model:GetSystemAttributeEffectConfigById(attrId)
end

--endregion

--region 任务

function XRiftControl:GetTaskConfigById(index)
    return self._Model:GetTaskConfigById(index)
end

function XRiftControl:GetTaskGroupIdList()
    local config = self:GetCurrentConfig()
    return config and config.TaskGroupId or 0
end

---检查所有任务是否有奖励可领取
function XRiftControl:CheckTaskCanReward()
    return self._Model:CheckTaskCanReward()
end

---获取任务按钮显示的任务
function XRiftControl:GetBtnShowTask()
    local finish = XDataCenter.TaskManager.TaskState.Finish
    local groupIdList = self:GetTaskGroupIdList()
    for index, groupId in ipairs(groupIdList) do
        local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)
        for _, taskData in pairs(taskList) do
            if taskData.State ~= finish then
                local taskCfg = self:GetTaskConfigById(index)
                local config = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
                return taskCfg.Name, config.Desc
            end
        end
    end

    return XUiHelper.GetText("PokerGuessingTask"), XUiHelper.GetText("DlcHuntTaskFinish")
end

--endregion

--region 商店

function XRiftControl:GetRiftShopById(id)
    return self._Model:GetRiftShopById(id)
end

function XRiftControl:GetActivityShopIds()
    local activity = self:GetCurrentConfig()
    if activity then
        return activity.ShopId
    end
    return nil
end

function XRiftControl:OpenUiShop()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        local shopIds = self:GetActivityShopIds()
        if shopIds then
            XShopManager.GetShopInfoList(shopIds, function()
                XLuaUiManager.Open("UiRiftShop")
                self:CloseShopRed()
            end, XShopManager.ActivityShopType.RiftShop)
        end
    end
end

function XRiftControl:GetShopRedSaveKey()
    return XPlayer.Id .. "_XRiftManager_ShopRed"
end

--endregion

--region 红点

function XRiftControl:SetCharacterRedPoint(isRed)
    self._Model:SetCharacterRedPoint(isRed)
end

function XRiftControl:GetCharacterRedPoint()
    return self._Model:GetCharacterRedPoint()
end

---关闭购买属性红点
function XRiftControl:CloseBuyAttrRed()
    self._Model:CloseBuyAttrRed()
end

function XRiftControl:IsPluginRed(pluginId)
    if not self:IsHavePlugin(pluginId) then
        return false
    end
    local saveKey = self:GetPluginSaveKey(pluginId)
    return XSaveTool.GetData(saveKey) == nil
end

function XRiftControl:ClosePluginRed(pluginId)
    if not self:IsHavePlugin(pluginId) then
        return
    end
    local saveKey = self:GetPluginSaveKey(pluginId)
    XSaveTool.SaveData(saveKey, true)
end

function XRiftControl:IsPluginBagRed()
    local configs = self._Model:GetRiftPluginConfigs()
    for _, plugin in pairs(configs) do
        if self:IsPluginRed(plugin.Id) then
            return true
        end
    end
    return false
end

function XRiftControl:ClosePluginBagRed()
    local ownPluginIds = self._Model:GetOwnPluginIds()
    if ownPluginIds then
        for pluginId, _ in pairs(ownPluginIds) do
            self:ClosePluginRed(pluginId)
        end
    end
end

function XRiftControl:IsShopRed()
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftCoin)
    if ownCnt > 0 then
        local recordTime = XSaveTool.GetData(self:GetShopRedSaveKey())
        if recordTime then
            local now = XTime.GetServerNowTimestamp()
            return not XTime.IsToday(now, recordTime)
        else
            return true
        end
    end

    return false
end

function XRiftControl:CloseShopRed()
    local now = XTime.GetServerNowTimestamp()
    XSaveTool.SaveData(self:GetShopRedSaveKey(), now)
end

--endregion

--region 编队

function XRiftControl:GetCurFightCharCount()
    return self._Model.CurFightCharCount or 0
end

function XRiftControl:CheckRoleInTeam(roleId)
    self._Model.ActivityData:CheckRoleInTeam(roleId)
end

function XRiftControl:ChangeMultiTeamData(data)
    self._Model.ActivityData:ChangeMultiTeamData(data)
end

function XRiftControl:GetMultiTeamData()
    return self._Model.ActivityData:GetMultiTeamData()
end

function XRiftControl:GetSingleTeamData(isLuckStage)
    return self._Model.ActivityData:GetSingleTeamData(isLuckStage)
end

function XRiftControl:CheckRoleInMultiTeamLock(xTeam)
    return self._Model:CheckRoleInMultiTeamLock(xTeam)
end

function XRiftControl:SwapMultiTeamMember(aTeamIndex, aPos, bTeamIndex, bPos)
    self._Model.ActivityData:SwapMultiTeamMember(aTeamIndex, aPos, bTeamIndex, bPos)
end

function XRiftControl:GetRobot()
    return self._Model:GetRobot()
end

--endregion

--region 排行榜

function XRiftControl:GetRankingList()
    local rankData = self._Model.ActivityData:GetRankData()
    return rankData and rankData.RankPlayerInfos or nil
end

function XRiftControl:IsHasRank()
    local rankData = self._Model.ActivityData:GetRankData()
    return rankData and XTool.IsNumberValid(rankData.Rank) or false
end

function XRiftControl:GetMyRankInfo()
    local rankData = self._Model.ActivityData:GetRankData()
    if not rankData then
        return nil
    end
    local myRank = {}
    local percentRank = 100 -- 101名及以上显示百分比
    local rank = rankData.Rank
    if rankData.Rank > percentRank then
        rank = math.max(1, math.floor(rankData.Rank * 100 / rankData.TotalCount)) .. "%" -- 最小显示1%
    elseif rankData.Rank == 0 then
        rank = XUiHelper.GetText("ExpeditionNoRanking")
    end
    myRank["Rank"] = rank
    myRank["Id"] = XPlayer.Id
    myRank["Name"] = XPlayer.Name
    myRank["HeadPortraitId"] = XPlayer.CurrHeadPortraitId
    myRank["HeadFrameId"] = XPlayer.CurrHeadFrameId
    myRank["Score"] = rankData.Score
    myRank["CharacterIds"] = rankData.CharacterIds
    return myRank
end

function XRiftControl:GetRankingSpecialIcon(rank)
    if type(rank) ~= "number" or rank < 1 or rank > 3 then
        return
    end
    return CS.XGame.ClientConfig:GetString("BabelTowerRankIcon" .. rank)
end

function XRiftControl:IsRankUnlock()
    local activity = self:GetCurrentConfig()
    if activity then
        local layerId = activity.RankLayerLimit
        if XTool.IsNumberValid(layerId) then
            if not self:IsLayerPass(layerId) then
                return false, XUiHelper.GetText("RiftLayerUnlockTip", self._Model:GetLayerConfigById(layerId).Name)
            end
        end
    end
    return true, ""
end

--endregion

--region 幸运关

function XRiftControl:GetLuckName()
    return self._Model:GetClientConfig("LuckyStageName")
end

function XRiftControl:GetLuckDesc()
    return self._Model:GetClientConfig("LuckyStageDesc")
end

function XRiftControl:GetMaxLuckyValue()
    local activity = self:GetCurrentConfig()
    return activity and activity.MaxLuckyValue or 0
end

function XRiftControl:GetLuckPassTime()
    return self._Model.ActivityData:GetLuckPassTime()
end

function XRiftControl:GetLuckValueProgress()
    local progress = self._Model.ActivityData:GetLuckyValue() / self:GetMaxLuckyValue()
    progress = progress >= 1 and 1 or progress
    progress = progress < 0 and 0 or progress
    return progress
end

-- 最高通关层的
function XRiftControl:GetLuckLayer()
    local layerId = self:GetMaxPassFightLayerId()
    return self:GetEntityFightLayerById(layerId)
end

function XRiftControl:GetLayerDetailConfigById(layerId)
    return self._Model:GetLayerDetailConfigById(layerId)
end

function XRiftControl:GetLuckStageId()
    return self._Model:GetLuckStageId()
end

---插件掉落概率
function XRiftControl:GetLuckPluginDrop(index)
    local layerId = self:GetMaxPassFightLayerId()
    local config = self:GetLayerDetailConfigById(layerId)
    return config.LuckPluginDropList[index] or 0
end

--endregion

--region 一键推荐

---@param role XBaseRole
function XRiftControl:GetOneKeyRecommendList(role)
    local plugins = {}
    local tempPluginId
    local datas = self._Model:GetRecommendSetting(role:GetCharacterId())
    local residue = self:GetMaxLoad()
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local isNormalRole = characterAgency:GetCharacterQuality(role:GetCharacterId()) < 4
    if isNormalRole then
        -- 优先装备构界突破
        local stageUpgradeType = tonumber(self._Model:GetClientConfig("BreakType"))
        tempPluginId, residue = self._Model:GetPluginByType(stageUpgradeType, residue)
        if tempPluginId then
            table.insert(plugins, tempPluginId)
        end
    end
    -- 遍历推荐表
    for _, v in pairs(datas) do
        tempPluginId, residue = self._Model:GetPluginByType(v.PluginType, residue)
        if tempPluginId then
            table.insert(plugins, tempPluginId)
        end
    end
    return plugins
end

--endregion

--region 图鉴加成

---@return table<number, XTableRiftCollectAttributeEffect>
function XRiftControl:GetHandbookEffect(star)
    return self._Model:GetHandbookEffect(star)
end

---@return XTableRiftCollectAttributeEffect[]
function XRiftControl:GetHandbookTakeEffectList()
    return self._Model:GetHandbookTakeEffectList()
end

--endregion

--region 协议

---激活词缀
---@param type number 解锁类型 1 单个 2 全部
function XRiftControl:RequestRiftActiveAffix(type, pluginId, slot, callBack)
    local request = { Type = type, PluginId = pluginId, Slot = slot }
    XNetwork.CallWithAutoHandleErrorCode("RiftActiveAffixRequest", request, function(res)
        if callBack then
            callBack()
        end
    end)
end

---请求重置词缀（仅做展示）
function XRiftControl:RequestRiftResetAffix(pluginId, slot, callBack)
    local request = { PluginId = pluginId, Slot = slot }
    XNetwork.CallWithAutoHandleErrorCode("RiftResetAffixRequest", request, function(res)
        if callBack then
            callBack(res.AffixId)
        end
    end)
end

---确认重置词缀
function XRiftControl:RequestRiftConfirmResetAffix()
    XNetwork.CallWithAutoHandleErrorCode("RiftConfirmResetAffixRequest", {})
end

function XRiftControl:RequireRanking(cb, chapterId)
    local request = { ChapterId = chapterId }
    XNetwork.Call("RiftGetRankRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:UpdateRankData(res)
        if cb then
            cb()
        end
    end)
end

---请求下发幸运关信息
function XRiftControl:RiftStartLuckyNodeRequest(cb)
    XNetwork.Call("RiftStartLuckyNodeRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:UpdateLuckNode(res.LuckyNodeData)
        if cb then
            cb()
        end
    end)
end

---请求扫荡
function XRiftControl:RiftSweepLayerRequest(cb)
    XNetwork.Call("RiftSweepLayerRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 解锁插件
        self:UnlockedPluginByDrop(res.PluginDropRecords)
        -- 记录当前层累计的插件掉落 如果没有任何层通关 按第一层的数据扫荡
        local maxPassFightLayerOrder = math.max(1, self:GetMaxPassFightLayerId())
        self._Model.ActivityData:AddFightLayerDropPlugin(maxPassFightLayerOrder, res.PluginDropRecords)
        self._Model.ActivityData:AddSweepTimes(res.SweepTick)
        self._Model.ActivityData:UpdateLuckNode(nil, res.LuckyValue)
        -- 弹层结算
        XLuaUiManager.Open("UiRiftSettleWin", maxPassFightLayerOrder, nil, true, true, res)
        if cb then
            cb()
        end
    end)
end

---请求装备/卸载角色插件
function XRiftControl:RiftSetCharacterPluginsRequest(xRole, pluginIdList, cb)
    local data = {
        CharacterId = not xRole:GetIsRobot() and xRole:GetId() or nil,
        RobotId = xRole:GetIsRobot() and xRole:GetId() or nil,
        PluginIds = pluginIdList,
    }
    XNetwork.Call("RiftSetCharacterPluginsRequest", data, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 装备成功 刷新角色插件
        self._Model.ActivityData:AddPluginToCharacter(xRole:GetId(), pluginIdList)
        if cb then
            cb()
        end
    end)
end

---请求更改队伍对应模板
function XRiftControl:RiftSetTeamRequest(xTeam, newChangeTempId, cb)
    if newChangeTempId == xTeam:GetAttrTemplateId() then
        return
    end
    local activity = self:GetCurrentConfig()
    local multiTeamDatas = self._Model.ActivityData:GetMultiTeamData()
    local teamDatas = self._Model.ActivityData:GetTeamDatas()
    if not activity or not multiTeamDatas or not teamDatas then
        return
    end
    for i = 1, activity.AttrLevelSetCount do
        local tempTeam = multiTeamDatas[i]
        teamDatas[i] = { Id = i, AttrSetId = tempTeam and tempTeam:GetShowAttrTemplateId() }
    end
    local teamId = xTeam:GetId()
    local currAttrTeamData = teamDatas[teamId]
    currAttrTeamData.AttrSetId = newChangeTempId

    XNetwork.Call("RiftSetTeamRequest", { TeamDatas = teamDatas }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        xTeam:SetAttrTemplateId(newChangeTempId)
        if cb then
            cb()
        end
    end)
end

function XRiftControl:RiftSetAttrSetNameRequest(attrSetId, name, cb)
    XNetwork.Call("RiftSetAttrSetNameRequest", { AttrSetId = attrSetId, Name = name }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local template = self._Model:GetAttrTemplate(attrSetId)
        if template then
            template:SetName(name)
        end
        if cb then
            cb()
        end
    end)
end

---请求保存属性模板
---@param attrTemplate XRiftAttributeTemplate
function XRiftControl:RequestSetAttrSet(attrTemplate, cb)
    local allLevel = attrTemplate:GetAllLevel()
    local attrList = XTool.Clone(attrTemplate.AttrList)
    local isClear = attrTemplate.Id ~= XEnumConst.Rift.DefaultAttrTemplateId and allLevel == 0 -- 默认模板不能设置为nil
    local request = { AttrSet = { Id = attrTemplate.Id, AttrLevels = nil } }
    if not isClear then
        request.AttrSet.AttrLevels = attrList
    end

    XNetwork.Call("RiftSetAttrSetRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateAttrSet(attrTemplate, attrList)

        if cb then
            cb()
        end
    end)
end

function XRiftControl:RequestBuyPlugin(id)
    local request = { PluginId = id }
    XNetwork.Call("RiftBuyPluginRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetPluginHave(id)
        XEventManager.DispatchEvent(XEventId.EVENT_RIFT_BUY)
        XUiManager.TipText("RiftPluginBuySuccess")
    end)
end

function XRiftControl:RequestRiftStartChapter(chapterId, cb)
    local request = { ChapterId = chapterId }
    XNetwork.CallWithAutoHandleErrorCode("RiftStartChapterRequest", request, function(res)
        self._Model.ActivityData:UpdateFightLayer(chapterId, res.LayerDataList)
        self._Model.ActivityData:UpdateCurFight(chapterId)
        if cb then
            cb()
        end
    end)
end

--endregion

--region 剧情

function XRiftControl:GetRiftStoryById(storyId)
    return self._Model:GetRiftStoryById(storyId)
end

function XRiftControl:GetChapterStory(chapterId)
    return self._Model:GetChapterStory(chapterId)
end

--endregion

return XRiftControl