local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")
local XRpgMakerGameMonsterPatrolLine = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameMonsterPatrolLine")

local type = type
local pairs = pairs
local tableInsert = table.insert
local IsNumberValid = XTool.IsNumberValid
local CSXResourceManagerLoad = CS.XResourceManager.Load
local Vector3 = CS.UnityEngine.Vector3
local _ViewFront = XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewFront  --怪物的前方
local _ViewBack = XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewBack   --怪物的后面
local _ViewLeft = XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewLeft   --怪物的左边
local _ViewRight = XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewRight  --怪物的右边

local DefaultHp = 100

local Default = {
    _CurrentHp = 100,       --当前血量
    _FaceDirection = 0,     --朝向
}

--往某个方向设置移动路线特效
local MoveLineEffectType = {
    Horizontal = 1,    --往水平方向设置特效
    Vertical = 2,      --往垂直方向设置特效
}

--怪物对象
local XRpgMakerGameMonsterData = XClass(XRpgMakerGameObject, "XRpgMakerGameMonsterData")

function XRpgMakerGameMonsterData:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.PatrolLineObjs = {}    --场景中生成的移动路线对象
    self.ViewAreaModels = {}    --场景中生成的视野范围模型
    self:InitData()
end

function XRpgMakerGameMonsterData:Dispose()
    self:RemovePatrolLineObjs()
    self:RemoveViewAreaModels()
    XRpgMakerGameMonsterData.Super.Dispose(self)
end

function XRpgMakerGameMonsterData:RemovePatrolLineObjs()
    for _, v in pairs(self.PatrolLineObjs) do
        v:Dispose()
    end
    self.PatrolLineObjs = {}
end

function XRpgMakerGameMonsterData:RemoveViewAreaModels()
    for _, v in pairs(self.ViewAreaModels) do
        CS.UnityEngine.GameObject.Destroy(v)
    end
    self.ViewAreaModels = {}
end

function XRpgMakerGameMonsterData:InitData()
    local monsterId = self:GetId()
    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameMonsterX(monsterId)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameMonsterY(monsterId)
    local direction = XRpgMakerGameConfigs.GetRpgMakerGameMonsterDirection(monsterId)
    self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    self:SetFaceDirection(direction)
    self:SetCurrentHp(DefaultHp)

    self:RemovePatrolLineObjs()
    self:RemoveViewAreaModels()
end

function XRpgMakerGameMonsterData:UpdateData(data)
    self._CurrentHp = data.CurrentHp
    self._FaceDirection = data.FaceDirection
    self:UpdatePosition(data)
end

function XRpgMakerGameMonsterData:SetCurrentHp(hp)
    self._CurrentHp = hp
end

function XRpgMakerGameMonsterData:SetFaceDirection(faceDirection)
    self._FaceDirection = faceDirection
end

function XRpgMakerGameMonsterData:GetFaceDirection()
    return self._FaceDirection
end

function XRpgMakerGameMonsterData:GetCurrentHp()
    return self._CurrentHp
end

function XRpgMakerGameMonsterData:IsDeath()
    local currentHp = self:GetCurrentHp()
    return currentHp <= 0
end

function XRpgMakerGameMonsterData:Die()
    self:SetCurrentHp(0)
end

--设置视野范围
function XRpgMakerGameMonsterData:SetGameObjectViewArea()
    self:RemoveViewAreaModels()

    if self:IsDeath() then
        return
    end

    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end
    
    local modelKey = "ViewArea"
    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    local resource = CSXResourceManagerLoad(effectPath)

    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XRpgMakerGameMonsterData加载视野范围特效:%s失败", effectPath))
        return
    end

    local monsterId = self:GetId()
    local viewFront = XRpgMakerGameConfigs.GetRpgMakerGameMonsterViewFront(monsterId)
    local viewBack = XRpgMakerGameConfigs.GetRpgMakerGameMonsterViewBack(monsterId)
    local viewLeft = XRpgMakerGameConfigs.GetRpgMakerGameMonsterViewLeft(monsterId)
    local viewRight = XRpgMakerGameConfigs.GetRpgMakerGameMonsterViewRight(monsterId)
    local direction = self:GetFaceDirection()
    local viewAreaEffectPos = self:GetViewAreaEffectPos()
    local asset = resource.Asset
    local model
    local cubeTransform
    local cubeUpCenterPosition
    local row, col

    if IsNumberValid(viewFront) then
        local currentScene = XDataCenter.RpgMakerGameManager.GetCurrentScene()
        row, col = viewAreaEffectPos[_ViewFront].row, viewAreaEffectPos[_ViewFront].col
        cubeTransform = self:GetCubeTransform(row, col)
        if cubeTransform then
            cubeUpCenterPosition = self:GetCubeUpCenterPosition(row, col)
            model = self:LoadEffect(asset, cubeUpCenterPosition, cubeTransform)
            tableInsert(self.ViewAreaModels, model)
        end
    end

    if IsNumberValid(viewBack) then
        row, col = viewAreaEffectPos[_ViewBack].row, viewAreaEffectPos[_ViewBack].col
        cubeTransform = self:GetCubeTransform(row, col)
        if cubeTransform then
            cubeUpCenterPosition = self:GetCubeUpCenterPosition(row, col)
            model = self:LoadEffect(asset, cubeUpCenterPosition, cubeTransform)
            tableInsert(self.ViewAreaModels, model)
        end
    end

    if IsNumberValid(viewLeft) then
        row, col = viewAreaEffectPos[_ViewLeft].row, viewAreaEffectPos[_ViewLeft].col
        cubeTransform = self:GetCubeTransform(row, col)
        if cubeTransform then
            cubeUpCenterPosition = self:GetCubeUpCenterPosition(row, col)
            model = self:LoadEffect(asset, cubeUpCenterPosition, cubeTransform)
            tableInsert(self.ViewAreaModels, model)
        end
    end

    if IsNumberValid(viewRight) then
        row, col = viewAreaEffectPos[_ViewRight].row, viewAreaEffectPos[_ViewRight].col
        cubeTransform = self:GetCubeTransform(row, col)
        if cubeTransform then
            cubeUpCenterPosition = self:GetCubeUpCenterPosition(row, col)
            model = self:LoadEffect(asset, cubeUpCenterPosition, cubeTransform)
            tableInsert(self.ViewAreaModels, model)
        end
    end
end

function XRpgMakerGameMonsterData:GetViewAreaEffectPos()
    local direction = self:GetFaceDirection()
    local positionX = self:GetPositionX()
    local positionY = self:GetPositionY()
    local intervalPos = 1   --间隔多少位置设置

    local viewAreaPos = {}
    if direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft then
        viewAreaPos[_ViewFront] = {row = positionY, col = positionX - intervalPos}
        viewAreaPos[_ViewBack] = {row = positionY, col = positionX + intervalPos}
        viewAreaPos[_ViewLeft] = {row = positionY - intervalPos, col = positionX}
        viewAreaPos[_ViewRight] = {row = positionY + intervalPos, col = positionX}

    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight then
        viewAreaPos[_ViewFront] = {row = positionY, col = positionX + intervalPos}
        viewAreaPos[_ViewBack] = {row = positionY, col = positionX - intervalPos}
        viewAreaPos[_ViewLeft] = {row = positionY + intervalPos, col = positionX}
        viewAreaPos[_ViewRight] = {row = positionY - intervalPos, col = positionX}

    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp then
        viewAreaPos[_ViewFront] = {row = positionY + intervalPos, col = positionX}
        viewAreaPos[_ViewBack] = {row = positionY - intervalPos, col = positionX}
        viewAreaPos[_ViewLeft] = {row = positionY, col = positionX - intervalPos}
        viewAreaPos[_ViewRight] = {row = positionY, col = positionX + intervalPos}

    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown then
        viewAreaPos[_ViewFront] = {row = positionY - intervalPos, col = positionX}
        viewAreaPos[_ViewBack] = {row = positionY + intervalPos, col = positionX}
        viewAreaPos[_ViewLeft] = {row = positionY, col = positionX - intervalPos}
        viewAreaPos[_ViewRight] = {row = positionY, col = positionX + intervalPos}
    end
    return viewAreaPos
end

function XRpgMakerGameMonsterData:UpdateObjPosAndDirection()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local x = self:GetPositionX()
    local y = self:GetPositionY()
    local direction = self:GetFaceDirection()
    local cubePosition = self:GetCubeUpCenterPosition(y, x)
    cubePosition.y = transform.position.y
    self:SetGameObjectPosition(cubePosition)
    self:ChangeDirectionAction({Direction = direction})
end

--设置下一回合的移动路线
function XRpgMakerGameMonsterData:SetMoveLine(action)
    self:RemovePatrolLineObjs()

    local direction = action.Direction
    local startPosition = action.StartPosition
    local endPosition = action.EndPosition

    local moveLinePath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath("MoveLine")

    local horizontal = 0    --往水平方向设置特效
    local vertical = 0      --往垂直方向设置特效
    local intervalPos = 1   --间隔多少位置设置

    if direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft then
        horizontal = -intervalPos
    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight then
        horizontal = intervalPos
    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp then
        vertical = intervalPos
    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown then
        vertical = -intervalPos
    end

    if XTool.IsNumberValid(horizontal) then
        self:LoadMoveLineEffect(horizontal, MoveLineEffectType.Horizontal, startPosition, endPosition, direction)
    elseif XTool.IsNumberValid(vertical) then
        self:LoadMoveLineEffect(vertical, MoveLineEffectType.Vertical, startPosition, endPosition, direction)
    end
end

function XRpgMakerGameMonsterData:LoadMoveLineEffect(num, moveLineEffectType, startPosition, endPosition, direction)
    local moveLinePath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath("MoveLine")
    local startPosX = startPosition.PositionX
    local startPosY = startPosition.PositionY
    local endPosX = endPosition.PositionX
    local endPosY = endPosition.PositionY
    local cubeUpCenterPos
    local patrolLineObj

    while true do
        if startPosX == endPosX and startPosY == endPosY then
            return
        end

        if moveLineEffectType == MoveLineEffectType.Horizontal then
            startPosX = startPosX + num
        elseif moveLineEffectType == MoveLineEffectType.Vertical then
            startPosY = startPosY + num
        else
            return
        end

        cubeUpCenterPos = self:GetCubeUpCenterPosition(startPosY, startPosX)
        if not cubeUpCenterPos then
            return
        end

        patrolLineObj = XRpgMakerGameMonsterPatrolLine.New()
        patrolLineObj:LoadPatrolLine(moveLinePath, startPosX, startPosY, direction)
        tableInsert(self.PatrolLineObjs, patrolLineObj) 
    end
end

function XRpgMakerGameMonsterData:CheckLoadTriggerEndEffect()
    local monsterId = self:GetId()
    if not XRpgMakerGameConfigs.IsRpgMakerGameMonsterTriggerEnd(monsterId) then
        return
    end

    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath("MonsterTriggerEffect")
    local resource = CSXResourceManagerLoad(effectPath)
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XRpgMakerGameMonsterData加载开启终点的指示特效:%s失败", effectPath))
        return
    end

    local modelName = self:GetModelName()
    local effectRootName = XRpgMakerGameConfigs.GetRpgMakerGameEffectRoot(modelName)
    local transform = self:GetTransform()
    local effectRoot = transform:FindTransform(effectRootName)
    if XTool.UObjIsNil(effectRoot) then
        XLog.Error(string.format("XRpgMakerGameObject:CheckLoadTriggerEndEffect error: 终点指示特效父节点找不到, effectRootName: %s，modelName：%s", effectRootName, modelName))
        return
    end

    local asset = resource.Asset
    local position = Vector3.zero
    local effectObj = self:LoadEffect(asset, effectRoot.transform.position, effectRoot)
end

--杀死玩家
function XRpgMakerGameMonsterData:PlayKillPlayerAction(action, cb)
    local cb = cb
    self:PlayAtkAction(function()
        local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
        playerObj:PlayBeAtkAction(cb)
    end)
end

--检查是否死亡并设置模型显示状态
function XRpgMakerGameMonsterData:CheckIsDeath()
    local isDeath = self:IsDeath()
    self:SetActive(not isDeath)
end

return XRpgMakerGameMonsterData