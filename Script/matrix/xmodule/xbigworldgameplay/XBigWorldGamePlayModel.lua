---@class XBigWorldGamePlayModel : XModel
local XBigWorldGamePlayModel = XClass(XModel, "XBigWorldGamePlayModel")

local TableKey = {
    BigWorldGamePlay = {
        Identifier = "WorldId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldActivity = {
        DirPath = XConfigUtil.DirectoryType.Client,
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Temp,
    }
}

function XBigWorldGamePlayModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._CurrentWorldId = 0
    self._CurrentLevelId = 0

    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Activity", TableKey)
end

function XBigWorldGamePlayModel:OnClear()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldGamePlayModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldGamePlayModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

-- region Config

function XBigWorldGamePlayModel:GetModuleIdByWorldId(worldId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldGamePlay, worldId)

    return config and config.ModuleId or ""
end

-- endregion

function XBigWorldGamePlayModel:SetCurrentWorldId(worldId)
    self._CurrentWorldId = worldId
end

function XBigWorldGamePlayModel:GetCurrentWorldId()
    return self._CurrentWorldId
end

function XBigWorldGamePlayModel:SetCurrentLevelId(levelId)
    self._CurrentLevelId = levelId
end

function XBigWorldGamePlayModel:GetCurrentLevelId()
    return self._CurrentLevelId
end

---@return table<number, XTableBigWorldActivity>
function XBigWorldGamePlayModel:GetAllActivityTemplates()
    return self._ConfigUtil:GetByTableKey(TableKey.BigWorldActivity)
end

function XBigWorldGamePlayModel:Clear()
    self._CurrentWorldId = 0
    self._CurrentLevelId = 0
end

return XBigWorldGamePlayModel
