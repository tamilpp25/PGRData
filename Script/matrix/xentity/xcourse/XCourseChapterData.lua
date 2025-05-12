local XCourseChapterData = XClass(nil, "XCourseChapterData")

local Default = {
    _Id = 0,
    _IsClear = false,
    _TotalPoint = 0     --课程或考级已获得的总点数
}

function XCourseChapterData:Ctor()
    self._Id = 0
    self._IsClear = false
    self._TotalPoint = 0
end

function XCourseChapterData:UpdateData(data)
    self._Id = data.Id
    self._IsClear = data.IsClear
    self._TotalPoint = data.TotalPoint
end

function XCourseChapterData:GetIsClear()
    return self._IsClear
end

function XCourseChapterData:GetTotalPoint()
    return self._TotalPoint
end

return XCourseChapterData