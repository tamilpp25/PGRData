local type = type
local pairs = pairs

local Default = {
    _PositionX = 0,
    _PositionY = 0,
}

--二维坐标点，非场景对象的坐标
local XRpgMakerGamePosition = XClass(nil, "XRpgMakerGamePosition")

function XRpgMakerGamePosition:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XRpgMakerGamePosition:UpdatePosition(data)
    if not data then
        return
    end
    if data.PositionX then
        self._PositionX = data.PositionX
    end
    if data.PositionY then
        self._PositionY = data.PositionY
    end
end

function XRpgMakerGamePosition:GetPositionX()
    return self._PositionX
end

function XRpgMakerGamePosition:GetPositionY()
    return self._PositionY
end

function XRpgMakerGamePosition:IsSamePoint(x, y)
    return self._PositionX == x and self._PositionY == y
end

return XRpgMakerGamePosition