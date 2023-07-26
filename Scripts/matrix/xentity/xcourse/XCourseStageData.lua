local XCourseStageData = XClass(nil, "XCourseStageData")

function XCourseStageData:Ctor()
    self._Id = 0
    self._StarsFlag = 0
end

function XCourseStageData:UpdateData(data)
    self._Id = data.Id
    self._StarsFlag = data.StarsFlag
end

function XCourseStageData:GetStarsFlag()
    return self._StarsFlag
end

return XCourseStageData