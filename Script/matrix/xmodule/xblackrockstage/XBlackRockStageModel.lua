---@class XBlackRockStageModel : XModel
local XBlackRockStageModel = XClass(XModel, "XBlackRockStageModel")

function XBlackRockStageModel:OnInit()
    self._UiData = {
        IsSkipMovie = nil,
        ---@type XBlackRockStageModelStageData[]
        StageList = nil,
        ChapterId = nil,
    }
end

function XBlackRockStageModel:ClearPrivate()
    self._UiData = {}
end

function XBlackRockStageModel:ResetAll()
    -- nothing to reset
end

----------public start----------
function XBlackRockStageModel:IsOpen()
    local chapterId = XEnumConst.BLACK_ROCK.STAGE.FESTIVAL_ACTIVITY_ID
    ---@type XFestivalChapter
    local chapter = XDataCenter.FubenFestivalActivityManager.GetFestivalChapterById(chapterId)
    if not chapter then
        return false
    end
    return chapter:GetIsOpen()
end

function XBlackRockStageModel:UpdateUiData()
    if not self._UiData then
        self._UiData = {}
    end
    local uiData = self._UiData
    local saveKey = self:_GetKeySkipMovie()
    uiData.IsSkipMovie = XSaveTool.GetData(saveKey)

    if not uiData.ChapterId then
        uiData.ChapterId = XEnumConst.BLACK_ROCK.STAGE.FESTIVAL_ACTIVITY_ID
    end

    ---@type XFestivalChapter
    local chapter = XDataCenter.FubenFestivalActivityManager.GetFestivalChapterById(uiData.ChapterId)
    local stageIdList = chapter:GetStageIdList()
    local stageList = {}
    for i = 1, #stageIdList do
        local stageId = stageIdList[i]
        local stage = chapter:GetStageByStageId(stageId)
        ---@class XBlackRockStageModelStageData
        local t = {
            StageId = stageId,
            IsOpen = stage:GetIsOpen(),
        }
        stageList[i] = t
    end
    uiData.StageList = stageList
end

function XBlackRockStageModel:GetStageProgress()
    ---@type XFestivalChapter
    local chapter = XDataCenter.FubenFestivalActivityManager.GetFestivalChapterById(XEnumConst.BLACK_ROCK.STAGE.FESTIVAL_ACTIVITY_ID)
    local stageIdList = chapter:GetStageIdList()
    local amount = 0
    local stageAmount = #stageIdList
    for i = 1, stageAmount do
        local stageId = stageIdList[i]
        if XMVCA.XFuben:CheckStageIsPass(stageId) then
            amount = amount + 1
        end
    end
    return amount, stageAmount
end

function XBlackRockStageModel:GetUiData()
    return self._UiData
end

function XBlackRockStageModel:SetSkipMovie(value)
    if self._KeyIsSkipMovie ~= value then
        self._KeyIsSkipMovie = value
        XSaveTool.SaveData(self._KeyIsSkipMovie, value)
    end
end

----------public end----------

----------private start----------

function XBlackRockStageModel:_GetKeySkipMovie()
    return "XBlackRockStageSkipMovie" .. XPlayer.Id
end

----------private end----------

----------config start----------
function XBlackRockStageModel:_GetFestivalActivityConfig()
    return XFestivalActivityConfig.GetFestivalById(XEnumConst.BLACK_ROCK.STAGE.FESTIVAL_ACTIVITY_ID)
end
----------config end----------


return XBlackRockStageModel