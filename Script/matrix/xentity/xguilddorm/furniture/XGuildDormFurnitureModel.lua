
local XGuildDormFurnitureModel = XClass(nil, "XGuildDormFurnitureModel")
local MapGridManager
local CsXGameEventManager = CS.XGameEventManager

function XGuildDormFurnitureModel:Ctor(id)
    local cfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.DefaultFurniture, id)
    local furnitureCfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Furniture, cfg.FurnitureId)
    self.Id = cfg.Id
    self.RoomId = cfg.RoomId
    self.FurnitureId = furnitureCfg.Id
    self.Name = furnitureCfg.Name
    self.BehaviorType = furnitureCfg.BehaviorType
    self.AttractBehaviorType = furnitureCfg.AttractBehaviorType
    self.FunitureBehaviorType = furnitureCfg.FunitureBehaviorType
    self.InteractPos = furnitureCfg.InteractPos
    self.IsNeedLoad = furnitureCfg.IsNeedLoad > 0
    self.FurnitureType = furnitureCfg.FurnitureType
    self.ShowButtonName = furnitureCfg.ShowButtonName
    self.DontAutoCreateCollider = furnitureCfg.DontAutoCreateCollider == 1
    self.AnimationType = furnitureCfg.AnimationType
    if self.AnimationType ~= XGuildDormConfig.FurnitureAnimationType.NoAnimation then
        self.AnimationName = furnitureCfg.AnimationName
        self.AnimationArg = furnitureCfg.AnimationArg
    end
    -- XGuildDormConfig.FurnitureButtonType
    self.ButtonType = furnitureCfg.ButtonType
    self.ButtonArg = furnitureCfg.ButtonArg
    self.InteractInfoList = {}
end

function XGuildDormFurnitureModel:SetGameObject(go)
    self.GameObject = go.gameObject
    self.Transform = go.transform
    self:OnLoadComplete()
end

function XGuildDormFurnitureModel:OnLoadComplete()
    self.Colliders = {}
    local list = self.GameObject:GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    if not self.DontAutoCreateCollider then
        self.GameObject:AddComponent(typeof(CS.UnityEngine.BoxCollider))
    end
    for i = 0, list.Length - 1 do
        table.insert(self.Colliders, list[i])
    end
    if self.FurnitureType == XGuildDormConfig.FurnitureType.DITHER then
        --获取dither
        self.Dithers = {}
        list = self.GameObject:GetComponentsInChildren(typeof(CS.XRoomWallDither))
        --获取家具下面是否有特效,需要在变成透明时处理显隐
        local fx = self.GameObject:FindGameObject("Fx")
        if fx then
            self.FxObj = fx
        end
        for i = 0, list.Length - 1 do
            list[i]:AddStateChangeListener(self.GameObject, handler(self, self.OnDitherStateChange))
            list[i]:AddRenderer(self.GameObject)
            table.insert(self.Dithers, list[i])
        end

    end
    if self.AnimationType ~= XGuildDormConfig.FurnitureAnimationType.NoAnimation then
        self.AnimationRoot = self.GameObject:FindGameObject("Animation")
        if self.AnimationType == XGuildDormConfig.FurnitureAnimationType.FunctionAnimation then
            local event = require("XEntity/XGuildDorm/Furniture/Events/XGDF" .. XGuildDormConfig.FurnitureAnimationEventType[self.AnimationArg])
            self.AnimationEvent = event.New(function(value) self:TriggerAnimation(value) end)
        end
    end
    --[[
    -- 监听点击
    self.GoInputHandler = self.Transform:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
    self.GoInputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    if not XTool.UObjIsNil(self.GoInputHandler) then
    self.GoInputHandler:AddPointerClickListener(function(eventData) self:OnClick(eventData) end)
    self.GoInputHandler:AddDragListener(function(eventData) self:OnDrag(eventData) end)
    self.GoInputHandler:AddPressListener(function(pressTime) self:OnPress(pressTime) end)
    end
    ]]
    self:InitInteractInfo()
    self:InitNavMesh()
end
--=================
--初始化家具交互信息
--=================
function XGuildDormFurnitureModel:InitInteractInfo()
    self.InteractInfoList = {}
    for k=1, self.InteractPos do
        local stayPoint = self.GameObject:FindGameObject("StayPos" .. tostring(k))
        local interactPoint = self.GameObject:FindGameObject("InteractPos" .. tostring(k))
        if interactPoint == nil then
            if XMain.IsEditorDebug then
                XLog.Error(string.format("%s 缺少交互点%s号", self.Name, k))
            end
            break
        end
        local info = {}
        info.Index = k
        if not XTool.UObjIsNil(stayPoint) then
            local stayPos = stayPoint.transform.position
        end
        info.Id = self.Id
        info.StayPos = stayPoint
        info.InteractPos = interactPoint
        info.PosIndex = k
        info.BehaviorType = self.BehaviorType[k] or self.BehaviorType[1]-- 标记互动点序号以分别不同角色在不同点的互动
        info.ShowButtonName = self.ShowButtonName
        info.ButtonType = self.ButtonType
        info.ButtonArg = self.ButtonArg
        info.AnimSetupTrigger = self.AnimationType == XGuildDormConfig.FurnitureAnimationType.TriggerAnimation
        and function() self:TriggerAnimation(true) end
        info.AnimExitTrigger = self.AnimationType == XGuildDormConfig.FurnitureAnimationType.TriggerAnimation
        and function() self:TriggerAnimation(false) end
        table.insert(self.InteractInfoList, info)
    end
end

function XGuildDormFurnitureModel:InitNavMesh()
    if self.FurnitureType == XGuildDormConfig.FurnitureType.GROUND then
        self.NavMeshSurface = CS.XNavMeshUtility.SetNavMeshSurfaceAndBuild(self.GameObject)
    else
        local Obstacle = self.GameObject:FindGameObject("Obstacle")
        if Obstacle then
            CS.XNavMeshUtility.AddNavMeshObstacleSizeByCollider(Obstacle)
        end
    end
end
--============
--销毁
--============
function XGuildDormFurnitureModel:Dispose()
    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:RemoveAllListeners()
    end
    self.GoInputHandler = nil
    if self.NavMeshSurface and self.NavMeshSurface:Exist() then
        self.NavMeshSurface:RemoveData()
    end
    --注销遮挡透明脚本事件
    for _, dither in pairs(self.Dithers or {}) do
        dither:RemoveStateChangeListener(self.GameObject)
    end
    if self.AnimationEvent then
        self.AnimationEvent:Dispose()
    end
end
--============
--遮挡状态改变时
--============
function XGuildDormFurnitureModel:OnDitherStateChange(state)
    if state == XGuildDormConfig.FurnitureDitherState.Display then
        self:EnableBoxColliders()
        if self.FxObj then self.FxObj:SetActiveEx(true) end
    elseif state == XGuildDormConfig.FurnitureDitherState.Hide then
        self:DisableBoxColliders()
        if self.FxObj then self.FxObj:SetActiveEx(false) end
    end
end
--============
--开启家具下所有碰撞盒子
--============
function XGuildDormFurnitureModel:EnableBoxColliders()
    for _, collider in pairs(self.Colliders or {}) do
        collider.enabled = true
    end
end
--============
--关闭家具下所有碰撞盒子
--============
function XGuildDormFurnitureModel:DisableBoxColliders()
    for _, collider in pairs(self.Colliders or {}) do
        collider.enabled = false
    end
end
--============
--获取家具交互点信息
--============
function XGuildDormFurnitureModel:GetInteractInfoList()
    if not self.InteractInfoList or next(self.InteractInfoList) == nil then
        local roomMap = CS.XRoomMapInfo.GenerateMap(self.CfgId)
        self:GenerateInteractInfo(roomMap)
    end
    return self.InteractInfoList
end
--==============
-- 播放动画
--==============
function XGuildDormFurnitureModel:PlayAnimation(animationName)
    if self.GameObject.activeInHierarchy then
        local timeline = self.AnimationRoot:FindGameObject(animationName)
        if timeline then
            if self.CurrentTimeline then
                self.CurrentTimeline:SetActiveEx(false)
            end
            self.CurrentTimeline = timeline.gameObject
            self.CurrentTimeline:SetActiveEx(true)
        end
    end
end
--==============
-- 触发动画
--==============
function XGuildDormFurnitureModel:TriggerAnimation(value)
    if value then
        self:PlayAnimation(self.AnimationName[XGuildDormConfig.FurnitureAnimationName.Setup])
    else
        self:PlayAnimation(self.AnimationName[XGuildDormConfig.FurnitureAnimationName.Exit])
    end
end

function XGuildDormFurnitureModel:ResetNavmeshObstacle()
    local Obstacle = self.GameObject:FindGameObject("Obstacle")
    if Obstacle then
        CS.XNavMeshUtility.ResetNavMeshObstacle(Obstacle)
    end
end
--==============
-- 点击家具
--==============
function XGuildDormFurnitureModel:OnClick(eventData)

end
--==============
-- 拖动家具
--==============
function XGuildDormFurnitureModel:OnDrag(eventData)

end
--==============
-- 按住家具
--==============
function XGuildDormFurnitureModel:OnPress(pressTime)

end

return XGuildDormFurnitureModel