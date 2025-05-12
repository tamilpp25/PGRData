---@class XNonogramAgency : XAgency
---@field private _Model XNonogramModel
local XNonogramAgency = XClass(XAgency, "XNonogramAgency")

local NonogramProto = {
    NonogramChapterUnlockRequest = "NonogramChapterUnlockRequest", -- 解锁关卡
    NonogramChapterStartRequest = "NonogramChapterStartRequest", -- 开始章节
    NonogramFinishStageRequest = "NonogramFinishStageRequest", -- 关卡结算
    NonogramUnlockCgRequest = "NonogramUnlockCgRequest", -- 解锁cg
    NonogramChapterExitRequest = "NonogramChapterExitRequest", -- 章节退出
}

function XNonogramAgency:OnInit()

end

function XNonogramAgency:InitRpc()
    XRpc.NotifyNonogramData = function(res)
        if res and res.NonogramData then
            self:_UpdateNonogramData(res.NonogramData)
        end
    end
end

function XNonogramAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region 公共接口
function XNonogramAgency:EnterActivity()
    if not XTool.IsNumberValid(self:GetCurActivityId()) then
        return
    end

    XLuaUiManager.Open("UiNonogramMain")
end

function XNonogramAgency:GetCurActivityId()
    local nonogramData = self._Model:GetNonogramData()
    if not nonogramData then
        return
    end

    return nonogramData:GetActivityId()
end

function XNonogramAgency:CheckChapterUnLock(chapterId)
    return self._Model:CheckChapterUnLock(chapterId)
end

function XNonogramAgency:GetChapterState(chapterId)
    ---@type XNonogramChapter
    local chapterData = self._Model:GetChapterData(chapterId)
    if not chapterData then
        if self._Model:CheckChapterIsRebrushById(chapterId) then
            return XEnumConst.Nonogram.NonogramChapterStatus.Init
        end

        return XEnumConst.Nonogram.NonogramChapterStatus.Lock
    end

    return chapterData:GetChapterStatus()
end

function XNonogramAgency:CheckChapterUnlockCg(chapterId)
    ---@type XNonogramChapter
    local chapterData = self._Model:GetChapterData(chapterId)
    if not chapterData then
        return false
    end

    return chapterData:GetIsUnlockCg()
end

function XNonogramAgency:CheckChapterStatus(chapterId, status)
    ---@type XNonogramChapter
    local chapterData = self._Model:GetChapterData(chapterId)
    if not chapterData then
        -- 没有数据默认未解锁
        return status == XEnumConst.Nonogram.NonogramChapterStatus.Lock
    end

    return chapterData:GetChapterStatus() == status
end

function XNonogramAgency:CheckUnLockChapterItemIsEnough(chapterId)
    local needCount = self._Model:GetChapterUnlockItemNumById(chapterId)
    return XDataCenter.ItemManager.CheckItemCountById(XDataCenter.ItemManager.ItemId.NonogramCoin, needCount)
end

-- 获取当前进度的章节索引（当前玩到哪一章了）
function XNonogramAgency:GetCurChapterIndexAndId()
    local curIndex = 1
    local curActivityId = self._Model:GetCurActivityId()
    if XTool.IsNumberValid(curActivityId) then
        local chapterIds = self._Model:GetActivityChapterIdsById(curActivityId)
        for index, chapterId in ipairs(chapterIds) do
            if self:CheckChapterStatus(chapterId, XEnumConst.Nonogram.NonogramChapterStatus.Init) then
                return index, chapterId
            elseif self:CheckChapterStatus(chapterId, XEnumConst.Nonogram.NonogramChapterStatus.Reward) then
                curIndex = index + 1
            end
        end
        if curIndex > #chapterIds then
            curIndex = #chapterIds
        end
        return curIndex, chapterIds[curIndex]
    end

    return curIndex
end

-- 蓝点检查
function XNonogramAgency:CheckChapterPoint(chapterId)
    local _, curChapterId = self:GetCurChapterIndexAndId()
    if chapterId ~= curChapterId then
        -- 只显示当前章节的
        return false
    end

    if not XTool.IsNumberValid(chapterId) then
        return false
    end

    local isCanUnlock = false
    local isCanUnlockCg = false
    if self:CheckChapterStatus(chapterId, XEnumConst.Nonogram.NonogramChapterStatus.Lock) then
        if self._Model:CheckChapterIsRebrushById(chapterId) then
            isCanUnlock = true
        else
            local unlockItemNeedCount = self._Model:GetChapterUnlockItemNumById(chapterId)
            isCanUnlock = XDataCenter.ItemManager.CheckItemCountById(XDataCenter.ItemManager.ItemId.NonogramCoin, unlockItemNeedCount)
        end
    elseif self:CheckChapterStatus(chapterId, XEnumConst.Nonogram.NonogramChapterStatus.Init) then
        if self._Model:CheckChapterIsRebrushById(chapterId) then
            isCanUnlockCg = false
        else
            local unlockCgItemId = self._Model:GetChapterUnlockCgItemIdById(chapterId)
            local unlockCgItemNeedCount = self._Model:GetChapterUnlockCgItemNumById(chapterId)
            isCanUnlockCg = XDataCenter.ItemManager.CheckItemCountById(unlockCgItemId, unlockCgItemNeedCount)
        end
    end

    return isCanUnlock or isCanUnlockCg
end

function XNonogramAgency:CheckActivityPoint()
    local curActivityId = self:GetCurActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return false
    end
    local curChapterIds = self._Model:GetActivityChapterIdsById(curActivityId)
    if XTool.IsTableEmpty(curChapterIds) then
        return false
    end

    for _, chapterId in ipairs(curChapterIds) do
        if self:CheckChapterStatus(chapterId, XEnumConst.Nonogram.NonogramChapterStatus.Init) then
            if not self._Model:CheckChapterIsRebrushById(chapterId) then
                -- 并且不是副刷关
                return true
            end
        end

        if self:CheckChapterPoint(chapterId) then
            return true
        end
    end

    return false
end
--endregion

--region 私有接口
function XNonogramAgency:_HandleErrorStatusWhenExitMidway()
    ---@type XNonogramChapter[]
    local chapterDataDir = self._Model:GetChapterDataDir()
    for chapterId, chapterData in pairs(chapterDataDir) do
        if chapterData:GetChapterStatus() == XEnumConst.Nonogram.NonogramChapterStatus.Ongoing then
            self:RequestChapterExit(chapterId)
        end
    end
end
--endregion

--region 协议请求
function XNonogramAgency:_UpdateNonogramData(data)
    self._Model:UpdateNonogramData(data)
    self:_HandleErrorStatusWhenExitMidway()
end

function XNonogramAgency:RequestChapterUnlock(chapterId, cb)
    -- 检查章节解锁需要的道具是否足够
    if not self:CheckUnLockChapterItemIsEnough(chapterId) then
        XUiManager.TipErrorWithKey("NonogramUnlockChapterItemNotEnough", XDataCenter.ItemManager.GetItemName(XDataCenter.ItemManager.ItemId.NonogramCoin))
        return
    end

    XNetwork.Call(NonogramProto.NonogramChapterUnlockRequest, { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if res.ChapterData then
            self._Model:UpdateChapterData(res.ChapterData)
        end

        if cb then
            cb()
        end

        XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_CHAPTER_UNLOCK, chapterId)
    end)
end

function XNonogramAgency:RequestChapterStart(chapterId, cb)
    XNetwork.Call(NonogramProto.NonogramChapterStartRequest, { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if res.ChapterData then
            self._Model:UpdateChapterData(res.ChapterData)
        end

        self._Model:SetCurGameChapterId(chapterId)

        if cb then
            cb()
        end

        XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_GAME_CHAPTER_START)
    end)
end

function XNonogramAgency:RequestFinishStage(chapterId, stageId, grids, remainTime, cb)
    remainTime = math.floor(remainTime)
    if remainTime < 0 then
        remainTime = 0
    end
    local requestData = {
        ChapterId = chapterId,
        StageId = stageId,
        Grids = grids,
        RemainTime = remainTime,
    }

    XNetwork.Call(NonogramProto.NonogramFinishStageRequest, requestData, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if res.ChapterData then
            self._Model:UpdateChapterData(res.ChapterData)
        end

        if cb then
            cb(res.RewardGoodsList)
        end
    end)
end

function XNonogramAgency:RequestUnlockCg(chapterId, cb)
    XNetwork.Call(NonogramProto.NonogramUnlockCgRequest, { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res.RewardGoodsList)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_CHAPTER_REWARDED, chapterId)
    end)
end

function XNonogramAgency:RequestChapterExit(chapterId, cb)
    XNetwork.Call(NonogramProto.NonogramChapterExitRequest, { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if res.ChapterData then
            self._Model:UpdateChapterData(res.ChapterData)
        end

        if cb then
            cb()
        end

        -- 需要刷新完再清除数据 结算界面会用到
        self._Model:SetCurGameChapterId(0)
    end)
end
--endregion

return XNonogramAgency