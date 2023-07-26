
----------------------------------------------------------------
--主线跑团珍藏-回忆红点检测
local XRedPointTRPGCollectionMemoir = {}
local Events = nil

function XRedPointTRPGCollectionMemoir.GetSubEvents()
    if not Events then
        local redPointEventElementList = {}
        local memoirStoryTemplate = XTRPGConfigs.GetMemoirStoryTemplate()
        local unlockItemId
        local aleardyUnlockItemIdList = {}
        for id in pairs(memoirStoryTemplate) do
            unlockItemId = XTRPGConfigs.GetMemoireStoryUnlockItemId(id)
            if not aleardyUnlockItemIdList[unlockItemId] then
                table.insert(redPointEventElementList, XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. unlockItemId))
                aleardyUnlockItemIdList[unlockItemId] = 1
            end
        end
        table.insert(redPointEventElementList, XRedPointEventElement.New(XEventId.EVENT_TRPG_GET_MEMOIR_REWARD))
        table.insert(redPointEventElementList, XRedPointEventElement.New(XEventId.EVENT_TRPG_FIRST_OPEN_COLLECTION))
        Events = redPointEventElementList
    end
    return Events
end

function XRedPointTRPGCollectionMemoir.Check()
    local ret = XTRPGConfigs.CheckButtonCondition(XTRPGConfigs.ButtonConditionId.Collection)
    if not ret then
        return false
    end

    if not XDataCenter.TRPGManager.CheckIsAlreadyOpenCollection() then
        return true
    end
    return XDataCenter.TRPGManager.CheckFirstPlayMemoirStory()
end

return XRedPointTRPGCollectionMemoir