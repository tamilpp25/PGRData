local TABLE_BRILLIANTWALK_PATH = "Client/Fight/FightBrilliantwalk.tab"
local FightBrilliantwalkConfigs = {}

XFightBrilliantwalkConfigs = XFightBrilliantwalkConfigs or {}

function XFightBrilliantwalkConfigs.Init()
    FightBrilliantwalkConfigs = XTableManager.ReadByIntKey(TABLE_BRILLIANTWALK_PATH, XTable.XTableFightBrilliantwalk, "Id")
end

local GetBrilliantwalkConfig = function(id)
    local config = FightBrilliantwalkConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XFightBrilliantwalkConfigs.GetBrilliantwalkConfig", "FightBrilliantwalkConfigs", TABLE_BRILLIANTWALK_PATH, "Id", id)
        return
    end
    return config
end

function XFightBrilliantwalkConfigs.GetPrefabPath(id, type)
    id = XTool.IsNumberValid(id) and id or 1    --默认用第一行的配置
    local config = GetBrilliantwalkConfig(id)
    return config.TypeToPrefabPaths[type]
end

function XFightBrilliantwalkConfigs.GetEffectName(id)
    id = XTool.IsNumberValid(id) and id or 1    --默认用第一行的配置
    local config = GetBrilliantwalkConfig(id)
    return config.EffectName
end