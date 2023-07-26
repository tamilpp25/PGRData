---@class XPlanetWeatherGroup
local XPlanetWeatherGroup = XClass(nil, "XPlanetWeatherGroup")

function XPlanetWeatherGroup:Ctor()
    self._GroupId = 0
    self._CurWeather = 0
    self._CurWeatherEndRound = 0    -- 当前天气结束的回合
    self._AllRoundDuration = 0      -- 天气组循环长度
    self._RoundWeatherDir = {}      -- 正常天气组字典 key = 回合 value = weatherId
    self._TempRoundWeatherDir = {}  -- 事件天气组字典 key = 回合 value = weatherId
    self._WeatherDir = {}           -- 该组天气序列(去重)
end

function XPlanetWeatherGroup:InitGroup(groupId)
    self._GroupId = groupId

    local round = 1
    for _, id in ipairs(XPlanetStageConfigs.GetWeatherGroup(self._GroupId)) do
        local weatherId = XPlanetStageConfigs.GetWeatherGroupWeatherId(id)
        local duration = XPlanetStageConfigs.GetWeatherGroupDuration(id)
        self._AllRoundDuration = self._AllRoundDuration + duration
        for i = round, self._AllRoundDuration do
            self._RoundWeatherDir[i] = weatherId
        end
        round = round + duration
        if not table.indexof(self._WeatherDir, weatherId) then
            table.insert(self._WeatherDir, weatherId)
        end
    end
    self:CleatTempWeatherDir()
end

-- 正常更新当前天气队列
function XPlanetWeatherGroup:UpdateCurWeatherByRound(round)
    local unitRound = round % self:GetGroupWeatherAllDuration()
    if unitRound == 0 then
        unitRound = self:GetGroupWeatherAllDuration()
    end
    local _, nextWeatherRound = self:GetNextWeatherAndRoundByCurRound(round)
    local curRoundWeatherId = self._RoundWeatherDir[unitRound] -- 当前天气回合等级
    
    self:SetCurWeather(curRoundWeatherId)
    self:SetCurWeatherEndRound(nextWeatherRound)
    return nextWeatherRound
end

-- 更新事件天气队列
function XPlanetWeatherGroup:UpdateTempWeather(weatherId, curRound, endRound)
    self:CleatTempWeatherDir()
    for i = curRound, endRound do
        self._TempRoundWeatherDir[i] = weatherId
    end
end

function XPlanetWeatherGroup:GetNextWeatherAndRoundByCurRound(round)
    local unitRound = round % self:GetGroupWeatherAllDuration()
    if unitRound == 0 then
        unitRound = self:GetGroupWeatherAllDuration()
    end
    local nextWeather = 0
    local nextWeatherRound = 0
    local curRoundWeatherId = self._CurWeather -- 当前天气
    if XTool.IsTableEmpty(self._TempRoundWeatherDir) then
        for i = unitRound, self._AllRoundDuration do
            if curRoundWeatherId ~= self._RoundWeatherDir[i] then
                nextWeather = self._RoundWeatherDir[i]
                nextWeatherRound = round + i - unitRound
                break
            end
            if curRoundWeatherId == self._RoundWeatherDir[i] and i == self._AllRoundDuration then
                nextWeather = self._RoundWeatherDir[1]
                nextWeatherRound = round + i - unitRound + 1
                break
            end
        end
    else
        nextWeatherRound = self._CurWeatherEndRound + 1
        local nextUnitRound = nextWeatherRound % self:GetGroupWeatherAllDuration()
        if nextUnitRound == 0 then
            nextUnitRound = self:GetGroupWeatherAllDuration()
        end
        nextWeather = self._RoundWeatherDir[nextUnitRound]
    end
    
    if XTool.IsNumberValid(nextWeather) then
        return nextWeather, nextWeatherRound
    end
    return self._WeatherDir[1], round + 1
end

function XPlanetWeatherGroup:SetCurWeather(weatherId)
    self._CurWeather = weatherId
end

function XPlanetWeatherGroup:SetCurWeatherEndRound(round)
    self._CurWeatherEndRound = round
end

function XPlanetWeatherGroup:GetCurWeather()
    return self._CurWeather
end

function XPlanetWeatherGroup:GetCurWeatherEndRound()
    return self._CurWeatherEndRound
end

function XPlanetWeatherGroup:GetCurWeatherIndex()
    local index =table.indexof(self._WeatherDir, self._CurWeather)
    if not index then
        index = 1
        XLog.Error("当前天气Id不存在当前Stage的WeatherGroupId内 WeatherId = "..self._CurWeather.." WeatherGroupId = "..self._GroupId)
    end
    return index
end

function XPlanetWeatherGroup:GetWeatherByIndex(index)
    return self._WeatherDir[index]
end

function XPlanetWeatherGroup:GetGroupWeatherList()
    return self._WeatherDir
end

function XPlanetWeatherGroup:GetGroupWeatherAllDuration()
    return self._AllRoundDuration
end

function XPlanetWeatherGroup:CleatTempWeatherDir()
    self._TempRoundWeatherDir = {}
end

return XPlanetWeatherGroup