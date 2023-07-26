XHaruUserManager = XHaruUserManager or {}

local AccountList = {}
local AccountDict = {}
local IsLoadList = false

function XHaruUserManager.IsNeedLogin()
    return not XUserManager.UserId or #XUserManager.UserId == 0
end

function XHaruUserManager.Login(cb)
    if XHaruUserManager.IsNeedLogin() then
        XLuaUiManager.Open("UiRegister", cb)
    end
end

function XHaruUserManager.Logout(cb)
    if XHaruUserManager.IsNeedLogin() then
        if cb then
            cb()
        end

        return
    end

    if XDataCenter.FunctionEventManager.CheckFuncDisable() then
        XUserManager.SignOut()
    else
        local title = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("LoginSignOut")
        local dialogType = XUiManager.DialogType.Normal
        local closeCallback = nil
        local sureCallback = function()
            XUserManager.SignOut()
        end

        XLuaUiManager.Open("UiDialog", title, content, dialogType, closeCallback, sureCallback);
    end

    if cb then
        cb()
    end
end

function XHaruUserManager.SignIn(userId, cb)
    AccountDict[userId] = os.time()
    IsLoadList = false
    XSaveTool.SaveData(XPrefs.AccountHistory, AccountDict)

    XUserManager.SetUserId(userId)
    XUserManager.SetUserName(userId)
    if cb then
        cb()
    end
end

function XHaruUserManager.GetAccountList()
    if not next(AccountDict) then
        AccountDict = XSaveTool.GetData(XPrefs.AccountHistory) or {}
    end
    if not IsLoadList then
        AccountList = {}
        for name, v in pairs(AccountDict) do
            local account = {
                Name = name,
                Time = v,
            }
            table.insert(AccountList, account)
        end
        table.sort(AccountList, function(a, b)
            return a.Time > b.Time
        end)
        IsLoadList = true
    end
    return AccountList
end