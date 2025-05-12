-- 冒险数据
---@class XTheatre4Adventure
local XTheatre4Adventure = XClass(nil, "XTheatre4Adventure")

function XTheatre4Adventure:Ctor()
    -- 难度
    self.Difficulty = 0
    -- 初始藏品Id
    self.Affix = 0
    -- 继承的藏品Id
    self.InheritItemId = 0
    -- 血量
    self.Hp = 0
    -- 行动点
    self.Ap = 0
    -- 最大行动点
    self.MaxAp = 0
    -- 额外最大行动点
    self.ExtraMaxAp = 0
    -- 建筑点数
    self.Bp = 0
    -- 觉醒值
    self.AwakeningPoint = 0
    -- 回溯次数
    self.TracebackPoint = 0
    -- 金币
    self.Gold = 0
    -- 结算额外给予的Bp经验
    self.SettleBpExp = 0
    -- 当前天数
    self.Days = 0
    -- 繁荣度
    self.Prosperity = 0
    -- id序列（生成单局游戏元素唯一id自增用）
    self.IdSequence = 0
    -- 闪退，掉线，强退次数
    self.ClashCount = 0
    -- 藏品限制
    self.ItemLimit = 0
    -- 颜色限制
    ---@type number[]
    self.ColorLimit = {}
    -- 招募卷列表
    ---@type number[]
    self.RecruitTickets = {}
    -- 藏品箱列表
    ---@type number[]
    self.ItemBoxs = {}
    -- 代办事务栈
    ---@type table<number, XTheatre4Transaction>
    self.Transactions = {}
    -- 公共效果集（效果自身管理生命周期：词缀效果、事件效果）
    ---@type table<number, XTheatre4Effect>
    self.CustomEffects = {}
    -- 藏品列表（玩法物品） 占用上限
    ---@type table<number, XTheatre4Item>
    self.Items = {}
    -- 线索道具 不占用上限
    ---@type table<number, XTheatre4Item>
    self.Props = {}
    -- 待处理藏品队列
    ---@type number[]
    self.WaitItems = {}
    -- 已招募角色
    ---@type table<number, XTheatre4CharacterData>
    self.Characters = {}
    -- 当前队伍
    ---@type XTheatre4TeamData
    self.TeamData = nil
    -- 颜色属性
    ---@type table<number, XTheatre4ColorTalent>
    self.Colors = {}
    -- 线路id
    self.MapBlueprintId = 0
    -- 命运（时间轴）

    --region fate
    ---abandon
    ---@type XTheatre4Fate
    self.Fate = nil
    self.FateId = 0
    ---@type XTheatre4Fate[]
    self.FateList = {}
    --endregion fate

    -- 章节（关卡）数据集
    ---@type XTheatre4ChapterData[]
    self.Chapters = {}
    -- 探索计数
    self.ExploreCount = 0
    -- 每日探索位置记录
    ---@type table<number, XTheatre4Pos>
    self.DailyExplorePosSet = {}
    -- 每日探索颜色记录
    ---@type number[]
    self.DailyExploreColors = {}
    -- 上一次探索的X,Y坐标
    ---@type XTheatre4Pos
    self.PreExplorePos = nil
    -- 格子生成过的Box组Id集
    ---@type number[]
    self.CreatedBoxGroupIds = {}
    -- 格子生成过的事件组id集
    ---@type number[]
    self.CreatedEventGroupIds = {}
    -- 格子生成过的商城id集
    ---@type number[]
    self.CreatedShopGroupIds = {}
    -- 格子生成过的战斗id集
    ---@type number[]
    self.CreatedFightGroupIds = {}
    -- 完成挑战的战斗id集
    self.FinishFightIds = {}
    -- 触发的事件记录
    ---@type table<number, number> 事件Id, 次数
    self.FinishEventIds = {}
    -- 事件选项记录
    ---@type number[]
    self.OptionIds = {}
    -- 效果相关-建造前触发过改造
    ---@type boolean
    self.EffectGridAlterBeforeBuilt = false
    -- 效果相关-已购物次数
    self.EffectShopBuyTimes = 0
    -- 效果相关-已扫荡(诏安)次数
    self.EffectSweepTimes = 0
    -- 开始时间（本局唯一id）
    self.StartTime = 0
    -- 回溯数据, 用字典保证key(天数)的唯一性
    self.TracebackDatas = {}
end

-- 服务端通知
function XTheatre4Adventure:NotifyAdventureData(data)
    self.Difficulty = data.Difficulty or 0
    self.Affix = data.Affix or 0
    self.InheritItemId = data.InheritItemId or 0
    self.Hp = data.Hp or 0
    self.Ap = data.Ap or 0
    self.MaxAp = data.MaxAp or 0
    self.ExtraMaxAp = data.ExtraMaxAp or 0
    self.Bp = data.Bp or 0
    self.AwakeningPoint = data.AwakeningPoint or 0
    self.TracebackPoint = data.TracebackPoint or 0
    self.Gold = data.Gold or 0
    self.SettleBpExp = data.SettleBpExp or 0
    self.Days = data.Days or 0
    self.Prosperity = data.Prosperity or 0
    self.IdSequence = data.IdSequence or 0
    self.ClashCount = data.ClashCount or 0
    self.ItemLimit = data.ItemLimit or 0
    self.ColorLimit = data.ColorLimit or {}
    self.RecruitTickets = data.RecruitTickets or {}
    self.ItemBoxs = data.ItemBoxs or {}
    self:UpdateTransactions(data.Transactions)
    self:UpdateCustomEffects(data.CustomEffects)
    self:UpdateItems(data.Items)
    self:UpdateProps(data.Props)
    self.WaitItems = data.WaitItems or {}
    self:UpdateCharacters(data.Characters)
    self:UpdateTeamData(data.TeamData)
    self:UpdateColors(data.Colors)
    self.MapBlueprintId = data.MapBlueprintId or 0
    self:UpdateFate(data.Fate)
    self:UpdateChapters(data.Chapters)
    self.ExploreCount = data.ExploreCount or 0
    self:UpdateDailyExplorePosSet(data.DailyExplorePosSet)
    self.DailyExploreColors = data.DailyExploreColors or {}
    self:UpdatePreExplorePos(data.PreExplorePos)
    self.CreatedBoxGroupIds = data.CreatedBoxGroupIds or {}
    self.CreatedEventGroupIds = data.CreatedEventGroupIds or {}
    self.CreatedShopGroupIds = data.CreatedShopGroupIds or {}
    self.CreatedFightGroupIds = data.CreatedFightGroupIds or {}
    self.FinishFightIds = data.FinishFightIds or {}
    self.FinishEventIds = data.FinishEventIds or {}
    self.OptionIds = data.OptionIds or {}
    self.EffectGridAlterBeforeBuilt = data.EffectGridAlterBeforeBuilt or false
    self.EffectShopBuyTimes = data.EffectShopBuyTimes or 0
    self.EffectSweepTimes = data.EffectSweepTimes or 0
    self.StartTime = data.StartTime or 0
    self.TracebackDatas = data.TracebackDatas or {}
end

function XTheatre4Adventure:UpdateTransactions(data)
    self.Transactions = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddTransaction(v)
    end
end

function XTheatre4Adventure:AddTransaction(data)
    if not data then
        return
    end
    ---@type XTheatre4Transaction
    local transaction = self.Transactions[data.Id]
    if not transaction then
        transaction = require("XModule/XTheatre4/XEntity/XTheatre4Transaction").New()
        self.Transactions[data.Id] = transaction
    end
    transaction:NotifyTransactionData(data)
end

-- 更新事务数据 不添加新的事务
function XTheatre4Adventure:UpdateTransaction(data)
    if not data then
        return
    end
    ---@type XTheatre4Transaction
    local transaction = self.Transactions[data.Id]
    if transaction then
        transaction:NotifyTransactionData(data)
    end
end

function XTheatre4Adventure:UpdateCustomEffects(data)
    self.CustomEffects = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddCustomEffects(v)
    end
end

function XTheatre4Adventure:AddCustomEffects(data)
    if not data then
        return
    end
    ---@type XTheatre4Effect
    local effect = self.CustomEffects[data.Id]
    if not effect then
        effect = require("XModule/XTheatre4/XEntity/XTheatre4Effect").New()
        self.CustomEffects[data.Id] = effect
    end
    effect:NotifyEffectData(data)
end

function XTheatre4Adventure:UpdateItems(data)
    self.Items = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddItem(v)
    end
end

function XTheatre4Adventure:AddItem(data)
    if not data then
        return
    end
    ---@type XTheatre4Item
    local item = self.Items[data.Uid]
    if not item then
        item = require("XModule/XTheatre4/XEntity/XTheatre4Item").New()
        self.Items[data.Uid] = item
    end
    item:NotifyItemData(data)
end

function XTheatre4Adventure:UpdateProps(data)
    self.Props = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddProp(v)
    end
end

function XTheatre4Adventure:AddProp(data)
    if not data then
        return
    end
    ---@type XTheatre4Item
    local prop = self.Props[data.Uid]
    if not prop then
        prop = require("XModule/XTheatre4/XEntity/XTheatre4Item").New()
        self.Props[data.Uid] = prop
    end
    prop:NotifyItemData(data)
end

-- 移除藏品或者道具
function XTheatre4Adventure:RemoveItemOrProp(data)
    if not data then
        return
    end
    if self.Items[data.Uid] then
        self.Items[data.Uid] = nil
    end
    if self.Props[data.Uid] then
        self.Props[data.Uid] = nil
    end
end

function XTheatre4Adventure:UpdateCharacters(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddCharacter(v)
    end
end

function XTheatre4Adventure:AddCharacter(data)
    if not data then
        return
    end
    ---@type XTheatre4CharacterData
    local character = self.Characters[data.CharacterId]
    if not character then
        character = require("XModule/XTheatre4/XEntity/XTheatre4CharacterData").New()
        self.Characters[data.CharacterId] = character
    end
    character:NotifyCharacterData(data)
end

function XTheatre4Adventure:UpdateTeamData(data)
    if not data then
        self.TeamData = nil
        return
    end
    if not self.TeamData then
        self.TeamData = require("XModule/XTheatre4/XEntity/XTheatre4TeamData").New()
    end
    self.TeamData:NotifyTeamData(data)
end

function XTheatre4Adventure:UpdateColors(data)
    self.Colors = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddColor(v)
    end
end

function XTheatre4Adventure:AddColor(data)
    if not data then
        return
    end
    ---@type XTheatre4ColorTalent
    local color = self.Colors[data.Color]
    if not color then
        color = require("XModule/XTheatre4/XEntity/XTheatre4ColorTalent").New()
        self.Colors[data.Color] = color
    end
    color:NotifyColorData(data)
end

function XTheatre4Adventure:UpdateFate(data)
    if not data then
        self.FateId = 0
        self.FateList = {}
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_FATE_DATA)
        return
    end
    self.FateId = data.Id
    if data.FateEvents then
        for i = 1, #data.FateEvents do
            local fateEventData = data.FateEvents[i]
            local fateEvent = self.FateList[i]
            if not fateEvent then
                fateEvent = require("XModule/XTheatre4/XEntity/XTheatre4Fate").New()
                self.FateList[i] = fateEvent
            end
            fateEvent:NotifyFateData(fateEventData)
        end
        for i = #data.FateEvents + 1, #self.FateList do
            self.FateList[i] = nil
        end
        table.sort(self.FateList, function(a, b)
            return a:GetEventTimeLeft() < b:GetEventTimeLeft()
        end)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_FATE_DATA)
end

function XTheatre4Adventure:UpdateChapters(data)
    if not data then
        return
    end
    for _, v in ipairs(data) do
        self:AddChapter(v)
    end
end

function XTheatre4Adventure:AddChapter(data)
    if not data then
        return
    end
    -- 根据MapGroup和MapId判断是否已存在 已存在直接刷新数据
    for _, chapter in ipairs(self.Chapters) do
        if chapter:GetMapGroup() == data.MapGroup and chapter:GetMapId() == data.MapId then
            chapter:NotifyChapterData(data)
            return
        end
    end
    -- 不存在则添加新的章节
    ---@type XTheatre4ChapterData
    local chapter = require("XModule/XTheatre4/XEntity/XTheatre4ChapterData").New()
    chapter:NotifyChapterData(data)
    table.insert(self.Chapters, chapter)
end

function XTheatre4Adventure:UpdateDailyExplorePosSet(data)
    self.DailyExplorePosSet = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddDailyExplorePos(v)
    end
end

function XTheatre4Adventure:AddDailyExplorePos(data)
    if not data then
        return
    end
    ---@type XTheatre4Pos
    local pos = self.DailyExplorePosSet[data.MapId]
    if not pos then
        pos = require("XModule/XTheatre4/XEntity/XTheatre4Pos").New()
        self.DailyExplorePosSet[data.MapId] = pos
    end
    pos:NotifyPosData(data)
end

function XTheatre4Adventure:UpdatePreExplorePos(data)
    if not data then
        self.PreExplorePos = nil
        return
    end
    if not self.PreExplorePos then
        self.PreExplorePos = require("XModule/XTheatre4/XEntity/XTheatre4Pos").New()
    end
    self.PreExplorePos:NotifyPosData(data)
end

-- 获取所有章节数据
---@return XTheatre4ChapterData[]
function XTheatre4Adventure:GetChapters()
    return self.Chapters
end

-- 获取章节数据
---@return XTheatre4ChapterData
function XTheatre4Adventure:GetChapterData(mapId)
    for index, chapter in pairs(self.Chapters) do
        if chapter:GetMapId() == mapId then
            return chapter, index
        end
    end
    return nil, 0
end

-- 获取最后一个章节数据
---@return XTheatre4ChapterData
function XTheatre4Adventure:GetLastChapterData()
    return self.Chapters[#self.Chapters] or nil
end

-- 获取倒数第二个章节数据
---@return XTheatre4ChapterData
function XTheatre4Adventure:GetPreLastChapterData()
    return self.Chapters[#self.Chapters - 1] or nil
end

-- 获取章节数量
function XTheatre4Adventure:GetChapterCount()
    return #self.Chapters
end

-- 获取章节通过的数量
function XTheatre4Adventure:GetChapterPassCount()
    local count = 0
    for _, chapter in pairs(self.Chapters) do
        if chapter:CheckIsPass() then
            count = count + 1
        end
    end
    return count
end

-- 获取事务数据
---@return XTheatre4Transaction
function XTheatre4Adventure:GetTransactionData(transactionId)
    return self.Transactions[transactionId] or nil
end

-- 获取事务数据 根据事务类型
---@return XTheatre4Transaction
function XTheatre4Adventure:GetTransactionDataByType(transactionType)
    for _, transaction in pairs(self.Transactions) do
        if transaction:GetType() == transactionType then
            return transaction
        end
    end
    return nil
end

-- 获取事务数据的数量 根据事务类型
function XTheatre4Adventure:GetTransactionDataCountByType(transactionType)
    local count = 0
    for _, transaction in pairs(self.Transactions) do
        if transaction:GetType() == transactionType then
            count = count + 1
        end
    end
    return count
end

-- 移除事务数据
function XTheatre4Adventure:RemoveTransactionData(transactionId)
    self.Transactions[transactionId] = nil
end

-- 获取所有已招募角色Ids
function XTheatre4Adventure:GetCharacterIds()
    local characterIds = {}
    for k, _ in pairs(self.Characters) do
        table.insert(characterIds, k)
    end
    return characterIds
end

-- 获取角色数据
---@return XTheatre4CharacterData
function XTheatre4Adventure:GetCharacterData(characterId)
    return self.Characters[characterId] or nil
end

-- 获取角色最高的星级
function XTheatre4Adventure:GetCharacterMaxStar()
    local maxStar = 0
    for _, character in pairs(self.Characters) do
        if character:GetStar() > maxStar then
            maxStar = character:GetStar()
        end
    end
    return maxStar
end

-- 获取队伍数据
---@return XTheatre4TeamData
function XTheatre4Adventure:GetTeamData()
    return self.TeamData
end

-- 获取线路Id
function XTheatre4Adventure:GetMapBlueprintId()
    return self.MapBlueprintId
end

-- 更新招募卷
function XTheatre4Adventure:UpdateRecruitTickets(recruitTickets)
    self.RecruitTickets = recruitTickets
end

-- 更新藏品箱
function XTheatre4Adventure:UpdateItemBoxs(itemBoxs)
    self.ItemBoxs = itemBoxs
end

-- 获取颜色Id列表
function XTheatre4Adventure:GetColorIds()
    local colorIds = {}
    for k, _ in pairs(self.Colors) do
        colorIds[k] = k
    end
    return colorIds
end

-- 获取颜色数据
---@return XTheatre4ColorTalent
function XTheatre4Adventure:GetColorData(color)
    return self.Colors[color] or nil
end

-- 修改颜色资源值
function XTheatre4Adventure:UpdateColorAssetData(color, resource, level, dailyResource, point, pointCanCost)
    local colorData = self.Colors[color]
    if not colorData then
        return
    end
    colorData:SetResource(resource)
    colorData:SetLevel(level)
    colorData:SetDailyResource(dailyResource)
    colorData:SetPoint(point)
    colorData:SetPointCanCost(pointCanCost)
end

-- 获取所有生效的天赋Ids
function XTheatre4Adventure:GetAllActiveTalentIds()
    local ids = {}
    for _, colorData in pairs(self.Colors) do
        for _, talentId in pairs(colorData:GetActiveTalentIds()) do
            table.insert(ids, talentId)
        end
    end
    return ids
end

-- 获取所有的天赋效果
---@return table<number, XTheatre4Effect>
function XTheatre4Adventure:GetAllTalentEffects()
    local effects = {}
    for _, colorData in pairs(self.Colors) do
        for index, effect in pairs(colorData:GetAllEffects()) do
            effects[index] = effect
        end
    end
    return effects
end

-- 获取天赋效果通过colorId
---@param colorId number 颜色Id
function XTheatre4Adventure:GetTalentEffectsByColorId(colorId)
    local colorData = self.Colors[colorId]
    if not colorData then
        return {}
    end
    return colorData:GetAllEffects()
end

-- 获取所有待处理档位的天赋Ids
---@return { Color: number, TalentIds: number[] }[]
function XTheatre4Adventure:GetAllWaitSlotTalentIds()
    local waitData = {}
    for _, colorData in pairs(self.Colors) do
        local talentIds = colorData:GetWaitSlotTalentIds()
        if #talentIds > 0 then
            table.insert(waitData, { Color = colorData:GetColor(), TalentIds = talentIds })
        end
    end
    return waitData
end

-- 获取难度
function XTheatre4Adventure:GetDifficulty()
    return self.Difficulty
end

-- 获取词缀Id
function XTheatre4Adventure:GetAffix()
    return self.Affix
end

-- 获取血量
function XTheatre4Adventure:GetHp()
    return self.Hp
end

-- 设置血量
function XTheatre4Adventure:SetHp(hp)
    self.Hp = hp
end

-- 获取行动点
function XTheatre4Adventure:GetAp()
    return self.Ap
end

-- 设置行动点
function XTheatre4Adventure:SetAp(ap)
    self.Ap = ap
end

-- 获取最大行动点
function XTheatre4Adventure:GetMaxAp()
    return self.MaxAp
end

-- 获取额外最大行动点
function XTheatre4Adventure:GetExtraMaxAp()
    return self.ExtraMaxAp
end

-- 设置额外最大行动点
function XTheatre4Adventure:SetExtraMaxAp(extraMaxAp)
    self.ExtraMaxAp = extraMaxAp
end

-- 获取建筑点数
function XTheatre4Adventure:GetBp()
    return self.Bp
end

-- 设置建筑点数
function XTheatre4Adventure:SetBp(bp)
    self.Bp = bp
end

function XTheatre4Adventure:SetAwakeningPoint(value)
    self.AwakeningPoint = value
end

function XTheatre4Adventure:GetAwakeningPoint()
    return self.AwakeningPoint
end

function XTheatre4Adventure:SetTracebackPoint(value)
    self.TracebackPoint = value
end

function XTheatre4Adventure:GetTracebackPoint()
    return self.TracebackPoint
end

-- 获取金币
function XTheatre4Adventure:GetGold()
    return self.Gold
end

-- 设置金币
function XTheatre4Adventure:SetGold(gold)
    self.Gold = gold
end

-- 获取结算额外给予的Bp经验
function XTheatre4Adventure:GetSettleBpExp()
    return self.SettleBpExp
end

-- 设置结算额外给予的Bp经验
function XTheatre4Adventure:SetSettleBpExp(settleBpExp)
    self.SettleBpExp = settleBpExp
end

-- 获取当前天数
function XTheatre4Adventure:GetDays()
    return self.Days
end

-- 获取繁荣度
function XTheatre4Adventure:GetProsperity()
    return self.Prosperity
end

-- 设置繁荣度
function XTheatre4Adventure:SetProsperity(prosperity)
    self.Prosperity = prosperity
end

-- 获取藏品限制
function XTheatre4Adventure:GetItemLimit()
    return self.ItemLimit
end

-- 设置藏品限制
function XTheatre4Adventure:SetItemLimit(itemLimit)
    self.ItemLimit = itemLimit
end

-- 获取时间轴
---@return XTheatre4Fate
function XTheatre4Adventure:GetFateList()
    return self.FateList
end

-- 获取当前时间轴Id
function XTheatre4Adventure:GetFateId()
    return self.FateId
end

--获取藏品箱数量通过Id
function XTheatre4Adventure:GetItemBoxCountById(id)
    local count = 0
    for _, v in pairs(self.ItemBoxs) do
        if v == id then
            count = count + 1
        end
    end
    return count
end

-- 获取藏品数量通过Id
function XTheatre4Adventure:GetItemCountById(id)
    local count = 0
    for _, v in pairs(self.Items) do
        if v:GetItemId() == id then
            count = count + 1
        end
    end
    for _, v in pairs(self.Props) do
        if v:GetItemId() == id then
            count = count + 1
        end
    end
    return count
end

-- 获取招募卷数量通过Id
function XTheatre4Adventure:GetRecruitTicketCountById(id)
    local count = 0
    for _, v in pairs(self.RecruitTickets) do
        if v == id then
            count = count + 1
        end
    end
    return count
end

-- 获取颜色等级通过Id
function XTheatre4Adventure:GetColorLevelById(id)
    local colorData = self.Colors[id]
    if not colorData then
        return 0
    end
    return colorData:GetLevel()
end

-- 获取颜色资源通过Id
function XTheatre4Adventure:GetColorResourceById(id)
    local colorData = self.Colors[id]
    if not colorData then
        return 0
    end
    return colorData:GetResource()
end

-- 红色买死值
function XTheatre4Adventure:GetColorPointCanCostById(id)
    local colorData = self.Colors[id]
    if not colorData then
        return 0
    end
    return colorData:GetPointCanCost()
end

-- 获取每日颜色资源通过Id
function XTheatre4Adventure:GetDailyColorResourceById(id)
    local colorData = self.Colors[id]
    if not colorData then
        return 0
    end
    return colorData:GetDailyResource()
end

-- 获取颜色天赋点通过Id
function XTheatre4Adventure:GetColorPointById(id)
    local colorData = self.Colors[id]
    if not colorData then
        return 0
    end
    return colorData:GetPoint()
end

-- 获取所有藏品列表
---@return table<number, XTheatre4Item>
function XTheatre4Adventure:GetItems()
    return self.Items
end

-- 获取藏品通过Uid
---@return XTheatre4Item
function XTheatre4Adventure:GetItemByUid(uid)
    return self.Items[uid] or nil
end

-- 获取所有藏品效果
---@return table<number, XTheatre4Effect>
function XTheatre4Adventure:GetAllItemEffects()
    local effects = {}
    for _, item in pairs(self.Items) do
        for index, effect in pairs(item:GetEffects()) do
            effects[index] = effect
        end
    end
    return effects
end

-- 获取藏品效果通过UId
---@return table<number, XTheatre4Effect>
function XTheatre4Adventure:GetItemEffectsByUid(uid)
    local item = self.Items[uid]
    if not item then
        return {}
    end
    return item:GetEffects()
end

-- 获取所有线索道具列表
---@return table<number, XTheatre4Item>
function XTheatre4Adventure:GetProps()
    return self.Props
end

-- 获取线索道具通过Uid
---@return XTheatre4Item
function XTheatre4Adventure:GetPropByUid(uid)
    return self.Props[uid] or nil
end

-- 获取所有线索道具效果
---@return table<number, XTheatre4Effect>
function XTheatre4Adventure:GetAllPropEffects()
    local effects = {}
    for _, prop in pairs(self.Props) do
        for index, effect in pairs(prop:GetEffects()) do
            effects[index] = effect
        end
    end
    return effects
end

-- 获取线索道具效果通过UId
---@return table<number, XTheatre4Effect>
function XTheatre4Adventure:GetPropEffectsByUid(uid)
    local prop = self.Props[uid]
    if not prop then
        return {}
    end
    return prop:GetEffects()
end

-- 获取最后一个待处理藏品Id
function XTheatre4Adventure:GetLastWaitItemId()
    if XTool.IsTableEmpty(self.WaitItems) then
        return 0
    end
    return self.WaitItems[#self.WaitItems] or 0
end

-- 添加待处理藏品
function XTheatre4Adventure:AddWaitItem(itemId)
    if XTool.IsNumberValid(itemId) then
        self.WaitItems = self.WaitItems or {}
        table.insert(self.WaitItems, itemId)
    end
end

-- 移除待处理藏品
function XTheatre4Adventure:RemoveWaitItem(itemId)
    if XTool.IsTableEmpty(self.WaitItems) then
        return
    end
    local index = 0
    for k, v in pairs(self.WaitItems) do
        if v == itemId then
            index = k
            break
        end
    end
    if index > 0 then
        table.remove(self.WaitItems, index)
    end
end

function XTheatre4Adventure:GetInheritItemId()
    return self.InheritItemId
end

-- 获取自定义效果集
---@return table<number, XTheatre4Effect>
function XTheatre4Adventure:GetCustomEffects()
    return self.CustomEffects
end

-- 更新完成事件Id记录
function XTheatre4Adventure:UpdateFinishEventIds(finishEventIds)
    self.FinishEventIds = finishEventIds or {}
end

-- 获取事件完成的次数
function XTheatre4Adventure:GetFinishEventTimes(eventId)
    return self.FinishEventIds[eventId] or 0
end

-- 更新完成挑战的战斗id集
function XTheatre4Adventure:UpdateFinishFightIds(fightIds)
    self.FinishFightIds = fightIds or {}
end

-- 获取完成挑战的战斗id集
function XTheatre4Adventure:GetFinishFightIds()
    return self.FinishFightIds
end

-- 获取已购物次数
function XTheatre4Adventure:GetEffectShopBuyTimes()
    return self.EffectShopBuyTimes
end

-- 设置已购物次数
function XTheatre4Adventure:SetEffectShopBuyTimes(shopBuyTimes)
    self.EffectShopBuyTimes = shopBuyTimes
end

-- 获取已扫荡(诏安)次数
function XTheatre4Adventure:GetEffectSweepTimes()
    return self.EffectSweepTimes
end

-- 设置已扫荡(诏安)次数
function XTheatre4Adventure:SetEffectSweepTimes(sweepTimes)
    self.EffectSweepTimes = sweepTimes
end

-- 获取探索计数
function XTheatre4Adventure:GetExploreCount()
    return self.ExploreCount
end

-- 设置闪退，掉线，强退次数
function XTheatre4Adventure:SetClashCount(clashCount)
    self.ClashCount = clashCount
end

-- 更新所有效果
function XTheatre4Adventure:UpdateAllEffects(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        local effect = self:GetEffectById(v.Id)
        if effect then
            effect:NotifyEffectData(v)
        end
    end
end

-- 获取效果通过自增Id
---@param id number 自增Id
---@return XTheatre4Effect
function XTheatre4Adventure:GetEffectById(id)
    local effect = self.CustomEffects[id] or self:GetEffectInColors(id) or self:GetEffectInItems(id) or self:GetEffectInProps(id)
    return effect or nil
end

function XTheatre4Adventure:GetEffectInColors(id)
    local effects = self:GetAllTalentEffects()
    return effects[id] or nil
end

function XTheatre4Adventure:GetEffectInItems(id)
    local effects = self:GetAllItemEffects()
    return effects[id] or nil
end

function XTheatre4Adventure:GetEffectInProps(id)
    local effects = self:GetAllPropEffects()
    return effects[id] or nil
end

-- 获取开始时间
function XTheatre4Adventure:GetStartTime()
    return self.StartTime
end

function XTheatre4Adventure:GetTracebackDatas()
    return self.TracebackDatas
end

function XTheatre4Adventure:GetTracebackDataByDays(days)
    if not days then
        return nil
    end
    if not self.TracebackDatas then
        return nil
    end
    return self.TracebackDatas[days] or nil
end

function XTheatre4Adventure:SetTracebackDataByDays(data, days)
    self.TracebackDatas = self.TracebackDatas or {}
    self.TracebackDatas[days] = data
end

function XTheatre4Adventure:SetTracebackDatas(datas)
    self.TracebackDatas = datas or {}
end

return XTheatre4Adventure
