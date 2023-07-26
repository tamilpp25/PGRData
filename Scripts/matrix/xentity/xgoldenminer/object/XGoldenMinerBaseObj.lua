local XGoldenMinerBaseObj = XClass(nil, "XGoldenMinerBaseObj")

local MILLION_PERCENT = 1000000

--黄金矿工玩法对象
function XGoldenMinerBaseObj:Ctor(go, id, index, trigerCallback, resourceManagerLoadFunc)
    self.GameObject = go
    self.Transform = go.transform
    self:SetId(id)  --GoldenMinerStone表Id
    self.Index = index --对象在地图中的下标
    self.TrigerCallback = trigerCallback    --触发本对象回调
    self.ResourceManagerLoadFunc = resourceManagerLoadFunc  --加载预制的方法

    self.RectTransform = self.Transform:GetComponent("RectTransform")
    -- 监听触发
    self.GoInputHandler = self.Transform:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    self.GoInputHandler:AddTriggerEnter2DCallback(function(collider) self:OnTriggerEnter(collider) end)
    self.GameObject.name = id
end

function XGoldenMinerBaseObj:Init(mapId, rectSize, originParent)
    local index = self.Index
    local width = rectSize.x
    local height = rectSize.y
    local xPosPercent = XGoldenMinerConfigs.GetMapXPosPercent(mapId, index) / MILLION_PERCENT
    local yPosPercent = XGoldenMinerConfigs.GetMapYPosPercent(mapId, index) / MILLION_PERCENT
    local scale = XGoldenMinerConfigs.GetMapScale(mapId, index) / MILLION_PERCENT
    local rotationZ = XGoldenMinerConfigs.GetMapRotationZ(mapId, index) / MILLION_PERCENT
    self.Transform.localPosition = Vector3(xPosPercent * width, yPosPercent * height, 0)
    self.RectTransform.localEulerAngles = Vector3(0, 0, rotationZ)
    self.Transform.localScale = Vector3(scale, scale, scale)

    self.OriginParent = originParent
    self.IsCatch = false
end

function XGoldenMinerBaseObj:OnTriggerEnter(collider)
    if XTool.UObjIsNil(collider.transform:GetComponent("Rigidbody2D")) then
        return
    end

    --触发对象不是钩爪
    local goldenMinerStoneId = tonumber(collider.gameObject.name)
    if XTool.IsNumberValid(goldenMinerStoneId) then
        local colliderHandler = collider.transform:GetComponent(typeof(CS.XGoInputHandler))
        local boomCollider = collider.transform:GetComponent("CircleCollider2D")    --炸弹的爆炸范围
        if not colliderHandler or not boomCollider or not colliderHandler.enabled or not boomCollider.enabled then
            return
        end

        local stoneType = XGoldenMinerConfigs.GetStoneType(goldenMinerStoneId)
        if stoneType == XGoldenMinerConfigs.StoneType.Boom and not XTool.UObjIsNil(self.GameObject) then
            self:DestroySelf(true)
        end
        return
    end
    self.StopMove = true

    self:SetGoInputHandlerActive(false)

    if self.TrigerCallback then
        self.TrigerCallback(self)
    end
end

function XGoldenMinerBaseObj:DestroySelf(isBoom)
    XUiHelper.Destroy(self.GameObject)
end

-- 自动销毁爆炸特效
function XGoldenMinerBaseObj:SelfDestroy(isBoom)
    if self.DestroyTime or self:GetIsCatch() or XTool.UObjIsNil(self.GameObject) then
        return
    end
    local destroyTime = 0.5
    local effectUrl = isBoom and XGoldenMinerConfigs.GetTypeBoomEffect() or XGoldenMinerConfigs.GetDestroyEffect()
    local effect = self:LoadResource(self.Transform.parent, effectUrl)
    effect.transform.position = self.Transform.position
    XUiHelper.Destroy(self.GameObject)
    self.StopMove = true
    self.DestroyTime = XScheduleManager.ScheduleForeverEx(function()
        destroyTime = destroyTime - CS.UnityEngine.Time.deltaTime
        if not XTool.UObjIsNil(effect) and destroyTime <= 0 then
            XUiHelper.Destroy(effect)
            XScheduleManager.UnSchedule(self.DestroyTime)
            self.DestroyTime = nil
        end
    end, 0)
end

function XGoldenMinerBaseObj:IsTriggerCollider(collider)
    if XTool.UObjIsNil(collider.transform:GetComponent("Rigidbody2D")) then
        return false
    end

    local goldenMinerStoneId = tonumber(collider.gameObject.name)
    if XTool.IsNumberValid(goldenMinerStoneId) then
        local colliderHandler = collider.transform:GetComponent(typeof(CS.XGoInputHandler))
        local boomCollider = collider.transform:GetComponent("CircleCollider2D")    --炸弹的爆炸范围
        if not colliderHandler or not boomCollider or not colliderHandler.enabled or not boomCollider.enabled then
            return false
        end
    end

    return true
end

--把自身设置到钩爪节点中
function XGoldenMinerBaseObj:SetObjToTriggerParent(triggerObjs)
    if XTool.UObjIsNil(triggerObjs) or XTool.UObjIsNil(self.GameObject) then
        return
    end
    if self.MoveType == XGoldenMinerConfigs.StoneMoveType.Circle then
        self.Transform.localPosition = self.InitPosition
        self.Transform.rotation = self.InitRotation
    end
    self.IsCatch = true

    self.Transform:SetParent(triggerObjs.transform, false)
    self:EdgeTop()

    local effect = XGoldenMinerConfigs.GetStoneCatchEffect(self:GetId())
    if string.IsNilOrEmpty(effect) then
        return
    end
    self:LoadResource(self.Transform, effect)
end

-- 移动相关
--=======================================================================

function XGoldenMinerBaseObj:Move(deltaTime)
    if XTool.UObjIsNil(self.GameObject) or not XTool.IsNumberValid(self.MoveType) or not self.GameObject.activeSelf then
        return
    end

    if self.StopMove then
        return
    end

    if self.MoveType == XGoldenMinerConfigs.StoneMoveType.Horizontal then
        self:MoveHorizontal(deltaTime)
    elseif self.MoveType == XGoldenMinerConfigs.StoneMoveType.Vertical then
        self:MoveVertical(deltaTime)
    elseif self.MoveType == XGoldenMinerConfigs.StoneMoveType.Circle then
        self:MoveCircle(deltaTime)
    end
end

-- 移动参数初始化
function XGoldenMinerBaseObj:InitMoveArgs()
    self.StopMove = false
    local stoneId = self:GetId()
    self.Scale = self.Transform.localScale.x
    self.MoveType = XGoldenMinerConfigs.GetStoneMoveType(stoneId)
    if not XTool.IsNumberValid(self.MoveType) then
        return
    end
    self.CurMoveDirection = XGoldenMinerConfigs.GetStoneStartMoveDirection(stoneId)
    self.MoveSpeed = XGoldenMinerConfigs.GetStoneMoveSpeed(stoneId)
    self.MoveRange = XGoldenMinerConfigs.GetStoneMoveRange(stoneId)

    if self.MoveType == XGoldenMinerConfigs.StoneMoveType.Horizontal then
        self:InitHorizontalMoveArgs()
    elseif self.MoveType == XGoldenMinerConfigs.StoneMoveType.Vertical then
        self:InitVerticalMoveArgs()
    elseif self.MoveType == XGoldenMinerConfigs.StoneMoveType.Circle then
        self:InitCircleMoveArgs()
    end
end

-- 水平移动参数初始化
function XGoldenMinerBaseObj:InitHorizontalMoveArgs()
    self.PosY = self.Transform.localPosition.y
    --左右方向能移动到的最大位置
    local posX = self.Transform.localPosition.x
    self.MoveMinPosX = posX - self.MoveRange
    self.MoveMaxPosX = posX + self.MoveRange
end

-- 垂直移动参数初始化
function XGoldenMinerBaseObj:InitVerticalMoveArgs()
    self.PosX = self.Transform.localPosition.x
    --左右方向能移动到的最大位置
    local posY = self.Transform.localPosition.y
    self.MoveMinPosY = posY - self.MoveRange
    self.MoveMaxPosY = posY + self.MoveRange
end

-- 圆周运动参数初始化
function XGoldenMinerBaseObj:InitCircleMoveArgs()
    -- 记录初始状态(被抓取用)
    self.InitPosition = self.Transform.localPosition
    self.InitRotation = self.Transform.rotation
    -- 记录圆心
    self.CirclePoint = self.Transform.position
    -- 设置初始起点与角度
    local x =  self.Transform.localPosition.x + self.MoveRange * math.cos(self.CurMoveDirection / 180 * math.pi)
    local y =  self.Transform.localPosition.y + self.MoveRange * math.sin(self.CurMoveDirection / 180 * math.pi)
    self.Transform:Rotate(0, 0, self.CurMoveDirection - 90)
    self.Transform.localPosition = Vector3(x, y, 0)
end

-- 水平移动
local _MoveX
function XGoldenMinerBaseObj:MoveHorizontal(deltaTime)
    _MoveX = self.Transform.localPosition.x + deltaTime * self.CurMoveDirection * self.MoveSpeed
    if _MoveX < self.MoveMinPosX then
        _MoveX = self.MoveMinPosX
        self:ChangeOrientation()
    elseif _MoveX > self.MoveMaxPosX then
        _MoveX = self.MoveMaxPosX
        self:ChangeOrientation()
    end

    self.Transform.localPosition = Vector3(_MoveX, self.PosY, 0)
end

-- 垂直移动
local _MoveY
function XGoldenMinerBaseObj:MoveVertical(deltaTime)
    _MoveY = self.Transform.localPosition.y + deltaTime * self.CurMoveDirection * self.MoveSpeed
    if _MoveY < self.MoveMinPosY then
        _MoveY = self.MoveMinPosY
        self:ChangeOrientation()
    elseif _MoveY > self.MoveMaxPosY then
        _MoveY = self.MoveMaxPosY
        self:ChangeOrientation()
    end

    self.Transform.localPosition = Vector3(self.PosX, _MoveY, 0)
end

-- 圆周运动
function XGoldenMinerBaseObj:MoveCircle(deltaTime)
    self.Transform:RotateAround(self.CirclePoint, -CS.UnityEngine.Vector3.forward, self.MoveSpeed * deltaTime)
end

--改变朝向
function XGoldenMinerBaseObj:ChangeOrientation()
    self.CurMoveDirection = -self.CurMoveDirection
end

--=======================================================================

--变成等重量的黄金
function XGoldenMinerBaseObj:ChangeToGold()
    local id = self:GetId()
    local weight = XGoldenMinerConfigs.GetStoneWeight(id)
    local goldId = XGoldenMinerConfigs.GetGoldIdByWeight(weight, id)
    if not goldId then
        return
    end

    local parent = self.Transform.parent
    local prefab = XGoldenMinerConfigs.GetStonePrefab(goldId)
    XUiHelper.Destroy(self.GameObject)
    local obj = self:LoadResource(parent, prefab)
    if obj then
        self.GameObject = obj
        self.Transform = obj.transform
    end

    self:EdgeTop()
    self:SetId(goldId)
end

--锚点设置到上中心
function XGoldenMinerBaseObj:EdgeTop()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    local rectTranform = self.Transform:GetComponent("RectTransform")
    rectTranform.anchorMin = Vector2(0.5, 1)
    rectTranform.anchorMax = Vector2(0.5, 1)
    rectTranform.pivot = Vector2(0.5, 1)
    self.Transform.localPosition = Vector3.zero
end

function XGoldenMinerBaseObj:LoadResource(parent, prefabPath, isCenter)
    if self.ResourceManagerLoadFunc then
        local resource = self.ResourceManagerLoadFunc(prefabPath)
        local obj = XUiHelper.Instantiate(resource.Asset, parent)
        if isCenter then
            local rectTranform = obj.transform:GetComponent("RectTransform")
            rectTranform:SetInsetAndSizeFromParentEdge(CS.UnityEngine.RectTransform.Edge.Top, 0, rectTranform.rect.height)
            rectTranform.anchorMin = Vector2(0.5, 0.5)
            rectTranform.anchorMax = Vector2(0.5, 0.5)
        end
        obj.transform.localPosition = Vector3.zero
        return obj
    end
end

--延迟生成用
function XGoldenMinerBaseObj:SetDisable(isDisable)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.GameObject:SetActiveEx(not isDisable)
end

function XGoldenMinerBaseObj:GetIsEnable()
    if XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return self.GameObject.activeSelf
end

function XGoldenMinerBaseObj:GetIsCatch()
    return self.IsCatch
end

function XGoldenMinerBaseObj:SetId(id)
    self.Id = id
end

function XGoldenMinerBaseObj:SetGoInputHandlerActive(isActive)
    if XTool.UObjIsNil(self.GoInputHandler) then
        return
    end
    self.GoInputHandler.enabled = isActive
end

function XGoldenMinerBaseObj:IsActiveGoInputHandler()
    if XTool.UObjIsNil(self.GoInputHandler) then
        return false
    end
    return self.GoInputHandler.enabled
end

function XGoldenMinerBaseObj:GetId()
    return self.Id
end

function XGoldenMinerBaseObj:GetIndex()
    return self.Index
end

function XGoldenMinerBaseObj:GetType()
    local id = self:GetId()
    return XGoldenMinerConfigs.GetStoneType(id)
end

function XGoldenMinerBaseObj:GetScore()
    local id = self:GetId()
    return XGoldenMinerConfigs.GetStoneScore(id)
end

function XGoldenMinerBaseObj:GetWeight()
    local id = self:GetId()
    return XGoldenMinerConfigs.GetStoneWeight(id)
end

function XGoldenMinerBaseObj:GetStoneBornDelay()
    local id = self:GetId()
    return XGoldenMinerConfigs.GetStoneBornDelay(id)
end

function XGoldenMinerBaseObj:GetStoneDestroyTime()
    local id = self:GetId()
    return XGoldenMinerConfigs.GetStoneDestroyTime(id)
end

return XGoldenMinerBaseObj