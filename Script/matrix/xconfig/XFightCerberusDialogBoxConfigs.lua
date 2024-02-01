local TABLE_PATH = "Client/Fight/UiFightCerberusDialogBox.tab"
local Configs = {}

XFightCerberusDialogBoxConfigs = XFightCerberusDialogBoxConfigs or {}

function XFightCerberusDialogBoxConfigs.Init()
    Configs = XTableManager.ReadByIntKey(TABLE_PATH, XTable.XTableUiFightCerberusDialogBox, "Id")
end

local GetConfig = function(id)
    local config = Configs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XFightCerberusDialogBoxConfigs.GetConfig", "Configs", TABLE_PATH, "Id", id)
        return
    end
    return config
end

function XFightCerberusDialogBoxConfigs.GetUiPrefab(id)
    local config = GetConfig(id)
    return config.UiPrefab
end

function XFightCerberusDialogBoxConfigs.GetIcon(id)
    local config = GetConfig(id)
    return config.Icon
end

function XFightCerberusDialogBoxConfigs.GetName(id)
    local config = GetConfig(id)
    return config.Name
end

function XFightCerberusDialogBoxConfigs.GetDesc(id)
    local config = GetConfig(id)
    return config.Desc
end

function XFightCerberusDialogBoxConfigs.GetShowTime(id)
    local config = GetConfig(id)
    return config.ShowTime
end

function XFightCerberusDialogBoxConfigs.GetCvList(id)
    local config = GetConfig(id)
    return config.CvList
end