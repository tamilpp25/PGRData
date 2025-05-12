---@class XUidObject
XUidObject = XClass(nil, "XUidObject")

local Uid = 0
local GenUid = function()
    Uid = Uid + 1
    return Uid
end

function XUidObject:Ctor()
    self._Uid = GenUid()
end

function XUidObject:GetUid()
    return self._Uid
end
