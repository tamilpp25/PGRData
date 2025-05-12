---@class XDunhuangPainting
local XDunhuangPainting = XClass(nil, "XDunhuangPainting")

function XDunhuangPainting:Ctor()
    self._Id = 0
    self._Icon = false
    self._Name = false
    self._Desc = false
    self._Price = 0

    self._FrameWidth = 0
    self._FrameHeight = 0
    self._Width = 0
    self._Height = 0
    self._MinScale = 0
    self._MaxScale = 0
    self._DefaultScale = 1

    self._Position = Vector2.zero
    self._Scale = 1
    self._FlipX = 0
    self._Rotation = 0

    -- temp
    self._RotationBegin = 0
    self._ScaleBegin = 1
end

function XDunhuangPainting:OnScaleBegin()
    self._RotationBegin = self._Rotation
    self._ScaleBegin = self._Scale
end

function XDunhuangPainting:SetRotationOffset(offsetVector)
    -- 右下角
    ---@type UnityEngine.Vector2
    local vector1 = Vector2(self._Width * self._ScaleBegin / 2, -self._Height * self._ScaleBegin / 2)
    local angleInRadians = math.rad(self._RotationBegin)
    local cos = math.cos(angleInRadians)
    local sin = math.sin(angleInRadians)
    local vector1X = vector1.x * cos - vector1.y * sin
    local vector1Y = vector1.x * sin + vector1.y * cos
    vector1.x = vector1X
    vector1.y = vector1Y

    ---@type UnityEngine.Vector2
    local vector2 = vector1 + offsetVector
    local angle = Vector2.SignedAngle(vector1, vector2)
    self._Rotation = self._RotationBegin + angle
    self._Rotation = self._Rotation % 360

    local length1 = vector1.sqrMagnitude
    local length2 = vector2.sqrMagnitude
    local ratio = math.sqrt(length2 / length1)
    self._Scale = ratio * self._ScaleBegin
    self._Scale = XMath.Clamp(self._Scale, self._MinScale, self._MaxScale)
end

function XDunhuangPainting:SetPos(x, y)
    self._Position.x = x
    self._Position.y = y
end

function XDunhuangPainting:SetPosOffset(offsetX, offsetY)
    self._Position.x = self._Position.x + offsetX
    self._Position.y = self._Position.y + offsetY
    if self._FrameHeight ~= 0 and self._FrameWidth ~= 0 then
        self._Position.x = XMath.Clamp(self._Position.x, -self._FrameWidth / 2, self._FrameWidth / 2)
        self._Position.y = XMath.Clamp(self._Position.y, -self._FrameHeight / 2, self._FrameHeight / 2)
    else
        XLog.Error("[XDunhuangPainting] 画布尺寸设置有误")
    end
end

function XDunhuangPainting:GetPos()
    return self._Position.x, self._Position.y
end

function XDunhuangPainting:GetFlipX()
    return self._FlipX
end

function XDunhuangPainting:SetFlipX(value)
    self._FlipX = value
end

function XDunhuangPainting:DoFlipX()
    if self._FlipX == 1 then
        self._FlipX = 0
    else
        self._FlipX = 1
    end
    --self._Rotation = (-self._Rotation) % 360
end

function XDunhuangPainting:SetRotation(rotation)
    self._Rotation = rotation
end

function XDunhuangPainting:GetDataToSave()
    ---@class XDunhuangPaintingSaveData
    local data = {
        Id = self._Id,
        X = math.floor(self._Position.x),
        Y = math.floor(self._Position.y),
        Scale = self._Scale,
        FlipX = self._FlipX,
        Rotation = math.floor(self._Rotation),
    }
    return data
end

function XDunhuangPainting:GetDataToDraw()
    ---@class XDunhuangPaintingDrawData:XDunhuangPaintingSaveData
    local dataToSave = self:GetDataToSave()
    dataToSave.Icon = self:GetIcon()
    dataToSave.Width = self._Width * self._Scale
    dataToSave.Height = self._Height * self._Scale
    dataToSave.OriginalWidth = self._Width
    dataToSave.OriginalHeight = self._Height
    dataToSave.IsOnTop = false
    return dataToSave
end

---@param data XDunhuangPaintingSaveData
function XDunhuangPainting:SetDataFromSave(data)
    self._Id = data.Id
    self._Position.x = data.X
    self._Position.y = data.Y
    self._Scale = data.Scale
    self._FlipX = data.FlipX
    self._Rotation = data.Rotation
end

---@param painting XDunhuangPainting
function XDunhuangPainting:Equals(painting)
    if not painting then
        return false
    end
    return self._Id == painting:GetId()
end

function XDunhuangPainting:GetId()
    return self._Id
end

function XDunhuangPainting:SetId(id)
    self._Id = id
end

function XDunhuangPainting:SetFrameSize(frameWidth, frameHeight)
    self._FrameWidth = frameWidth
    self._FrameHeight = frameHeight
end

function XDunhuangPainting:SetDataFromConfig(config, frameWidth, frameHeight)
    self:SetId(config.Id)
    self._Icon = config.Icon
    self._Name = config.Name
    self._Desc = config.Desc
    self._Price = config.Price

    self._Width = config.Width
    self._Height = config.Height
    self._Scale = config.DefaultScale
    self._DefaultScale = config.DefaultScale
    self._MinScale = CS.XGame.ClientConfig:GetFloat("DunhuangPaintingMinScale")
    self._MaxScale = CS.XGame.ClientConfig:GetFloat("DunhuangPaintingMaxScale")

    self._FrameWidth = frameWidth
    self._FrameHeight = frameHeight
    self:SetFrameSize(frameWidth, frameHeight)

    if XMain.IsEditorDebug then
        if self._Scale < self._MinScale then
            XLog.Error("[XDunhuangPainting] 默认尺寸小于最小尺寸")
        end
    end
end

function XDunhuangPainting:GetIcon()
    return self._Icon
end

function XDunhuangPainting:GetName()
    return self._Name
end

function XDunhuangPainting:_GetNewPaintingKey(id)
    return "DunhuangPaintingNew2" .. XPlayer.Id .. id
end

function XDunhuangPainting:IsNewPainting()
    local id = self:GetId()
    local data = XSaveTool.GetData(self:_GetNewPaintingKey(id))
    if data == nil then
        return true
    end
end

function XDunhuangPainting:SetPaintingNotNew()
    local id = self:GetId()
    XSaveTool.SaveData(self:_GetNewPaintingKey(id), true)
end

function XDunhuangPainting:GetDesc()
    return self._Desc
end

function XDunhuangPainting:GetPrice()
    return self._Price
end

function XDunhuangPainting:IsAfford()
    return XDataCenter.ItemManager.CheckItemCountById(XDataCenter.ItemManager.ItemId.MuralShareCoin, self:GetPrice())
end

function XDunhuangPainting:ClearDataOnGame()
    self._Position = Vector2.zero
    self._Scale = self._DefaultScale
    self._FlipX = 0
    self._Rotation = 0
end

return XDunhuangPainting
