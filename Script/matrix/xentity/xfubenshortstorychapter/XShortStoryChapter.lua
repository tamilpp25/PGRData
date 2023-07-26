local type = type
local pairs = pairs

local Default = {
    _Id = 0,
    _Unlock = false, --false 未解锁 、 true 已解锁
    _IsOpen = false,
}

local XShortStoryChapter = XClass(nil,"XShortStoryChapter")

function XShortStoryChapter:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XShortStoryChapter:Change(isUnlock, isOpen)
    self._Unlock = isUnlock
    self._IsOpen = isOpen
end

function XShortStoryChapter:IsUnlock()
    return self._Unlock
end

function XShortStoryChapter:IsOpen()
    return self._IsOpen
end

return XShortStoryChapter