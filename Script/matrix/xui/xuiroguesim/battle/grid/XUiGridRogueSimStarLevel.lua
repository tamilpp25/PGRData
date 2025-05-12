---@class XUiGridRogueSimStarLevel : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimStarLevel = XClass(XUiNode, "XUiGridRogueSimStarLevel")

function XUiGridRogueSimStarLevel:OnStart()
    self.Star = {
        [1] = self.Star1,
        [2] = self.Star2,
        [3] = self.Star3,
    }
    self.Moon = {
        [1] = self.Moon1,
        [2] = self.Moon2,
    }
    self.Sun = {
        [1] = self.Sun,
    }
    self.Levels = {
        [0] = { Stars = 0, Moons = 0, Suns = 0 },
        [1] = { Stars = 1, Moons = 0, Suns = 0 },
        [2] = { Stars = 2, Moons = 0, Suns = 0 },
        [3] = { Stars = 0, Moons = 1, Suns = 0 },
        [4] = { Stars = 1, Moons = 1, Suns = 0 },
        [5] = { Stars = 2, Moons = 1, Suns = 0 },
        [6] = { Stars = 0, Moons = 2, Suns = 0 },
        [7] = { Stars = 1, Moons = 2, Suns = 0 },
        [8] = { Stars = 2, Moons = 2, Suns = 0 },
        [9] = { Stars = 0, Moons = 0, Suns = 1 },
    }
end

---@field curLevel number 当前等级
---@field isMaxLevel boolean 是否最大等级
function XUiGridRogueSimStarLevel:Refresh(curLevel, isMaxLevel)
    self.CurLevel = curLevel
    local level = self.Levels[self.CurLevel]
    -- 星星
    for i = 1, 3 do
        local isOn = i <= level.Stars
        self.Star[i].gameObject:SetActiveEx(isOn or not isMaxLevel)
        self.Star[i]:GetObject("On").gameObject:SetActiveEx(isOn)
        self.Star[i]:GetObject("Off").gameObject:SetActiveEx(not isOn)
    end
    -- 月亮
    for i = 1, 2 do
        self.Moon[i].gameObject:SetActiveEx(i <= level.Moons)
    end
    -- 太阳
    self.Sun[1].gameObject:SetActiveEx(level.Suns == 1)
end

return XUiGridRogueSimStarLevel
