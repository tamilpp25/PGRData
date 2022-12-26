-------------------------------------------------------------------------------------------------------------
CsXUiType = CS.XUiType
-- CsXUiResType = CS.XUiResType
CsXUiManager = CS.XUiManager
-- CsIBaseEventListener = CS.IBaseEventListener
CsXGameEventManager = CS.XGameEventManager
-- CsXLuaEventProxy = CS.XLuaEventProxy
-- CsXUi = CS.XUi
-- CsXChildUi = CS.XChildUi
-- CsXGameUi = CS.XGameUi
-- CsXMaskManager = CS.XMaskManager
-- CsXUguiEventListener = CS.XUguiEventListener
-- CsXUiData = CS.XUiData
-- CsXUiStackContainer = CS.XUiStackContainer
-- CsXUiListContainer = CS.XUiListContainer
-- CsXUiChildContainer = CS.XUiChildContainer
CsXUiHelper = CS.XUiHelper
CsXTextManagerGetText = CS.XTextManager.GetText
CSXTextManagerGetText = CsXTextManagerGetText
------------------------------------------------LuaUI---------------------------------------------------------
XLuaUi = XClass(nil, "XLuaUi")

function XLuaUi:Ctor(name, uiProxy)
    self.Name = name
    self.UiProxy = uiProxy
    self.Ui = uiProxy.Ui
    -- 页面自动关闭时间id
    self.AutoCloseTimerId = nil
    self.OpenAutoClose = false
    self.AutoCloseEndTime = 0
    self.AutoCloseCallback = nil
    self.AutoCloseIntervalTime = nil
    self.AutoCloseDelayTime = nil
end

-- PS:如果页面重写了OnEnable和OnDisable，使用时必须在OnEnable和OnDisable调用下父类方法
-- XXX.Super.OnEnable(self)
-- interval : 间隔多少毫秒执行，默认是一秒
-- delay : 初次延迟多少毫秒执行，默认是一秒
function XLuaUi:SetAutoCloseInfo(endTime, callback, interval, delay)
    interval = interval or XScheduleManager.SECOND
    delay = delay or XScheduleManager.SECOND
    self.OpenAutoClose = true
    self.AutoCloseEndTime = endTime
    self.AutoCloseCallback = callback
    self.AutoCloseIntervalTime = interval
    self.AutoCloseDelayTime = delay
end

function XLuaUi:SetGameObject()
    self.Transform = self.Ui.Transform
    self.GameObject = self.Ui.GameObject
    self.UiAnimation = self.Ui.UiAnimation
    self.UiSceneInfo = self.Ui.UiSceneInfo
    self.UiModelGo = self.Ui.UiModelGo
    self.UiModel = self.Ui.UiModel
    self:InitUiObjects()
end

function XLuaUi:OnAwake()
end

function XLuaUi:OnStart()
end

function XLuaUi:OnEnable()
    if self.OpenAutoClose then
        self:_StartAutoCloseTimer()
    end
end

function XLuaUi:OnDisable()
    if self.OpenAutoClose then
        self:_StopAutoCloseTimer()
    end
end

function XLuaUi:OnDestroy()
end

function XLuaUi:_StartAutoCloseTimer()
    self.AutoCloseTimerId = XScheduleManager.ScheduleForever(function()
        local time = XTime.GetServerNowTimestamp()
        if time > self.AutoCloseEndTime then
            if self.AutoCloseCallback then
                self.AutoCloseCallback(true)
            end
            self:_StopAutoCloseTimer()
        else
            if self.AutoCloseCallback then
                self.AutoCloseCallback(false)
            end
        end
        -- PS:-1 * self.AutoCloseIntervalTime 这么处理是因为XScheduleManager.ScheduleForever里计算时间自动叠加多一次Interval
    end, self.AutoCloseIntervalTime, self.AutoCloseDelayTime + -1 * self.AutoCloseIntervalTime)
end

function XLuaUi:_StopAutoCloseTimer()
    if self.AutoCloseTimerId then
        XScheduleManager.UnSchedule(self.AutoCloseTimerId)
        self.AutoCloseTimerId = nil
    end
end

function XLuaUi:OnReleaseInstOnly()
    XLuaUiManager.SetUiData(self.Name, self:OnReleaseInst())
end

function XLuaUi:OnReleaseInst()

end

function XLuaUi:OnResumeUi()
    self:OnResume(XLuaUiManager.GetUiData(self.Name))
    XLuaUiManager.RemoveUiData(self.Name)
end

function XLuaUi:OnResume()
end

--用于释放lua的内存
function XLuaUi:OnRelease()

    --self.Name = nil
    self.UiProxy = nil
    self.Ui = nil

    self.Transform = nil
    self.GameObject = nil
    self.UiAnimation = nil

    self.UiSceneInfo = nil
    self.UiModelGo = nil
    self.UiModel = nil

    if self.Obj and self.Obj:Exist() then
        local nameList = self.Obj.NameList
        for _, v in pairs(nameList) do
            self[v] = nil
        end
        self.Obj = nil
    end

    for k, v in pairs(self) do
        local t = type(v)
        if t == 'userdata' and CsXUiHelper.IsUnityObject(v) then
            self[k] = nil
        end
    end

end

--CS.XEventId.EVENT_UI_ALLOWOPERATE 允许UI操作事件（可以理解为动画播放完成后的回调）
function XLuaUi:OnNotify(evt, ...)
end

function XLuaUi:OnGetEvents()
end

function XLuaUi:SetUiSprite(image, spriteName, callBack)
    self.UiProxy:SetUiSprite(image, spriteName, callBack)
end

--快捷隐藏界面（不建议使用）
function XLuaUi:SetActive(active)
    local temp = active and true or false
    self.UiProxy:SetActive(temp)
end

--快捷关闭界面
function XLuaUi:Close()

    if self.UiProxy == nil then
        XLog.Error(self.Name .. "重复Close")
    else
        self.UiProxy:Close()
    end

end

--快捷移除UI,移除的UI不会播放进场、退场动画
--不允许用于移除栈顶的UI 使用时注意！！！
function XLuaUi:Remove()
    if self.UiProxy then
        self.UiProxy:Remove()
    end
end

--注册点击事件
function XLuaUi:RegisterClickEvent(button, handle, clear)

    clear = clear and true or false
    self.UiProxy:RegisterClickEvent(button, function(eventData)
        if handle then
            handle(self, eventData)
        end
    end, clear)

end

--返回指定名字的子节点的Component
--@name 子节点名称
--@type Component类型
function XLuaUi:FindComponent(name, type)
    return self.UiProxy:FindComponent(name, type)
end


--通过名字查找GameObject 例如:A/B/C
--@name 要查找的名字
function XLuaUi:FindGameObject(name)
    return self.UiProxy:FindGameObject(name)
end

--通过名字查找Transfrom 例如:A/B/C
--@name 要查找的名字
function XLuaUi:FindTransform(name)
    return self.UiProxy:FindTransform(name)
end

--打开一个子UI
--@childUIName 子UI名字
--@... 传到OnStart的参数
function XLuaUi:OpenChildUi(childUIName, ...)
    self.UiProxy:OpenChildUi(childUIName, ...)
end

--打开一个子UI,会关闭其他已显示的子UI
--@childUIName 子UI名字
--@... 传到OnStart的参数
function XLuaUi:OpenOneChildUi(childUIName, ...)
    self.UiProxy:OpenOneChildUi(childUIName, ...)
    --self.UiProxy:OpenOneChildUi(childUIName, ...)
end

--关闭子UI
--@childUIName 子UI名字
function XLuaUi:CloseChildUi(childUIName)
    self.UiProxy:CloseChildUi(childUIName)
end

--查找子窗口对应的lua对象
--@childUiName 子窗口名字
function XLuaUi:FindChildUiObj(childUiName)
    local childUi = self.UiProxy:FindChildUi(childUiName)
    if childUi then
        return childUi.UiProxy.UiLuaTable
    end
end

function XLuaUi:InitUiObjects()
    self.Obj = self.Transform:GetComponent("UiObject")
    if self.Obj ~= nil then
        for i = 0, self.Obj.NameList.Count - 1 do
            self[self.Obj.NameList[i]] = self.Obj.ObjList[i]
        end
    end
end

function XLuaUi:InitChildUis()
    if self.Ui == nil then
        return
    end

    if not self.Ui.UiData.HasChildUi then
        return
    end

    local childUis = self.Ui:GetAllChildUis()

    if childUis == nil then
        return
    end

    --子UI初始化完成后可在父UI通过self.Child+子UI名称的方式直接获取句柄
    local childUiName
    for k, v in pairs(childUis) do
        childUiName = "Child" .. k
        if self[childUiName] then
            XLog.Error(string.format("%s该名字已被占用", childUiName))
        else
            self[childUiName] = v.UiProxy.UiLuaTable
        end
    end
end

--播放动画（只支持Timeline模式）
-- 符合以下命名的动画将会自动播放，无须手动调用（AnimStart、AnimEnable、AnimDisable、AnimDestroy）
function XLuaUi:PlayAnimation(animName, callback, beginCallback, wrapMode)
    self.UiProxy:PlayAnimation(animName, callback, beginCallback, wrapMode or CS.UnityEngine.Playables.DirectorWrapMode.Hold)
end

--播放动画（只支持Timeline模式, 增加Mask阻止操作打断动画）
function XLuaUi:PlayAnimationWithMask(animName, callback, beginCallback, wrapMode)
    self.UiProxy:PlayAnimation(animName, function(state)
        XLuaUiManager.SetMask(false)
        if callback then callback(state) end
    end, function()
        XLuaUiManager.SetMask(true)
        if beginCallback then beginCallback() end
    end, wrapMode or CS.UnityEngine.Playables.DirectorWrapMode.Hold)
end

--获取Open传递的参数
function XLuaUi:GetArgs()
    return self.UiProxy:GetArgs()
end

-- 加载(切换)ui场景
function XLuaUi:LoadUiScene(sceneUrl, modelUrl, cb, force)
    if force == nil then
        force = true
    end
    self.Ui:LoadUiScene(sceneUrl, modelUrl, force)

    if cb then
        cb(sceneUrl, modelUrl)
    end
end

-- 根据名字查找虚拟相机位置
function XLuaUi:FindVirtualCamera(virtualCamName)
    local virtualCamTrans = nil
    local sceneVirtualCamRoot = self.UiSceneInfo.Transform:FindTransform("UiCamContainer")
    if sceneVirtualCamRoot then
        virtualCamTrans = sceneVirtualCamRoot:FindTransform(virtualCamName)
        if virtualCamTrans then
            return virtualCamTrans
        end
    end

    virtualCamTrans = self.UiModelGo:FindTransform(virtualCamName)
    return virtualCamTrans
end

-- 默认ui场景路径
function XLuaUi:GetDefaultSceneUrl()
    return self.Ui.UiData.SceneUrl
end

--  默认ui场景模型路径
function XLuaUi:GetDefaultUiModelUrl()
    return self.Ui.UiData.UiModelUrl
end

-- 绑定帮助按钮
function XLuaUi:BindHelpBtn(btn, helpDataKey, cb)
    if not btn then
        XLog.Error("XLuaUi.BindHelpBtn Error: Buttton Is Nil")
        return
    end

    if not helpDataKey then
        XLog.Error("XLuaUi.BindHelpBtn Error: HelpDataKey Is Nil")
        return
    end

    if CS.XTool.ConfirmObjectType(btn, "XUiButton") then
        btn.CallBack = function() XUiManager.ShowHelpTip(helpDataKey, cb) end
        return
    end

    if CS.XTool.ConfirmObjectType(btn, "Button") then
        self:RegisterClickEvent(btn, function() XUiManager.ShowHelpTip(helpDataKey, cb) end)
        return
    end

    XLog.Error("XLuaUi.BindHelpBtn Faild")
end

function XLuaUi:BindHelpBtnNew(btn, getHelpDataFunc, cb)
    if not btn then
        XLog.Error("XLuaUi.BindHelpBtn Error: Buttton Is Nil")
        return
    end

    if not getHelpDataFunc then
        XLog.Error("XLuaUi.BindHelpBtn Error: GetHelpDataFunc Is Nil")
        return
    end

    if CS.XTool.ConfirmObjectType(btn, "XUiButton") then
        btn.CallBack = function() XUiManager.ShowHelpTipNew(getHelpDataFunc, cb) end
        return
    end

    if CS.XTool.ConfirmObjectType(btn, "Button") then
        self:RegisterClickEvent(btn, function() XUiManager.ShowHelpTipNew(getHelpDataFunc, cb) end)
        return
    end

    XLog.Error("XLuaUi.BindHelpBtnNew Faild")
end

function XLuaUi:BindHelpBtnOnly(btn)
    -- TODO 对帮助按钮进行统一隐藏
end

-- function XLuaUi:GetUiModelRoot()
--     return self.UiModel.UiModelParent
-- end
------------------------------------------------------------------------------------------------------------------------
XLuaUiManager = XClass(nil, "XLuaUiManager")
local UiData = {}
local ClassType = {}

--注册UI
-- @super 父类
-- @uiName UI名字
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
        baseName = string.match(baseName, '%w*[^(%d)$*]')       -- 解析包含数字后缀的界面
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
    CsXUiManager.Instance:Open(uiName, ...)
end

--打开UI，完成后执行回调
--@uiName 打开的UI名称
--@callback 打开完成回调
--@... 传递到OnStart的参数
function XLuaUiManager.OpenWithCallback(uiName, callback, ...)
    CsXUiManager.Instance:OpenWithCallback(uiName, callback, ...)
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
    CsXUiManager.Instance:PopThenOpen(uiName, ...)
end

--针对Normal类型的管理，关闭栈中所有界面，然后打开下一个界面（无缝切换）
--@uiName 需要打开的UI名字
--@... 传递到OnStart的参数
function XLuaUiManager.PopAllThenOpen(uiName, ...)
    CsXUiManager.Instance:PopAllThenOpen(uiName, ...)
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

--某个UI是否已经加载
function XLuaUiManager.IsUiLoad(uiName)
    return CsXUiManager.Instance:IsUiLoad(uiName)
end

--设置mask，visible=true时不能操作
function XLuaUiManager.SetMask(visible)
    visible = visible and true or false
    CsXUiManager.Instance:SetMask(visible)
end

--设置animationMask，tag标签,visible=true时不能操作，delay(默认2秒)后会展示菊花
function XLuaUiManager.SetAnimationMask(tag, visible, delay)
    visible = visible and true or false
    CsXUiManager.Instance:SetAnimationMask(tag, visible, delay)
end

function XLuaUiManager.ClearMask(resetMaskCount)
    resetMaskCount = resetMaskCount and true or false
    CsXUiManager.Instance:ClearMask(resetMaskCount)
end

function XLuaUiManager.ClearAnimationMask()
    CsXUiManager.Instance:ClearAnimationMask()
end

function XLuaUiManager.ClearAllMask(resetMaskCount)
    XLuaUiManager.ClearMask(resetMaskCount)
    CsXUiManager.Instance:ClearAnimationMask()
end

--返回主界面
function XLuaUiManager.RunMain(notDialogTip)
    if XDataCenter.RoomManager.RoomData then
        if notDialogTip then
            XDataCenter.RoomManager.Quit(function()
                CsXUiManager.Instance:RunMain()
            end)

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

        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RoomManager.Quit(function()
                CsXUiManager.Instance:RunMain()
            end)
        end)
    elseif XDataCenter.RoomManager.Matching then
        if notDialogTip then
            XDataCenter.RoomManager.CancelMatch(function()
                CsXUiManager.Instance:RunMain()
            end)

            return
        end

        local title = CsXTextManagerGetText("TipTitle")
        local cancelMatchMsg = CsXTextManagerGetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RoomManager.CancelMatch(function()
                CsXUiManager.Instance:RunMain()
            end)
        end)
    else
        local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
        local unionInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
        local inActivity = false
        if unionInfo and unionInfo.Id and unionInfo.Id > 0 then
            inActivity = XFubenUnionKillConfigs.UnionKillInActivity(unionInfo.Id)
        end

        if inActivity and unionFightData and unionFightData.Id then
            local title = CsXTextManagerGetText("TipTitle")
            local cancelMatchMsg = CsXTextManagerGetText("UnionKillExitRoom")
            XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
                XDataCenter.FubenUnionKillRoomManager.LeaveUnionTeamRoom(function()
                    CsXUiManager.Instance:RunMain()
                end)
            end)
        else
            if XLoginManager.IsFirstOpenMainUi() then
                CS.XCustomUi.Instance:GetData()
            end
            CsXUiManager.Instance:RunMain()
        end
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