local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")
---@class XTheatre4Agency : XFubenSimulationChallengeAgency
---@field private _Model XTheatre4Model
local XTheatre4Agency = XClass(XFubenSimulationChallengeAgency, "XTheatre4Agency")
function XTheatre4Agency:OnInit()
    --初始化一些变量
    self:RegisterChapterAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.Theatre4)
end

function XTheatre4Agency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyTheatre4ActivityData = handler(self, self.NotifyTheatre4ActivityData)
    XRpc.NotifyTheatre4AdventureData = handler(self, self.NotifyTheatre4AdventureData)
    XRpc.NotifyTheatre4AddChapter = handler(self, self.NotifyTheatre4AddChapter)
    XRpc.NotifyTheatre4Transactions = handler(self, self.NotifyTheatre4Transactions)
    XRpc.NotifyTheatre4FateData = handler(self, self.NotifyTheatre4FateData)
    XRpc.NotifyTheatre4ColorResourceData = handler(self, self.NotifyTheatre4ColorResourceData)
    XRpc.NotifyTheatre4ColorTalentAddInfo = handler(self, self.NotifyTheatre4ColorTalentAddInfo)
    XRpc.NotifyTheatre4BattlePassExp = handler(self, self.NotifyTheatre4BattlePassExp)
    XRpc.NotifyTheatre4ColorTalentData = handler(self, self.NotifyTheatre4ColorTalentData)
    XRpc.NotifyTheatre4RecruitTicks = handler(self, self.NotifyTheatre4RecruitTicks)
    XRpc.NotifyTheatre4ItemBoxs = handler(self, self.NotifyTheatre4ItemBoxs)
    XRpc.NotifyTheatre4ChangeGrids = handler(self, self.NotifyTheatre4ChangeGrids)
    XRpc.NotifyTheatre4AdventureSettle = handler(self, self.NotifyTheatre4AdventureSettle)
    XRpc.NotifyTheatre4Reward = handler(self, self.NotifyTheatre4Reward)
    XRpc.NotifyTheatre4RemoveItem = handler(self, self.NotifyTheatre4RemoveItem)
    XRpc.NotifyTheatre4RemoveTransaction = handler(self, self.NotifyTheatre4RemoveTransaction)
    XRpc.NotifyTheatre4AddTransaction = handler(self, self.NotifyTheatre4AddTransaction)
    XRpc.NotifyTheatre4CustomEffects = handler(self, self.NotifyTheatre4CustomEffects)
    XRpc.NotifyTheatre4CustomResource = handler(self, self.NotifyTheatre4CustomResource)
    XRpc.NotifyTheatre4CustomCounter = handler(self, self.NotifyTheatre4CustomCounter)
    XRpc.NotifyTheatre4EffectsChange = handler(self, self.NotifyTheatre4EffectsChange)
    XRpc.NotifyTheatre4ItemAdd = handler(self, self.NotifyTheatre4ItemAdd)
    XRpc.NotifyTheatre4ItemUpdate = handler(self, self.NotifyTheatre4ItemUpdate)
    XRpc.NotifyTheatre4Atlas = handler(self, self.NotifyTheatre4Atlas)
    XRpc.NotifyTheatre4ExtraMaxAp = handler(self, self.NotifyTheatre4ExtraMaxAp)
    XRpc.NotifyTheatre4CharacterUpdate = handler(self, self.NotifyTheatre4CharacterUpdate)
    XRpc.NotifyTheatre4FinishFightRecord = handler(self, self.NotifyTheatre4FinishFightRecord)
    XRpc.NotifyTheatre4FinishEventRecord = handler(self, self.NotifyTheatre4FinishEventRecord)
    XRpc.NotifyTheatre4AbnormalExit = handler(self, self.NotifyTheatre4AbnormalExit)
    XRpc.NotifyTheatre4FinishDifficultys = handler(self, self.NotifyTheatre4FinishDifficultys)
    XRpc.NotifyTheatre4FinishEndings = handler(self, self.NotifyTheatre4FinishEndings)
    XRpc.NotifyTheatre4TracebackInfo = handler(self, self.NotifyTheatre4TracebackInfo)
    XRpc.NotifyTheatre4SingleTracebackData = handler(self, self.NotifyTheatre4SingleTracebackData)
end

function XTheatre4Agency:InitEvent()
    --实现跨Agency事件注册
    self:AddAgencyEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFightSettle, self)
end

function XTheatre4Agency:RemoveEvent()
    self:RemoveAgencyEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFightSettle, self)
end

--region 服务端通知

-- 下发活动数据
function XTheatre4Agency:NotifyTheatre4ActivityData(data)
    if not data or not data.Data or not XTool.IsNumberValid(data.Data.ActivityId) then
        return
    end
    self._Model:NotifyActivityData(data.Data)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_ACTIVITY_DATA)
end

-- 下发冒险数据
function XTheatre4Agency:NotifyTheatre4AdventureData(data)
    if not data then
        return
    end
    -- 检查是否正在日结算 如果是则记录藏品数据
    if self._Model.IsDailySettling then
        self._Model:RecordDailySettleItemDataList()
    end
    local lastChapterData = self._Model:GetLastChapterData()
    local oldPunishCountdown = -1
    local newPunishCountdown = -1
    if lastChapterData then
        oldPunishCountdown = lastChapterData:GetBossPunishCountdown()
    end
    self._Model.ActivityData:UpdateAdventureData(data.AdventureData)
    if lastChapterData then
        newPunishCountdown = lastChapterData:GetBossPunishCountdown()
    end
    -- 惩罚倒计时变化
    if lastChapterData and not lastChapterData:CheckIsPass() and (oldPunishCountdown == 0 or oldPunishCountdown > newPunishCountdown) then
        -- 入队弹窗
        self._Model:EnqueuePopupData(XEnumConst.Theatre4.PopupType.BloodEffect, true, lastChapterData:GetMapId(), newPunishCountdown)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_ADVENTURE_DATA)
end

-- 下发新章节
function XTheatre4Agency:NotifyTheatre4AddChapter(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:AddChapter(data.Chapter)
    -- 入队弹窗
    self._Model:EnqueuePopupData(XEnumConst.Theatre4.PopupType.ArriveNewArea, data.Chapter.MapGroup, data.Chapter.MapId)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_ADD_CHAPTER)
end

-- 下发事务栈变更
function XTheatre4Agency:NotifyTheatre4Transactions(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateTransactions(data.Transactions)
end

-- 下发时间轴数据
function XTheatre4Agency:NotifyTheatre4FateData(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateFate(data.FateData)
end

-- 下发颜色变化
function XTheatre4Agency:NotifyTheatre4ColorResourceData(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    -- 检查等级是否提升
    local newLevel = self._Model:GetColorTalentLevel(data.Color, data.Point)
    local oldLevel = self._Model:GetColorTalentLevel(data.Color, adventureData:GetColorPointById(data.Color))
    if newLevel > oldLevel then
        -- 入队弹窗
        self._Model:EnqueuePopupData(XEnumConst.Theatre4.PopupType.TalentLevelUp, true, data.Color, newLevel, oldLevel)
    end
    adventureData:UpdateColorAssetData(data.Color, data.Resource, data.Level, data.DailyResource, data.Point, data.PointCanCost)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_COLOR_DATA)
end

-- 下发天赋信息通知
function XTheatre4Agency:NotifyTheatre4ColorTalentAddInfo(data)
    if not data then
        return
    end
    -- 入队弹窗
    self._Model:EnqueuePopupData(XEnumConst.Theatre4.PopupType.TalentLevelUp, false, data.TalentIds)
end

-- 同步 bp exp 数量
function XTheatre4Agency:NotifyTheatre4BattlePassExp(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end

    local oldExp = self._Model.ActivityData:GetTotalBattlePassExp() or 0
    local newExp = data.TotalBattlePassExp or 0

    self._Model.ActivityData:SetTotalBattlePassExp(newExp)
    self._Model:SetIsBattlePassLvUp(newExp > oldExp, newExp)
end

-- 下发颜色信息 全量
function XTheatre4Agency:NotifyTheatre4ColorTalentData(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateColors(data.ColorTalents)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_COLOR_DATA)
end

-- 下发招募卷列表
function XTheatre4Agency:NotifyTheatre4RecruitTicks(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateRecruitTickets(data.RecruitTicks)
end

-- 下发藏品箱列表
function XTheatre4Agency:NotifyTheatre4ItemBoxs(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateItemBoxs(data.ItemBoxs)
end

-- 下发格子变更
function XTheatre4Agency:NotifyTheatre4ChangeGrids(data)
    if not data then
        return
    end
    local curChapterData = self._Model:GetChapterData(data.MapId)
    if not curChapterData then
        return
    end
    curChapterData:UpdateGrids(data.Grids)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_MAP_GRID_DATA, data.MapId)
end

-- 下发冒险结算
function XTheatre4Agency:NotifyTheatre4AdventureSettle(data)
    if not data then
        return
    end
    self._Model.ActivityData:UpdatePreAdventureSettleData(data.SettleData)
    self._Model:RecordAdventureSettleResult(data.AdventureData)
end

-- 下发奖励
function XTheatre4Agency:NotifyTheatre4Reward(data)
    if not data then
        return
    end
    -- 入队弹窗
    self._Model:EnqueuePopupData(XEnumConst.Theatre4.PopupType.AssetReward, data.Rewards)
end

-- 下发移除物品
function XTheatre4Agency:NotifyTheatre4RemoveItem(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    -- 检测剩余持续天数是否为0
    if data.Item and data.Item.LeftDays == 0 then
        local name = self._Model:GetItemNameById(data.Item.ItemId)
        XLuaUiManager.OpenWithCallback("UiTheatre4TipsCommon", function(ui)
            ui.UiProxy.UiLuaTable:Refresh(XUiHelper.GetText("Theatre4ItemExpire", name))
        end)
    end
    adventureData:RemoveItemOrProp(data.Item)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_REMOVE_PROP)
end

-- 下发移除事务
function XTheatre4Agency:NotifyTheatre4RemoveTransaction(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:RemoveTransactionData(data.TrxId)
end

-- 下发添加事务
function XTheatre4Agency:NotifyTheatre4AddTransaction(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:AddTransaction(data.Trx)
end

-- 下发自定义效果
function XTheatre4Agency:NotifyTheatre4CustomEffects(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateCustomEffects(data.Effects)
end

-- 下发自定义资源
function XTheatre4Agency:NotifyTheatre4CustomResource(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:SetGold(data.Gold)
    local oldHp = adventureData:GetHp()
    adventureData:SetHp(data.Hp)
    local newHp = adventureData:GetHp()
    adventureData:SetAp(data.Ap)
    adventureData:SetBp(data.Bp)
    adventureData:SetAwakeningPoint(data.AwakeningPoint)
    adventureData:SetTracebackPoint(data.TracebackPoint)
    adventureData:SetProsperity(data.Prosperity)
    adventureData:SetItemLimit(data.ItemLimit)
    -- 血量变化
    if oldHp > newHp then
        -- 入队弹窗
        self._Model:EnqueuePopupData(XEnumConst.Theatre4.PopupType.BloodEffect, false)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA)
end

-- 下发自定义计数器
function XTheatre4Agency:NotifyTheatre4CustomCounter(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    -- 已购物次数
    adventureData:SetEffectShopBuyTimes(data.EffectShopBuyTimes)
    -- 已扫荡(诏安)次数
    adventureData:SetEffectSweepTimes(data.EffectSweepTimes)
end

-- 下发效果变更
function XTheatre4Agency:NotifyTheatre4EffectsChange(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateAllEffects(data.Effects)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_EFFECT_CHANGE)
end

-- 下发物品增加
function XTheatre4Agency:NotifyTheatre4ItemAdd(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    if data.Item then
        if self._Model:GetItemIsPropById(data.Item.ItemId) == 1 then
            adventureData:AddProp(data.Item)
        else
            adventureData:AddItem(data.Item)
            -- Index 藏品的索引 目前使用不到
        end
    end
    adventureData:AddWaitItem(data.WaitItem)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_ADD_PROP)
end

-- 下发物品更新
function XTheatre4Agency:NotifyTheatre4ItemUpdate(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    if data.Item then
        if self._Model:GetItemIsPropById(data.Item.ItemId) == 1 then
            adventureData:AddProp(data.Item)
        else
            adventureData:AddItem(data.Item)
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_PROP)
end

-- 图鉴变更
function XTheatre4Agency:NotifyTheatre4Atlas(data)
    if not data then
        return
    end
    self._Model:SetItemsAtlas(data.ItemsAtlas or {})
    self._Model:SetTalentAtlas(data.TalentAtlas or {})
    self._Model:SetMapAtlas(data.MapAtlas or {})
    self._Model:ClearAtlasCacheMap()
end

-- 下发额外最大行动点
function XTheatre4Agency:NotifyTheatre4ExtraMaxAp(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:SetExtraMaxAp(data.ExtraMaxAp)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA)
end

-- 下发角色更新
function XTheatre4Agency:NotifyTheatre4CharacterUpdate(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:AddCharacter(data.Character)
end

-- 下发战斗记录
function XTheatre4Agency:NotifyTheatre4FinishFightRecord(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateFinishFightIds(data.FinishFightIds)
end

-- 下发事件记录
function XTheatre4Agency:NotifyTheatre4FinishEventRecord(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:UpdateFinishEventIds(data.FinishEventIds)
    -- 外循环完成事件记录
    self._Model.ActivityData:SetGlobalFinishEventIds(data.GlobalFinishEventIds)
end

-- 发生非正常退出，触发保底保护
function XTheatre4Agency:NotifyTheatre4AbnormalExit(data)
    if not data then
        return
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return
    end
    adventureData:SetClashCount(data.ClashCount)
end

function XTheatre4Agency:NotifyTheatre4FinishDifficultys(data)
    if not data then
        return
    end
    local activityData = self._Model.ActivityData
    if not activityData then
        return false
    end
    activityData:SetDifficultys(data.Difficultys)
end

function XTheatre4Agency:NotifyTheatre4FinishEndings(data)
    if not data then
        return
    end
    local activityData = self._Model.ActivityData
    if not activityData then
        return false
    end
    activityData:SetEndings(data.Endings)
end

--endregion

-- 活动是否开启
function XTheatre4Agency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre4, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipErrorWithKey("CommonActivityNotStart")
        end
        return false
    end
    return true
end

-- 获取活动时间id
function XTheatre4Agency:GetActivityTimeId()
    return self._Model:GetActivityTimeId()
end

--region 已招募角色相关

-- 获取已招募角色的CharacterIds
function XTheatre4Agency:GetRecruitedCharacterIds()
    local configIds = self._Model:GetRecruitedCharacterConfigIds()
    if not configIds then
        return nil
    end
    local characterIds = {}
    for _, configId in pairs(configIds) do
        local characterId = self._Model:GetCharacterIdById(configId)
        if characterId then
            table.insert(characterIds, characterId)
        end
    end
    return characterIds
end

function XTheatre4Agency:GetCharacterList(characterType)
    local characterIds = XMVCA.XTheatre4:GetRecruitedCharacterIds()
    if not characterIds then
        return {}
    end
    local entities = {}
    -- 角色
    if not XTool.IsTableEmpty(characterIds) then
        for _, characterId in pairs(characterIds) do
            if XMVCA.XCharacter:IsOwnCharacter(characterId) then
                local characterData = XMVCA.XCharacter:GetCharacter(characterId)
                table.insert(entities, characterData)
            end
        end
    end
    -- 机器人
    local robotIds = XMVCA.XTheatre4:GetRecruitedRobotIds()
    if not XTool.IsTableEmpty(robotIds) then
        for _, robotId in pairs(robotIds) do
            local entity = XRobotManager.GetRobotById(robotId)
            if entity then
                table.insert(entities, entity)
            end
        end
    end
    return entities
end

-- 获取已招募角色的RobotIds
function XTheatre4Agency:GetRecruitedRobotIds()
    local configIds = self._Model:GetRecruitedCharacterConfigIds()
    if not configIds then
        return nil
    end
    local robotIds = {}
    for _, configId in pairs(configIds) do
        local robotId = self._Model:GetCharacterRobotIdById(configId)
        if robotId then
            table.insert(robotIds, robotId)
        end
    end
    return robotIds
end

--endregion

--region 副本扩展入口

function XTheatre4Agency:ExOpenMainUi()
    local skipId = self:ExGetConfig().SkipId

    -- 先检查跳转，防止配置表未修改时无法进入界面
    if XTool.IsNumberValid(skipId) then
        XFunctionManager.SkipInterface(self:ExGetConfig().SkipId)
    else
        return self:ExOnSkip()
    end
end

function XTheatre4Agency:ExOnSkip()
    if not self:GetIsOpen() then
        return false
    end

    --分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Theatre4) then
        return false
    end

    -- 打开主界面
    return self:CheckPlayEntryStoryAndOpenMainUi()
end

function XTheatre4Agency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenChallengeBanner
        self.ExConfig = XFubenConfigs.GetChapterBannerByType(self:ExGetChapterType())
    end
    return self.ExConfig
end

function XTheatre4Agency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.Theatre4
end

function XTheatre4Agency:ExCheckInTime()
    local timeId = self:GetActivityTimeId()
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        return true
    end
    return false
end

function XTheatre4Agency:ExCheckIsShowRedPoint()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Theatre4) then
        return false
    end

    return self:CheckAllBattlePassRedDot()
end

function XTheatre4Agency:ExGetProgressTip()
    local count = 0
    local currentLevel = 0
    local configs = self._Model:GetBattlePassConfigs()
    local activityData = self._Model.ActivityData
    local totalExp = activityData and activityData:GetTotalBattlePassExp() or 0
    local currentExp = 0
    local desc = self._Model:GetClientConfig("EntryProgressDesc", 1) or ""

    if not XTool.IsTableEmpty(configs) then
        for level, config in pairs(configs) do
            currentExp = currentExp + config.NeedExp
            if currentExp <= totalExp then
                currentLevel = level
            end
            if count < level then
                count = level
            end
        end
    end

    return string.format(desc, currentLevel, count)
end

function XTheatre4Agency:ExCheckIsFinished(cb)
    -- TODO: 检查是否完成
    return false
end

--endregion

--region condition

-- 检查天赋是否存在
---@param talentId number 天赋Id
---@param isOwn boolean 是否拥有 1：持有 0：未持有
function XTheatre4Agency:CheckTalentExist(talentId, isOwn)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local allTalents = adventureData:GetAllActiveTalentIds()
    local exist = table.contains(allTalents, talentId)
    if isOwn == 0 then
        return not exist
    end
    return exist
end

-- 检查事件完成次数
---@param eventId number 事件Id
---@param count number 次数 0：未完成过事件 1-n:完成事件的次数
function XTheatre4Agency:CheckEventFinishCount(eventId, count)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local times = adventureData:GetFinishEventTimes(eventId)
    if count == 0 then
        return times == 0
    end
    return times >= count
end

-- 检查藏品是否存在
---@param itemId number 藏品Id
---@param isOwn boolean 是否拥有 1：持有 0：未持有
function XTheatre4Agency:CheckItemExist(itemId, isOwn)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local count = adventureData:GetItemCountById(itemId)
    if isOwn == 0 then
        return count == 0
    end
    return count > 0
end

-- 检查颜色天赋点的累计数
---@param color number 颜色
---@param point number 天赋点
function XTheatre4Agency:CheckColorPointCount(color, point)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local colorCount = adventureData:GetColorPointById(color)
    return colorCount >= point
end

-- 检查颜色等级的累计数
---@param color number 颜色
---@param level number 需要的等级
function XTheatre4Agency:CheckColorLevelCount(color, level)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local colorLevel = adventureData:GetColorLevelById(color)
    return colorLevel >= level
end

-- 检查金币是否满足要求
---@param compareType number 比较类型 1：大于等于 2：小于等于
---@param count number 金币数量
function XTheatre4Agency:CheckGoldCount(compareType, count)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local goldCount = adventureData:GetGold()
    if compareType == 1 then
        return goldCount >= count
    end
    return goldCount <= count
end

-- 检查血量是否满足要求
---@param compareType number 比较类型 1：大于等于 2：小于等于
---@param count number 血量数量
function XTheatre4Agency:CheckHpCount(compareType, count)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local hpCount = adventureData:GetHp()
    if compareType == 1 then
        return hpCount >= count
    end
    return hpCount <= count
end

-- 检查天赋点是否最高
---@param color number 颜色
function XTheatre4Agency:CheckColorPointIsLargest(color)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local colorPoint = adventureData:GetColorPointById(color)
    for _, id in pairs(XEnumConst.Theatre4.ColorType) do
        if id ~= color and adventureData:GetColorPointById(id) > colorPoint then
            return false
        end
    end
    return true
end

-- 检查繁荣度是否满足要求
---@param prosperity number 繁荣度
function XTheatre4Agency:CheckProsperityCount(prosperity)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local prosperityCount = adventureData:GetProsperity()
    return prosperityCount >= prosperity
end

-- 检查难度完成次数
---@param difficultyId number 难度Id 0 任意难度（失败不算）非0 指定难度
---@param count number 完成次数
function XTheatre4Agency:CheckDifficultyCompleteCount(difficultyId, count)
    local activityData = self._Model.ActivityData
    if not activityData then
        return false
    end
    local difficultyList = activityData:GetDifficultys()
    local completeCount = 0
    if difficultyId == 0 then
        for _, num in pairs(difficultyList) do
            completeCount = completeCount + num
        end
    else
        completeCount = difficultyList[difficultyId] or 0
    end
    return completeCount >= count
end

-- 检查结局完成次数
---@param endingId number 结局Id 0 任意结局（失败结局不算）非0 指定结局
---@param count number 完成次数
function XTheatre4Agency:CheckEndingCompleteCount(endingId, count)
    local activityData = self._Model.ActivityData
    if not activityData then
        return false
    end
    local endingList = activityData:GetEndings()
    local completeCount = 0
    if endingId == 0 then
        for _, num in pairs(endingList) do
            completeCount = completeCount + num
        end
    else
        completeCount = endingList[endingId] or 0
    end
    return completeCount >= count
end

-- 检查是否通过指定战斗
---@param fightId number 战斗Id
function XTheatre4Agency:CheckFightIsPass(fightId)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local finishFightIds = adventureData:GetFinishFightIds()
    return table.contains(finishFightIds, fightId)
end

-- 检查是否处于特定章节
---@param compareType number 比较类型 1：大于 2：小于 3：等于
---@param count number 章节数
function XTheatre4Agency:CheckCurSpecificChapter(compareType, count)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local chapterCount = adventureData:GetChapterCount()
    if compareType == 1 then
        return chapterCount > count
    end
    if compareType == 2 then
        return chapterCount < count
    end
    return chapterCount == count
end

-- 检查颜色等级是否最大
---@param color number 颜色
function XTheatre4Agency:CheckColorLevelIsLargest(color)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local colorLevel = adventureData:GetColorLevelById(color)
    for _, id in pairs(XEnumConst.Theatre4.ColorType) do
        if id ~= color and adventureData:GetColorLevelById(id) > colorLevel then
            return false
        end
    end
    return true
end

-- 检查全局事件完成次数
---@param eventId number 事件Id
---@param count number 完成次数
function XTheatre4Agency:CheckGlobalEventFinishCount(eventId, count)
    local activityData = self._Model.ActivityData
    if not activityData then
        return false
    end
    local times = activityData:GetGlobalFinishEventTimes(eventId)
    if count == 0 then
        return times == 0
    end
    return times >= count
end

-- 检查格子是否完成
---@param mapId number 地图Id
---@param x number x坐标
---@param y number y坐标
function XTheatre4Agency:CheckGridFinish(mapId, x, y)
    local chapter = self._Model:GetChapterData(mapId)
    if not chapter then
        return false
    end
    local gridId = chapter:GetGridId(x, y)
    if not XTool.IsNumberValid(gridId) then
        return false
    end
    local grid = chapter:GetGridData(gridId)
    if not grid then
        return false
    end
    return grid:IsGridStateProcessed()
end

-- 检查本局内当前所选的难度
---@param compareType number 比较类型 1：等于(只比较一个值) 2：大于等于 3：小于等于 4: 任意一个等于(比较一个以上的值)
---@param params number[] 难度Ids
---@param index number 难度Id开始索引
function XTheatre4Agency:CheckCurDifficulty(compareType, params, index)
    if XTool.IsTableEmpty(params) or #params < index then
        return false
    end

    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end

    local curDifficulty = adventureData:GetDifficulty()
    if curDifficulty <= 0 then
        return false
    end

    if compareType == 1 then
        return curDifficulty == params[index]
    elseif compareType == 2 then
        return curDifficulty >= params[index]
    elseif compareType == 3 then
        return curDifficulty <= params[index]
    elseif compareType == 4 then
        for i = index, #params do
            if curDifficulty == params[i] then
                return true
            end
        end
    end

    return false
end

--endregion condition

--region Fight 副本相关

-- 获取金币数量（外部调用）
function XTheatre4Agency:GetGoldCount()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetGold()
end

-- 获取金币名称（外部调用）
function XTheatre4Agency:GetGoldName()
    return self._Model:GetAssetName(XEnumConst.Theatre4.AssetType.Gold)
end

-- 获取重启金币名称（外部调用）
function XTheatre4Agency:GetRestartGoldName()
    return self._Model:GetClientConfig("RestartGoldName", 1) or ""
end

-- 获取重启消耗（外部调用）
function XTheatre4Agency:GetFubenRestartCostById(rebootId)
    return self._Model:GetFubenRestartCostById(rebootId)
end

-- 战前准备
---@param stage XTableStage
function XTheatre4Agency:PreFight(stage, teamId, isAssist, challengeCount)
    local teamData = self._Model:GetTeam():GetTeamData()
    local preFight = {}
    preFight.RobotIds = teamData.RobotIds
    preFight.CardIds = teamData.CardIds
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist
    preFight.ChallengeCount = challengeCount
    preFight.CaptainPos = teamData.CaptainPos
    preFight.FirstFightPos = teamData.FirstFightPos
    preFight.GeneralSkill = teamData.GeneralSkill
    preFight.EnterCgIndex = teamData.EnterCgIndex
    preFight.SettleCgIndex = teamData.SettleCgIndex
    return preFight
end

-- 进入战斗
function XTheatre4Agency:EnterFight(stageId, teamId, isAssist, challengeCount)
    self._Model.IsManualEndBattle = false
    -- 额外数据
    local extraData = self._Model:GetTeam():GetExtraData()
    local request
    if not extraData then
        request = { Type = XEnumConst.Theatre4.FightLocateType.Fate }
    else
        request = {
            Type = XEnumConst.Theatre4.FightLocateType.Grid,
            MapId = extraData.MapId,
            PosX = extraData.PosX,
            PosY = extraData.PosY
        }
    end
    -- 战斗类型定位
    XNetwork.Call("Theatre4FightLocateRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 进入战斗
        XMVCA.XFuben:EnterFightByStageId(stageId, teamId, isAssist, challengeCount)
    end)
end

-- 结束战斗(包含手动结束和战斗结束)
function XTheatre4Agency:CallFinishFight()
    local res = XMVCA.XFuben:GetFubenSettleResult()
    -- 手动结束
    if not res then
        XMVCA.XFuben:ResetSettle()
        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
        -- 恢复回系统音声设置 避免战斗里将BGM音量设置为0导致结算后没有声音
        XLuaAudioManager.ResetSystemAudioVolume()
        -- 打开黑幕界面
        self:OpenBlackUi()
        self._Model.IsManualEndBattle = true
        return
    end
    self._Model.IsManualEndBattle = false
    -- 战斗结束
    XMVCA.XFuben:CallFinishFight()
end

-- 战斗结束
function XTheatre4Agency:FinishFight(settle)
    if self._Model.IsManualEndBattle then
        return
    end
    if not self:CheckAndOpenAdventureSettle(true) then
        -- 结算数据为空，关闭黑幕界面
        self:CloseBlackUi()
    end
end

function XTheatre4Agency:OnFightSettle(settle)
    if not self._Model.IsManualEndBattle then
        return
    end
    self._Model.IsManualEndBattle = false
    if not self:CheckAndOpenAdventureSettle(true) then
        -- 结算数据为空，关闭黑幕界面
        self:CloseBlackUi()
    end
end

--endregion

--region 黑幕相关

-- 打开黑幕界面
function XTheatre4Agency:OpenBlackUi()
    if not self:IsBlackUiOpen() then
        XLuaUiManager.Open("UiBiancaTheatreBlack")
    end
end

-- 黑幕界面是否打开
function XTheatre4Agency:IsBlackUiOpen()
    return XLuaUiManager.IsUiLoad("UiBiancaTheatreBlack")
end

-- 关闭黑幕界面
function XTheatre4Agency:CloseBlackUi()
    if self:IsBlackUiOpen() then
        XLuaUiManager.Close("UiBiancaTheatreBlack")
    end
end

-- 移除黑幕界面
function XTheatre4Agency:RemoveBlackUi()
    if self:IsBlackUiOpen() then
        XLuaUiManager.Remove("UiBiancaTheatreBlack")
    end
end

-- 移除界面
function XTheatre4Agency:RemoveAdventureUi()
    XLuaUiManager.Remove("UiTheatre4Shop")
    XLuaUiManager.Remove("UiTheatre4Game")
    XLuaUiManager.SafeClose("UiTheatre4ReceiveReward")
end

-- 检查并打开冒险结算
---@param isFightEnd boolean 是否战斗结束
function XTheatre4Agency:CheckAndOpenAdventureSettle(isFightEnd)
    local settleResult = self._Model:GetAdventureSettleResult()
    if not settleResult then
        return false
    end
    local settleType = self._Model:GetAdventureSettleType()
    if settleType == XEnumConst.Theatre4.SettleType.Failed then
        local title = self._Model:GetClientConfig("AdventureFailedPopupTitle", 1) or ""
        local content = self._Model:GetClientConfig("AdventureFailedPopupContent", 1) or ""
        local confirmText = self._Model:GetClientConfig("AdventureFailedPopupConfirmText", 1) or ""
        local sureCallback = handler(self, self.DoAdventureSettle)
        -- 如果是战斗结束后弹失败提示需要先打开黑幕界面
        if isFightEnd then
            self:OpenBlackUi()
        end
        XLuaUiManager.Open("UiTheatre4PopupCommon", title, content, sureCallback, nil, { SureText = confirmText, IsHideCancel = true })
    else
        self:DoAdventureSettle()
    end
    return true
end

-- 进行冒险结算
function XTheatre4Agency:DoAdventureSettle()
    -- 清空活动里的冒险数据
    self._Model.ActivityData:UpdateAdventureData(nil)
    -- 清理弹框数据
    self._Model:ClearAllPopupData()
    local endingId = self._Model:GetAdventureEndingId()
    if not XTool.IsNumberValid(endingId) then
        self:CloseBlackUi()
        return
    end
    local storyId = self:GetEndingStoryId(endingId)
    if storyId then
        self:OpenBlackUi()
        -- 打开剧情
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            self:RemoveBlackUi()
            self:RemoveAdventureUi()
            XLuaUiManager.Open("UiTheatre4EndLoading", endingId)
        end, nil, nil, false)
    else
        self:RemoveBlackUi()
        self:RemoveAdventureUi()
        XLuaUiManager.Open("UiTheatre4EndLoading", endingId)
    end
end

-- 获取结局剧情Id
function XTheatre4Agency:GetEndingStoryId(endingId)
    local endingConfig = self._Model:GetEndingConfigById(endingId)
    if not endingConfig or XTool.IsTableEmpty(endingConfig.StoryId) then
        return nil
    end
    for index, storyId in pairs(endingConfig.StoryId) do
        local condition = endingConfig.StoryCondition[index]
        if not XTool.IsNumberValid(condition) or XConditionManager.CheckCondition(condition) then
            return storyId
        end
    end
    return nil
end

--endregion

--region 红点相关

function XTheatre4Agency:CheckAllTechRedDot()
    if self:GetIsOpen(true) then
        local configs = self._Model:GetTechConfigs()

        if not XTool.IsTableEmpty(configs) then
            for id, config in pairs(configs) do
                if self:CheckTechUnlock(id) and not self:CheckTechActived(id) then
                    local itemCount = XDataCenter.ItemManager.GetCount(
                        XDataCenter.ItemManager.ItemId.Theatre4TechTreeCoin)

                    return config.Cost <= itemCount
                end
            end
        end
    end

    return false
end

function XTheatre4Agency:CheckTechActived(id)
    if self:GetIsOpen(true) then
        local activedTech = self._Model:GetActivedTechIdMap()

        return activedTech[id] or false
    end

    return false
end

function XTheatre4Agency:CheckTechUnlock(id)
    if self:GetIsOpen(true) then
        local preIds = self._Model:GetTechPreIdsById(id)

        if not XTool.IsTableEmpty(preIds) then
            for _, id in pairs(preIds) do
                if not self:CheckTechUnlock(id) then
                    return false
                end
                if not self:CheckTechActived(id) then
                    return false
                end
            end
        end

        local condition = self._Model:GetTechConditionById(id)

        if XTool.IsNumberValid(condition) then
            if not XConditionManager.CheckCondition(condition) then
                return false
            end
        end

        return true
    end

    return false
end

function XTheatre4Agency:CheckAllHandBookRedDot()
    -- return self:CheckItemHandBookRedDot() or self:CheckColorTalentHandBookRedDot() or self:CheckMapIndexHandBookRedDot()
    return self:CheckItemHandBookRedDot() or self:CheckColorTalentHandBookRedDot()
end

function XTheatre4Agency:CheckItemHandBookRedDot()
    if self:GetIsOpen(true) then
        local unlockItems = self._Model:GetItemsAtlas()
        local localItemMap = self._Model:GetLocalUnlockItemMap()

        for _, itemId in pairs(unlockItems) do
            if not localItemMap[itemId] then
                return true
            end
        end
    end

    return false
end

function XTheatre4Agency:CheckColorTalentHandBookRedDot()
    if self:GetIsOpen(true) then
        local unlockTalents = self._Model:GetTalentAtlas()
        local localTalentMap = self._Model:GetLocalUnlockColorTalentMap()

        for _, talentId in pairs(unlockTalents) do
            local talentType = self._Model:GetColorTalentTypeById(talentId)

            if not localTalentMap[talentId] and talentType == XEnumConst.Theatre4.TalentType.Big then
                return true
            end
        end
    end

    return false
end

function XTheatre4Agency:CheckMapIndexHandBookRedDot()
    if self:GetIsOpen(true) then
        local unlockMaps = self._Model:GetMapAtlas()
        local localIndexMap = self._Model:GetLocalUnlockMapIndexMap()

        for _, index in pairs(unlockMaps) do
            if not localIndexMap[index] then
                return true
            end
        end
    end

    return false
end

function XTheatre4Agency:CheckAllBattlePassRedDot()
    return self:CheckBattlePassRedDot() or self:CheckAllBattlePassTaskRedDot()
end

function XTheatre4Agency:CheckBattlePassRedDot()
    if self:GetIsOpen(true) then
        local receiveIds = self._Model:GetBattlePassRewardIdMap()
        local totalExp = self._Model.ActivityData:GetTotalBattlePassExp()
        local configs = self._Model:GetBattlePassConfigs()
        local currentExp = 0

        for level, config in pairs(configs) do
            currentExp = currentExp + config.NeedExp

            if not receiveIds[config.Level] and totalExp >= currentExp then
                return true
            end
        end
    end

    return false
end

function XTheatre4Agency:CheckAllBattlePassTaskRedDot()
    return self:CheckBattlePassChallengeTaskRedDot() or self:CheckBattlePassVersionTaskRedDot()
        or self:CheckBattlePassProcessTaskRedDot()
end

function XTheatre4Agency:CheckBattlePassTaskRedDotByTaskType(taskType)
    if self:GetIsOpen(true) then
        local taskIdList = self._Model:GetTaskTaskIdById(taskType)

        if not XTool.IsTableEmpty(taskIdList) then
            for _, taskId in pairs(taskIdList) do
                if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                    return true
                end
            end
        end
    end

    return false
end

function XTheatre4Agency:CheckBattlePassChallengeTaskRedDot()
    return self:CheckBattlePassTaskRedDotByTaskType(XEnumConst.Theatre4.BattlePassTaskType.ChallengeTask)
end

function XTheatre4Agency:CheckBattlePassProcessTaskRedDot()
    return self:CheckBattlePassTaskRedDotByTaskType(XEnumConst.Theatre4.BattlePassTaskType.ProcessTask)
end

function XTheatre4Agency:CheckBattlePassVersionTaskRedDot()
    return self:CheckBattlePassTaskRedDotByTaskType(XEnumConst.Theatre4.BattlePassTaskType.VersionTask)
end

--endregion

--region 编队相关

-- 获取角色配置Id
function XTheatre4Agency:GetCharacterConfigIdByEntityId(entityId)
    local configIds = self._Model:GetRecruitedCharacterConfigIds()
    if not configIds then
        return 0
    end
    local isRobot = XRobotManager.CheckIsRobotId(entityId)
    for _, configId in ipairs(configIds) do
        if isRobot then
            if self._Model:GetCharacterRobotIdById(configId) == entityId then
                return configId
            end
        else
            if self._Model:GetCharacterIdById(configId) == entityId then
                return configId
            end
        end
    end
    return 0
end

-- 获取角色星级
function XTheatre4Agency:GetCharacterStar(entityId)
    local configId = self:GetCharacterConfigIdByEntityId(entityId)
    if configId == 0 then
        return 0
    end
    local characterData = self._Model:GetCharacterData(configId)
    if not characterData then
        return 0
    end
    return characterData:GetStar()
end

-- 获取角色颜色等级
function XTheatre4Agency:GetCharacterColorLevel(entityId)
    local configId = self:GetCharacterConfigIdByEntityId(entityId)
    if configId == 0 then
        return 0
    end
    local characterData = self._Model:GetCharacterData(configId)
    if not characterData then
        return 0
    end
    return characterData:GetColorLevelAdds()
end

--endregion

--region 入场剧情相关

function XTheatre4Agency:GetFirstEntryStoryId()
    return self._Model:GetClientConfig("FirstEntryStoryId", 1)
end

function XTheatre4Agency:GetSaveFirstEntryStoryKey(storyId)
    local activityId = self._Model:GetActivityId()

    return string.format("THEATRE4_FIRST_ENTRY_STORY_%s_%s_%s", storyId, XPlayer.Id, activityId)
end

function XTheatre4Agency:CheckLocalPlayedEntryStory()
    local storyId = self:GetFirstEntryStoryId()
    local key = self:GetSaveFirstEntryStoryKey(storyId)

    return XSaveTool.GetData(key) or false
end

function XTheatre4Agency:SaveFirstEntryStory()
    local storyId = self:GetFirstEntryStoryId()
    local key = self:GetSaveFirstEntryStoryKey(storyId)

    XSaveTool.SaveData(key, true)
end

function XTheatre4Agency:CheckPlayEntryStoryAndOpenMainUi()
    local storyId = self:GetFirstEntryStoryId()

    if self:CheckLocalPlayedEntryStory() or string.IsNilOrEmpty(storyId) then
        XLuaUiManager.Open("UiTheatre4Main")
    else
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            XLuaUiManager.Open("UiTheatre4Main")
        end, nil, nil, false)
        self:SaveFirstEntryStory()
    end
    
    return true
end

--endregion

function XTheatre4Agency:NotifyTheatre4TracebackInfo(data)
    self._Model:GetAdventureData():SetTracebackDatas(data.TracebackDatas)
end

function XTheatre4Agency:NotifyTheatre4SingleTracebackData(serverData)
    local data = serverData.Data
    self._Model:GetAdventureData():SetTracebackDataByDays(data, data.Days)
end

function XTheatre4Agency:GetDays()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetDays()
end

function XTheatre4Agency:GetEffectRedBuyDeadAvailable()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return false
    end
    local allTalentEffects = adventureData:GetCustomEffects()
    for i, effect in pairs(allTalentEffects) do
        local effectId = effect:GetEffectId()
        local effectType = self._Model:GetEffectTypeById(effectId)
        if effectType == XEnumConst.Theatre4.EffectType.Type424 then
            return true
        end
    end
    return false
end

return XTheatre4Agency
