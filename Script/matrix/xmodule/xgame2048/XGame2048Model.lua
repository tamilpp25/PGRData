---@class XGame2048Model : XModel
local XGame2048Model = XClass(XModel, "XGame2048Model")

local TableNormal = {
    Game2048Activity = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048Chapter = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048Stage = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048ClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },

}

local TablePrivate = {
    Game2048Buff = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048Item = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048BoardShowGroup = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048Block = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048BlockType = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Type", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048ChapterShow = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "ChapterId", ReadFunc = XConfigUtil.ReadType.Int },
    
    Game2048Board = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    
    Game2048BoardShow = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    Game2048ShowCondition = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
}

function XGame2048Model:OnInit()
    self._ConfigUtil:InitConfigByTableKey('MiniActivity/Game2048', TableNormal, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey('MiniActivity/Game2048', TablePrivate, XConfigUtil.CacheType.Private)
end

function XGame2048Model:ClearPrivate()

end

function XGame2048Model:ResetAll()
    --清空上一个号的活动数据
    self._ActivityId = nil
    self._StageInfos = nil
    self._CurStageData = nil
end


--region -------------------- ActivityData -------------------->>
function XGame2048Model:UpdateActivityId(activityId)
    self._ActivityId = XTool.IsNumberValid(activityId) and activityId or 0
end

function XGame2048Model:UpdateStageInfos(stageinfos)
    self._StageInfos = stageinfos
end

function XGame2048Model:UpdateCurStageData(stageData)
    self._CurStageData = stageData
end

function XGame2048Model:GetCurActivityId()
    return self._ActivityId or 0
end

function XGame2048Model:GetStageInfoById(stageId)
    if not XTool.IsTableEmpty(self._StageInfos) then
        for i, v in pairs(self._StageInfos) do
            if v.StageId == stageId then
                return v
            end
        end
    end
end

function XGame2048Model:GetCurStageData()
    return self._CurStageData
end

function XGame2048Model:GetCurActivityCfg()
    local activityId = self:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        return self:GetGame2048ActivityCfgById(activityId)
    end
end

function XGame2048Model:GetCurActivityTimeId()
    local activityCfg = self:GetCurActivityCfg()

    if activityCfg then
        return activityCfg.TimeId
    end

    return 0
end

function XGame2048Model:GetChapterCurStarSummary(chapterId)
    local starSummary = 0
    ---@type XTableGame2048Chapter
    local chapterCfg = self:GetGame2048ChapterCfgs()[chapterId]

    if chapterCfg then
        for i, stageId in ipairs(chapterCfg.StageIds) do
            local stageCfg = self:GetGame2048StageCfgs()[stageId]
            if stageCfg then
                local info = self:GetStageInfoById(stageId)
                if info then
                    starSummary = starSummary + XTool.GetTableCount(info.GetRewardIndex)
                end
            end
        end
    end

    return starSummary
end

--endregion <<--------------------------------------------------

--region --------------------- Reddot Key ---------------------->>>
function XGame2048Model:GetChapterNewReddotKey(chapterId)
    return 'Game2048_'..tostring(self:GetCurActivityId())..tostring(chapterId)..tostring(XPlayer.Id)
end
--endregion <<<---------------------------------------------------

function XGame2048Model:GetSelectStageIndexLocalKey(chapterId)
    local activityId = self:GetCurActivityId()
    local key = 'Game2048ModelActivitySelectStage_'..tostring(activityId)..tostring(chapterId)..XPlayer.Id
    return key
end

function XGame2048Model:GetLastSelectStageIndex(chapterId)
    return XSaveTool.GetData(self:GetSelectStageIndexLocalKey(chapterId))
end

function XGame2048Model:SetSelectStageIndex(chapterId, stageIndex)
    XSaveTool.SaveData(self:GetSelectStageIndexLocalKey(chapterId), stageIndex)
end

--region -------------------- Configs ------------------->>
function XGame2048Model:GetGame2048ActivityCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.Game2048Activity) 
end

function XGame2048Model:GetGame2048ActivityCfgById(activityId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Game2048Activity, activityId)
end

function XGame2048Model:GetGame2048ChapterCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.Game2048Chapter)
end

function XGame2048Model:GetGame2048StageCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.Game2048Stage)
end

function XGame2048Model:GetGame2048StageCfgById(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Game2048Stage, stageId)
end

function XGame2048Model:GetGame2048BuffCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Game2048Buff)
end

function XGame2048Model:GetGame2048BoardShowGroupCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Game2048BoardShowGroup, id)
end

function XGame2048Model:GetGame2048BoardShowCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Game2048BoardShow, id)
end

function XGame2048Model:GetGame2048ShowConditionCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Game2048ShowCondition, id)
end

function XGame2048Model:GetGame2048BoardCfgById(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Game2048Board, id, noTips)
end

function XGame2048Model:GetGame2048BlockCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Game2048Block)
end

function XGame2048Model:GetGame2048BlockCfgById(blockId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Game2048Block, blockId)
end

function XGame2048Model:GetGame2048BlockTypeCfgByType(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Game2048BlockType, type)
end

function XGame2048Model:GetClientConfig()
    return self._ConfigUtil:GetByTableKey(TableNormal.Game2048ClientConfig)
end

---@return XTableGame2048ChapterShow
function XGame2048Model:GetChapterShowCfgById(chapterId)
    local cfgs = self._ConfigUtil:GetByTableKey(TablePrivate.Game2048ChapterShow)

    if cfgs then
        return cfgs[chapterId]
    end
end

function XGame2048Model:GetClientConfigVector2(key)
    local config = self:GetClientConfig()[key]
    if config then
        local _x = string.IsNumeric(config.Values[1]) and tonumber(config.Values[1]) or 0
        local _y = string.IsNumeric(config.Values[2]) and tonumber(config.Values[2]) or 0

        return { x = _x, y = _y }
    end
    return {0, 0}
end

function XGame2048Model:GetClientConfigNum(key, index)
    index = index or 1

    local config = self:GetClientConfig()[key]
    if config and config.Values[index] then
        local val = string.IsFloatNumber(config.Values[index]) and tonumber(config.Values[index]) or 0
        return val
    end

    return 0
end

function XGame2048Model:GetClientConfigText(key, index)
    index = index or 1

    local config = self:GetClientConfig()[key]
    if config then
        return config.Values[index] or ''
    end

    return ''
end

function XGame2048Model:GetChapterStarTotalById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableGame2048Chapter
        local chapterCfg = self:GetGame2048ChapterCfgs()[chapterId]
        if chapterCfg then
            local stageIds = chapterCfg.StageIds

            if not XTool.IsTableEmpty(stageIds) then
                local chapterStar = 0

                for i, v in ipairs(stageIds) do
                    ---@type XTableGame2048Stage
                    local stageCfg = self:GetGame2048StageCfgs()[v]
                    if stageCfg then
                        chapterStar = chapterStar + #stageCfg.Scores
                    end
                end

                return chapterStar
            end
        end
    end
    return 0
end

--endregion <<--------------------------------------------
return XGame2048Model