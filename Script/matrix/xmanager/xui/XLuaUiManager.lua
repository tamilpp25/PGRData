CsXUiType = CS.XUiType
CsXUiManager = CS.XUiManager
CsXGameEventManager = CS.XGameEventManager
CsXUiHelper = CS.XUiHelper
CsXTextManagerGetText = CS.XTextManager.GetText
CSXTextManagerGetText = CsXTextManagerGetText
CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
Vector2 = CS.UnityEngine.Vector2
Vector3 = CS.UnityEngine.Vector3

local Registry = require("UiRegistry")

local IsWindowsEditor = XMain.IsWindowsEditor
local Uid2UiNameMap = {}
local _UIUid = 0

---@class XLuaUiManager
XLuaUiManager = XClass(nil, "XLuaUiManager")
local UiData = {}
local ClassType = {}
local ImportModule = {}
local XUiPrefix = "XUi/X%s/X%s"

function XLuaUiManager.GenUIUid()
    _UIUid = _UIUid + 1
    return _UIUid
end

function XLuaUiManager.IsWindowsEditor()
    return IsWindowsEditor
end

--- 注册Ui
---@param super XLuaUi 父类
---@param uiName string ui名
--------------------------
function XLuaUiManager.Register(super, uiName)
    super = super or XLuaUi
    local uiObject = XClass(super, uiName)
    ClassType[uiName] = uiObject
    return uiObject
end

--创建一个LuaUI的实例
--@name LuaUI脚本名字
--@gameUI C#的GameUI
function XLuaUiManager.New(uiName, uiProxy)
    local baseName = uiName
    local class = ClassType[baseName]

    if not class then
        local register = Registry[baseName]
        if register then
            require(register)
        end

        class = ClassType[baseName]
    end

    if not class then
        baseName = string.match(baseName, "%w*[^(%d)$*]") -- 解析包含数字后缀的界面
        class = ClassType[baseName]
        if not class then
            XLog.Error("XLuaUiManager.New error, class not exist, name: " .. uiName)
            return nil
        end
    end
    local obj = class.New(uiName, uiProxy)
    uiProxy:SetLuaTable(obj)
    return obj
end

--打开UI
--@uiName 打开的UI名字
function XLuaUiManager.Open(uiName, ...)
    XLuaUiManager.RecordTryDownload(uiName)
    CsXUiManager.Instance:Open(uiName, ...)
end

--打开UI，完成后执行回调
--@uiName 打开的UI名称
--@callback 打开完成回调
--@... 传递到OnStart的参数
function XLuaUiManager.OpenWithCallback(uiName, callback, ...)
    XLuaUiManager.RecordTryDownload(uiName)
    CsXUiManager.Instance:OpenWithCallback(uiName, callback, ...)
end

--打开UI，关闭后执行回调
--@uiName 打开的UI名称
--@callback 关闭后执行的回调
--@... 传递到OnStart的参数
function XLuaUiManager.OpenWithCloseCallback(uiName, callback, ...)
    XLuaUiManager.RecordTryDownload(uiName)
    CsXUiManager.Instance:OpenWithCloseCallback(uiName, callback, ...)
end

--关闭UI，完成后执行回调
--@uiName 打开的UI名称
--@callback 打开完成回调
function XLuaUiManager.CloseWithCallback(uiName, callback)
    CsXUiManager.Instance:CloseWithCallback(uiName, callback)
end

--针对Normal类型的管理，关闭上一个界面，然后打开下一个界面（无缝切换）
--@uiName 需要打开的UI名字
--@... 传递到OnStart的参数
function XLuaUiManager.PopThenOpen(uiName, ...)
    XLuaUiManager.RecordTryDownload(uiName)
    CsXUiManager.Instance:PopThenOpen(uiName, ...)
end

--针对Normal类型的管理，关闭栈中所有界面，然后打开下一个界面（无缝切换）
--@uiName 需要打开的UI名字
--@... 传递到OnStart的参数
function XLuaUiManager.PopAllThenOpen(uiName, ...)
    XLuaUiManager.RecordTryDownload(uiName)
    CsXUiManager.Instance:PopAllThenOpen(uiName, ...)
end

--- 关闭目标Ui栈上方的所有Ui（针对Normal类型）
---@param uiName string 目标Ui名称
function XLuaUiManager.CloseAllUpperUi(uiName)
    CsXUiManager.Instance:CloseAllUpperUi(uiName)
end

--- 关闭目标Ui栈上方的所有Ui（针对Normal类型）
---@param uiName string 目标Ui名称
---@param callback fun():void 完成回调
function XLuaUiManager.CloseAllUpperUiWithCallback(uiName, callback)
    CsXUiManager.Instance:CloseAllUpperUi(uiName, callback)
end

--关闭UI
--@uiName 关闭的UI名字(只能关闭当前显示的UI)
function XLuaUiManager.Close(uiName)
    CsXUiManager.Instance:Close(uiName)
end

--移除UI,移除的UI不会播放进场、退场动画
--@uiName 关闭的UI名字（可以关闭非当前显示UI）
function XLuaUiManager.Remove(uiName)
    CsXUiManager.Instance:Remove(uiName)
end

--某个UI是否显示
function XLuaUiManager.IsUiShow(uiName)
    return CsXUiManager.Instance:IsUiShow(uiName)
end

--某个UI是否正在推入中，打开即推入，Awake推出
function XLuaUiManager.IsUiPushing(uiName)
    return CsXUiManager.Instance:IsUiPushing(uiName)
end

--某个UI是否已经加载
function XLuaUiManager.IsUiLoad(uiName)
    return CsXUiManager.Instance:IsUiLoad(uiName)
end

local _MaskCount = {}
--设置mask，visible=true时不能操作
function XLuaUiManager.SetMask(visible, key)
    visible = visible and true or false
    CsXUiManager.Instance:SetMask(visible)

    -- key分类计数
    if key then
        if not _MaskCount[key] then
            _MaskCount[key] = 0
        end
        if visible then
            _MaskCount[key] = _MaskCount[key] + 1
        else
            _MaskCount[key] = math.max(_MaskCount[key] - 1, 0)
        end
    end
end

function XLuaUiManager.IsMaskShow(key)
    if not key then
        XLog.Error("[XLuaUiManager] 不支持获取计数")
        return false
    end
    return (_MaskCount[key] or 0) > 0
end

--设置animationMask，tag标签,visible=true时不能操作，delay(默认2秒)后会展示菊花
function XLuaUiManager.SetAnimationMask(tag, visible, delay)
    visible = visible and true or false
    delay = delay or 2
    CsXUiManager.Instance:SetAnimationMask(tag, visible, delay)
end

function XLuaUiManager.ClearMask(resetMaskCount)
    resetMaskCount = resetMaskCount and true or false
    if resetMaskCount then
        _MaskCount = {}
    end
    CsXUiManager.Instance:ClearMask(resetMaskCount)
end

function XLuaUiManager.ClearAnimationMask()
    CsXUiManager.Instance:ClearAnimationMask()
end

function XLuaUiManager.ClearAllMask(resetMaskCount)
    XLuaUiManager.ClearMask(resetMaskCount)
    CsXUiManager.Instance:ClearAnimationMask()
end

function XLuaUiManager.TryImportLuaFile(name)
    local module = ImportModule[name]
    if module then
        return
    end
    local str = string.format(XUiPrefix, name, name)
    XLog.Error(str)
    require(str)
    ImportModule[name] = 1
end

--返回主界面
function XLuaUiManager.RunMain(notDialogTip)
    --CsXUiManager.Instance:Clear()
    local needClearUiName = {
        "UiFubenMainLineChapter",
        "UiFubenMainLineChapterFw",
        "UiFubenMainLineChapterDP",
        "UiPrequel"
    }
    for _, uiName in pairs(needClearUiName) do
        XLuaUiManager.RemoveUiData(uiName)
    end

    if XDataCenter.RoomManager.RoomData then
        if notDialogTip then
            XDataCenter.RoomManager.Quit(
                    function()
                        CsXUiManager.Instance:RunMain()
                    end
            )

            return
        end

        -- 如果在房间中，需要先弹确认框
        local title = CsXTextManagerGetText("TipTitle")
        local cancelMatchMsg
        local stageId = XDataCenter.RoomManager.RoomData.StageId
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            cancelMatchMsg = CsXTextManagerGetText("ArenaOnlineInstanceQuitRoom")
        else
            cancelMatchMsg = CsXTextManagerGetText("OnlineInstanceQuitRoom")
        end

        XUiManager.DialogTip(
                title,
                cancelMatchMsg,
                XUiManager.DialogType.Normal,
                nil,
                function()
                    XDataCenter.RoomManager.Quit(
                            function()
                                CsXUiManager.Instance:RunMain()
                            end
                    )
                end
        )
    elseif XDataCenter.RoomManager.Matching then
        if notDialogTip then
            XDataCenter.RoomManager.CancelMatch(
                    function()
                        CsXUiManager.Instance:RunMain()
                    end
            )

            return
        end

        local title = CsXTextManagerGetText("TipTitle")
        local cancelMatchMsg = CsXTextManagerGetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(
                title,
                cancelMatchMsg,
                XUiManager.DialogType.Normal,
                nil,
                function()
                    XDataCenter.RoomManager.CancelMatch(
                            function()
                                CsXUiManager.Instance:RunMain()
                            end
                    )
                end
        )
    elseif XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.DialogTipQuitRoom(function()
            CsXUiManager.Instance:RunMain()
        end)
    elseif XMVCA.XDlcRoom:IsInRoom() then
        if notDialogTip then
            XMVCA.XDlcRoom:Quit(function()
                CsXUiManager.Instance:RunMain()
            end)
        else
            XMVCA.XDlcRoom:DialogTipQuit(function()
                CsXUiManager.Instance:RunMain()
            end)
        end
    elseif XMVCA.XDlcRoom:IsMatching() then
        if notDialogTip then
            XMVCA.XDlcRoom:CancelMatch(function()
                CsXUiManager.Instance:RunMain()
            end)
        else
            XMVCA.XDlcRoom:DialogTipCancelMatch(function()
                CsXUiManager.Instance:RunMain()
            end)
        end
    else

        --local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
        --local unionInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
        --local inActivity = false
        --if unionInfo and unionInfo.Id and unionInfo.Id > 0 then
        --    inActivity = XFubenUnionKillConfigs.UnionKillInActivity(unionInfo.Id)
        --end

        --if inActivity and unionFightData and unionFightData.Id then
        --    if notDialogTip then
        --        XDataCenter.FubenUnionKillRoomManager.LeaveUnionTeamRoom(function()
        --            CsXUiManager.Instance:RunMain()
        --        end)
        --        return
        --    end
        --
        --    local title = CsXTextManagerGetText("TipTitle")
        --    local cancelMatchMsg = CsXTextManagerGetText("UnionKillExitRoom")
        --    XUiManager.DialogTip(
        --        title,
        --        cancelMatchMsg,
        --        XUiManager.DialogType.Normal,
        --        nil, function()
        --            XDataCenter.FubenUnionKillRoomManager.LeaveUnionTeamRoom(function()
        --                CsXUiManager.Instance:RunMain()
        --            end)
        --        end
        --    )
        --else
        if XLoginManager.IsFirstOpenMainUi() then
            CS.XCustomUi.Instance:GetData()
        end
        CsXUiManager.Instance:RunMain()
        --end
    end
end

function XLuaUiManager.ShowTopUi()
    CsXUiManager.Instance:ShowTopUi()
end

--获取ui状态
function XLuaUiManager.GetUiData(uiName)
    if UiData then
        return UiData[uiName]
    end
end

--缓存ui状态
function XLuaUiManager.SetUiData(uiName, data)
    UiData = UiData and UiData or {}
    UiData[uiName] = data
end

function XLuaUiManager.RemoveUiData(uiName)
    if UiData then
        UiData[uiName] = nil
    end
end

function XLuaUiManager.FindTopUi(uiname)
    return CsXUiManager.Instance:FindTopUi(uiname)
end

function XLuaUiManager.GetTopUiName()
    return CsXUiManager.Instance:GetTopUiName()
end

-- 等待uiname页面signalName信号
function XLuaUiManager.AwaitSignal(uiname, signalName, fromObj)
    local luaUi = XLuaUiManager.FindTopUi(uiname)
    if luaUi == nil then
        return XSignalCode.EMPTY_UI
    end
    luaUi = luaUi.UiProxy
    if luaUi == nil then
        return XSignalCode.EMPTY_UI
    end
    luaUi = luaUi.UiLuaTable
    if luaUi == nil then
        return XSignalCode.EMPTY_UI
    end
    return luaUi:AwaitSignal(signalName, fromObj)
end

function XLuaUiManager.GetTopLuaUi(uiname)
    local luaUi = XLuaUiManager.FindTopUi(uiname)
    if luaUi == nil then
        return nil
    end
    luaUi = luaUi.UiProxy
    if luaUi == nil then
        return nil
    end
    luaUi = luaUi.UiLuaTable
    if luaUi == nil then
        return nil
    end
    return luaUi
end

function XLuaUiManager.SafeClose(uiName)
    if XLuaUiManager.IsUiShow(uiName) then
        --if XLuaUiManager.GetTopUiName() ~= uiName then
        --    XLuaUiManager.Remove(uiName)
        --    return
        --end
        XLuaUiManager.Close(uiName)
        return
    end
    XLuaUiManager.Remove(uiName)
end

function XLuaUiManager.OpenSingleUi(uiName, ...)
    if XLuaUiManager.IsUiShow(uiName) then
        XLuaUiManager.Close(uiName)
    elseif XLuaUiManager.IsUiLoad(uiName) then
        XLuaUiManager.Remove(uiName)
    end

    XLuaUiManager.Open(uiName, ...)
end

function XLuaUiManager.RemoveTopOne(uiName)
    CsXUiManager.Instance:RemoveTopOne(uiName)
end

function XLuaUiManager.GetUid2NameMap()
    return Uid2UiNameMap
end

function XLuaUiManager.SetUi2NameMap(uid, name)
    Uid2UiNameMap[uid] = name
end

function XLuaUiManager.RecordTryDownload(uiName)
    if not XMVCA then
        return
    end

    if not XMVCA.XSubPackage then
        return
    end

    XMVCA.XSubPackage:RecordTryDownload(uiName)
end

function XLuaUiManager.SetUiActive(uiName, isActive)
    CsXUiManager.Instance:SetActive(uiName, isActive)
end

CS.XLaunchManager.InitLuaUIProxy(XLuaUiManager.New)
