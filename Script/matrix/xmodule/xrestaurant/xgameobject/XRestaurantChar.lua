
local XRestaurantIScene = require("XModule/XRestaurant/XGameObject/XRestaurantIScene")

---@class XRestaurantChar : XRestaurantIScene
---@field _Id
---@field _Animator UnityEngine.Animator
---@field _CtrlResource XIResource
---@field _Input XGoInputHandler
---@field _BubbleOffset UnityEngine.Vector3 气泡偏移
---@field _Agent BehaviorTree.XAgent
---@field _ReferenceCount number 引用计数
---@field _EffectLoader XUiLoadPrefab
---@field _IsShowDelayBubble boolean
---@field _IsDoLoadBehaviour boolean
---@field _MoveSpeed number 移动速度
---@field _MoveAgent XMoveAgent
local XRestaurantChar = XClass(XRestaurantIScene, "XRestaurantChar")

--行为树代理
--require("XEntity/XRestaurant/XBehaviour/XRestaurantCharAgent")

local ResourceUnloadTime = 10000 --延时销毁

function XRestaurantChar:Ctor(root, id)
    self._Id = id
    self._ReferenceCount = 0
    self._BubbleOffset = XRestaurantConfigs.StrPos2Vector3(XRestaurantConfigs.GetClientConfig("CharacterProperty", 2))
    self:InitData()
end

function XRestaurantChar:Init()
    self._MoveSpeed = tonumber(XRestaurantConfigs.GetClientConfig("CharacterProperty", 1))
end

function XRestaurantChar:InitData()
    
end

function XRestaurantChar:Born(bornCb)
    self._ReferenceCount = self._ReferenceCount + 1
    if self:Exist() then
        self:Show()
        if bornCb then bornCb() end
        return
    end

    if self:IsLoading() then
        return
    end
    
    self:Load(bornCb)
end

function XRestaurantChar:Dispose()
    if not self:Exist() then
        self._ReferenceCount = 0
        return
    end
    self._ReferenceCount = self._ReferenceCount - 1
    self:Hide()
    XScheduleManager.ScheduleOnce(self._DelayReleaseCb, ResourceUnloadTime)
end

function XRestaurantChar:DisposeImmediately()
    self:Release()
end

function XRestaurantChar:OnLoadSuccess()
    --动画
    self._Animator = self._GameObject:GetComponent(typeof(CS.UnityEngine.Animator))
    -- 加载自定义状态机
    local path = self:GetControllerPath()
    if not string.IsNilOrEmpty(path) then
        local resource = CS.XResourceManager.Load(path)
        if not (resource and resource.Asset) then
            XLog.Error(string.format("%s:角色状态机加载失败, 路径: %s", self:GetCharTypeDesc(), path))
            return
        end
        
        self._CtrlResource = resource
        self._Animator.runtimeAnimatorController = resource.Asset
    end
    --取消动画自带的位移
    self._Animator.applyRootMotion = false
    --行为树代理
    self._Agent = self._GameObject:GetComponent(typeof(CS.BehaviorTree.XAgent))
    if not self._Agent then
        self._Agent = self._GameObject:AddComponent(typeof(CS.BehaviorTree.XAgent))
        self._Agent.ProxyType = "RestaurantChar"
        self._Agent:InitProxy()
    end
    self._Agent.Proxy.LuaAgentProxy:SetRole(self)
    --是否需要点击
    if self:IsNeedClick() then
        --设置层级，点击生效
        self._GameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.HomeCharacter))
        self._Input = self._GameObject:GetComponent(typeof(CS.XGoInputHandler))
        if not self._Input then
            self._Input = self._GameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
        self._Input:AddPointerClickListener(handler(self, self.OnClick))
    end
    --处理旋转/位移/缩放
    self:InitCharTransform()
    --处理阴影
    CS.XMaterialContainerHelper.SetCharacterShadowVolumeEnable(self._GameObject, false)
    CS.XShadowHelper.AddShadow(self._GameObject, true)

    self._DelayReleaseCb = handler(self, self.DelayRelease)

    self:PlayBehaviour()
end

function XRestaurantChar:Release()
    if self._Agent then
        self._Agent:ClearVarDic()
    end

    XRestaurantIScene.Release(self)
    if self._CtrlResource then
        self._CtrlResource:Release()
        self._CtrlResource = nil
    end
    self._Animator = nil
    self._Input = nil
    self._Agent = nil
    self._EffectLoader = nil
    self._Effect = nil
    self._MoveAgent = nil

    self._ReferenceCount = 0
    self._IsShowDelayBubble = false
end

function XRestaurantChar:Hide()
    XRestaurantIScene.Hide(self)
    self:DoHideBubble()
    self._IsDoLoadBehaviour = false
end

function XRestaurantChar:DelayRelease()
    if not self:Exist() then
        return
    end
    --还有引用，不销毁
    if self._ReferenceCount > 0 then
        return
    end
    self:Release()
end

function XRestaurantChar:GetControllerPath()
    return ""
end

--Debug 输出, 不用于实际业务
function XRestaurantChar:GetCharTypeDesc()
    return ""
end

function XRestaurantChar:IsNeedClick()
    return false
end

function XRestaurantChar:OnClick()
    XLog.Warning("未实现点击方法！")
end

function XRestaurantChar:InitCharTransform()
end

function XRestaurantChar:PlayBehaviour()
    XLog.Error("子类未实现该方法")
end

function XRestaurantChar:ChangeState(state)
end

--播放动画
function XRestaurantChar:DoAction(actionId, needFadeCross, crossDuration)
    if not self:Exist() then
        return
    end
    if needFadeCross then
        self._Animator:CrossFade(actionId, crossDuration, -1, 0)
    else
        self._Animator:Play(actionId, -1, 0)
    end
end

--根据下标播放动画
function XRestaurantChar:DoActionIndex(index, needFadeCross, crossDuration)
    self:DoAction(self:GetActionId(index), needFadeCross, crossDuration)
end

function XRestaurantChar:CheckPlayRepeat(index, isRequireRepeat)
    if isRequireRepeat then
        return true
    end

    local stateInfo = self._Animator:GetCurrentAnimatorStateInfo(0)
    local nextInfo = self._Animator:GetNextAnimatorStateInfo(0)
    
    local actionId = self:GetActionId(index)
    
    local newHash = CS.UnityEngine.Animator.StringToHash(actionId)

    if newHash == stateInfo.shortNameHash 
            or nextInfo.shortNameHash == newHash then
        return false
    end
    return true
end

function XRestaurantChar:GetActionId(index)
    XLog.Error("子类调用，但未实现该方法")
    return "Error"
end

function XRestaurantChar:GetActionDuration(index)
    local actionId = self:GetActionId(index)
    if string.IsNilOrEmpty(actionId) then
        return 0
    end
    local animationClips = self._Animator.runtimeAnimatorController.animationClips;
    for i = 0, animationClips.Length - 1 do
        local clip = animationClips[i]
        if clip and clip.name == actionId then
            return clip.length
        end
    end
    return 0
end

--弹出聊天气泡
function XRestaurantChar:DoRandomBubble()
    if XTool.UObjIsNil(self._GameObject) or self:IsHide() then
        return
    end
    local text = self:GetRandomBubbleText()
    
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_SHOW_3D_DIALOG, self:GetBubbleKey(), text, nil, self._Transform, self._BubbleOffset)
end

function XRestaurantChar:DoBubble(index)
    if XTool.UObjIsNil(self._GameObject) or self:IsHide() then
        return
    end
    local text = self:GetBubbleText(index)
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_SHOW_3D_DIALOG, self:GetBubbleKey(), text, nil, self._Transform, self._BubbleOffset)
end

--- 延时弹出气泡
---@param delay number 毫秒
--------------------------
function XRestaurantChar:DoRandomBubbleDelay(delay)
    --上次的正在展示
    if self:IsShowDelayBubble() then
        return
    end
    
    if not self._RandomBubbleHandler then
        self._RandomBubbleHandler = function()
            if not self:Exist() then
                return
            end
            
            self:DoRandomBubble()
            XScheduleManager.ScheduleOnce(function() 
                self:DoHideBubble()
                self._IsShowDelayBubble = false
            end, XRestaurantConfigs.BubbleDuration * XScheduleManager.SECOND)
        end
    end
    self._IsShowDelayBubble = true
    XScheduleManager.ScheduleOnce(self._RandomBubbleHandler, delay)
end

function XRestaurantChar:IsShowDelayBubble()
    return self._IsShowDelayBubble
end

--隐藏气泡
function XRestaurantChar:DoHideBubble()
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_HIDE_3D_DIALOG, self:GetBubbleKey())
end

--获取随机聊天气泡
function XRestaurantChar:GetRandomBubbleText()
    XLog.Error("子类调用，但未实现该方法")
    return "Error"
end

--通过下标获取冒泡
function XRestaurantChar:GetBubbleText(index)
    XLog.Error("子类调用，但未实现该方法")
    return "Error"
end

--获取气泡Id
function XRestaurantChar:GetBubbleKey()
    if not self:Exist() then
        return self._Id
    end
    return self._GameObject:GetHashCode()
end

--随机寻路
function XRestaurantChar:DoFindRandomPoint()
    local point = self:GetRandomPoint()
    self._Agent:SetVarDicByKey("TargetPosition", point)
end

--随机点位方法
function XRestaurantChar:GetRandomPoint()
    XLog.Error("子类调用，但未实现该方法")
    return CS.UnityEngine.Vector3.zero
end

function XRestaurantChar:DoStopMove()
    if not self:Exist() then
        return
    end
    if not self._MoveAgent then
        return
    end
    
    self._MoveAgent:Stop()
end

function XRestaurantChar:GetId()
    return self._Id
end

--加载特效
function XRestaurantChar:DoLoadEffect(path, initPos)
    if XTool.UObjIsNil(self._GameObject) then
        return
    end

    if self._EffectLoader and self._EffectLoader.PrefabAssetUrl == path and not XTool.UObjIsNil(self._Effect) then
        self._Effect.gameObject:SetActiveEx(true)
        self._Effect.transform.localPosition = initPos
        return
    end
     
    self._Effect = self._Transform:LoadPrefab(path)
    if not self._EffectLoader then
        self._EffectLoader = self._Transform:GetComponent(typeof(CS.XUiLoadPrefab))
    end
    self._Effect.gameObject:SetActiveEx(true)
    self._Effect.transform.localPosition = initPos
end

--隐藏特效
function XRestaurantChar:DoHideEffect()
    if XTool.UObjIsNil(self._GameObject) 
            or XTool.UObjIsNil(self._Effect) then
        return
    end
    self._Effect.gameObject:SetActiveEx(false)
end

--销毁
function XRestaurantChar:DoDestroyEffect()
    if XTool.UObjIsNil(self._GameObject)
            or XTool.UObjIsNil(self._Effect) then
        return
    end
    XUiHelper.Destroy(self._Effect.gameObject)
end

--是否在工作
function XRestaurantChar:DoIsWorking()
    return false
end

function XRestaurantChar:DoCheckInt(intValue)
    return false
end

function XRestaurantChar:DoLoadComplete()
    self:OnLoadBehaviourComplete()
end

--加载行为完成
function XRestaurantChar:OnLoadBehaviourComplete()
    self._IsDoLoadBehaviour = true
end

-- 添加移动控件
function XRestaurantChar:TryAddNavMeshAgent()
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    local agent = self._GameObject:GetComponent(typeof(CS.XMoveAgent))
    if not agent then
        agent = CS.XNavMeshUtility.AddMoveAgent(self._GameObject)
        agent.Radius = 0.35
        agent.IsObstacle = true
        agent.IsIgnoreCollide = false
        agent.CeilSize = 0.3
        agent.Speed = self._MoveSpeed
        self._MoveAgent = agent
    end
end

return XRestaurantChar