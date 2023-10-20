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
CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
Vector2 = CS.UnityEngine.Vector2
Vector3 = CS.UnityEngine.Vector3

local IsWindowsEditor = XMain.IsWindowsEditor

local _UIUid = 0
local GenUIUid = function()
    _UIUid = _UIUid + 1
    return _UIUid
end

local UIBindControl = require("MVCA/UIBindControl")

---子节点状态标记
local XUiNodeState = {
    None = 0,
    Start = 1,
    Enable = 2,
    Disable = 3,
    Destroy = 4,
    Release = 5
}

---@class XUiNode
XUiNode = XClass(nil, "XUiNode")
--XUiNode._Profiler()
--XUiNode._ProfilerNode("XUiGridCharacterNew")

---@param ui UnityEngine.Component
---@param parent XLuaUi
function XUiNode:Ctor(ui, parent, ...)
    self:InitNode(ui, parent, ...)
end

function XUiNode:InitNode(ui, parent, ...)
    self._IsPopPanel = false
    self._Uid = GenUIUid()
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)

    ---@type XUiNode[]
    self._ChildNodes = {} --子节点
    self._Control = nil
    self._AbleCount = 0
    self._BindControlId = nil
    self:BindParent() --跟父节点绑定关系
    self:InitBindControlId() --实例化要绑定的control名字,优先父节点
    self:BindControl() --绑定control
    self._StateFlag = XUiNodeState.None
    self._arg = table.pack(...)
    self._IsNodeShow = false

    self._LuaEvents = self:OnGetLuaEvents()

    XTool.InitUiObjectNewIndex(self)

    if self.GameObject.activeSelf then
        self:Open()
    end
end

---返回该子节点是否有效
function XUiNode:IsValid()
    if self._StateFlag >= XUiNodeState.Destroy then
        return false
    elseif XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return true
end

function XUiNode:IsValidState()
    return self._StateFlag > XUiNodeState.None and self._StateFlag < XUiNodeState.Destroy
end

function XUiNode:CallStart()
    if self._StateFlag < XUiNodeState.Start then
        self._StateFlag = XUiNodeState.Start
        self:OnStart(table.unpack(self._arg)) --执行子类的onStart
        self._arg = nil
    end
end

---这个函数用来检测activeInHierarchy
function XUiNode:_CheckUIActive()
    if IsWindowsEditor then
        if self._StateFlag == XUiNodeState.Enable then
            if not self.GameObject.activeInHierarchy then
                XLog.Error(string.format("子节点 %s 显示后, activeInHierarchy依旧为false, go name : %s", self.__cname, self.GameObject.name))
            end
        elseif self._StateFlag == XUiNodeState.Disable then --暂时用不了, 因为是先OnDisable再SetActive
            if self.GameObject.activeInHierarchy then
                XLog.Error(string.format("子节点 %s 隐藏后, activeInHierarchy依旧为true, go name : %s", self.__cname, self.GameObject.name))
            end
        end
    end
end


---设置是否为弹出的界面, 用于那种使用内部节点做资源, 但是有独立的弹出窗体的界面
function XUiNode:SetIsPopPanel(value)
    self._IsPopPanel = value
end

function XUiNode:GetIsPopPanel()
    return self._IsPopPanel
end

function XUiNode:OnGetLuaEvents()

end

function XUiNode:OnNotify(evt, ...)

end

function XUiNode:OnStart()

end

function XUiNode:OnEnableUi()
    if self._StateFlag == XUiNodeState.Start or self._StateFlag == XUiNodeState.Disable then
        self._StateFlag = XUiNodeState.Enable
        self:_CheckUIActive()

        self:EnableChildNodes()

        self:OnEnable()
        if self._LuaEvents then
            for i = 1, #self._LuaEvents do
                XUIEventBind.AddEventListener(self._LuaEvents[i], self.OnNotify, self)
            end
        end
    end
end

function XUiNode:OnEnable()
end

function XUiNode:OnDisableUi()
    if self._StateFlag == XUiNodeState.Start or self._StateFlag == XUiNodeState.Enable then
        self._StateFlag = XUiNodeState.Disable
        --self:_CheckUIActive()

        self:DisableChildNodes()

        if self._LuaEvents then
            for i = 1, #self._LuaEvents do
                XUIEventBind.RemoveEventListener(self._LuaEvents[i], self.OnNotify, self)
            end
        end
        self:OnDisable()
    end
end

function XUiNode:OnDisable()
end

function XUiNode:OnDestroyUi()
    if self._StateFlag >= XUiNodeState.Start and self._StateFlag < XUiNodeState.Destroy then
        self._StateFlag = XUiNodeState.Destroy

        self._IsNodeShow = false
        self:DestroyChildNodes()
        self:OnDestroy()
    end
end

function XUiNode:OnDestroy()

end


function XUiNode:EnableChildNodes()
    for _, child in ipairs(self._ChildNodes) do
        if child:IsNodeShow() then
            child:OnEnableUi()
        end
    end
end

function XUiNode:DisableChildNodes()
    for _, child in ipairs(self._ChildNodes) do
        if child:IsNodeShow() then
            child:OnDisableUi()
        end
    end
end

function XUiNode:DestroyChildNodes()
    for _, child in ipairs(self._ChildNodes) do
        child:OnDestroyUi()
    end
end

function XUiNode:IsNodeShow()
    return self._IsNodeShow
end

---显示节点
function XUiNode:Open()
    if not self._IsNodeShow then
        self._IsNodeShow = true
        self:SetDisplay(true)
        if self._StateFlag == XUiNodeState.None then
            self:CallStart()
        end
        self:OnEnableUi()
    end
end

---隐藏节点
function XUiNode:Close()
    if self._IsNodeShow then
        self._IsNodeShow = false
        self:SetDisplay(false)
        self:OnDisableUi()
    end
end

---设置显示
---@param val boolean 是否显示
function XUiNode:SetDisplay(val)
    --if IsWindowsEditor then
    --    self.TempGameObject:SetActiveEx(val)
    --else
    self.GameObject:SetActiveEx(val)
    --end
    self:OnSetDisplay(val)
end

---设置显示状态后提供给子类重写
function XUiNode:OnSetDisplay(val)

end

function XUiNode:BindParent()
    if self.Parent then
        if self.Parent.AddChildNode then
            self.Parent:AddChildNode(self)
        else
            local parentClsName = self.Parent.__cname and self.Parent.__cname or ""
            if IsWindowsEditor then
                XLog.Error("Parent 不为XLuaUi 或 XUiNode: ".. parentClsName)
            end
        end
    else
        if IsWindowsEditor then
            XLog.Error("XUiNode has not Parent: "..self.__cname)
        end
    end
end

--暂时没有中途移除的需求
function XUiNode:UnBindParent()
    if self.Parent then
        if self.Parent.RemoveChildNode then
            self.Parent:RemoveChildNode(self)
        else
            local parentClsName = self.Parent.__cname and self.Parent.__cname or ""
            if IsWindowsEditor then
                XLog.Error("Parent 不为XLuaUi 或 XUiNode: ".. parentClsName)
            end
        end
    else
        if IsWindowsEditor then
            XLog.Error("XUiNode has not Parent: "..self.__cname)
        end
    end
end

---@param node XUiNode
function XUiNode:AddChildNode(node)
    table.insert(self._ChildNodes, node)
end

---@param node XUiNode
function XUiNode:RemoveChildNode(node)
    local index = table.indexof(self._ChildNodes, node)
    if index then
        table.remove(self._ChildNodes, index)
    end
end

---获取绑定的control名字,优先获取父节点
function XUiNode:InitBindControlId()
    local tempBindName = UIBindControl[self.__cname] --有配置的优先读取配置
    if not tempBindName then
        if self.Parent then
            if self.Parent._BindControlId then --这个有值证明可以绑定
                tempBindName = self.Parent._BindControlId
            elseif self.Parent.__cname and UIBindControl[self.Parent.__cname] then
                tempBindName = UIBindControl[self.Parent.__cname]
            end
        end
    end
    self._BindControlId = tempBindName
end


function XUiNode:BindControl()
    if self._BindControlId then --子界面用_BindControlId
        self._Control = XMVCA:_GetOrRegisterControl(self._BindControlId)
        self._Control:AddViewRef(self._Uid)
    end
end

function XUiNode:UnBindControl()
    self._BindControlId = nil
    if self._Control then
        if not self._Control:GetIsRelease() then
            self._Control:SubViewRef(self._Uid)
            XMVCA:CheckReleaseControl(self._Control:GetId())
        end
        self._Control = nil
    end
end

function XUiNode:Release()
    self._IsNodeShow = false
    self._StateFlag = XUiNodeState.Release

    self:ReleaseChildNodes() --执行子节点的

    self:OnRelease()

    self:UnBindControl() --移除控制器
    self:ReleaseRedPoint()
    XTool.ReleaseUiObjectIndex(self)

    self.GameObject = nil
    self.Transform = nil
    self.Parent = nil
    self._LuaEvents = nil
    self._arg = nil
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.UI, self)
    end
end

function XUiNode:ReleaseChildNodes()
    for _, child in ipairs(self._ChildNodes) do
        child:Release()
    end
    self._ChildNodes = nil
end

--这是给子类重写的
function XUiNode:OnRelease()

end

--添加红点绑定接口，优化红点释放问题
function XUiNode:AddRedPointEvent(node, func, listener, conditionGroup, args, isCheck)
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

function XUiNode:ReleaseRedPoint()
    if XTool.IsTableEmpty(self.RedEventDic) then
        return
    end
    for _, redPointId in pairs(self.RedEventDic) do
        XRedPointManager.RemoveRedPointEvent(redPointId)
    end
    self.RedEventDic = {}
end

function XUiNode:RemoveRedPointEvent(redPointId)
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

function XUiNode:PlayAnimationWithMask(animeName, finCb, beginCb)
    local subBeginCb = function ()
        XLuaUiManager.SetMask(true)
        if beginCb then
            beginCb()
        end
    end

    local subFinCb = function ()
        XLuaUiManager.SetMask(false)
        if finCb then
            finCb()
        end
    end

    self:PlayAnimation(animeName, subFinCb, subBeginCb)
end

function XUiNode:PlayAnimation(animeName, finCb, beginCb)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    local animRoot = self.Transform:Find("Animation")
    if XTool.UObjIsNil(animRoot) then
        return
    end

    local animTrans = animRoot:FindTransform(animeName)
    if not animTrans or not animTrans.gameObject.activeInHierarchy then
        return
    end
    if beginCb then
        beginCb()
    end
    animTrans:PlayTimelineAnimation(finCb)
end

------------------------------------------------LuaUI---------------------------------------------------------
---@class XLuaUi
---@field UiModel XUiModel
XLuaUi = XClass(nil, "XLuaUi")

function XLuaUi:Ctor(name, uiProxy)
    self._Uid = GenUIUid()
    self.Name = name
    ---@type XUiLuaProxy
    self.UiProxy = uiProxy
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
end

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
    self:ReleaseRedPoint()
    self:DestroyChildNodes()
    self:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_UI_DESTROY)
end

function XLuaUi:OnDestroy()

end

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
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.UI, self)
    end
end

--CS.XEventId.EVENT_UI_ALLOWOPERATE 允许UI操作事件（可以理解为动画播放完成后的回调）
function XLuaUi:OnNotify(evt, ...)
end

function XLuaUi:OnGetEvents()
end

function XLuaUi:OnGetLuaEvents()
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
    self.UiProxy:RegisterClickEvent(
        button,
        function(eventData)
            if handle then
                handle(self, eventData)
            end
        end,
        clear
    )
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

-- 绑定返回/主界面按钮
function XLuaUi:BindExitBtns(btnBack, btnMainUi)
    btnBack = btnBack or self.BtnBack
    btnMainUi = btnMainUi or self.BtnMainUi
    self:RegisterClickEvent(
        btnBack,
        function()
            self:Close()
        end
    )
    self:RegisterClickEvent(
        btnMainUi,
        function()
            XLuaUiManager.RunMain()
        end
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
            if openCb then openCb() end
            XUiManager.ShowHelpTip(helpDataKey, cb)
        end
        return
    end

    if CS.XTool.ConfirmObjectType(btn, "Button") then
        self:RegisterClickEvent(
            btn,
            function()
                if openCb then openCb() end
                XUiManager.ShowHelpTip(helpDataKey, cb)
            end
        )
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
------------------------------------------------------------------------------------------------------------------------
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

-- function XLuaUiCheckGC:OnRelease()
--     XLuaUiCheckGC.Super.OnRelease(self)
-- end
------------------------------------------------------------------------------------------------------------------------
---@class XLuaUiManager
XLuaUiManager = XClass(nil, "XLuaUiManager")
local UiData = {}
local ClassType = {}
local ImportModule = {}
local XUiPrefix = "XUi/X%s/X%s"
local UiMainName = "UiMain"
local Registry = require("UiRegistry")

--- 注册Ui
---@param super XLuaUi 父类
---@param uiName string ui名
---@return XLuaUi
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
        XMVCA.XDlcRoom:Quit(function()
            CsXUiManager.Instance:RunMain()
        end)
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
    if luaUi == nil then return XSignalCode.EMPTY_UI end
    luaUi = luaUi.UiProxy
    if luaUi == nil then return XSignalCode.EMPTY_UI end
    luaUi = luaUi.UiLuaTable
    if luaUi == nil then return XSignalCode.EMPTY_UI end
    return luaUi:AwaitSignal(signalName, fromObj)
end

function XLuaUiManager.GetTopLuaUi(uiname)
    local luaUi = XLuaUiManager.FindTopUi(uiname)
    if luaUi == nil then return nil end
    luaUi = luaUi.UiProxy
    if luaUi == nil then return nil end
    luaUi = luaUi.UiLuaTable
    if luaUi == nil then return nil end
    return luaUi
end

function XLuaUiManager.SafeClose(uiName)
    if XLuaUiManager.IsUiShow(uiName) then
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