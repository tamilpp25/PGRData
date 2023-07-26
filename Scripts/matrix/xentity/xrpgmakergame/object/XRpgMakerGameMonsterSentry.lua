local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")
local XRpgMakerGameMonsertSentryRoand = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameMonsertSentryRoand")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local LastOneRound = 1      --指示物停留的最后一回合

local Default = {
    _SentryStartPositionX = 0,  --移动前怪物所在的X坐标
    _SentryStartPositionY = 0,  --移动前怪物所在的Y坐标
    _SentryEndPositionX = 0,    --结束停留下回合移动到哨戒指示物的X坐标
    _SentryEndPositionY = 0,    --结束停留下回合移动到哨戒指示物的Y坐标
    _SentryStartRound = 0,      --开始停留的回合数
}

--哨戒指示物
local XRpgMakerGameMonsterSentry = XClass(XRpgMakerGameObject, "XRpgMakerGameMonsterSentry")

function XRpgMakerGameMonsterSentry:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.SentryRoand = XRpgMakerGameMonsertSentryRoand.New()
end

function XRpgMakerGameMonsterSentry:Dispose()
    self.SentryRoand:Dispose()
    XRpgMakerGameMonsterSentry.Super.Dispose(self)
end

function XRpgMakerGameMonsterSentry:Load(position)
    if self:IsShowNextRoundSentry() then
        local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.Sentry
        local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        local x = self:InFirstRoundCreate() and self._SentryEndPositionX or self._SentryStartPositionX
        local y = self:InFirstRoundCreate() and self._SentryEndPositionY or self._SentryStartPositionY
        local cubeObj = self:GetCubeTransform(y, x)
        local objPos = self:GetCubeUpCenterPosition(y, x)
        self:LoadModel(modelPath, cubeObj, nil, modelKey)      --特效绑定在cube上，绑定在怪物上会被改变旋转角度
        self:SetGameObjectPosition(objPos)
    end

    if self:IsShowLastStopRound() then
        self.SentryRoand:Load(position, self._SentryEndPositionY, self._SentryEndPositionX)
    end
end

function XRpgMakerGameMonsterSentry:UpdateData(data)
    self._SentryStartPositionX = data.SentryStartPositionX or 0
    self._SentryStartPositionY = data.SentryStartPositionY or 0
    self._SentryEndPositionX = data.SentryEndPositionX or 0
    self._SentryEndPositionY = data.SentryEndPositionY or 0
    self._SentryStartRound = data.SentryStartRound or 0
end

--获得指示物消失时是第几回合
function XRpgMakerGameMonsterSentry:GetClearRound()
    if self._SentryStartRound <= 0 then
        return 0
    end

    local monsterId = self:GetId()
    local stopRound = XRpgMakerGameConfigs.GetRpgMakerGameSentryStopRound(monsterId)
    return self._SentryStartRound + stopRound
end

--获得指示物剩余停留回合数
function XRpgMakerGameMonsterSentry:GetLastStopRound()
    local clearRound = self:GetClearRound()
    local curRound = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    return clearRound - curRound
end

function XRpgMakerGameMonsterSentry:IsCreateSentry()
    local curRound = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    local clearRound = self:GetClearRound()
    return clearRound > curRound
end

--是否显示指示物剩余停留回合数，生成的那一回合不显示
function XRpgMakerGameMonsterSentry:IsShowLastStopRound()
    local curRound = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    return self._SentryStartRound <= curRound and self:GetLastStopRound() > 0
end

function XRpgMakerGameMonsterSentry:InFirstRoundCreate()
    local curRound = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    return self._SentryStartRound > curRound
end

--是否显示下一回合，模型要移动的目的地指示物
function XRpgMakerGameMonsterSentry:IsShowNextRoundSentry()
    return self:InFirstRoundCreate() or self:GetLastStopRound() == LastOneRound
end

function XRpgMakerGameMonsterSentry:GetSentryRoandGameObjPosition()
    local transform = self.SentryRoand:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local centerPoint = transform:Find("GameObject/background")
    if XTool.UObjIsNil(centerPoint) then
        XLog.Error("找不到哨戒挂点，检查预制体上是否有GameObject/background")
        return
    end
    
    return centerPoint.transform.position
end

return XRpgMakerGameMonsterSentry