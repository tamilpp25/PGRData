local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3

--陷阱对象
local XRpgMakerGameTrap = XClass(XRpgMakerGameObject, "XRpgMakerGameTrap")

function XRpgMakerGameTrap:Ctor(id, gameObject)

end

return XRpgMakerGameTrap