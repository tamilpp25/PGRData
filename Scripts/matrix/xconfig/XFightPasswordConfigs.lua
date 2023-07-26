local TABLE_PASSWORD_PATH = "Client/Fight/PasswordGame/FightPasswordGame.tab"
local PasswordGameConfigs = {}

XFightPasswordConfigs = XFightPasswordConfigs or {}

function XFightPasswordConfigs.Init()
    PasswordGameConfigs = XTableManager.ReadByIntKey(TABLE_PASSWORD_PATH, XTable.XTableFightPasswordGame, "Id")
end

local GetPasswordGameConfig = function(id)
    local config = PasswordGameConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XFightPasswordConfigs.GetPasswordGameConfig", "PasswordGameConfigs", TABLE_PASSWORD_PATH, "Id", id)
        return
    end
    return config
end

function XFightPasswordConfigs.GetCorrectPassword(id, index)
    local config = GetPasswordGameConfig(id)
    return config.CorrectPasswords[index]
end 