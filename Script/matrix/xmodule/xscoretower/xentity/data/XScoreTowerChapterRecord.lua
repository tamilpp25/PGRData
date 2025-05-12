---@class XScoreTowerChapterRecord
local XScoreTowerChapterRecord = XClass(nil, "XScoreTowerChapterRecord")

function XScoreTowerChapterRecord:Ctor()
    self.ChapterId = 0
    self.MaxPoint = 0
end

function XScoreTowerChapterRecord:NotifyScoreTowerChapterRecordData(data)
    self.ChapterId = data.ChapterId or 0
    self.MaxPoint = data.MaxPoint or 0
end

--region 数据获取

function XScoreTowerChapterRecord:GetChapterId()
    return self.ChapterId
end

function XScoreTowerChapterRecord:GetMaxPoint()
    return self.MaxPoint
end

--endregion

return XScoreTowerChapterRecord
