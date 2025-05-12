local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
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
    self._Uid = XLuaUiManager.GenUIUid()
    ---@type UnityEngine.GameObject
    self.GameObject = ui.gameObject
    ---@type UnityEngine.RectTransform
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)

    ---@type XUiNode[]
    self._ChildNodes = {} --子节点
    self._Control = nil
    self._AbleCount = 0
    self._BindControlId = nil
    ---@type XLuaUi
    self._TweenAnimationAgency = nil
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
    if XLuaUiManager.IsWindowsEditor() then
        XLuaUiManager.SetUi2NameMap(self._Uid, self.GameObject.name)
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
    if XLuaUiManager.IsWindowsEditor() then
        if self._StateFlag == XUiNodeState.Enable then
            if not self.GameObject.activeInHierarchy then
                XLog.Error(string.format("子节点 %s 显示后, activeInHierarchy依旧为false, go name : %s",
                        self.__cname, CS.XUnityEx.GetPath(self.Transform)))
            end
        elseif self._StateFlag == XUiNodeState.Disable then
            --暂时用不了, 因为是先OnDisable再SetActive
            if self.GameObject.activeInHierarchy then
                XLog.Error(string.format("子节点 %s 隐藏后, activeInHierarchy依旧为true, go name : %s",
                        self.__cname, CS.XUnityEx.GetPath(self.Transform)))
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
        
        self._TweenAnimationAgency = nil
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
    --if XLuaUiManager.IsWindowsEditor() then
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
            self:BindTweenAnimationAgency()
        else
            local parentClsName = self.Parent.__cname and self.Parent.__cname or ""
            if XLuaUiManager.IsWindowsEditor() then
                XLog.Error("Parent 不为XLuaUi 或 XUiNode: " .. parentClsName)
            end
        end
    else
        if XLuaUiManager.IsWindowsEditor() then
            XLog.Error("XUiNode has not Parent: " .. self.__cname)
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
            if XLuaUiManager.IsWindowsEditor() then
                XLog.Error("Parent 不为XLuaUi 或 XUiNode: " .. parentClsName)
            end
        end
    else
        if XLuaUiManager.IsWindowsEditor() then
            XLog.Error("XUiNode has not Parent: " .. self.__cname)
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
            if self.Parent._BindControlId then
                --这个有值证明可以绑定
                tempBindName = self.Parent._BindControlId
            elseif self.Parent.__cname and UIBindControl[self.Parent.__cname] then
                tempBindName = UIBindControl[self.Parent.__cname]
            end
        end
    end
    self._BindControlId = tempBindName
end

function XUiNode:BindControl()
    if self._BindControlId then
        --子界面用_BindControlId
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

function XUiNode:BindTweenAnimationAgency()
    if self.Parent then
        if CheckClassSuper(self.Parent, XUiNode) then
            self._TweenAnimationAgency = self.Parent._TweenAnimationAgency
        elseif CheckClassSuper(self.Parent, XLuaUi) then
            self._TweenAnimationAgency = self.Parent
        else
            if XLuaUiManager.IsWindowsEditor() then
                XLog.Error("Parent 不为XLuaUi 或 XUiNode: " .. self.Parent.__cname)
            end
        end
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
    if XLuaUiManager.IsWindowsEditor() then
        WeakRefCollector.AddRef(WeakRefCollector.Type.UI, self)
        XLuaUiManager.SetUi2NameMap(self._Uid, nil)
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

function XUiNode:PlayAnimationWithMask(animeName, finCb, beginCb, wrapMode)
    local subBeginCb = function()
        XLuaUiManager.SetMask(true)
        if beginCb then
            beginCb()
        end
    end

    local subFinCb = function()
        XLuaUiManager.SetMask(false)
        if finCb then
            finCb()
        end
    end

    self:PlayAnimation(animeName, subFinCb, subBeginCb, wrapMode)
end

function XUiNode:PlayAnimation(animeName, finCb, beginCb, wrapMode)
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

    -- XLuaUi的动画播放beginCb是传入C#端的，除了gameobject隐藏判断外，还判断了控制器组件是否存在
    -- 需要注意两边播放动画接口的差异，先不修改此处的beginCb调用时机
    if beginCb then
        beginCb()
    end

    animTrans:PlayTimelineAnimation(finCb, nil, wrapMode or CS.UnityEngine.Playables.DirectorWrapMode.Hold)
end

function XUiNode:StopAnimation(animeName)
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

    animTrans:StopTimelineAnimation()
end

--region Tween动画
function XUiNode:Tween(duration, onRefresh, onFinish, easeMethod)
    if self._TweenAnimationAgency then
        return self._TweenAnimationAgency:Tween(duration, onRefresh, onFinish, easeMethod)
    else
        if XLuaUiManager.IsWindowsEditor() then
            XLog.Error("TweenAnimationAgency is nil")
        end
    end
end

function XUiNode:DoUiMove(rectTf, tarPos, duration, easeType, cb)
    if self._TweenAnimationAgency then
        return self._TweenAnimationAgency:DoUiMove(rectTf, tarPos, duration, easeType, cb)
    else
        if XLuaUiManager.IsWindowsEditor() then
            XLog.Error("TweenAnimationAgency is nil")
        end
    end
end

function XUiNode:DoMove(rectTf, tarPos, duration, easeType, cb)
    if self._TweenAnimationAgency then
        return self._TweenAnimationAgency:DoMove(rectTf, tarPos, duration, easeType, cb)
    else
        if XLuaUiManager.IsWindowsEditor() then
            XLog.Error("TweenAnimationAgency is nil")
        end
    end
end

function XUiNode:DoWorldMove(rectTf, tarPos, duration, easeType, cb)
    if self._TweenAnimationAgency then
        return self._TweenAnimationAgency:DoWorldMove(rectTf, tarPos, duration, easeType, cb)
    else
        if XLuaUiManager.IsWindowsEditor() then
            XLog.Error("TweenAnimationAgency is nil")
        end
    end
end

function XUiNode:DoScale(rectTf, startScale, tarScale, duration, easeType, cb)
    if self._TweenAnimationAgency then
        return self._TweenAnimationAgency:DoScale(rectTf, startScale, tarScale, duration, easeType, cb)
    else
        if XLuaUiManager.IsWindowsEditor() then
            XLog.Error("TweenAnimationAgency is nil")
        end
    end
end

function XUiNode:DoAlpha(canvasGroup, startAlpha, tarAlpha, duration, easeType, cb)
    if self._TweenAnimationAgency then
        return self._TweenAnimationAgency:DoAlpha(canvasGroup, startAlpha, tarAlpha, duration, easeType, cb)
    else
        if XLuaUiManager.IsWindowsEditor() then
            XLog.Error("TweenAnimationAgency is nil")
        end
    end
end

function XUiNode:_RemoveTimerIdAndDoCallback(timerId, cb)
    self._TweenAnimationAgency:_RemoveTimerIdAndDoCallback(timerId, cb)
end
--endregion