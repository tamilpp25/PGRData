local XActivityBrieIsOpen = require("XUi/XUiActivityBrief/XActivityBrieIsOpen")
----------------------------------------------------------------
--间章剧情：有可挑战关卡

local XRedPointConditionPrequel = {}
local Events = nil
function XRedPointConditionPrequel.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_STAGE_SYNC),
    }
    return Events
end

function XRedPointConditionPrequel.Check(args)
    local isOpen = XActivityBrieIsOpen.Get(args.activityGroupId)
    if isOpen then
        return XRedPointConditionPrequel.CheckIsNew(args.chapterId)
    else
        return false
    end
end

function XRedPointConditionPrequel.CheckIsNew(chapterId)
    local chapter = XPrequelConfigs.GetPrequelChapterById(chapterId)

    local stageIds = chapter.StageId
    for i,stageId in ipairs(stageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if XDataCenter.PrequelManager.CheckPrequelStageOpen(stageId) and not stageInfo.Passed then
            return true
        end
    end
end


return XRedPointConditionPrequel