---@class XBigWorldTeachControl : XControl
---@field private _Model XBigWorldTeachModel
local XBigWorldTeachControl = XClass(XControl, "XBigWorldTeachControl")

function XBigWorldTeachControl:OnInit()
    -- 初始化内部变量
    self._LastGroupId = 1
end

function XBigWorldTeachControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldTeachControl:RemoveAgencyEvent()

end

function XBigWorldTeachControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

function XBigWorldTeachControl:GetTeachTitleByTeachId(teachId)
    return self._Model:GetBigWorldHelpCourseNameById(teachId)
end

function XBigWorldTeachControl:GetTeachContentImageByTeachContentId(teachContentId)
    return self._Model:GetBigWorldHelpCourseDetailImageById(teachContentId)
end

---@return XTableBigWorldHelpCourseGroup[]
function XBigWorldTeachControl:GetTeachGroupConfigs()
    return self._Model:GetBigWorldHelpCourseGroupConfigs()
end

function XBigWorldTeachControl:GetTeachContentDescByTeachIdAndIndex(teachId, index)
    local content = self._Model:GetTeachContentByTeachIdAndIndex(teachId, index)

    return content and XUiHelper.ReplaceTextNewLine(content.Desc) or ""
end

function XBigWorldTeachControl:GetTeachContentIdByTeachIdAndIndex(teachId, index)
    local content = self._Model:GetTeachContentByTeachIdAndIndex(teachId, index)

    return content and content.Id or 0
end

function XBigWorldTeachControl:GetTeachContentCountByTeachId(teachId)
    local contents = self._Model:GetTeachContentsByTeachId(teachId)

    return table.nums(contents)
end

function XBigWorldTeachControl:GetTeachsByGroupId(groupId)
    return self._Model:GetTeachsByGroupId(groupId)
end

function XBigWorldTeachControl:GetUnlockTeachsByGroupId(groupId)
    local result = {}
    local teachs = self:GetTeachsByGroupId(groupId)

    if groupId ~= self._LastGroupId then
        if not XTool.IsTableEmpty(teachs) then
            for _, teach in pairs(teachs) do
                if self:CheckTeachIsUnlock(teach.Id) then
                    table.insert(result, teach)
                end
            end
        end
    else
        teachs = self._Model:GetTeachLatestList()

        for _, teach in pairs(teachs) do
            if self:CheckTeachIsUnlock(teach.Id) then
                local config = self._Model:GetBigWorldHelpCourseConfigById(teach.Id)

                table.insert(result, config)
            end
        end
    end

    table.sort(result, function(teachA, teachB)
        return self:CheckTeachReadPriority(teachA, teachB)
    end)

    return result
end

function XBigWorldTeachControl:CheckHasUnReadTeachByGroupId(groupId)
    local teachs = self:GetUnlockTeachsByGroupId(groupId)

    if not XTool.IsTableEmpty(teachs) then
        for _, teach in pairs(teachs) do
            if not self:CheckTeachIsRead(teach.Id) then
                return true
            end
        end
    end

    return false
end

function XBigWorldTeachControl:GetTeachLatestValue()
    return self._Model:GetTeachLatestValue()
end

function XBigWorldTeachControl:GetSearchTeachName(searchName, searchKey)
    if string.IsNilOrEmpty(searchKey) then
        return searchName
    end

    local highlight = XMVCA.XBigWorldService:GetText("TeachHighlightColor", searchKey)

    return string.gsub(searchName, searchKey, highlight)
end

function XBigWorldTeachControl:GetTeachTipShowTime()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("TeachTipShowTime")
end

function XBigWorldTeachControl:GetTeachUnlockTime(teachId)
    if not XTool.IsNumberValid(teachId) then
        return 0
    end

    return self._Model:GetTeachUnlockTime(teachId)
end

function XBigWorldTeachControl:CheckTeachContentIsVideo(teachContentId)
    local image = self:GetTeachContentImageByTeachContentId(teachContentId)

    return string.IsNilOrEmpty(image)
end

function XBigWorldTeachControl:CheckTeachPriority(teachAConfig, teachBConfig)
    if teachAConfig.Priority == teachBConfig.Priority then
        return teachAConfig.Id > teachBConfig.Id
    end

    return teachAConfig.Priority > teachBConfig.Priority
end

function XBigWorldTeachControl:CheckTeachUnlockTimePriority(teachAConfig, teachBConfig)
    local unlockTime = self:GetTeachUnlockTime(teachAConfig.Id)
    local unlockTimeB = self:GetTeachUnlockTime(teachBConfig.Id)

    if unlockTime == unlockTimeB then
        return self:CheckTeachPriority(teachAConfig, teachBConfig)
    end

    return unlockTime > unlockTimeB
end

function XBigWorldTeachControl:CheckTeachReadPriority(teachAConfig, teachBConfig)
    local isARead = self:CheckTeachIsRead(teachAConfig.Id)
    local isBRead = self:CheckTeachIsRead(teachBConfig.Id)

    if (isARead and isBRead) or (not isARead and not isBRead) then
        return self:CheckTeachUnlockTimePriority(teachAConfig, teachBConfig)
    end

    return not isARead
end

function XBigWorldTeachControl:CheckTeachIsRead(teachId)
    return self._Model:CheckTeachIsRead(teachId)
end

function XBigWorldTeachControl:CheckTeachIsUnlock(teachId)
    return self._Model:CheckTeachIsUnlock(teachId)
end

function XBigWorldTeachControl:SearchTeach(searchKey)
    local result = {}
    local teachs = self._Model:GetBigWorldHelpCourseConfigs()

    for _, teach in pairs(teachs) do
        if string.find(teach.Name, searchKey, 1, false) and self:CheckTeachIsUnlock(teach.Id) then
            table.insert(result, teach)
        end
    end

    table.sort(result, function(teachA, teachB)
        return self:CheckTeachReadPriority(teachA, teachB)
    end)

    return result
end

function XBigWorldTeachControl:ReadTeach(teachId, callback)
    if self:CheckTeachIsUnlock(teachId) then
        if not self:CheckTeachIsRead(teachId) then
            self:RequestBigWorldHelpCourseRead(teachId, callback)
        end
    end
end

function XBigWorldTeachControl:RequestBigWorldHelpCourseRead(teachId, callback)
    XNetwork.Call("BigWorldHelpCourseReadRequest", {
        CourseId = teachId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateTeachDataRead(teachId)

        if callback then
            callback()
        end

        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_READ)
    end)
end

return XBigWorldTeachControl
