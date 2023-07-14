local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")
local XRpgMakerGameMonsterPatrolLine = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameMonsterPatrolLine")
local XRpgMakerGameMonsterSentry = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameMonsterSentry")

local type = type
local pairs = pairs
local tableInsert = table.insert
local IsNumberValid = XTool.IsNumberValid
local CSXResourceManagerLoad = CS.XResourceManager.Load
local Vector3 = CS.UnityEngine.Vector3
local LookRotation = CS.UnityEngine.Quaternion.LookRotation
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
    self.PatrolLineObjs = {}    --场景中生成的下回合移动路线
    self.ViewAreaModels = {}    --场景中生成的视野范围
    self.SentryLineModels = {}  --场景中生成的探测视野
    self.Sentry = XRpgMakerGameMonsterSentry.New(id)           --场景中生成的哨戒指示物
    self.HeadRoot = nil         --模型的头部挂点
    self:InitData()
end

function XRpgMakerGameMonsterData:Dispose()
    self:RemoveViewAreaAndLine()
    self:RemoveSentry()
    XRpgMakerGameMonsterData.Super.Dispose(self)
end

function XRpgMakerGameMonsterData:RemoveSentry()
    if self.Sentry then
        self.Sentry:Dispose()
    end
end

function XRpgMakerGameMonsterData:RemovePatrolLineObjs()
    for _, v in pairs(self.PatrolLineObjs) do
        v:Dispose()
    end
    self.PatrolLineObjs = {}
end

function XRpgMakerGameMonsterData:RemoveViewAreaModels()
    for _, v in pairs(self.ViewAreaModels) do
        if not XTool.UObjIsNil(v) then
            XUiHelper.Destroy(v)
        end
    end
    self.ViewAreaModels = {}
end

function XRpgMakerGameMonsterData:RemoveSentryLineModels()
    for _, v in pairs(self.SentryLineModels) do
        v:Dispose()
    end
    self.SentryLineModels = {}
end

function XRpgMakerGameMonsterData:InitData()
    local monsterId = self:GetId()
    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameMonsterX(monsterId)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameMonsterY(monsterId)
    local direction = XRpgMakerGameConfigs.GetRpgMakerGameMonsterDirection(monsterId)
    self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    self:SetFaceDirection(direction)
    self:SetCurrentHp(DefaultHp)

    self:RemoveViewAreaAndLine()
    self:InitSentryData()
end

function XRpgMakerGameMonsterData:UpdateData(data)
    self._CurrentHp = data.CurrentHp
    self._FaceDirection = data.FaceDirection
    self.Sentry:UpdateData(data)
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

function XRpgMakerGameMonsterData:Death(cb)
    self:RemoveViewAreaModels()
    XRpgMakerGameMonsterData.Super.Death(self, cb)
end

function XRpgMakerGameMonsterData:IsDeath()
    local currentHp = self:GetCurrentHp()
    return currentHp <= 0
end

function XRpgMakerGameMonsterData:Die()
    self:SetCurrentHp(0)
end

--朝向转方向
function XRpgMakerGameMonsterData:FaceToDirection(faceDirection)
    local curDirection = self:GetFaceDirection()
    local direction
    if faceDirection == XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewBack then
        if curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft
        end

    elseif faceDirection == XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewLeft then
        if curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp
        end

    elseif faceDirection == XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewRight then
        if curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp
        elseif curDirection == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight then
            direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown
        end
    end
    return direction or curDirection
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
    
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.ViewArea
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
    local viewAreaEffectPos = self:GetViewAreaEffectPos()
    local asset = resource.Asset
    local row, col
    local monsterPosX = self:GetPositionX()
    local monsterPosY = self:GetPositionY()

    local isNotUsePool = true
    local InsertModel = function(row, col, models, faceDirection)
        local cubeTransform = self:GetCubeTransform(row, col)
        if not cubeTransform then
            return
        end

        local direction = self:FaceToDirection(faceDirection)
        local isNextSet = XDataCenter.RpgMakerGameManager.IsCurGapSet(monsterPosX, monsterPosY, direction)
        if not isNextSet then
            return
        end

        local cubeUpCenterPosition = self:GetCubeUpCenterPosition(row, col)
        local model = self:LoadEffect(asset, cubeUpCenterPosition, cubeTransform, isNotUsePool)
        tableInsert(models, model)
    end

    if IsNumberValid(viewFront) then
        row, col = viewAreaEffectPos[_ViewFront].row, viewAreaEffectPos[_ViewFront].col
        InsertModel(row, col, self.ViewAreaModels, XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewFront)
    end

    if IsNumberValid(viewBack) then
        row, col = viewAreaEffectPos[_ViewBack].row, viewAreaEffectPos[_ViewBack].col
        InsertModel(row, col, self.ViewAreaModels, XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewBack)
    end

    if IsNumberValid(viewLeft) then
        row, col = viewAreaEffectPos[_ViewLeft].row, viewAreaEffectPos[_ViewLeft].col
        InsertModel(row, col, self.ViewAreaModels, XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewLeft)
    end

    if IsNumberValid(viewRight) then
        row, col = viewAreaEffectPos[_ViewRight].row, viewAreaEffectPos[_ViewRight].col
        InsertModel(row, col, self.ViewAreaModels, XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewRight)
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
    local moveLinePath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.MoveLine)
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

    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.MonsterTriggerEffect)
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
    self:LoadEffect(asset, effectRoot.transform.position, effectRoot)
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

--小怪或人类移动前先播放惊动的动作再移动
function XRpgMakerGameMonsterData:PlayMoveAction(action, cb, mapId)
    local id = self:GetId()
    local skillType = XRpgMakerGameConfigs.GetMonsterSkillType(self:GetId())
    self:CheckIsSteelAdsorb(mapId, action.EndPosition.PositionX, action.EndPosition.PositionY, skillType)

    --检查下一个动作
    local nextAction = XDataCenter.RpgMakerGameManager.GetNextAction(true)
    if nextAction then
        if nextAction.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterTransfer then
            self:SetIsTranser(true)
        end
    end

    local monsterType = XRpgMakerGameConfigs.GetRpgMakerGameMonsterType(id)
    if monsterType == XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Normal or monsterType == XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Human then
        self:PlayAlarmAnima(function()
            XRpgMakerGameMonsterData.Super.PlayMoveAction(self, action, cb, skillType)
        end)
        return
    end
    XRpgMakerGameMonsterData.Super.PlayMoveAction(self, action, cb, skillType)
end

------------哨戒 begin--------------
function XRpgMakerGameMonsterData:InitSentryData()
    self.Sentry:UpdateData({})
end

--哨戒指示物位置数据
function XRpgMakerGameMonsterData:UpdateSentrySignAction(action)
    local startPosition = action.StartPosition
    local startPosX = self:GetPositionX()
    local startPosY = self:GetPositionY()
    local endPosX = startPosition and startPosition.PositionX or 0
    local endPosY = startPosition and startPosition.PositionY or 0
    local curRount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    curRount = curRount and curRount + 1 or 0       --创建指示物的回合数同步服务端+1
    self.Sentry:UpdatePosition({PositionX = startPosX, PositionY = startPosY})
    self.Sentry:UpdateData({SentryStartPositionX = startPosX,
        SentryStartPositionY = startPosY,
        SentryEndPositionX = endPosX,
        SentryEndPositionY = endPosY,
        SentryStartRound = curRount})
end

function XRpgMakerGameMonsterData:CheckRemoveSentry()
    if not self.Sentry:IsCreateSentry() then
        self:RemoveSentry()
    end
end

--加载哨戒指示物
function XRpgMakerGameMonsterData:LoadSentrySign()
    self:RemoveSentry()
    if not self.Sentry:IsCreateSentry() or self:IsDeath() then
        return
    end

    local position = self:GetGameObjPosition()
    local modelName = self:GetModelName()
    local yOffset = XRpgMakerGameConfigs.GetRpgMakerGameSentrySignYOffset(modelName)
    self.Sentry:Load(position + Vector3(0, yOffset, 0))

    if self.Sentry:IsShowNextRoundSentry() then
        XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_SentrySign, XSoundManager.SoundType.Sound)
    end
end

--设置哨戒警戒线
function XRpgMakerGameMonsterData:SetSentryLine()
    self:RemoveSentryLineModels()

    if self:IsDeath() then
        return
    end

    --生成指示物的第一回合会生成警戒线，之后直到指示物消失才会重新生成警戒线
    if not self.Sentry:InFirstRoundCreate() and self.Sentry:IsCreateSentry() then
        return
    end

    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    --哨戒路线
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.SentryLine
    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    local monsterId = self:GetId()
    local sentryFront = XRpgMakerGameConfigs.GetRpgMakerGameSentryFront(monsterId)
    local sentryBack = XRpgMakerGameConfigs.GetRpgMakerGameSentryBack(monsterId)
    local sentryLeft = XRpgMakerGameConfigs.GetRpgMakerGameSentryLeft(monsterId)
    local sentryRight = XRpgMakerGameConfigs.GetRpgMakerGameSentryRight(monsterId)
    local faceDirection = self:GetFaceDirection()
    local direction

    local InsertModel = function(direction)
        local intervalPos = 1   --间隔多少位置设置
        --往水平方向设置特效
        local horizontal = (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft and -intervalPos) or (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight and intervalPos) or 0
        --往垂直方向设置特效
        local vertical = (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown and -intervalPos) or (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp and intervalPos) or 0

        local posX, posY = self:GetPositionX(), self:GetPositionY()
        local cubeUpCenterPos
        local obj
        local isCurSet       --是否能在当前的坐标中设置
        local isNextSet = XDataCenter.RpgMakerGameManager.IsCurGapSet(posX, posY, direction)      --是否能继续在下一个坐标中设置

        while isNextSet do
            posX = posX + horizontal
            posY = posY + vertical
            cubeUpCenterPos = self:GetCubeUpCenterPosition(posX, posY)
            if not cubeUpCenterPos then
                return
            end

            isCurSet, isNextSet = XDataCenter.RpgMakerGameManager.IsCurPositionSet(posX, posY, direction)

            if isCurSet then
                obj = XRpgMakerGameMonsterPatrolLine.New()
                obj:LoadPatrolLine(effectPath, posX, posY, direction)
                tableInsert(self.SentryLineModels, obj) 
            end
        end
    end

    if IsNumberValid(sentryFront) then
        InsertModel(faceDirection)
    end

    if IsNumberValid(sentryBack) then
        direction = self:FaceToDirection(XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewBack)
        InsertModel(direction)
    end

    if IsNumberValid(sentryLeft) then
        direction = self:FaceToDirection(XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewLeft)
        InsertModel(direction)
    end

    if IsNumberValid(sentryRight) then
        direction = self:FaceToDirection(XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType.ViewRight)
        InsertModel(direction)
    end
end

function XRpgMakerGameMonsterData:IsSentryShowLastStopRound()
    return self.Sentry:IsShowLastStopRound()
end

function XRpgMakerGameMonsterData:GetSentryLastStopRound()
    return self.Sentry:GetLastStopRound()
end

function XRpgMakerGameMonsterData:GetSentryRoandGameObjPosition()
    return self.Sentry:GetSentryRoandGameObjPosition()
end
------------哨戒 end----------------

function XRpgMakerGameMonsterData:SetViewAreaAndLine()
    self:SetGameObjectViewArea()
    self:SetSentryLine()
end

function XRpgMakerGameMonsterData:RemoveViewAreaAndLine()
    self:RemovePatrolLineObjs()
    self:RemoveViewAreaModels()
    self:RemoveSentryLineModels()
end

return XRpgMakerGameMonsterData