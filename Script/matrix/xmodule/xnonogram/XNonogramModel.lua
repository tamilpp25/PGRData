local XNonogramDataDb = require("XModule/XNonogram/DataEntity/XNonogramDataDb")
local XNonogramConfigModel = require("XModule/XNonogram/XNonogramConfigModel")

---@class XNonogramModel : XNonogramConfigModel
---@field _NonogramData XNonogramDataDb
local XNonogramModel = XClass(XNonogramConfigModel, "XNonogramModel")
function XNonogramModel:OnInit()
    self.Super.OnInit(self)
    self._NonogramData = nil
    self._CurGameChapterId = 0
end

function XNonogramModel:ClearPrivate()
    self._CurGameChapterId = 0
end

function XNonogramModel:ResetAll()
    self._NonogramData = nil
end


--region Getter
function XNonogramModel:GetNonogramData()
    if not self._NonogramData then
        self._NonogramData = XNonogramDataDb.New()
    end

    return self._NonogramData
end

function XNonogramModel:GetCurActivityId()
    return self._NonogramData:GetActivityId()
end

function XNonogramModel:GetChapterDataDir()
    return self._NonogramData:GetChapterDir()
end

function XNonogramModel:GetChapterData(chapterId)
    if XTool.IsNumberValid(chapterId) then
        return self._NonogramData:GetChapterInfo(chapterId)
    end

    return nil
end

function XNonogramModel:GetCurGameChapterId()
    return self._CurGameChapterId
end

function XNonogramModel:GetCurGameStageId()
    if not self._CurGameChapterId then
        return 0
    end

    ---@type XNonogramChapter
    local chapterData = self:GetChapterData(self._CurGameChapterId)
    if not chapterData then
        return 0
    end

    return chapterData:GetCurStageId()
end
--endregion

--region Setter
function XNonogramModel:UpdateNonogramData(data)
    if not self._NonogramData then
        self._NonogramData = XNonogramDataDb.New()
    end

    self._NonogramData:UpdateData(data)
end

function XNonogramModel:UpdateChapterData(data)
    if not self._NonogramData then
        return
    end

    self._NonogramData:UpdateChapterData(data)
end

function XNonogramModel:SetCurGameChapterId(chapterId)
    self._CurGameChapterId = chapterId
end
--endregion

--region Checker

function XNonogramModel:CheckChapterUnLock(chapterId)
    ---@type XNonogramChapter
    local chapterData = self:GetChapterData(chapterId)
    if not chapterData then
        if self:CheckChapterIsRebrushById(chapterId) then
            return true
        end

        return false
    end

    return chapterData:GetChapterStatus() ~= XEnumConst.Nonogram.NonogramChapterStatus.Lock
end

function XNonogramModel:CheckChapterIsRebrushById(chapterId)
    return self:GetChapterIsRebrushById(chapterId)
end

--endregion

return XNonogramModel