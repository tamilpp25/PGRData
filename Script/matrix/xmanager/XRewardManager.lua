local pairs = pairs
local table = table
local tableInsert = table.insert
local tableSort = table.sort

XRewardManager = XRewardManager or {}

local XRewardType = {
    Item = 1,
    Character = 2,
    Equip = 3,
    Fashion = 4,
    BaseEquip = 5,
    Furniture = 9,
    HeadPortrait = 10,
    DormCharacter = 11,
    ChatEmoji = 12,
    WeaponFashion = 13,
    Collection = 14,
    Background = 15,
    Pokemon = 16,
    Partner = 17,
    Nameplate = 18,
    RankScore = 20,
    Medal = 21, --勋章
    DrawTicket = 22,--免费抽奖券
    GuildGoods = 23, --公会道具
    DlcHuntChip = 24, --dlcHunt芯片
    ItemCollection = 25, --道具收藏
}

--local HeadPortraitQuality = CS.XGame.Config:GetInt("HeadPortraitQuality")
local TABLE_REWARD_PATH = "Share/Reward/Reward.tab"
local TABLE_REWARD_GOODS_PATH = "Share/Reward/RewardGoods.tab"

--local RewardTemplates = {}
local RewardSubIds = {}
local RewardGoodsTable = {}

local Arrange2RewardType = {
    [XArrangeConfigs.Types.Item] = XRewardType.Item,
    [XArrangeConfigs.Types.Character] = XRewardType.Character,
    [XArrangeConfigs.Types.Weapon] = XRewardType.Equip,
    [XArrangeConfigs.Types.Wafer] = XRewardType.Equip,
    [XArrangeConfigs.Types.Fashion] = XRewardType.Fashion,
    [XArrangeConfigs.Types.BaseEquip] = XRewardType.BaseEquip,
    [XArrangeConfigs.Types.Furniture] = XRewardType.Furniture,
    [XArrangeConfigs.Types.HeadPortrait] = XRewardType.HeadPortrait,
    [XArrangeConfigs.Types.DormCharacter] = XRewardType.DormCharacter,
    [XArrangeConfigs.Types.ChatEmoji] = XRewardType.ChatEmoji,
    [XArrangeConfigs.Types.WeaponFashion] = XRewardType.WeaponFashion,
    [XArrangeConfigs.Types.Collection] = XRewardType.Collection,
    [XArrangeConfigs.Types.Background] = XRewardType.Background,
    [XArrangeConfigs.Types.Pokemon] = XRewardType.Pokemon,
    [XArrangeConfigs.Types.Partner] = XRewardType.Partner,
    [XArrangeConfigs.Types.Nameplate] = XRewardType.Nameplate,
    [XArrangeConfigs.Types.RankScore] = XRewardType.RankScore,
    [XArrangeConfigs.Types.Medal] = XRewardType.Medal,
    [XArrangeConfigs.Types.DrawTicket] = XRewardType.DrawTicket,
    [XArrangeConfigs.Types.GuildGoods] = XRewardType.GuildGoods,
    [XArrangeConfigs.Types.DlcHuntChip] = XRewardType.DlcHuntChip,
    [XArrangeConfigs.Types.ItemCollection] = XRewardType.ItemCollection,
}

local CreateGoodsFunc = {
    [XRewardType.Item] = function(templateId, count)
        return {
            RewardType = XRewardType.Item,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,

    [XRewardType.Character] = function(templateId, count, args)
        local template = XMVCA.XCharacter:GetCharacterBorderTemplate(templateId)
        if not template then
            local path = XMVCA.XCharacter:GetCharacterElementPath()
            XLog.ErrorTableDataNotFound("CreateGoodsFunc", "template", path, "templateId", tostring(templateId))
            return
        end

        local len = #args
        local level, quality, grade = template.MinLevel, template.MinQuality, template.MinGrade

        if len > 0 and args[1] > 0 then
            level = args[1]
            if level > template.MaxLevel or level < template.MinLevel then
                XLog.Error("XRewardManager CreateRewardCharacter 函数错误: level超出范围, id is ", templateId, " level is ",
                level, " 最小 level is ", template.MinLeXvel, " 最大 level is ", template.MaxLeXvel)
                return
            end
        end

        if len > 1 and args[2] > 0 then
            quality = args[2]
            if quality > template.MaxQuality or quality < template.MinQuality then
                XLog.Error("XRewardManager CreateRewardCharacter 函数错误: quality 超出范围, id is ", templateId, " quality is ",
                quality, " 最小 quality is ", template.MinQuality, " 最大 quality is ", template.MaxQuality)
                return
            end
        end

        if len > 2 and args[3] > 0 then
            grade = args[3]
            if grade > template.MaxGrade or grade < template.MinGrade then
                XLog.Error("XRewardManager CreateRewardCharacter 函数错误: grade 超出范围, id is ", templateId, " grade is ",
                grade, " 最小 grade is ", template.MinGrade, " 最大 grade is ", template.MaxGrade)
                return
            end
        end

        return {
            RewardType = XRewardType.Character,
            TemplateId = templateId,
            Count = count and count or 1,
            Level = level,
            Quality = quality,
            Grade = grade
        }
    end,

    [XRewardType.Equip] = function(templateId, count, args)
        local len = args and #args or 0
        local level, breakthrough
        local borderCfg = XEquipConfig.GetEquipBorderCfg(templateId)

        if len > 0 and args[1] then
            level = args[1]
            if level > borderCfg.MaxLevel or level < borderCfg.MinLevel then
                XLog.Error("XRewardManager CreateRewardEquip 函数错误: level 超出范围, id is ", templateId, "level is ", level,
                " 最小 level is ", borderCfg.MinLevel, " 最大 level is ", borderCfg.MaxLevel)
                return
            end
        else
            level = borderCfg.MinLevel
        end

        if len > 2 and args[3] > 0 then
            breakthrough = args[3]
            if breakthrough > borderCfg.MaxBreakthrough or breakthrough < borderCfg.MinBreakthrough then
                XLog.Error("XRewardManager CreateRewardEquip 函数错误: breakthrough 超出范围, id is ", templateId, " breakthrough is ", breakthrough,
                " 最小 breakthrough is ", borderCfg.MinBreakthrough, " 最大 breakthrough is ", borderCfg.MaxBreakthrough)
                return
            end
        else
            breakthrough = borderCfg.MinBreakthrough
        end

        return {
            RewardType = XRewardType.Equip,
            TemplateId = templateId,
            Count = count and count or 1,
            Level = level,
            Breakthrough = breakthrough
        }
    end,

    [XRewardType.Fashion] = function(templateId, count)
        return {
            RewardType = XRewardType.Fashion,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,

    [XRewardType.BaseEquip] = function(templateId, count)
        return {
            RewardType = XRewardType.BaseEquip,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,

    [XRewardType.Furniture] = function(templateId, count)
        local quality = XDataCenter.FurnitureManager.GetRewardFurnitureQuality(templateId)
        return {
            XRewardType = XRewardType.Furniture,
            TemplateId = templateId,
            Count = count and count or 1,
            Quality = quality,
        }
    end,

    [XRewardType.HeadPortrait] = function(templateId, count)
        return {
            RewardType = XRewardType.HeadPortrait,
            TemplateId = templateId,
            Count = count and count or 1,
        }
    end,

    [XRewardType.DormCharacter] = function(templateId, count)
        return {
            RewardType = XRewardType.DormCharacter,
            TemplateId = templateId,
            Count = count and count or 1,
        }
    end,

    [XRewardType.ChatEmoji] = function(templateId, count)
        return {
            RewardType = XRewardType.ChatEmoji,
            TemplateId = templateId,
            Count = count and count or 1,
        }
    end,

    [XRewardType.WeaponFashion] = function(templateId, count)
        return {
            RewardType = XRewardType.WeaponFashion,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,
    [XRewardType.Collection] = function(templateId, count)
        return {
            RewardType = XRewardType.Collection,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,
    [XRewardType.Background] = function(templateId, count)
        return {
            RewardType = XRewardType.Collection,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,
    [XRewardType.Pokemon] = function(templateId, count)
        return {
            RewardType = XRewardType.Pokemon,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,
    [XRewardType.Partner] = function(templateId, count)
        return {
            RewardType = XRewardType.Partner,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,
    [XRewardType.Nameplate] = function(templateId, count)
        return {
            RewardType = XRewardType.Nameplate,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,
    [XRewardType.RankScore] = function(templateId, count)
        return {
            RewardType = XRewardType.RankScore,
            TemplateId = templateId,
            Count = count and count or 1
        }
    end,
    [XRewardType.Medal] = function(templateId, count, params)
        return {
            RewardType = XRewardType.Medal,
            TemplateId = params[1],
            Count = count and count or 1,
        }
    end,
    [XRewardType.DrawTicket] = function(templateId, count)
        return {
            RewardType = XRewardType.DrawTicket,
            TemplateId = templateId, 
            Count = count and count or 1,
        }
    end,
    [XRewardType.DlcHuntChip] = function(templateId, count)
        return {
            RewardType = XRewardType.DlcHuntChip,
            TemplateId = templateId,
            Count = count and count or 1,
        }
    end,
    [XRewardType.ItemCollection] = function(templateId, count) 
        return {
            RewardType = XRewardType.ItemCollection,
            TemplateId = templateId,
            Count = count and count or 1,
        }
    end
}

local CloneRewardGoods = function(rewardGoods)
    return {
        RewardType = rewardGoods.RewardType,
        TemplateId = rewardGoods.TemplateId,
        Count = rewardGoods.Count,
        Level = rewardGoods.Level,
        Quality = rewardGoods.Quality,
        Grade = rewardGoods.Grade,
        Star = rewardGoods.Star,
        ConvertFrom = rewardGoods.ConvertFrom,
        Breakthrough = rewardGoods.Breakthrough,
        IsGift = rewardGoods.IsGift
    }
end

local CreateRewardGoods = function(templateId, count, args)
    local idType = XArrangeConfigs.GetType(templateId)
    local rewardType = Arrange2RewardType[idType]

    if not rewardType then
        XLog.Error("XRewardManager.CreateRewardGoodsByTemplate error: reward type not support, templateId is " .. templateId)
        return
    end

    return CreateGoodsFunc[rewardType](templateId, count, args)
end

local CreateRewardGoodsByTemplate = function(tab)
    return CreateRewardGoods(tab.TemplateId, tab.Count, tab.Params)
end

--==============================--
--desc: 通用角色奖励排序
--==============================--
local SortCharacters = function(a, b)
    local tmpId1 = a.TemplateId and a.TemplateId or a.Id
    local tmpId2 = b.TemplateId and b.TemplateId or b.Id

    local quality1 = a.Quality and a.Quality or XMVCA.XCharacter:GetCharMinQuality(tmpId1)
    local quality2 = b.Quality and b.Quality or XMVCA.XCharacter:GetCharMinQuality(tmpId2)

    if quality1 ~= quality2 then
        return quality1 > quality2
    end

    local priority1 = XMVCA.XCharacter:GetCharacterPriority(tmpId1)
    local priority2 = XMVCA.XCharacter:GetCharacterPriority(tmpId2)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end

    return tmpId1 > tmpId2
end

--==============================--
--desc: 通用时装奖励排序
--==============================--
local SortFashions = function(a, b)
    local tmpId1 = a.TemplateId and a.TemplateId or a.Id
    local tmpId2 = b.TemplateId and b.TemplateId or b.Id

    local quality1 = XDataCenter.FashionManager.GetFashionQuality(tmpId1)
    local quality2 = XDataCenter.FashionManager.GetFashionQuality(tmpId2)

    if quality1 ~= quality2 then
        return quality1 > quality2
    end

    local priority1 = XDataCenter.FashionManager.GetFashionPriority(tmpId1)
    local priority2 = XDataCenter.FashionManager.GetFashionPriority(tmpId2)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end

    return tmpId1 > tmpId2
end

--==============================--
--desc: 通用装备奖励排序
--==============================--
local SortEquips = function(a, b)
    local tmpId1 = a.TemplateId
    local tmpId2 = b.TemplateId

    local quality1 = XDataCenter.EquipManager.GetEquipQuality(tmpId1)
    local quality2 = XDataCenter.EquipManager.GetEquipQuality(tmpId2)

    if quality1 ~= quality2 then
        return quality1 > quality2
    end

    if a.Star ~= b.Star then
        return a.Star > b.Star
    end

    if a.Level ~= b.Level then
        return a.Level > b.Level
    end

    local priority1 = XDataCenter.EquipManager.GetEquipPriority(tmpId1)
    local priority2 = XDataCenter.EquipManager.GetEquipPriority(tmpId2)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end

    return tmpId1 > tmpId2
end

--==============================--
--desc: 通用基地装备奖励排序
--==============================--
local SortBaseEquips = function(a, b)
    -- 等级 > 品质
    local tmpId1 = a.TemplateId
    local tmpId2 = b.TemplateId

    local template1 = XDataCenter.BaseEquipManager.GetBaseEquipTemplate(tmpId1)
    local template2 = XDataCenter.BaseEquipManager.GetBaseEquipTemplate(tmpId2)

    if template1.Level ~= template2.Level then
        return template1.Level > template2.Level
    end

    if template1.Quality ~= template2.Quality then
        return template1.Quality > template2.Quality
    end

    if template1.Priority ~= template2.Priority then
        return template1.Priority > template2.Priority
    end

    return tmpId1 > tmpId2
end

--==============================--
--desc: 通用家具奖励排序
--==============================--
local SortFurnitures = function(a, b)
    return a.TemplateId < b.TemplateId
end

--==============================--
--desc: 通用道具奖励排序
--==============================--
local SortItems = function(a, b)
    local tmpId1 = a.TemplateId and a.TemplateId or a.Id
    local tmpId2 = b.TemplateId and b.TemplateId or b.Id

    local quality1 = XDataCenter.ItemManager.GetItemQuality(tmpId1)
    local quality2 = XDataCenter.ItemManager.GetItemQuality(tmpId2)

    if quality1 ~= quality2 then
        return quality1 > quality2
    end

    local priority1 = XDataCenter.ItemManager.GetItemPriority(tmpId1)
    local priority2 = XDataCenter.ItemManager.GetItemPriority(tmpId2)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end

    return tmpId1 > tmpId2
end

--==============================--
--desc: 通用头像奖励排序
--==============================--
local SortHeadPortraits = function(a, b)
    return a.TemplateId > b.TemplateId
end

local SortDormCharacter = function(a, b)
    return a.TemplateId > b.TemplateId
end

local SortChatEmoji = function(a, b)
    return a.TemplateId > b.TemplateId
end

local SortWeaponFashions = function(a, b)
    local tmpId1 = a.TemplateId and a.TemplateId or a.Id
    local tmpId2 = b.TemplateId and b.TemplateId or b.Id

    local quality1 = XDataCenter.WeaponFashionManager.GetFashionQuality(tmpId1)
    local quality2 = XDataCenter.WeaponFashionManager.GetFashionQuality(tmpId2)

    if quality1 ~= quality2 then
        return quality1 > quality2
    end

    local priority1 = XDataCenter.WeaponFashionManager.GetFashionPriority(tmpId1)
    local priority2 = XDataCenter.WeaponFashionManager.GetFashionPriority(tmpId2)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end

    return tmpId1 > tmpId2
end

local SortCollection = function(a, b)
    local priority1 = XMedalConfigs.GetCollectionPriorityById(a.TemplateId)
    local priority2 = XMedalConfigs.GetCollectionPriorityById(b.TemplateId)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end
    return a.TemplateId > b.TemplateId
end

local SortBackground = function(a, b)
    local priority1 = XPhotographConfigs.GetBackgroundPriorityById(a.TemplateId)
    local priority2 = XPhotographConfigs.GetBackgroundPriorityById(b.TemplateId)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end
    return a.TemplateId > b.TemplateId
end

local SortPartner = function(a, b)
    local priority1 = XPartnerConfigs.GetPartnerTemplateQuality(a.TemplateId)
    local priority2 = XPartnerConfigs.GetPartnerTemplateQuality(b.TemplateId)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end
    return a.TemplateId > b.TemplateId
end

local SortNameplate = function(a, b)
    local priority1 = XMedalConfigs.GetNameplateQuality(a.TemplateId)
    local priority2 = XMedalConfigs.GetNameplateQuality(b.TemplateId)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end
    return a.TemplateId > b.TemplateId
end

local SortRankScore = function(a, b)
    local priority1 = XFubenSpecialTrainConfig.GetRankScoreGoodQuality(a.TemplateId)
    local priority2 = XFubenSpecialTrainConfig.GetRankScoreGoodQuality(b.TemplateId)

    if priority1 ~= priority2 then
        return priority1 > priority2
    end
    return a.TemplateId > b.TemplateId
end

local SortDlcHuntChip = function(a, b)
    return XDlcHuntChipConfigs.GetChipPriority(a.TemplateId) >  XDlcHuntChipConfigs.GetChipPriority(b.TemplateId)
end

local SortItemCollect = function(a, b) 
    local templateA = XItemConfigs.GetItemCollectTemplate(a.TemplateId)
    local templateB = XItemConfigs.GetItemCollectTemplate(b.TemplateId)

    if templateA.Quality ~= templateB.Quality then
        return templateA.Quality > templateB.Quality
    end
    
    return a.TemplateId > b.TemplateId
end

local SortRewardTypePrioriy = {
    [XRewardType.Item] = 1,
    [XRewardType.Character] = 4,
    [XRewardType.Equip] = 2,
    [XRewardType.Fashion] = 3,
    [XRewardType.BaseEquip] = 5,
    [XRewardType.Furniture] = 9,
    [XRewardType.HeadPortrait] = 10,
    [XRewardType.DormCharacter] = 11,
    [XRewardType.ChatEmoji] = 12,
    [XRewardType.Collection] = 14,
    [XRewardType.Partner] = 15,
    [XRewardType.Nameplate] = 16,
    [XRewardType.Background] = 17,
    [XRewardType.RankScore] = 18,
    [XRewardType.DlcHuntChip] = 19,
    [XRewardType.ItemCollection] = 20,
}

local SortFunc = {
    [XRewardType.Item] = SortItems,
    [XRewardType.Character] = SortCharacters,
    [XRewardType.Equip] = SortEquips,
    [XRewardType.Fashion] = SortFashions,
    [XRewardType.BaseEquip] = SortBaseEquips,
    [XRewardType.Furniture] = SortFurnitures,
    [XRewardType.HeadPortrait] = SortHeadPortraits,
    [XRewardType.DormCharacter] = SortDormCharacter,
    [XRewardType.ChatEmoji] = SortChatEmoji,
    [XRewardType.WeaponFashion] = SortWeaponFashions,
    [XRewardType.Collection] = SortCollection,
    [XRewardType.Background] = SortBackground,
    [XRewardType.Partner] = SortPartner,
    [XRewardType.Nameplate] = SortNameplate,
    [XRewardType.RankScore] = SortRankScore,
    [XRewardType.DlcHuntChip] = SortDlcHuntChip,
    [XRewardType.ItemCollection] = SortItemCollect,
}

local RewardsFilter = {
    [XRewardType.Pokemon] = 16
}
--==============================--
--desc: 奖励过滤
--@rewardGoodsList: 奖励列表
--@return 过滤后列表
--==============================--
local function FilterRewardsGoodsList(rewardGoodsList)
    local rewardList = {}
    for k, v in pairs(rewardGoodsList) do
        if not RewardsFilter[v.RewardType] then
            tableInsert(rewardList, v)
        end
    end

    return rewardList
end

--==============================--
--desc: 奖励排序
--@rewardGoodsList: 奖励列表
--@return 排序后列表
--==============================--
local function SortRewardGoodsList(rewardGoodsList)
    if not rewardGoodsList then
        XLog.Warning("XRewardManager.SortRewardGoodsList: rewardGoodsList is nil")
        return
    end
    
    tableSort(rewardGoodsList, function(a, b)
        local rewardType1, rewardType2 = a.RewardType, b.RewardType

        if rewardType1 ~= rewardType2 then
            return SortRewardTypePrioriy[rewardType1] > SortRewardTypePrioriy[rewardType2]
        end

        local sort = SortFunc[rewardType1]
        if sort then
            return sort(a, b)
        end
        return a.TemplateId > b.TemplateId
    end)

    return rewardGoodsList
end

--==============================--
--desc: 合并相同奖励
--@rewardGoodsList: 奖励列表
--@return 合并列表
--==============================--
local function MergeRewardGoodsList(rewardGoodsList)
    if not rewardGoodsList then
        XLog.Warning("XRewardManager.MergeRewardGoodsList: rewardGoodsList is nil")
        return
    end

    local mergeList = {}
    local mergeDict = {}

    for _, goods in pairs(rewardGoodsList) do
        if goods.RewardType == XRewardType.Character or
        goods.RewardType == XRewardType.Equip then
            tableInsert(mergeList, goods)
        else
            local oldGoods = mergeDict[goods.TemplateId]

            if oldGoods then
                mergeDict[goods.TemplateId].Count = mergeDict[goods.TemplateId].Count + goods.Count
            else
                mergeDict[goods.TemplateId] = CloneRewardGoods(goods)
            end
        end
    end

    for _, goods in pairs(mergeDict) do
        tableInsert(mergeList, goods)
    end

    return mergeList
end

--==============================--
--desc: 奖励合并排序
--@rewardGoodsList: 奖励列表
--@return 处理完列表
--==============================--
local function MergeAndSortRewardGoodsList(rewardGoodsList)
    if not rewardGoodsList then
        XLog.Warning("XRewardManager.MergeAndSortRewardGoodsList: rewardGoodsList is nil")
        return
    end

    return SortRewardGoodsList(MergeRewardGoodsList(rewardGoodsList))
end



function XRewardManager.Init()
    local rewardTable = XTableManager.ReadAllByIntKey(TABLE_REWARD_PATH, XTable.XTableReward, "Id")
    RewardGoodsTable = XTableManager.ReadAllByIntKey(TABLE_REWARD_GOODS_PATH, XTable.XTableRewardGoods, "Id")

    for k, v in pairs(rewardTable) do
        RewardSubIds[k] = v.SubIds
    end

    --RewardTemplates = XReadOnlyTable.Create(RewardTemplates)
    --RewardSubIds = XReadOnlyTable.Create(RewardSubIds)
end

function XRewardManager.GetRewardSubId(id, index)
    local rewardSubIds = RewardSubIds[id]
    if not rewardSubIds then
        XLog.Error("XRewardManager.GetRewardSubId error: can not found SubIds, id is " .. id)
        return
    end

    return rewardSubIds[index]
end


function XRewardManager.GetRewardList(id)
    local subids = RewardSubIds[id]
    if not subids then
        return
    end

    local list = {}
    for _, id in pairs(subids) do
        local tab = RewardGoodsTable[id]
        if not tab then
            XLog.Error("XRewardManager.Init error: can not found reward, id = " .. id)
            return
        end
        tableInsert(list, XRewardManager.CreateRewardGoodsByTemplate(tab))
    end

    if not list then
        XLog.Error("XRewardManager.GetRewardList error: can not found reward, id is " .. id)
        return
    end

    return list
end

function XRewardManager.GetRewardGoodsCfgById(id)
    return RewardGoodsTable[id]
end

function XRewardManager.GetRewardListNotCount(id)
    local rewardList = XRewardManager.GetRewardList(id)
    local rewardNotCountList = {}
    if not rewardList then
        XLog.Error("XRewardManager.GetRewardList error: can not found reward, id is " .. id)
        return
    end

    for _, Val in pairs(rewardList) do
        local tmpList = {}
        for k, v in pairs(Val) do
            if k ~= "Count" then
                tmpList[k] = v
            end
        end
        table.insert(rewardNotCountList, tmpList)
    end
    return rewardNotCountList
end

function XRewardManager.CheckRewardOwn(rewardType, templateId)
    local isHave = false
    local ownRewardIsLimitTime = false       --拥有的是否限时
    local rewardIsLimitTime = false
    local leftTime = 0
    if not rewardType or not templateId then return isHave, ownRewardIsLimitTime, rewardIsLimitTime, leftTime end

    if XRewardManager.IsRewardFashion(rewardType, templateId) then
        isHave = true
    elseif XRewardManager.IsRewardWeaponFashion(rewardType, templateId) then
        local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(templateId)
        local ownWeaponFashion = XDataCenter.WeaponFashionManager.GetWeaponFashion(weaponFashionId)
        if ownWeaponFashion then
            isHave = XDataCenter.WeaponFashionManager.CheckHasFashion(weaponFashionId)
            ownRewardIsLimitTime = ownWeaponFashion:IsTimeLimit()
            rewardIsLimitTime = XDataCenter.ItemManager.IsWeaponFashionTimeLimit(templateId)
            leftTime = ownWeaponFashion:GetLeftTime()
        end
    elseif XRewardManager.IsRewardHeadPortrait(rewardType, templateId) then
        isHave = true
    elseif XRewardManager.IsRewardDormCharacter(rewardType, templateId) then
        isHave = true
    elseif XRewardManager.IsRewardBackground(rewardType, templateId) then
        isHave = true
    elseif XRewardManager.IsRewardCharacter(rewardType, templateId) then
        isHave = true
        -- elseif XRewardManager.IsRewardEquip(rewardType, templateId) then -- 取消装备已拥有显示限制
        --     isHave = true
    end
    return isHave, ownRewardIsLimitTime, rewardIsLimitTime, leftTime
end

-- 只要list有任意一个满足即返回true
function XRewardManager.CheckRewardGoodsListIsOwn(rewardGoodsList)
    if not rewardGoodsList then return false end
    local isHave = false
    local ownRewardIsLimitTime = false
    local rewardIsLimitTime = false
    local leftTime = 0

    for k, v in pairs(rewardGoodsList) do
        isHave, ownRewardIsLimitTime, rewardIsLimitTime, leftTime = XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId)
        if isHave then
            return isHave, ownRewardIsLimitTime, rewardIsLimitTime, leftTime
        end
    end
    return isHave, ownRewardIsLimitTime, rewardIsLimitTime, leftTime
end

-- 全部满足拥有且不是限时的才会返回true
function XRewardManager.CheckRewardGoodsListIsOwnWithAll(rewardGoodsList)
    local isHave = false
    local ownRewardIsLimitTime = false
    for k, v in pairs(rewardGoodsList) do
        isHave, ownRewardIsLimitTime = XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId)
        if not isHave or ownRewardIsLimitTime then
            return false
        end
    end
    return true
end

function XRewardManager.IsRewardWeaponFashion(rewardType, templateId) -- 是否拥有武器涂装
    return (rewardType == XRewardManager.XRewardType.Item or rewardType == XRewardManager.XRewardType.WeaponFashion) and XDataCenter.ItemManager.IsWeaponFashion(templateId)
end

function XRewardManager.IsRewardFashion(rewardType, templateId) -- 是否拥有涂装
    return (rewardType == XRewardManager.XRewardType.Fashion and XDataCenter.FashionManager.CheckHasFashion(templateId))
    or (rewardType == XRewardManager.XRewardType.Character and XMVCA.XCharacter:IsOwnCharacter(templateId))
end

function XRewardManager.IsRewardHeadPortrait(rewardType, templateId) -- 是否拥有头像
    return (rewardType == XRewardManager.XRewardType.HeadPortrait and XDataCenter.HeadPortraitManager.IsHeadPortraitValid(templateId))
end

function XRewardManager.IsRewardDormCharacter(rewardType, templateId) -- 是否拥有宿舍小人
    return (rewardType == XRewardManager.XRewardType.DormCharacter and XDataCenter.DormManager.CheckHaveDormCharacterByRewardId(templateId))
end

function XRewardManager.IsRewardBackground(rewardType, templateId) -- 是否拥有界面场景
    return (rewardType == XRewardManager.XRewardType.Background and XDataCenter.PhotographManager.CheckSceneIsHaveById(templateId))
end

function XRewardManager.IsRewardCharacter(rewardType, templateId) -- 是否拥有角色
    return (rewardType == XRewardManager.XRewardType.Character and XMVCA.XCharacter:IsOwnCharacter(templateId))
end

function XRewardManager.IsRewardEquip(rewardType, templateId) -- 是否拥有武器
    return (rewardType == XRewardManager.XRewardType.Equip and XDataCenter.EquipManager.GetFirstEquip(templateId))
end

XRewardManager.XRewardType = XRewardType
XRewardManager.CreateRewardGoodsByTemplate = CreateRewardGoodsByTemplate
XRewardManager.CreateRewardGoods = CreateRewardGoods
XRewardManager.SortRewardGoodsList = SortRewardGoodsList
XRewardManager.MergeAndSortRewardGoodsList = MergeAndSortRewardGoodsList
XRewardManager.FilterRewardGoodsList = FilterRewardsGoodsList