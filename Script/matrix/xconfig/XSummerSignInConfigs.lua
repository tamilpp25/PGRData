XSummerSignInConfigs = XSummerSignInConfigs or {}

local SHARE_SUMMER_SIGNIN = "Share/SignIn/SummerSignIn/SummerSignIn.tab"

local CLIENT_SUMMER_MESSAGE = "Client/SignIn/SummerSignIn/SummerMessage.tab"

local SummerSignInConfig
local SummerMessageConfig

function XSummerSignInConfigs.Init()
    SummerSignInConfig = XTableManager.ReadByIntKey(SHARE_SUMMER_SIGNIN, XTable.XTableSummerSignIn, "Id")
    SummerMessageConfig = XTableManager.ReadByIntKey(CLIENT_SUMMER_MESSAGE, XTable.XTableSummerMessage, "Id")
end

--region 获取配置表

local function GetSummerSignInConfig(id)
    local config = SummerSignInConfig[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetSummerSignInConfig", "tab", SHARE_SUMMER_SIGNIN, "id", tostring(id))
        return
    end
    return config
end

local function GetSummerMessageConfig(id)
    local config = SummerMessageConfig[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetSummerMessageConfig", "tab", CLIENT_SUMMER_MESSAGE, "id", tostring(id))
        return
    end
    return config
end

--endregion

--region 活动表

function XSummerSignInConfigs.GetActivityTimeId(id)
    local config = GetSummerSignInConfig(id)
    return config.TimeId or 0
end

function XSummerSignInConfigs.GetActivityMessageId(id)
    local config = GetSummerSignInConfig(id)
    return config.MessageId or {}
end

--endregion

--region 留言表

function XSummerSignInConfigs.GetSummerMessageConfig(messageId)
    return GetSummerMessageConfig(messageId)
end

function XSummerSignInConfigs.GetTeamName(messageId)
    local config = GetSummerMessageConfig(messageId)
    return config.TeamName or ""
end

--endregion