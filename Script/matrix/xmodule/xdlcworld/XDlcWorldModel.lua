---@class XDlcWorldModel : XModel
local XDlcWorldModel = XClass(XModel, "XDlcWorldModel")
---注册配置表的读取方式
--- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local TableKey = {
    DlcWorld = { Identifier = "WorldId", CacheType = XConfigUtil.CacheType.Normal }
}

function XDlcWorldModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("DlcWorld", TableKey)
    self._Result = nil
end

function XDlcWorldModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XDlcWorldModel:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

--region World
---@return XTableDlcHuntWorld[]
function XDlcWorldModel:GetWorldConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.DlcWorld) or {}
end

---@return XTableDlcHuntWorld
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

function XDlcWorldModel:GetRobootIdById(worldId)
    local config = self:GetWorldConfigById(worldId)

    return config.RebootId
end 
--endregion

--region Result
function XDlcWorldModel:SetResult(result)
    self._Result = result
end

function XDlcWorldModel:GetResult()
    return self._Result
end
--endregion

return XDlcWorldModel