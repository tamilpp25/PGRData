local type = type
local pairs = pairs

local Default = {
    _Id = 0,
    _Unlock = false, --已解锁
}

local XAreaWarPlugin = XClass(nil, "XAreaWarPlugin")

function XAreaWarPlugin:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XAreaWarPlugin:Unlock()
    self._Unlock = true
end

function XAreaWarPlugin:IsUnlock()
    return self._Unlock
end

return XAreaWarPlugin
