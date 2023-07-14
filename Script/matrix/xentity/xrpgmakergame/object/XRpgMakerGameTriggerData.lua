local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local Vec3Lerp = CS.UnityEngine.Vector3.Lerp

local Default = {
    _TriggerStatus = 0,       --状态，1阻挡，0不阻挡
    _ElectricStatus = 0,      --电墙机关（开关）状态，1关闭电网，0开启
}

local TriggerType1OpenOffSetY = -0.22       --类型1开关开启时的位置偏移
local TriggerType2OpenOffSetY = -0.46       --类型2开关开启时的位置偏移
local ModelDefaultScale = Vector3(1, 1, 1)      --模型默认大小
local TriggerType2OpenScale = Vector3(0.9, 0.9, 0.9)          --类型2开关开启时的模型大小
local TriggerType2PlayTime = 0.5            --类型2开关开启或关闭播放动画的时间（单位：秒）

--开关对象
local XRpgMakerGameTriggerData = XClass(XRpgMakerGameObject, "XRpgMakerGameTriggerData")

function XRpgMakerGameTriggerData:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self:InitData()
end

function XRpgMakerGameTriggerData:InitData()
    self.StatusIsChange = false  --新的机关状态是否和旧的不同
    self.ElectricStatusIsChange = false --新的电墙机关状态是否和旧的不同
    self.IsPlayElectricStatusSwitchSound = false    --是否播放电墙机关切换音效

    local triggerId = self:GetId()
    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameTriggerX(triggerId)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameTriggerY(triggerId)
    local defaultBlock = XRpgMakerGameConfigs.GetRpgMakerGameTriggerDefaultBlock(triggerId)
    self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    self:SetTriggerStatus(defaultBlock)
    self:SetElectricStatus(XRpgMakerGameConfigs.XRpgMakerGameElectricStatus.OpenElectricFence)
end

function XRpgMakerGameTriggerData:UpdateData(data)
    local status = data.TriggerStatus or data.BlockStatus
    self:SetStatusIsChange(self._TriggerStatus ~= status)
    self:SetElectricStatusIsChange(self._ElectricStatus ~= data.ElectricStatus)
    self._TriggerStatus = status
    self._ElectricStatus = data.ElectricStatus
end

function XRpgMakerGameTriggerData:SetElectricStatusIsChange(isChange)
    self.ElectricStatusIsChange = isChange
end

function XRpgMakerGameTriggerData:SetIsPlayElectricStatusSwitchSound(isPlayElectricStatusSwitchSound)
    self.IsPlayElectricStatusSwitchSound = isPlayElectricStatusSwitchSound
end

function XRpgMakerGameTriggerData:SetElectricStatus(status)
    self:SetElectricStatusIsChange(self._ElectricStatus ~= status)
    self._ElectricStatus = status
end

function XRpgMakerGameTriggerData:SetTriggerStatus(status)
    self:SetStatusIsChange(self._TriggerStatus ~= status)
    self._TriggerStatus = status
end

function XRpgMakerGameTriggerData:SetStatusIsChange(isChange)
    self.StatusIsChange = isChange
end

function XRpgMakerGameTriggerData:IsBlock(status)
    local triggerStatus = status or self._TriggerStatus
    return triggerStatus == XRpgMakerGameConfigs.XRpgMakerGameBlockStatus.Block
end

function XRpgMakerGameTriggerData:IsElectricOpen()
    return self._ElectricStatus == XRpgMakerGameConfigs.XRpgMakerGameElectricStatus.OpenElectricFence
end

function XRpgMakerGameTriggerData:UpdateObjTriggerStatus(isNotPlaySound)
    local action = {
        TriggerStatus = self._TriggerStatus,
        ElectricStatus = self._ElectricStatus
    }
    self:PlayTriggerStatusChangeAction(action, nil, isNotPlaySound)
end

--播放开关状态切换动画
function XRpgMakerGameTriggerData:PlayTriggerStatusChangeAction(action, cb, isNotPlaySound)
    local transform = self:GetTransform()
    local gameObjPosition = self:GetGameObjPosition()
    if not transform or not gameObjPosition then
        return
    end

    local triggerId = self:GetId()
    local triggerType = XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(triggerId)
    local triggerStatus = action.TriggerStatus or action.BlockStatus
    local electricStatus = action.ElectricStatus
    local isBlock = self:IsBlock(triggerStatus)
    local positionX = gameObjPosition.x
    local positionZ = gameObjPosition.z
    local originScale = transform.localScale
    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameTriggerX(triggerId)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameTriggerY(triggerId)
    local cubeUpCenterPosition = self:GetCubeUpCenterPosition(pointY, pointX)
    local cubeUpCenterPositionY = cubeUpCenterPosition.y

    local isGrassShelter = XDataCenter.RpgMakerGameManager.IsGrassShelter(pointX, pointY)

    --升降台阻挡物
    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger2 then
        self:CheckTriggerType1Touch(isBlock)
        self:StopTriggerType2PlayTimer()
        local objSize = self:GetGameObjSize()
        local offSetY = objSize and -objSize.y + 0.1 or TriggerType2OpenOffSetY
        local isRise = isBlock and not isGrassShelter

        local easeMethod = function(f)
            return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, f)
        end
        local onRefresh = function(f)
            if XTool.UObjIsNil(transform) then
                return
            end

            local offsetY = cubeUpCenterPositionY + offSetY
            local position = isRise and Vec3Lerp(gameObjPosition, Vector3(positionX, cubeUpCenterPositionY, positionZ), f) 
                or Vec3Lerp(gameObjPosition, Vector3(positionX, offsetY, positionZ), f)
            self:SetGameObjectPosition(position)

            local scale = isRise and Vec3Lerp(originScale, ModelDefaultScale, f) 
                or Vec3Lerp(originScale, TriggerType2OpenScale, f)
            self:SetGameObjScale(scale)
        end
        self.TriggerType2PlayTimer = XUiHelper.Tween(TriggerType2PlayTime, onRefresh, nil, easeMethod)

        if not isNotPlaySound and self.StatusIsChange then
            XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_TriggerType2, XSoundManager.SoundType.Sound)
        end

    --地刺
    elseif triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger3 then
        local trigger = XUiHelper.TryGetComponent(transform, "ScenePuzzle01_02Dici")
        if trigger then
            trigger.gameObject:SetActiveEx(isBlock)
            self:SetActive(true)
        else
            self:SetActive(isBlock)
        end

        if isBlock and not isNotPlaySound and self.StatusIsChange then
            XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_TriggerType3, XSoundManager.SoundType.Sound)
        end

    elseif triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.TriggerElectricFence then
        local sceneObjRoot = self:GetGameObjModelRoot()
        local isElectricOpen = self:IsElectricOpen()
        local modelKey = XRpgMakerGameConfigs.GetRpgMakerGameTriggerKey(triggerType, isElectricOpen)
        local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        self:LoadModel(modelPath, sceneObjRoot, nil, modelKey)

        if self.IsPlayElectricStatusSwitchSound and self.ElectricStatusIsChange then
            XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_ElectricStatusSwitch, XSoundManager.SoundType.Sound)
        end
        self:SetIsPlayElectricStatusSwitchSound(false)
    end

    if cb then
        cb()
    end
end

function XRpgMakerGameTriggerData:StopTriggerType2PlayTimer()
    if self.TriggerType2PlayTimer then
        XScheduleManager.UnSchedule(self.TriggerType2PlayTimer)
        self.TriggerType2PlayTimer = nil
    end
end

--检查是否触发了类型1的机关（有怪物或玩家在机关上）
function XRpgMakerGameTriggerData:CheckTriggerType1Touch(isBlock)
    local currentScene = XDataCenter.RpgMakerGameManager.GetCurrentScene()
    local mapId = currentScene:GetMapId()
    local triggerIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    local positionX
    local positionY
    local triggerType
    local pointX
    local pointY
    local monsterIdList
    local monsterObj

    for _, triggerId in ipairs(triggerIdList) do
        triggerType = XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(triggerId)
        if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger1 then
            pointX = XRpgMakerGameConfigs.GetRpgMakerGameTriggerX(triggerId)
            pointY = XRpgMakerGameConfigs.GetRpgMakerGameTriggerY(triggerId)
            positionX = playerObj:GetPositionX()
            positionY = playerObj:GetPositionY()
            if pointX == positionX and pointY == positionY then
                self:PlayTriggerType1Action(triggerId, isBlock)
                goto continue
            end

            monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
            for _, monsterId in ipairs(monsterIdList) do
                monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
                positionX = monsterObj:GetPositionX()
                positionY = monsterObj:GetPositionY()
                if pointX == positionX and pointY == positionY then
                    self:PlayTriggerType1Action(triggerId, isBlock)
                    goto continue
                end
            end

            --没怪物或玩家在机关上还原成默认的状态
            self:PlayTriggerType1Action(triggerId, true)
        end

        ::continue::
    end
end

function XRpgMakerGameTriggerData:PlayTriggerType1Action(triggerId, isBlock)
    local triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
    if not triggerObj then
        return
    end

    local gameObjPosition = triggerObj:GetGameObjPosition()
    if not gameObjPosition then
        return
    end

    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameTriggerX(triggerId)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameTriggerY(triggerId)
    local cubeUpCenterPosition = self:GetCubeUpCenterPosition(pointY, pointX)
    local cubeUpCenterPositionY = cubeUpCenterPosition.y
    local positionX = gameObjPosition.x
    local positionZ = gameObjPosition.z
    local offsetY = cubeUpCenterPositionY + TriggerType1OpenOffSetY
    local position = isBlock and Vector3(positionX, cubeUpCenterPositionY, positionZ)
        or Vector3(positionX, offsetY, positionZ)

    triggerObj:SetGameObjectPosition(position)
end

return XRpgMakerGameTriggerData