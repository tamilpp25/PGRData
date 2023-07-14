local XGoldenMinerBaseObj = require("XEntity/XGoldenMiner/Object/XGoldenMinerBaseObj")
local MathAbs = math.abs
local AnimaState = {
    Run = 1,
    Grab = 2,
    Bomb = 3
}

--黄金矿工鼬鼠
local XGoldenMinerMouse = XClass(XGoldenMinerBaseObj, "XGoldenMinerMouse")

function XGoldenMinerMouse:Ctor()
    self:InitObj()

    self.StopMove = false
    self.StopTime = 0 --停止移动的时间（单位：秒）
    self.CurCarryStoneId = 0  --当前携带的矿石Id
end

function XGoldenMinerMouse:InitObj()
    self.BombRotate = XUiHelper.TryGetComponent(self.Transform, "Animation/BombRotate")
    self.Run = XUiHelper.TryGetComponent(self.Transform, "Run")
    self.Grab = XUiHelper.TryGetComponent(self.Transform, "Grab")
    self.Bomb = XUiHelper.TryGetComponent(self.Transform, "Bomb")
    self.RunCarryItemParent = XUiHelper.TryGetComponent(self.Run.transform, "RunCarryItemParent")
    self.GrabCarryItemParent = XUiHelper.TryGetComponent(self.Grab.transform, "GrabCarryItemParent")
    self.RunSkeletonAnima = XUiHelper.TryGetComponent(self.Transform, "Run", "SkeletonGraphic")
end

function XGoldenMinerMouse:Init(mapId, rectSize, originParent)
    XGoldenMinerMouse.Super.Init(self, mapId, rectSize, originParent)

    self.Scale = self.Transform.localScale.x
    local stoneId = self:GetId()
    local startMoveDirection = XGoldenMinerConfigs.GetStoneStartMoveDirection(stoneId)
    self.CurMoveDirection = startMoveDirection
    self.Transform.localScale = Vector3(self.Scale * startMoveDirection, self.Scale, self.Scale)
    self.PosY = self.Transform.localPosition.y
    self.MoveSpeed = XGoldenMinerConfigs.GetStoneMoveSpeed(stoneId)
    self.MoveRange = XGoldenMinerConfigs.GetStoneMoveRange(stoneId)

    --左右方向能移动到的最大位置
    local posX = self.Transform.localPosition.x
    local range = XGoldenMinerConfigs.GetStoneMoveRange(stoneId)
    self.MoveMinPosX = posX - range
    self.MoveMaxPosX = posX + range

    self:InitCarryItem(stoneId)

    self:SetAnimaState(AnimaState.Run)
end

--初始化鼬鼠携带物品
function XGoldenMinerMouse:InitCarryItem(stoneId)
    local carryStoneId = XGoldenMinerConfigs.GetStoneCarryStoneId(stoneId)
    if not XTool.IsNumberValid(carryStoneId) then
        return
    end
    self:LoadCarryItem(carryStoneId)
end

function XGoldenMinerMouse:LoadCarryItem(stoneId)
    local prefab = XGoldenMinerConfigs.GetStonePrefab(stoneId)
    self:LoadResource(self.RunCarryItemParent, prefab)
    self:LoadResource(self.GrabCarryItemParent, prefab)
    self.CurCarryStoneId = stoneId
end

function XGoldenMinerMouse:OnTriggerEnter(collider)
    if not self:IsTriggerCollider(collider) then
        return
    end
    self.StopMove = true
    XGoldenMinerMouse.Super.OnTriggerEnter(self, collider)
end

function XGoldenMinerMouse:SetObjToTriggerParent(triggerObjs)
    self:SetAnimaState(AnimaState.Grab)
    XGoldenMinerMouse.Super.SetObjToTriggerParent(self, triggerObjs)
end

local _MoveX
function XGoldenMinerMouse:Move(deltaTime)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    self:CheckRunAnima()
    if self.StopMove then
        return
    end

    if self.StopTime > 0 then
        self.StopTime = self.StopTime - deltaTime
        return
    end

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

function XGoldenMinerMouse:CheckRunAnima()
    if self.RunSkeletonAnima then
        self.RunSkeletonAnima.timeScale = self.StopTime > 0 and 0 or 1
    end
end

--改变朝向
function XGoldenMinerMouse:ChangeOrientation()
    local scale = self.Scale
    self.Transform.localScale = Vector3(self.Transform.localScale.x * -1, scale, scale)
    self.CurMoveDirection = -self.CurMoveDirection
end

function XGoldenMinerMouse:StopMoveTime(time)
    self.StopTime = time
end

function XGoldenMinerMouse:SetAnimaState(state)
    self.Run.gameObject:SetActiveEx(AnimaState.Run == state)
    self.Grab.gameObject:SetActiveEx(AnimaState.Grab == state)
    self.Bomb.gameObject:SetActiveEx(AnimaState.Bomb == state)
end

function XGoldenMinerMouse:GetCurCarryStoneId()
    return self.CurCarryStoneId
end

-- 获得贝塞尔曲线点
-- t：0到1的值，0获取曲线的起点，1获得曲线的终点
-- start：曲线的起始位置
-- center：决定曲线形状的控制点
-- end：曲线的终点
function XGoldenMinerMouse:GetBezierPoint(t, startPoint, center, endPoint)
    return (1 - t) * (1 - t) * startPoint + 2 * t * (1 - t) * center + t * t * endPoint
end

function XGoldenMinerMouse:GetCarryStoneScore()
    local carryStoneId = self:GetCurCarryStoneId()
    return XTool.IsNumberValid(carryStoneId) and XGoldenMinerConfigs.GetStoneScore(carryStoneId) or 0
end

function XGoldenMinerMouse:RemoveBoomAnima()
    if self.BoomAnima then
        XScheduleManager.UnSchedule(self.BoomAnima)
        self.BoomAnima = nil
    end
end

-------------重写接口 begin-----------------
function XGoldenMinerMouse:GetWeight()
    local weight = 0
    local id = self:GetId()
    weight = XGoldenMinerConfigs.GetStoneWeight(id)

    local carryStoneId = self:GetCurCarryStoneId()
    if XTool.IsNumberValid(carryStoneId) then
        weight = weight + XGoldenMinerConfigs.GetStoneWeight(carryStoneId)
    end

    return weight
end

--变成等重量的黄金
function XGoldenMinerMouse:ChangeToGold()
    local carryStoneId = self:GetCurCarryStoneId()
    if not XTool.IsNumberValid(carryStoneId) then
        return
    end

    local weight = XGoldenMinerConfigs.GetStoneWeight(carryStoneId)
    local goldId = XGoldenMinerConfigs.GetGoldIdByWeight(weight, carryStoneId)
    if not goldId then
        return
    end

    XTool.DestroyChildren(self.RunCarryItemParent)
    XTool.DestroyChildren(self.GrabCarryItemParent)

    self:LoadCarryItem(goldId)
end

--碰到炸弹移到屏幕外再消除
function XGoldenMinerMouse:DestroySelf(isBoom)
    self:RemoveBoomAnima()

    local onFinish = function()
        XGoldenMinerMouse.Super.DestroySelf(self)
    end

    if XTool.UObjIsNil(self.OriginParent) or not isBoom then
        onFinish()
        return
    end

    self:SetAnimaState(AnimaState.Bomb)
    local boomBefore = self.Transform.localPosition
    self.Transform:SetParent(self.OriginParent)

    local screen = CS.UnityEngine.Screen
    local startPos = self.Transform.localPosition
    --随机左右边界
    local endPosX = math.random(0, 1) == 1 and screen.width or 0
    local endPos = Vector3(endPosX, self.Transform.localPosition.y, self.Transform.localPosition.z)
    --中间点，起点和终点的向量相加乘0.5，再加一个高度
    local bezierControlPoint = (self.Transform.localPosition + endPos) * 0.5 + (Vector3.up * 400)
    
    local curBazierPoint
    local onRefresh = function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        curBazierPoint = self:GetBezierPoint(f, startPos, bezierControlPoint, endPos)
        self.Transform.localPosition = curBazierPoint
    end
    
    self.BoomAnima = XUiHelper.Tween(1, onRefresh, onFinish)
end
-------------重写接口 end-------------------

return XGoldenMinerMouse