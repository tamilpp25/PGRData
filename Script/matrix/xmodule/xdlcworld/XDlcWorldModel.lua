---@class XDlcWorldModel : XModel
local XDlcWorldModel = XClass(XModel, "XDlcWorldModel")
---注册配置表的读取方式
--- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
-- =============
-- 配置表枚举
-- ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
-- DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
-- Identifier : 读取表格的主键名，默认为Id
-- TableDefinedName : 表定于名，默认同表名
-- CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
-- =============
local TableKey = {
    DlcWorld = {
        Identifier = "WorldId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcWorldAttrib = {
        TableDefindName = "XTableAttribBase",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcWorldSettingDetail = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XDlcWorldModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._AgencyMap = {}
    self._Result = nil
    self._ConfigUtil:InitConfigByTableKey("DlcWorld", TableKey)
end

function XDlcWorldModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XDlcWorldModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

-- region World

---@return XTableDlcWorld[]
function XDlcWorldModel:GetWorldConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.DlcWorld) or {}
end

---@return XTableDlcWorld
function XDlcWorldModel:GetWorldConfigById(worldId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcWorld, worldId, false) or {}
end

function XDlcWorldModel:GetNameById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.Name
end

function XDlcWorldModel:GetTypeById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.WorldType
end

function XDlcWorldModel:GetPreWorldIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.PreWorldId
end

function XDlcWorldModel:GetTeachingCharacterIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.TeachingCharacterId
end

function XDlcWorldModel:GetChapterIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.ChapterId
end

function XDlcWorldModel:GetBgmIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.BgmId
end

function XDlcWorldModel:GetEventIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.EventId
end

function XDlcWorldModel:GetLoadingTypeById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.LoadingType
end

function XDlcWorldModel:GetFinishRewardShowById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.FinishRewardShow
end

function XDlcWorldModel:GetFinishDropIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.FinishDropId
end

function XDlcWorldModel:GetFirstRewardIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.FirstRewardId
end

function XDlcWorldModel:GetTeamPlayerLeastById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.TeamPlayerLeast
end

function XDlcWorldModel:GetTeamPlayerLimitById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.TeamPlayerLimit
end

function XDlcWorldModel:GetOnlinePlayerLeastById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.OnlinePlayerLeast
end

function XDlcWorldModel:GetOnlinePlayerLimitById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.OnlinePlayerLimit
end

function XDlcWorldModel:GetSettleLoseTipIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.SettleLoseTipId
end

function XDlcWorldModel:GetMatchPlayerCountThresholdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.MatchPlayerCountThreshold
end

function XDlcWorldModel:GetNeedFightPowerById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.NeedFightPower
end

function XDlcWorldModel:GetIsRankById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.IsRank
end

function XDlcWorldModel:GetDifficultyIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.DifficultyId
end

function XDlcWorldModel:GetSettingDetailIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.SettingDetailId
end

function XDlcWorldModel:GetRobootIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.RebootId
end

function XDlcWorldModel:GetMatchStrategyById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.MatchStrategy
end

-- endregion

-- region SettingDetail

---@return XTableDlcWorldSettingDetail[]
function XDlcWorldModel:GetSettingDetailConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.DlcWorldSettingDetail) or {}
end

---@return XTableDlcWorldSettingDetail
function XDlcWorldModel:GetSettingDetailConfigById(detailId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcWorldSettingDetail, detailId) or {}
end

function XDlcWorldModel:GetSettingDetailTipNameById(detailId)
    local config = self:GetSettingDetailConfigById(detailId)

    return config.TipName or {}
end

function XDlcWorldModel:GetSettingDetailTipDescById(detailId)
    local config = self:GetSettingDetailConfigById(detailId)

    return config.TipDes or {}
end

function XDlcWorldModel:GetSettingDetailTipAssetById(detailId)
    local config = self:GetSettingDetailConfigById(detailId)

    return config.TipAsset or {}
end

-- endregion

-- region Character

---@return XTableDlcCharacter[]
function XDlcWorldModel:GetCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.DlcCharacter) or {}
end

---@return XTableDlcCharacter
function XDlcWorldModel:GetCharacterConfigByNpcId(npcId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcCharacter, npcId) or {}
end

function XDlcWorldModel:GetCharacterIdByNpcId(npcId)
    local config = self:GetCharacterConfigByNpcId(npcId)

    return config.CharacterId
end

-- endregion

-- region Attribute

---@return XTableAttribBase
function XDlcWorldModel:GetAttributeConfigById(attribId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.DlcWorldAttrib, attribId, false) or {}
end

-- endregion

-- region Result

function XDlcWorldModel:SetResult(result)
    self._Result = result
end

function XDlcWorldModel:GetResult()
    return self._Result
end

-- endregion

function XDlcWorldModel:AddAgency(worldType, moduleId)
    if self._AgencyMap[worldType] then
        XLog.Error("请勿重复注册Agency! ModuleId = " .. moduleId)
    end

    self._AgencyMap[worldType] = moduleId
end

function XDlcWorldModel:GetAgencyByWorldType(worldType)
    return self._AgencyMap[worldType]
end

return XDlcWorldModel
