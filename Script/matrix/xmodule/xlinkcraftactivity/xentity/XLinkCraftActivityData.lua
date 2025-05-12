---@class XLinkCraftActivityData
local XLinkCraftActivityData = XClass(nil, 'XLinkCraftActivityData')
local XLinkCraftChapterData = require('XModule/XLinkCraftActivity/XEntity/XLinkCraftChapterData')
local XLinkListData = require('XModule/XLinkCraftActivity/XEntity/XLinkListData')

function XLinkCraftActivityData:Ctor(data)
    self._CurActivityId = data.ActivityId
    self._UnlockSkillSet = data.Skills

    --初始化章节数据
    self._ChapterDataList = {}
    for i, v in ipairs(data.ChapterDatas) do
        local chapterData = XLinkCraftChapterData.New(v)
        table.insert(self._ChapterDataList, chapterData)
    end
    self._CurChapterData = nil
    
    --初始化链条数据
    self._LinkDataList = {}
    for i, v in ipairs(data.LinkDatas) do
        local linkData = XLinkListData.New(v)
        table.insert(self._LinkDataList, linkData)
    end
end

function XLinkCraftActivityData:GetCurActivityId()
    return self._CurActivityId
end

function XLinkCraftActivityData:CheckSkillInUnLockSetById(skillId)
    if not XTool.IsTableEmpty(self._UnlockSkillSet) then
        return table.contains(self._UnlockSkillSet, skillId)
    end
    return false
end

--region 章节数据
function XLinkCraftActivityData:SetCurChapterById(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        self._CurChapterData = nil
        return
    end
    for i, v in ipairs(self._ChapterDataList) do
        if v:GetChapterId() == chapterId then
            self._CurChapterData = v
            break
        end
    end
end

---@return XLinkCraftChapterData
function XLinkCraftActivityData:GetCurChapterData()
    return self._CurChapterData
end

function XLinkCraftActivityData:GetCurChapterId()
    return self._CurChapterData and self._CurChapterData:GetChapterId() or 0
end

function XLinkCraftActivityData:CheckIsInChapter()
    return self._CurChapterData ~= nil
end

---@return XLinkCraftChapterData
function XLinkCraftActivityData:GetChapterDataById(chapterId)
    for i, v in ipairs(self._ChapterDataList) do
        if v:GetChapterId() == chapterId then
            return v
        end
    end
end

function XLinkCraftActivityData:GetChapterIdByIndex(index)
    if self._ChapterDataList[index] then
        return self._ChapterDataList[index]:GetChapterId()
    end
    return 0
end

function XLinkCraftActivityData:GetTotalStarAward()
    local starCount = 0

    for i, v in ipairs(self._ChapterDataList) do
        starCount = starCount + v:GetAwardedStarCount()
    end
    
    return starCount
end

--endregion

--region 链条数据

---@return XLinkListData
function XLinkCraftActivityData:GetLinkDataById(linkId)
    for i, v in ipairs(self._LinkDataList) do
        if v:GetId() == linkId then
            return v
        end
    end
end

---@return XLinkListData
function XLinkCraftActivityData:GetCurLinkdData()
    if self:CheckIsInChapter() then
        local curLinkId = self:GetCurChapterData():GetCurSelectLinkId()
        return self:GetLinkDataById(curLinkId)
    end
end
--endregion

return XLinkCraftActivityData