local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs

local Default = {
    _BlockStatus = 0,       --状态，1阻挡，0不阻挡
}

--阻挡物对象
local XRpgMakerGameBlock = XClass(XRpgMakerGameObject, "XRpgMakerGameBlock")

function XRpgMakerGameBlock:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

return XRpgMakerGameBlock