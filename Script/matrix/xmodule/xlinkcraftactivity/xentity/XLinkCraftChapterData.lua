---@class XLinkCraftChapterData
local XLinkCraftChapterData = XClass(nil, 'XLinkCraftChapterData')

function XLinkCraftChapterData:Ctor(data)
    self._Id = data.ChapterId
    self._CurLinkId = data.CurLinkId
    self._StageDatas = data.StageDatas
end

function XLinkCraftChapterData:GetChapterId()
    return self._Id
end

function XLinkCraftChapterData:GetCurSelectLinkId()
    return self._CurLinkId
end

function XLinkCraftChapterData:GetStageDataByIndex(index)
    return self._StageDatas[index]
end

function XLinkCraftChapterData:GetStagePassSchedule()
    local count = XMVCA.XLinkCraftActivity:GetStarCntByChapterId(self:GetChapterId())
    local passCount = self:GetAwardedStarCount()

    if count <= 0 then
        count = 1
    end

    if passCount > count then
        passCount = count
    end
    
    return passCount/count
end

function XLinkCraftChapterData:CheckStageIsPassById(stageId)
    for i, v in ipairs(self._StageDatas) do
        if v.StageId == stageId then
            return v.IsPass
        end
    end
end

function XLinkCraftChapterData:GetStageAwardStarById(stageId)
    for i, v in ipairs(self._StageDatas) do
        if v.StageId == stageId then
            if not XTool.IsNumberValid(v.StarNum) then
                return XMVCA.XLinkCraftActivity:GetStarCntSetsByStageId(v.StageId)
            else
                return v.StarNum
            end
        end
    end
    return 0
end

function XLinkCraftChapterData:GetAwardedStarCount()
    local count = 0
    for i, v in ipairs(self._StageDatas) do
        if not XTool.IsNumberValid(v.StarNum) then
            count = count + XMVCA.XLinkCraftActivity:GetStarCntSetsByStageId(v.StageId)
        else
            count = count + v.StarNum
        end
    end
    return count
end

-- 通关数据索引顺序和关卡先后顺序是一致的，后续版本如果出现不一致则需要处理这里的逻辑
function XLinkCraftChapterData:GetLastPassedStageIndex()
    local data = self._StageDatas[#self._StageDatas]
    if data then
        return data.StageId
    end
    return 0
end

return XLinkCraftChapterData