---@class XDlcCasualModel : XModel
local XDlcCasualModel = XClass(XModel, "XDlcCasualModel")

local TableKey = {
    DlcCasualActivity = { CacheType = XConfigUtil.CacheType.Normal },
    DlcCasualChapter = { CacheType = XConfigUtil.CacheType.Private },
    DlcCasualCharacterPool = { CacheType = XConfigUtil.CacheType.Private },
    DlcCharacterCute = { CacheType = XConfigUtil.CacheType.Private },
    DlcCasualScore = { CacheType = XConfigUtil.CacheType.Private, Identifier = "WorldId" },
    DlcCasualConfig = { CacheType = XConfigUtil.CacheType.Private, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
}

function XDlcCasualModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ActivityId = nil
    self._CurrentCharacterId = nil
    self._WorldMode = XEnumConst.DlcCasualGame.WorldMode.Easy
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/DlcCasual", TableKey)
end

function XDlcCasualModel:ClearPrivate()
    --这里执行内部数据清理
end

function XDlcCasualModel:ResetAll()
    self._ActivityId = nil
    self._CurrentCharacterId = nil
    self._WorldMode = nil
end

--region ActivityConfig
---@return XTableDlcCasualActivity[]
function XDlcCasualModel:GetActivityConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.DlcCasualActivity)

    return configs or {}
end

---@return XTableDlcCasualActivity
function XDlcCasualModel:GetActivityConfigById(activityId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcCasualActivity, activityId)

    return config or {}
end

function XDlcCasualModel:GetActivityTimeIdById(activityId)
    local config = self:GetActivityConfigById(activityId)

    return config.TimeId
end

function XDlcCasualModel:GetActivityTypeById(activityId)
    local config = self:GetActivityConfigById(activityId)

    return config.Type
end

function XDlcCasualModel:GetActivityChapterIdsById(activityId)
    local config = self:GetActivityConfigById(activityId)

    return config.ChapterIds
end

function XDlcCasualModel:GetActivityHelpIdById(activityId)
    local config = self:GetActivityConfigById(activityId)

    return config.HelpId
end

function XDlcCasualModel:GetActivityCharacterPoolIdById(activityId)
    local config = self:GetActivityConfigById(activityId)

    return config.CharacterPoolId
end

function XDlcCasualModel:GetActivityTaskGroupIdsById(activityId)
    local config = self:GetActivityConfigById(activityId)

    return config.TaskGroupIds
end

function XDlcCasualModel:GetActivityTutorialWorldIdById(activityId)
    local config = self:GetActivityConfigById(activityId)

    return config.TutorialWorldId
end

function XDlcCasualModel:GetActivityTutorialLevelIdById(activityId)
    local config = self:GetActivityConfigById(activityId)

    return config.TutorialLevelId
end

--endregion

--region Chapter
---@return XTableDlcCasualChapter[]
function XDlcCasualModel:GetChapterConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.DlcCasualChapter)

    return configs or {}
end

---@return XTableDlcCasualChapter
function XDlcCasualModel:GetChapterConfigById(chapterId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcCasualChapter, chapterId)

    return config or {}
end

function XDlcCasualModel:GetChapterTimeIdById(chapterId)
    local config = self:GetChapterConfigById(chapterId)

    return config.TimeId
end

function XDlcCasualModel:GetChapterNameById(chapterId)
    local config = self:GetChapterConfigById(chapterId)

    return config.Name
end 

function XDlcCasualModel:GetChapterWorldIdsById(chapterId)
    local config = self:GetChapterConfigById(chapterId)

    return config.WorldIds
end

function XDlcCasualModel:GetChapterLevelIdsById(chapterId)
    local config = self:GetChapterConfigById(chapterId)

    return config.LevelIds
end

function XDlcCasualModel:GetChapterWorldDescById(chapterId)
    local config = self:GetChapterConfigById(chapterId)

    return config.WorldDesc
end

--endregion

--region 角色相关
function XDlcCasualModel:GetCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.DlcCharacterCute) or {}
end

function XDlcCasualModel:GetCharacterConfigById(characterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcCharacterCute, characterId, false) or {}
end

function XDlcCasualModel:GetCharacterNpcIdById(characterId)
    local config = self:GetCharacterConfigById(characterId)

    return config.NpcId
end

function XDlcCasualModel:GetCharacterAttribIdById(characterId)
    local config = self:GetCharacterConfigById(characterId)

    return config.AttribId
end

function XDlcCasualModel:GetCharacterNameById(characterId)
    local config = self:GetCharacterConfigById(characterId)

    return config.Name
end

function XDlcCasualModel:GetCharacterTradeNameById(characterId)
    local config = self:GetCharacterConfigById(characterId)

    return config.TradeName
end

function XDlcCasualModel:GetCharacterHeadIconById(characterId)
    local config = self:GetCharacterConfigById(characterId)

    return config.Icon
end

function XDlcCasualModel:GetCharacterRoundHeadImageById(characterId)
    local config = self:GetCharacterConfigById(characterId)

    return config.RoundHeadImage
end

--endregion

--region 角色池相关
---@return XTableDlcCasualCharacterPool[]
function XDlcCasualModel:GetCharacterPoolConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.DlcCasualCharacterPool)

    return configs or {}
end

---@return XTableDlcCasualCharacterPool
function XDlcCasualModel:GetCharacterPoolConfigById(poolId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcCasualCharacterPool, poolId)

    return config or {}
end

function XDlcCasualModel:GetCharacterPoolListById(poolId)
    local config = self:GetCharacterPoolConfigById(poolId)

    return config.CharacterId
end

--endregion

--region 分数相关
---@return XTableDlcCasualScore[]
function XDlcCasualModel:GetScoreConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.DlcCasualScore)

    return configs
end

---@return XTableDlcCasualScore
function XDlcCasualModel:GetScoreConfigById(worldId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcCasualScore, worldId)

    return config
end

function XDlcCasualModel:GetScoreJudgeScoreById(worldId)
    local config = self:GetScoreConfigById(worldId)

    return config.JudgeScore
end

function XDlcCasualModel:GetScoreJudgeNameById(worldId)
    local config = self:GetScoreConfigById(worldId)

    return config.JudgeName
end

function XDlcCasualModel:GetScoreCubeRankMaxTeamScoreById(worldId)
    local config = self:GetScoreConfigById(worldId)

    return config.CubeRankMaxTeamScore
end

--endregion

--region Config
---@return XTableDlcCasualConfig[]
function XDlcCasualModel:GetOtherConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.DlcCasualConfig)

    return configs or {}
end

---@return XTableDlcCasualConfig
function XDlcCasualModel:GetOtherConfigByKey(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcCasualConfig, key)

    return config or {}
end

function XDlcCasualModel:GetOtherConfigValuesByKey(key)
    local config = self:GetOtherConfigByKey(key)

    return config.Values
end
--endregion

function XDlcCasualModel:SetActivityId(activityId)
    self._ActivityId = activityId
end

function XDlcCasualModel:GetActivityId()
    return self._ActivityId
end

function XDlcCasualModel:SetCurrentCharacterId(characterId)
    self._CurrentCharacterId = characterId
end

function XDlcCasualModel:GetCurrentCharacterId()
    return self._CurrentCharacterId
end

function XDlcCasualModel:SetWorldMode(mode)
    self._WorldMode = mode
end

function XDlcCasualModel:GetWorldMode()
    return self._WorldMode or XEnumConst.DlcCasualGame.WorldMode.Easy
end

return XDlcCasualModel
