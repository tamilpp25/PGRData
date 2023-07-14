local type = type

--大逃杀章节结果
local XEscapeChapterResult = XClass(nil, "XEscapeChapterResult")

local Default = {
    _ChapterId = 0,
    _Score = 0,          --历史最高积分
}

function XEscapeChapterResult:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XEscapeChapterResult:UpdateData(data)
    self._ChapterId = data.ChapterId
    self._Score = data.Score
end

function XEscapeChapterResult:GetScore()
    return self._Score
end

return XEscapeChapterResult