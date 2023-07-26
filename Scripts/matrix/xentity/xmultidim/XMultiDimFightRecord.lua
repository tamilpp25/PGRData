local type = type
local pairs = pairs

--[[
public class XMultiDimFightRecord
{
    public int ThemeId;

    //最高积分
    public int Point;
}
]]

local Default = {
    _ThemeId = 0, -- 主题id
    _Point = 0, -- 最高积分
}

---@class XMultiDimFightRecord
local XMultiDimFightRecord = XClass(nil, "XMultiDimFightRecord")

function XMultiDimFightRecord:Ctor(themeId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    
    self._ThemeId = themeId
end

function XMultiDimFightRecord:UpdatePoint(point)
    if XTool.IsNumberValid(point) then
        self._Point = point
    end
end

-- 多维积分
function XMultiDimFightRecord:GetPoint()
    return self._Point
end

return XMultiDimFightRecord