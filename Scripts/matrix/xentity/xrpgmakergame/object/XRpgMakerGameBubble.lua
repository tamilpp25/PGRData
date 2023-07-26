local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local MoveSpeed = CS.XGame.ClientConfig:GetInt("RpgMakeGameMoveSpeed")

---推箱子魔法阵
---@class XRpgMakerGameBubble:XRpgMakerGameObject
local XRpgMakerGameBubble = XClass(XRpgMakerGameObject, "XRpgMakerGameBubble")

function XRpgMakerGameBubble:Ctor(id)
    self:InitData()
end

function XRpgMakerGameBubble:InitData()
    if not XTool.IsTableEmpty(self.MapObjData) then
        self:InitDataByMapObjData(self.MapObjData)
    end
    self.IsBroken = false
end

---@param mapObjData XMapObjectData
function XRpgMakerGameBubble:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
    self:UpdatePosition({PositionX = self.MapObjData:GetX(), PositionY = self.MapObjData:GetY()})
end

function XRpgMakerGameBubble:UpdateData(data)
    self:UpdatePosition(data)
end

function XRpgMakerGameBubble:UpdateObjPosAndDirection()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local x = self:GetPositionX()
    local y = self:GetPositionY()
    local cubePosition = self:GetCubeUpCenterPosition(y, x)
    cubePosition.y = transform.position.y
    self:SetGameObjectPosition(cubePosition)
    self:SetActive(not self.IsBroken)
    self:ShowBaseEffect(not self.IsBroken)
end

function XRpgMakerGameBubble:Dispose()
    if self.BubbleBrokenEffect then
        CS.UnityEngine.GameObject.Destroy(self.BubbleBrokenEffect)
        self.BubbleBrokenEffect = nil
    end
    XRpgMakerGameBubble.Super.Dispose(self)
end

--移动
function XRpgMakerGameBubble:PlayMoveAction(action, cb)
    local transform = self:GetTransform()
    local startPosX = action.StartPosition.PositionX
    local startPosY = action.StartPosition.PositionY
    local endPosX = action.EndPosition.PositionX
    local endPosY = action.EndPosition.PositionY

    local startCube = self:GetCubeObj(startPosY, startPosX)
    local endCube = self:GetCubeObj(endPosY, endPosX)
    local startCubePosition = startCube:GetGameObjUpCenterPosition()
    local endCubePosition = endCube:GetGameObjUpCenterPosition()
    local cubeDistance = CS.UnityEngine.Vector3.Distance(startCubePosition, endCubePosition)
    local playActionTime = cubeDistance / MoveSpeed

    self:SetGameObjectPosition(startCubePosition)

    --计算移动到目标位置的距离
    local gameObjPosition = self:GetGameObjPosition()
    local enterStageDb = XDataCenter.RpgMakerGameManager:GetRpgMakerGameEnterStageDb()
    local mapId = enterStageDb:GetMapId()
    local trapId = XRpgMakerGameConfigs.GetRpgMakerGameTrapId(mapId, endPosX, endPosY)  --移动到的坐标有陷阱时，不偏移模型的位置
    local moveX = endCubePosition.x - gameObjPosition.x
    local moveZ = endCubePosition.z - gameObjPosition.z

    --在格子边缘停止移动
    if (self:IsDieByDrown() and not self:IsNotPlayDrownAnima()) or self:IsTranser() then
        local cubeSize = endCube:GetGameObjSize()
        local moveTempX = endCubePosition.x - startCubePosition.x
        if moveTempX < 0 then
            moveX = moveX + cubeSize.x / 2
        elseif moveTempX > 0 then
            moveX = moveX - cubeSize.x / 2
        end

        local moveTempZ = endCubePosition.z - startCubePosition.z
        if moveTempZ < 0 then
            moveZ = moveZ + cubeSize.z / 2
        elseif moveTempZ > 0 then
            moveZ = moveZ - cubeSize.z / 2
        end
    end

    local movePositionX
    local movePositionZ
    local curMoveDistance   --当前距离起点移动了多少
    self.PlayMoveActionTimer = XUiHelper.Tween(2, function(f)
        if XTool.UObjIsNil(transform) then
            return
        end

        curMoveDistance = playActionTime * f * MoveSpeed

        movePositionX = gameObjPosition.x + moveX * f
        movePositionZ = gameObjPosition.z + moveZ * f

        self:SetGameObjectPosition(Vector3(movePositionX, startCubePosition.y, movePositionZ), trapId)
    end, function()
        self:StopPlayMoveActionTimer()
        if cb then cb() end
    end)
end

function XRpgMakerGameBubble:SetIsBroken(isBroken)
    self.IsBroken = isBroken
end

---泡泡破裂特效
function XRpgMakerGameBubble:PlayBubbleBrokenEffect(cb)
    if XTool.UObjIsNil(self.BubbleBrokenEffect) then
        local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.BubbleBrokenEffect)
        local resource = self:ResourceManagerLoad(effectPath)
        local position = self:GetTransform().position
        if not position then
            return
        end
        self.BubbleBrokenEffect = self:LoadEffect(resource.Asset, position)
    end
    self.BubbleBrokenEffect.gameObject:SetActiveEx(true)
    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_BubbleBroken, XSoundManager.SoundType.Sound)
    self:ShowBaseEffect(false)

    XScheduleManager.ScheduleOnce(function()
        self:SetActive(false)
        self.BubbleBrokenEffect.gameObject:SetActiveEx(false)
        if cb then cb() end
    end, 500)
end

function XRpgMakerGameBubble:ShowBaseEffect(active)
    self:GetTransform():GetChild(0).gameObject:SetActiveEx(active)
end

function XRpgMakerGameBubble:OnLoadComplete()
    self:SetActive(false)
    self:SetActive(true)
    XRpgMakerGameBubble.Super.OnLoadComplete(self)
end

return XRpgMakerGameBubble