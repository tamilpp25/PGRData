
---@class XSkyGardenCafeConfig : XModel
local XSkyGardenCafeConfig = XClass(XModel, "XSkyGardenCafeConfig")

local pairs = pairs
local MaxQuality = 5

local TableKey = {
    SGCafeActivity = { CacheType = XConfigUtil.CacheType.Normal },
    SGCafeChapter = {},
    SGCafeStage = { CacheType = XConfigUtil.CacheType.Normal },
    SGCafeCustomerGroup = {},
    SGCafeCustomerGenerate = {},
    SGCafeCustomer = { ReadFunc = XConfigUtil.ReadType.IntAll },
    SGCafeConfig = { ReadFunc = XConfigUtil.ReadType.String },
    SGCafeCondition = {},
    SGCafeEffect = {},
    SGCafeBuffList = {},
    SGCafeNpcShow = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "LevelNpcBaseId" },
    SGCafePosition = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.IntAll },
    SGCafeRoute = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.IntAll },
    SGCafeTag = { DirPath = XConfigUtil.DirectoryType.Client },
    SGCafeCustomerPreset = { CacheType = XConfigUtil.CacheType.Normal },
}

function XSkyGardenCafeConfig:OnInit()
    self._AllShowCustomerIds = false
    self._AllPositionIds = false
    self._AllPatrolIds = false
    self._ConfigUtil:InitConfigByTableKey("BigWorld/SkyGarden/Cafe", TableKey)
end

function XSkyGardenCafeConfig:ClearPrivate()
end

function XSkyGardenCafeConfig:ResetAll()
end

---@return XTableSGCafeActivity
function XSkyGardenCafeConfig:GetActivityTemplate(activityId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeActivity, activityId)
end

function XSkyGardenCafeConfig:GetStoryChapterId(activityId)
    local t = self:GetActivityTemplate(activityId)
    return t and t.StoryChapterId
end

function XSkyGardenCafeConfig:GetChallengeChapterId(activityId)
    local t = self:GetActivityTemplate(activityId)
    return t and t.ChallengeChapterId
end

function XSkyGardenCafeConfig:GetActivityTimeId(activityId)
    local t = self:GetActivityTemplate(activityId)
    return t and t.TimeId
end

---@return number[]
function XSkyGardenCafeConfig:GetChapterStageIds(chapterId)
    ---@type XTableSGCafeChapter
    local t = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeChapter, chapterId)
    return t and t.StageIds
end

---@return XTableSGCafeStage
function XSkyGardenCafeConfig:GetStageTemplate(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeStage, stageId)
end

function XSkyGardenCafeConfig:GetStageReward(stageId)
    if not stageId or stageId <= 0 then
        return
    end
    local t = self:GetStageTemplate(stageId)
    return t and t.Reward or nil
end

function XSkyGardenCafeConfig:GetStageTarget(stageId)
    if not stageId or stageId <= 0 then
        return
    end
    local t = self:GetStageTemplate(stageId)
    return t and t.Target or nil
end

function XSkyGardenCafeConfig:GetStageRounds(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.Rounds or 0
end

function XSkyGardenCafeConfig:GetStageInitReview(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.InitReview or 0
end

function XSkyGardenCafeConfig:GetStageGenerateGroupId(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.CustomerGroup or 0
end

function XSkyGardenCafeConfig:IsStoryStage(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.Type == XMVCA.XSkyGardenCafe.StageType.Story or false
end

function XSkyGardenCafeConfig:IsEndlessChallengeStage(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.Type == XMVCA.XSkyGardenCafe.StageType.EndlessChallenge or false
end

function XSkyGardenCafeConfig:GetMaxCustomer(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.MaxCustomer or 0
end

function XSkyGardenCafeConfig:GetActPoint(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.ActPoint or 0
end

function XSkyGardenCafeConfig:GetStageBuffListId(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.BuffListId or 0
end

function XSkyGardenCafeConfig:IsReviewStage(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.Review or false
end

function XSkyGardenCafeConfig:IsReDrawStage(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.IsReDraw or false
end

function XSkyGardenCafeConfig:IsSingleGenerate(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.IsSingleGenerate or false
end

function XSkyGardenCafeConfig:GetPreStageId(stageId)
    local t = self:GetStageTemplate(stageId)
    return t and t.PreStage
end

function XSkyGardenCafeConfig:GetGenerateIds(groupId)
    ---@type XTableSGCafeCustomerGroup
    local t = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeCustomerGroup, groupId)
    local ids = t.GenerateIds
    if not ids then
        XLog.Error("不存在该配置: " .. groupId)
        return ids
    end
    return ids
end

function XSkyGardenCafeConfig:IsFixedOrder(generateId)
    ---@type XTableSGCafeCustomerGenerate
    local t = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeCustomerGenerate, generateId)
    return t and t.IsOrder or false
end

function XSkyGardenCafeConfig:GetCustomerIds(generateId)
    ---@type XTableSGCafeCustomerGenerate
    local t = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeCustomerGenerate, generateId)
    return t and t.CustomerIds or nil
end

---@return XTableSGCafeCustomer
function XSkyGardenCafeConfig:GetCustomerTemplate(customerId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeCustomer, customerId)
end

function XSkyGardenCafeConfig:GetCustomerTags(customerId)
    local t = self:GetCustomerTemplate(customerId)
    return t and t.Tags
end

function XSkyGardenCafeConfig:GetCustomerCoffee(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.Coffee
end

function XSkyGardenCafeConfig:GetCustomerPriority(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.Priority or 0
end

function XSkyGardenCafeConfig:GetCustomerReview(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.Review
end

function XSkyGardenCafeConfig:GetCustomerType(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.Type
end

function XSkyGardenCafeConfig:GetCustomerUseCondition(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.UseConditions
end

function XSkyGardenCafeConfig:GetCustomerQuality(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.Quality
end

function XSkyGardenCafeConfig:GetCustomerUnlockDesc(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.UnlockDesc
end

function XSkyGardenCafeConfig:GetCustomerNpcId(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.NpcId
end

function XSkyGardenCafeConfig:GetCustomerBuffIds(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.Effects
end

function XSkyGardenCafeConfig:IsReDrawCustomer(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.IsReDraw or false
end

function XSkyGardenCafeConfig:GetCustomerDesc(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.Desc or ""
end

function XSkyGardenCafeConfig:GetCustomerWorldDesc(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.WorldDesc or ""
end

function XSkyGardenCafeConfig:GetCustomerDetails(id)
    local t = self:GetCustomerTemplate(id)
    return t and t.Details or ""
end

function XSkyGardenCafeConfig:IsMaxQuality(id)
    return self:GetCustomerQuality(id) == MaxQuality
end

function XSkyGardenCafeConfig:GetMaxQuality()
    return MaxQuality
end

function XSkyGardenCafeConfig:GetAllShowCustomerIds()
    if self._AllShowCustomerIds then
        return self._AllShowCustomerIds
    end
    ---@type table<number, XTableSGCafeCustomer>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SGCafeCustomer)
    local list = {}
    for id, t in pairs(templates) do
        if t and t.IsShow then
            list[#list + 1] = id
        end
    end
    self._AllShowCustomerIds = list
    
    return list
end

---@return XTableSGCafeCondition
function XSkyGardenCafeConfig:GetConditionTemplate(conditionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeCondition, conditionId)
end

--region Config

---@return string
function XSkyGardenCafeConfig:GetConfig(id)
    ---@type XTableSGCafeConfig
    local t = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeConfig, id)
    return t.Value
end

function XSkyGardenCafeConfig:GetChallengeMaxCustomer()
    return tonumber(self:GetConfig("GroupMaxCardNum"))
end

function XSkyGardenCafeConfig:GetMaxPatrolNpcCount()
    return tonumber(self:GetConfig("MaxPatrolNpc"))
end

function XSkyGardenCafeConfig:GetMaxIdleNpcCount()
    return tonumber(self:GetConfig("MaxStaticNpc"))
end

function XSkyGardenCafeConfig:GetBarTableClickCd()
    return tonumber(self:GetConfig("ClickBarCd"))
end

function XSkyGardenCafeConfig:GetPatrolInterval()
    return tonumber(self:GetConfig("PatrolCd"))
end

function XSkyGardenCafeConfig:GetBtnReDrawText(isSelect)
    local index = isSelect and "Redraw" or "ConfirmHand"
    return self:GetConfig(index)
end

function XSkyGardenCafeConfig:GetResourceNotEnough(isCoffee)
    local index = isCoffee and "Undersales" or "LackAffection"
    return self:GetConfig(index)
end

function XSkyGardenCafeConfig:GetMaxDealCount()
    return tonumber(self:GetConfig("MaxSeat"))
end

function XSkyGardenCafeConfig:GetMaxDeckCount()
    return tonumber(self:GetConfig("MaxHandCardNum"))
end

--endregion Config

--region Effect

---@return XTableSGCafeEffect
function XSkyGardenCafeConfig:GetEffectTemplate(effectId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeEffect, effectId)
end

function XSkyGardenCafeConfig:GetEffectTriggerId(effectId)
    local t = self:GetEffectTemplate(effectId)
    return t and t.Trigger
end

function XSkyGardenCafeConfig:GetEffectType(effectId)
    local t = self:GetEffectTemplate(effectId)
    return t and t.Type
end

function XSkyGardenCafeConfig:GetEffectParams(effectId)
    local t = self:GetEffectTemplate(effectId)
    return t and t.Params
end

function XSkyGardenCafeConfig:IsSingleShotEffect(effectId)
    local t = self:GetEffectTemplate(effectId)
    return t and t.SingleShot or false
end

function XSkyGardenCafeConfig:GetEffectConditions(effectId)
    local t = self:GetEffectTemplate(effectId)
    return t and t.Conditions
end

---@return XTableSGCafeBuffList
function XSkyGardenCafeConfig:GetBuffListTemplate(buffListId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeBuffList, buffListId)
end

function XSkyGardenCafeConfig:GetBuffListEffectIds(buffListId)
    local t = self:GetBuffListTemplate(buffListId)
    return t and t.EffectIds or nil
end

--endregion Effect


--region show

---@return XTableSGCafeNpcShow
function XSkyGardenCafeConfig:GetNpcShowTemplate(npcId, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeNpcShow, npcId, noTips)
end

function XSkyGardenCafeConfig:GetShowSettleEmoji(npcId)
    local t = self:GetNpcShowTemplate(npcId)
    return t and t.SettleEmoji
end

function XSkyGardenCafeConfig:GetShowClickText(npcId)
    local t = self:GetNpcShowTemplate(npcId)
    return t and t.ClickText
end

function XSkyGardenCafeConfig:GetNpcDefaultPosId(npcId, noTips)
    local t = self:GetNpcShowTemplate(npcId, noTips)
    return t and t.DefaultPosId or 0
end

function XSkyGardenCafeConfig:GetShowCoffeeOffset(posId)
    local t = self:GetCafePositionTemplate(posId)
    return t.CoffeeOffsetX, t.CoffeeOffsetY
end

function XSkyGardenCafeConfig:GetShowReviewOffset(posId)
    local t = self:GetCafePositionTemplate(posId)
    return t.ReviewOffsetX, t.ReviewOffsetY
end

function XSkyGardenCafeConfig:GetShowEmojiOffset(posId)
    local t = self:GetCafePositionTemplate(posId)
    return t.EmojiOffsetX, t.EmojiOffsetY
end

function XSkyGardenCafeConfig:GetSpotId(posId)
    local t = self:GetCafePositionTemplate(posId)
    return t and t.SpotId or 0
end

---@return XTableSGCafePosition
function XSkyGardenCafeConfig:GetCafePositionTemplate(posId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafePosition, posId)
end

---@return number[]
function XSkyGardenCafeConfig:GetAllPositionIds()
    if self._AllPositionIds then
        return self._AllPositionIds
    end
    local ids = {}
    ---@type table<number, XTableSGCafePosition>
    local temps = self._ConfigUtil:GetByTableKey(TableKey.SGCafePosition)
    -- 吧台区域，不参与随机
    local targetArea = 1
    for _, t in pairs(temps) do
        if t.Area ~= targetArea then
            ids[#ids + 1] = t.Id
        end
    end
    self._AllPositionIds = ids
    
    return ids
end

function XSkyGardenCafeConfig:GetAllPatrolIds()
    if self._AllPatrolIds then
        return self._AllPatrolIds
    end
    local ids = {}
    ---@type table<number, XTableSGCafeRoute>
    local temps = self._ConfigUtil:GetByTableKey(TableKey.SGCafeRoute)
    for _, t in pairs(temps) do
        ids[#ids + 1] = t.RouteId
    end
    self._AllPatrolIds = ids

    return ids
end


--endregion show


---@return XTableSGCafeTag
function XSkyGardenCafeConfig:GetTagTemplate(tagId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeTag, tagId)
end

---@return number[]
function XSkyGardenCafeConfig:GetPresetCustomerIds(deckId)
    ---@type XTableSGCafeCustomerPreset
    local t = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SGCafeCustomerPreset, deckId)
    return t and t.CustomerIds
end

return XSkyGardenCafeConfig