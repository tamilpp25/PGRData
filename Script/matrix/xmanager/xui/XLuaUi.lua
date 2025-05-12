local UIBindControl = require("MVCA/UIBindControl")

---@class XLuaUi
---@field UiModel XUiModel
XLuaUi = XClass(nil, "XLuaUi")

---@param uiProxy XUiLuaProxy
function XLuaUi:Ctor(name, uiProxy)
    self._Uid = XLuaUiManager.GenUIUid()
    self.Name = name
    ---@type XUiLuaProxy
    self.UiProxy = uiProxy
    ---@type XUi
    self.Ui = uiProxy.Ui
    -- 页面自动关闭时间id
    self.AutoCloseTimerId = nil
    self.OpenAutoClose = false
    self.AutoCloseEndTime = 0
    self.AutoCloseCallback = nil
    self.AutoCloseIntervalTime = nil
    self.AutoCloseDelayTime = nil
    self._Control = nil
    ---@type XUiNode[]
    self._ChildNodes = {} --子节点
    self:BindControl()
    self._LuaEvents = self:OnGetLuaEvents()
    if XLuaUiManager.IsWindowsEditor() then
        XLuaUiManager.SetUi2NameMap(self._Uid, self.name)
    end
    ---@type number[] -- 当前正在播放的Tween动画Id字典
    self._TimerIds = {}
end

--region 生命周期
function XLuaUi:OnAwakeUi()
    self:OnAwake()
end

function XLuaUi:OnAwake()
end

function XLuaUi:OnStartUi(...)
    self:OnStart(...)
end
function XLuaUi:OnStart()
end

function XLuaUi:OnEnableUi(...)
    self:EnableChildNodes()

    self:OnEnable(...)
    if self._LuaEvents then
        for i = 1, #self._LuaEvents do
            XUIEventBind.AddEventListener(self._LuaEvents[i], self.OnNotify, self)
        end
    end
    if self.OpenAutoClose then
        self:_StartAutoCloseTimer()
    end
end

function XLuaUi:OnEnable()

end

function XLuaUi:OnDisableUi()
    self:DisableChildNodes()

    if self._LuaEvents then
        for i = 1, #self._LuaEvents do
            XUIEventBind.RemoveEventListener(self._LuaEvents[i], self.OnNotify, self)
        end
    end
    if self.OpenAutoClose then
        self:_StopAutoCloseTimer()
    end
    self:OnDisable()
end

function XLuaUi:OnDisable()

end

function XLuaUi:OnDestroyUi()
    self:StopAllTweener()
    self:ReleaseRedPoint()
    self:DestroyChildNodes()
    self:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_UI_DESTROY)
end

function XLuaUi:OnDestroy()

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

function XLuaUi:OnReleaseNotLoadUi()
    self._Uid = nil
    self.Name = nil
    self.UiProxy = nil
    self.Ui = nil
    self.AutoCloseTimerId = nil
    self.OpenAutoClose = false
    self.AutoCloseEndTime = 0
    self.AutoCloseCallback = nil
    self.AutoCloseIntervalTime = nil
    self.AutoCloseDelayTime = nil
    self._Control = nil
    self:ReleaseChildNodes()
    self:UnBindControl()
    self._LuaEvents = nil
    self:StopAllTweener()
end

function XLuaUi:OnReleaseUi()
    self:OnRelease()

    --self.Name = nil
    self.UiProxy = nil
    self.Ui = nil
    self.ParentUi = nil

    self.Transform = nil
    self.GameObject = nil
    self.UiAnimation = nil

    self.UiSceneInfo = nil
    self.UiModelGo = nil
    self.UiModel = nil

    -- 释放自动关闭数据
    -- 做个防御，避免外部使用错误导致没有释放
    self:_StopAutoCloseTimer()
    self.AutoCloseTimerId = nil
    self.OpenAutoClose = nil
    self.AutoCloseEndTime = 0
    self.AutoCloseCallback = nil
    self.AutoCloseIntervalTime = nil
    self.AutoCloseDelayTime = nil
    self._LuaEvents = nil

    -- 释放信号数据
    if self.SignalData then
        self.SignalData:Release()
        self.SignalData = nil
    end

    if self.ChildSignalDatas then
        for _, signalData in ipairs(self.ChildSignalDatas) do
            signalData:Release()
        end
        self.ChildSignalDatas = nil
    end

    if self._GridsDic then
        self._GridsDic = nil
    end

    --释放ViewModel层已绑定对象
    if self._ViewModelDic then
        for viewModel in pairs(self._ViewModelDic) do
            viewModel:UnBindUiObjs(self.Name)
        end
        self._ViewModelDic = nil
    end

    self:UnBindControl()
    self:ReleaseChildNodes()

    XTool.ReleaseUiObjectIndex(self)
    if XLuaUiManager.IsWindowsEditor() then
        WeakRefCollector.AddRef(WeakRefCollector.Type.UI, self)
        XLuaUiManager.SetUi2NameMap(self._Uid, nil)
    end
end

--用于释放lua的内存
function XLuaUi:OnRelease()

end
--endregion

--region 公共通用方法
-- PS:如果页面重写了OnEnable和OnDisable，使用时必须在OnEnable和OnDisable调用下父类方法
-- XXX.Super.OnEnable(self)
-- interval : 间隔多少毫秒执行，默认是一秒
-- delay : 初次延迟多少毫秒执行，默认是一秒
function XLuaUi:SetAutoCloseInfo(endTime, callback, interval, delay)
    interval = interval or XScheduleManager.SECOND
    delay = delay or XScheduleManager.SECOND
    self.OpenAutoClose = endTime ~= nil
    self.AutoCloseEndTime = endTime or 0
    self.AutoCloseCallback = callback
    self.AutoCloseIntervalTime = interval
    self.AutoCloseDelayTime = delay
end

function XLuaUi:SetGameObject()
    self.Transform = self.Ui.Transform
    self.GameObject = self.Ui.GameObject
    self.UiAnimation = self.Ui.UiAnimation
    ---@type XUiSceneInfo
    self.UiSceneInfo = self.Ui.UiSceneInfo
    self.UiModelGo = self.Ui.UiModelGo
    self.UiModel = self.Ui.UiModel
    self:InitUiObjects()
    XTool.InitUiObjectNewIndex(self)
end

function XLuaUi:InitUiObjects()
    self.Obj = self.Transform:GetComponent("UiObject")
    if self.Obj ~= nil then
        for i = 0, self.Obj.NameList.Count - 1 do
            self[self.Obj.NameList[i]] = self.Obj.ObjList[i]
        end
    end
end

--获取Open传递的参数
function XLuaUi:GetArgs()
    return self.UiProxy:GetArgs()
end
--endregion

--region 私有方法
function XLuaUi:_StartAutoCloseTimer()
    self.AutoCloseTimerId = XScheduleManager.ScheduleForever(
            function()
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
            end,
            self.AutoCloseIntervalTime,
            self.AutoCloseDelayTime + -1 * self.AutoCloseIntervalTime
    )
end

function XLuaUi:_StopAutoCloseTimer()
    if self.AutoCloseTimerId then
        XScheduleManager.UnSchedule(self.AutoCloseTimerId)
        self.AutoCloseTimerId = nil
    end
end
--endregion

--region 子UI相关
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
--endregion

--region 子节点管理
---@param node XUiNode
function XLuaUi:AddChildNode(node)
    table.insert(self._ChildNodes, node)
end

---@param node XUiNode
function XLuaUi:RemoveChildNode(node)
    local index = table.indexof(self._ChildNodes, node)
    if index then
        table.remove(self._ChildNodes, index)
    end
end

function XLuaUi:ReleaseChildNodes()
    for _, child in ipairs(self._ChildNodes) do
        child:Release()
    end
    self._ChildNodes = nil
end

function XLuaUi:EnableChildNodes()
    for _, child in ipairs(self._ChildNodes) do
        if child:IsNodeShow() then
            child:OnEnableUi()
        end
    end
end

function XLuaUi:DisableChildNodes()
    for _, child in ipairs(self._ChildNodes) do
        if child:IsNodeShow() then
            child:OnDisableUi()
        end
    end
end

function XLuaUi:DestroyChildNodes()
    for _, child in ipairs(self._ChildNodes) do
        child:OnDestroyUi()
    end
end
--endregion

--region 控制器绑定
function XLuaUi:BindControl()
    if UIBindControl[self.__cname] then
        local controlId = UIBindControl[self.__cname]
        self._Control = XMVCA:_GetOrRegisterControl(controlId)
        self._Control:AddViewRef(self._Uid)
    end
end

function XLuaUi:UnBindControl()
    if self._Control then
        if not self._Control:GetIsRelease() then
            self._Control:SubViewRef(self._Uid)
            XMVCA:CheckReleaseControl(self._Control:GetId())
        end
        self._Control = nil
    end
end
--endregion

--region ViewModel
--[[    绑定ViewModel层属性到Ui对象（单向绑定）
    @param viewModel:XDataEntityBase
    @param propertyName:viewModel字段名称
    @param func:更新函数闭包
]]
function XLuaUi:BindViewModelPropertyToObj(viewModel, func, propertyName)
    self._ViewModelDic = self._ViewModelDic or {}
    self._ViewModelDic[viewModel] = self._ViewModelDic[viewModel] or viewModel
    viewModel:BindPropertyToObj(self.Name, func, propertyName)
end

--[[    绑定ViewModel层属性到Ui对象（单向多重绑定）
    @param viewModel:XDataEntityBase
    @param func:更新函数闭包
    @param ...:多个viewModel字段名称
]]
function XLuaUi:BindViewModelPropertiesToObj(viewModel, func, ...)
    self._ViewModelDic = self._ViewModelDic or {}
    self._ViewModelDic[viewModel] = self._ViewModelDic[viewModel] or viewModel
    viewModel:BindPropertiesToObj(self.Name, func, ...)
end
--endregion

--region 事件相关
--CS.XEventId.EVENT_UI_ALLOWOPERATE 允许UI操作事件（可以理解为动画播放完成后的回调）
function XLuaUi:OnNotify(evt, ...)
end

function XLuaUi:OnGetEvents()
end

function XLuaUi:OnGetLuaEvents()
end
--endregion

--region 红点相关
--添加红点绑定接口，优化红点释放问题
---@param node UnityEngine.Component
function XLuaUi:AddRedPointEvent(node, func, listener, conditionGroup, args, isCheck)
    if not self.RedEventDic then
        self.RedEventDic = {}
    end
    if self.RedEventDic[node] then
        local redPointId = self.RedEventDic[node]
        local exist = XRedPointManager.CheckEventExist(redPointId)
        --存在则再检查一次
        if exist then
            XRedPointManager.Check(redPointId, args)
            return
        else
            self.RedEventDic[node] = nil
            XLog.Error("红点释放时机不对，请检查添加与释放函数，当前界面：" ..
                    tostring(self.GameObject.name) .. ", 节点：" .. tostring(node.gameObject.name))
        end
    end
    local id = XRedPointManager.AddRedPointEvent(node, func, listener, conditionGroup, args, isCheck)
    self.RedEventDic[node] = id
    return id
end

function XLuaUi:ReleaseRedPoint()
    if XTool.IsTableEmpty(self.RedEventDic) then
        return
    end
    for _, redPointId in pairs(self.RedEventDic) do
        XRedPointManager.RemoveRedPointEvent(redPointId)
    end
    self.RedEventDic = {}
end

function XLuaUi:RemoveRedPointEvent(redPointId)
    if XTool.IsTableEmpty(self.RedEventDic) then
        return
    end
    local tmpNode
    for node, pointId in pairs(self.RedEventDic) do
        if pointId == redPointId then
            tmpNode = node
            break
        end
    end

    if tmpNode then
        self.RedEventDic[tmpNode] = nil
        XRedPointManager.RemoveRedPointEvent(redPointId)
    end
end
--endregion

--region 快捷方法
--region UI操作/查找节点
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
--endregion

--region 点击事件
--注册点击事件
function XLuaUi:RegisterClickEvent(button, handle, clear, isOpenCd, cdTime)
    clear = clear and true or false
    if isOpenCd == nil then
        isOpenCd = true
    end
    cdTime = cdTime or 0.2
    self.UiProxy:RegisterClickEvent(
            button,
            function(eventData)
                if handle then
                    handle(self, eventData)
                end
            end,
            clear, isOpenCd, cdTime)
end
--endregion

--region 动画相关
--region TimeLine
--播放动画（只支持Timeline模式）
-- 符合以下命名的动画将会自动播放，无须手动调用（AnimStart、AnimEnable、AnimDisable、AnimDestroy）
function XLuaUi:PlayAnimation(animName, callback, beginCallback, wrapMode)
    self.UiProxy:PlayAnimation(
            animName,
            callback,
            beginCallback,
            wrapMode or CS.UnityEngine.Playables.DirectorWrapMode.Hold
    )
end

--播放动画（只支持Timeline模式, 增加Mask阻止操作打断动画）
function XLuaUi:PlayAnimationWithMask(animName, callback, beginCallback, wrapMode)
    self.UiProxy:PlayAnimation(
            animName,
            function(state)
                XLuaUiManager.SetMask(false)
                if callback then
                    callback(state)
                end
            end,
            function()
                XLuaUiManager.SetMask(true)
                if beginCallback then
                    beginCallback()
                end
            end,
            wrapMode or CS.UnityEngine.Playables.DirectorWrapMode.Hold
    )
end

---因为PlayAnimation不能手动停止，遇到需求需要所以添加此接口 v2.7 by ljb
function XLuaUi:StopAnimation(animName, isTriggerCallBack, isEvaluate)
    if isEvaluate == nil then
        isEvaluate = true
    end
    self.UiProxy:StopAnimation(animName, isTriggerCallBack, isEvaluate)
end

---带mask的anim手动停止需特殊处理 v2.7 by ljb
function XLuaUi:PlayMaskAnimation(animName, callback, beginCallback, wrapMode)
    self.UiProxy:PlayAnimation(
            animName,
            function(state)
                XLuaUiManager.SetMask(false, animName)
                if callback then
                    callback(state)
                end
            end,
            function()
                XLuaUiManager.SetMask(true, animName)
                if beginCallback then
                    beginCallback()
                end
            end,
            wrapMode or CS.UnityEngine.Playables.DirectorWrapMode.Hold
    )
end

---带mask的anim手动停止需特殊处理 v2.7 by ljb
function XLuaUi:StopMaskAnimation(animName, isTriggerCallBack, isEvaluate)
    if not XLuaUiManager.IsMaskShow(animName) then
        XLog.Error("[StopMaskAnimation Error:此接口仅对使用PlayMaskAnimation播放的Animation有效]")
    end
    if isEvaluate == nil then
        isEvaluate = true
    end
    self.UiProxy:StopAnimation(animName, isTriggerCallBack, isEvaluate)
    XLuaUiManager.SetMask(false, animName)
end

-- 查找PlayableDirector
---@param animName string 动画名
---@return UnityEngine.Playables.PlayableDirector
function XLuaUi:FindPlayable(animName)
    return self.Ui:FindPlayable(animName)
end
--endregion

--region Tween
function XLuaUi:_AddTimerId(timerId)
    if self._TimerIds[timerId] then
        XLog.Error("AddTimerId Error: TimerId Already Exist")
        return
    end
    self._TimerIds[timerId] = timerId
end

function XLuaUi:_RemoveTimerIdAndDoCallback(timerId, callback)
    if self._TimerIds[timerId] then
        self._TimerIds[timerId] = nil
    end
    
    if callback then
        callback(timerId)
        callback = nil
    end
end

function XLuaUi:StopTweener(timerId)
    if self._TimerIds[timerId] then
        XScheduleManager.UnSchedule(timerId)
        self._TimerIds[timerId] = nil
    end
end

function XLuaUi:StopAllTweener()
    for timerId, _ in pairs(self._TimerIds) do
        XScheduleManager.UnSchedule(timerId)
        self._TimerIds[timerId] = nil
    end
end

function XLuaUi:Tween(duration, onRefresh, onFinish, easeMethod)
    local tweenTimerId = XUiHelper.Tween(duration, onRefresh, function(timerId)
        self:_RemoveTimerIdAndDoCallback(timerId, onFinish)
    end, easeMethod)
    
    self:_AddTimerId(tweenTimerId)
    return tweenTimerId
end

function XLuaUi:DoUiMove(rectTf, tarPos, duration, easeType, cb)
    local tweenTimerId = XUiHelper.DoUiMove(rectTf, tarPos, duration, easeType, function(timerId)
        self:_RemoveTimerIdAndDoCallback(timerId, cb)
    end)
    
    self:_AddTimerId(tweenTimerId)
    return tweenTimerId
end

function XLuaUi:DoMove(rectTf, tarPos, duration, easeType, cb)
    local tweenTimerId = XUiHelper.DoMove(rectTf, tarPos, duration, easeType, function(timerId)
        self:_RemoveTimerIdAndDoCallback(timerId, cb)
    end)
    
    self:_AddTimerId(tweenTimerId)
    return tweenTimerId
end

function XLuaUi:DoWorldMove(rectTf, tarPos, duration, easeType, cb)
    local tweenTimerId = XUiHelper.DoWorldMove(rectTf, tarPos, duration, easeType, function(timerId)
        self:_RemoveTimerIdAndDoCallback(timerId, cb)
    end)
    
    self:_AddTimerId(tweenTimerId)
    return tweenTimerId
end

function XLuaUi:DoScale(rectTf, startScale, tarScale, duration, easeType, cb)
    local tweenTimerId = XUiHelper.DoScale(rectTf, startScale, tarScale, duration, easeType, function(timerId)
        self:_RemoveTimerIdAndDoCallback(timerId, cb)
    end)
    
    self:_AddTimerId(tweenTimerId)
    return tweenTimerId
end

function XLuaUi:DoAlpha(canvasGroup, startAlpha, tarAlpha, duration, easeType, cb)
    local tweenTimerId = XUiHelper.DoAlpha(canvasGroup, startAlpha, tarAlpha, duration, easeType, function(timerId)
        self:_RemoveTimerIdAndDoCallback(timerId, cb)
    end)
    
    self:_AddTimerId(tweenTimerId)
    return tweenTimerId
end
--endregion
--endregion

--region 相机/3D场景
-- 加载(切换)ui场景
function XLuaUi:LoadUiScene(sceneUrl, modelUrl, cb, force)
    if force == nil then
        force = true
    end
    self.Ui:LoadUiScene(sceneUrl, modelUrl, force)
    self.UiModelGo = self.Ui.UiModelGo
    self.UiModel = self.Ui.UiModel
    self.UiSceneInfo = self.Ui.UiSceneInfo
    if cb then
        cb(sceneUrl, modelUrl)
    end
end

-- 异步加载(切换)ui场景
function XLuaUi:LoadUiSceneAsync(sceneUrl, modelUrl, cb)
    self.Ui:LoadUiSceneAsync(sceneUrl, modelUrl, function()
        self.UiModelGo = self.Ui.UiModelGo
        self.UiModel = self.Ui.UiModel
        self.UiSceneInfo = self.Ui.UiSceneInfo
        if cb then
            cb(sceneUrl, modelUrl)
        end
    end)
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
--endregion

--region 通用按钮绑定
-- 绑定返回/主界面按钮
function XLuaUi:BindExitBtns(btnBack, btnMainUi)
    btnBack = btnBack or self.BtnBack
    btnMainUi = btnMainUi or self.BtnMainUi
    self:RegisterClickEvent(
            btnBack,
            function()
                self:Close()
            end, nil, true
    )
    self:RegisterClickEvent(
            btnMainUi,
            function()
                XLuaUiManager.RunMain()
            end, nil, true
    )
end
-- 绑定帮助按钮
function XLuaUi:BindHelpBtn(btn, helpDataKey, cb, openCb)
    btn = btn or self.BtnHelp
    helpDataKey = helpDataKey or self.Name

    if not btn then
        XLog.Error("XLuaUi.BindHelpBtn Error: Buttton Is Nil")
        return
    end

    if not helpDataKey then
        XLog.Error("XLuaUi.BindHelpBtn Error: HelpDataKey Is Nil")
        return
    end

    if CS.XTool.ConfirmObjectType(btn, "XUiButton") then
        btn.CallBack = function()
            if openCb then
                openCb()
            end
            XUiManager.ShowHelpTip(helpDataKey, cb)
        end
        return
    end

    if CS.XTool.ConfirmObjectType(btn, "Button") then
        self:RegisterClickEvent(
                btn,
                function()
                    if openCb then
                        openCb()
                    end
                    XUiManager.ShowHelpTip(helpDataKey, cb)
                end, nil, true
        )
        return
    end

    XLog.Error("XLuaUi.BindHelpBtn Faild")
end

function XLuaUi:BindHelpBtnByHelpId(btn, helpId, cb, openCb)
    local config = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)

    if not config then
        return
    end

    self:BindHelpBtn(btn, config.Function, cb, openCb)
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
        btn.CallBack = function()
            XUiManager.ShowHelpTipNew(getHelpDataFunc, cb)
        end
        return
    end

    if CS.XTool.ConfirmObjectType(btn, "Button") then
        self:RegisterClickEvent(
                btn,
                function()
                    XUiManager.ShowHelpTipNew(getHelpDataFunc, cb)
                end
        )
        return
    end

    XLog.Error("XLuaUi.BindHelpBtnNew Faild")
end

function XLuaUi:BindHelpBtnOnly(btn)
    -- TODO 对帮助按钮进行统一隐藏
end
--endregion

function XLuaUi:SetUiSprite(image, spriteName, callBack)
    self.UiProxy:SetUiSprite(image, spriteName, callBack)
end

--region 动态格子模板
--根据指定模板创建一批格子并刷新对应格子视图数据
function XLuaUi:RefreshTemplateGrids(templateGo, dataList, parents, ctor, name, refreshFunc)
    self._GridsDic = self._GridsDic or {}

    name = name or "_DefualtGrids"
    local grids = self._GridsDic[name] or {}

    local multiTemplateGo = false --有些情况下无需copy格子，直接传入UI做好的格子gameobject
    if type(templateGo) == "table" then
        multiTemplateGo = true
        for _, go in pairs(templateGo) do
            go.gameObject:SetActiveEx(false)
        end
    else
        templateGo.gameObject:SetActiveEx(false)
    end

    --有些情况下可能需要挂载不同的父节点
    local multiParents = type(parents) == "table"

    for index, data in ipairs(dataList) do
        local grid = grids[index]
        if not grid then
            local parent = multiParents and parents[index] or parents

            local go
            if multiTemplateGo then
                go = templateGo[index]
            else
                if parent then
                    go = CSObjectInstantiate(templateGo, parent)
                else
                    go = templateGo
                end
            end

            if ctor then
                if type(ctor) == "function" then
                    grid = ctor()
                else
                    grid = ctor.New()
                end
            else
                grid = {}
            end

            --统一构造函数,省略冗余代码
            grid.Index = index
            grid.GameObject = go.gameObject
            grid.Transform = go.transform
            grid.Parent = self
            XTool.InitUiObject(grid)

            if grid.Init then
                grid:Init()
            end

            grids[index] = grid
        end

        --先显示再刷新，避免动画被打断
        grid.GameObject:SetActiveEx(true)

        if refreshFunc then
            refreshFunc(grid, data)
        elseif grid.Refresh then
            grid:Refresh(data)
        end

    end

    for index = #dataList + 1, #grids do
        grids[index].GameObject:SetActiveEx(false)
    end

    self._GridsDic[name] = grids
end

--根据数据列表获取已经创建过的格子
function XLuaUi:GetGrid(index, name)
    if XTool.IsTableEmpty(self._GridsDic) then
        return
    end
    name = name or "_DefualtGrids"
    return self._GridsDic[name] and self._GridsDic[name][index]
end
--endregion
--endregion

--region 信号事件相关
function XLuaUi:AwaitSignal(signalName, fromObj)
    if self.SignalData == nil then
        self.SignalData = XSignalData.New()
    end
    return self.SignalData:AwaitSignal(signalName, fromObj)
end

function XLuaUi:EmitSignal(signalName, ...)
    if self.SignalData == nil then
        return
    end
    self.SignalData:EmitSignal(signalName, ...)
end

function XLuaUi:CheckHasSignal(signalName, fromObj)
    if self.SignalData == nil then
        return false
    end
    return self.SignalData:CheckHasSignal(signalName, fromObj)
end

-- 连接单个信号
function XLuaUi:ConnectSignal(path, event, callback, caller, returnArgKey)
    if self.ChildSignalDatas == nil then
        -- 对子信号的一个管理，方便页面释放
        self.ChildSignalDatas = {}
    end
    table.insert(self.ChildSignalDatas, XTool.ConnectSignal(self, path, event, callback, caller, returnArgKey))
end

-- 连接多个信号
function XLuaUi:ConnectSignals(path, event, callback, caller)
    if self.ChildSignalDatas == nil then
        -- 对子信号的一个管理，方便页面释放
        self.ChildSignalDatas = {}
    end
    appendArray(self.ChildSignalDatas, XTool.ConnectSignals(self, path, event, callback, caller))
end

function XLuaUi:GetSignalData()
    if self.SignalData == nil then
        self.SignalData = XSignalData.New()
    end
    return self.SignalData
end

-- value : XSignalData
function XLuaUi:AddChildSignalData(value)
    if self.ChildSignalDatas == nil then
        self.ChildSignalDatas = {}
    end
    table.insert(self.ChildSignalDatas, value)
end
--endregion
-------------------------------XLuaUiCheckGC-------------------------------
XLuaUiCheckGC = XClass(XLuaUi, "XLuaUiCheckGC")

function XLuaUiCheckGC:Ctor()
    XLog.Warning(string.format("====================%sUi已创建", self.Name))
    local metatable = getmetatable(self)
    -- metatable.__mode = "kv"
    metatable.__gc = function()
        XLog.Warning(string.format("====================%sUi已释放", self.Name))
    end
    setmetatable(self, metatable)
end