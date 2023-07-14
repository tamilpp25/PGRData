local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs

local Default = {
    _OpenStatus = 0,       --状态，1开启，0关闭
}

--终点对象
local XRpgMakerGameEndPoint = XClass(XRpgMakerGameObject, "XRpgMakerGameEndPoint")

function XRpgMakerGameEndPoint:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XRpgMakerGameEndPoint:InitData(mapId)
    self.StatusIsChange = false  --新的状态是否和旧的不同
    local endPointId = XRpgMakerGameConfigs.GetRpgMakerGameEndPointId(mapId)
    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameEndPointX(endPointId)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameEndPointY(endPointId)
    local endPointType = XRpgMakerGameConfigs.GetRpgMakerGameEndPointType(endPointId)

    self:SetId(endPointId)
    self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    self:UpdateData({OpenStatus = endPointType})
end

function XRpgMakerGameEndPoint:UpdateData(data)
    self:SetStatusIsChange(self._OpenStatus ~= data.OpenStatus)
    self._OpenStatus = data.OpenStatus
end

function XRpgMakerGameEndPoint:SetStatusIsChange(isChange)
    self.StatusIsChange = isChange
end

function XRpgMakerGameEndPoint:IsOpen()
    return self._OpenStatus == XRpgMakerGameConfigs.XRpgMakerGameEndPointType.DefaultOpen
end

function XRpgMakerGameEndPoint:EndPointOpen()
    self:SetStatusIsChange(true)
    self._OpenStatus = XRpgMakerGameConfigs.XRpgMakerGameEndPointType.DefaultOpen
end

function XRpgMakerGameEndPoint:UpdateObjStatus()
    self:PlayEndPointStatusChangeAction()
end

function XRpgMakerGameEndPoint:PlayEndPointStatusChangeAction(action, cb)
    local modelKey = self:IsOpen() and XRpgMakerGameConfigs.ModelKeyMaps.GoldOpen or XRpgMakerGameConfigs.ModelKeyMaps.GoldClose
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    local sceneObjRoot = self:GetGameObjModelRoot()
    self:LoadModel(modelPath, sceneObjRoot, nil, modelKey)

    if self.StatusIsChange then
        XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_EndPointOpen, XSoundManager.SoundType.Sound)
    end
    
    if cb then
        cb()
    end
end

return XRpgMakerGameEndPoint