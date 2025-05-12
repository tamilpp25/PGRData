local TABLE_PATH = "Client/Fight/UiFightTutorial.tab"
local Configs = {}

XUiFightTutorialConfigs = XUiFightTutorialConfigs or {}

function XUiFightTutorialConfigs.Init()
    Configs = XTableManager.ReadByIntKey(TABLE_PATH, XTable.XTableUiFightTutorial, "Id")
end

local GetConfig = function(id)
    local config = Configs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XUiFightTutorialConfigs.GetConfig", "Configs", TABLE_PATH, "Id", id)
        return
    end
    return config
end

function XUiFightTutorialConfigs.Get(id)
    local config = GetConfig(id)
    return config
end