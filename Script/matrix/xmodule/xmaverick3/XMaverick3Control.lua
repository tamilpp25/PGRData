---@class XMaverick3Control : XControl
---@field private _Model XMaverick3Model
local XMaverick3Control = XClass(XControl, "XMaverick3Control")

function XMaverick3Control:OnInit()

end

function XMaverick3Control:AddAgencyEvent()

end

function XMaverick3Control:RemoveAgencyEvent()

end

function XMaverick3Control:OnRelease()

end

function XMaverick3Control:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
end

--region 活动数据

function XMaverick3Control:GetCurActivityCfg()
    return self._Model:GetActivityById(self._Model:GetActivityId())
end

function XMaverick3Control:GetActivityGameEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XMaverick3Control:GetShopEndTime()
    XShopManager.GetShopTimeInfo(ClosedLeftTime)
end

--endregion

--region 章节关卡

function XMaverick3Control:IsStageFinish(stageId)
    return self._Model:IsStageFinish(stageId)
end

function XMaverick3Control:IsChapterUnlock(id)
    return self._Model:IsChapterUnlock(id)
end

function XMaverick3Control:IsStageUnlock(id)
    return self._Model:IsStageUnlock(id)
end

function XMaverick3Control:IsStagePlaying(id)
    return self._Model:IsStagePlaying(id)
end

function XMaverick3Control:IsChapterRed(chapterId)
    return self._Model:IsChapterRed(chapterId)
end

function XMaverick3Control:IsMainLineNormalRed()
    return self._Model:IsMainLineNormalRed()
end

function XMaverick3Control:IsMainLineHardRed()
    return self._Model:IsMainLineHardRed()
end

function XMaverick3Control:IsInfiniteRed()
    return self._Model:IsInfiniteRed()
end

function XMaverick3Control:GetStageById(id)
    return self._Model:GetStageById(id)
end

function XMaverick3Control:GetChapterById(id)
    return self._Model:GetChapterById(id)
end

function XMaverick3Control:GetChapterConfigs()
    return self._Model:GetChapterConfigs()
end

function XMaverick3Control:GetStageData(id)
    return self._Model.ActivityData:GetStageData(id)
end

function XMaverick3Control:GetStageSavedData(id)
    return self._Model.ActivityData:GetStageSavedData(id)
end

function XMaverick3Control:GetStageStar(id)
    return self._Model:GetStageStar(id)
end

function XMaverick3Control:GetStagesByChapterId(chapterId)
    return self._Model:GetStagesByChapterId(chapterId)
end

function XMaverick3Control:GetChapterProgress(chapterId)
    local cur, all = 0, 0
    local datas = self:GetStagesByChapterId(chapterId)
    for _, v in pairs(datas) do
        all = all + 1
        if self:IsStageFinish(v.StageId) then
            cur = cur + 1
        end
    end
    return cur, all
end

function XMaverick3Control:GetCurChapterId()
    local curChapterId, firstChapterId
    local datas = self._Model:GetChapterConfigs()
    for _, chapter in pairs(datas) do
        if chapter.Type == XEnumConst.Maverick3.ChapterType.MainLine then
            if firstChapterId then
                firstChapterId = math.min(firstChapterId, chapter.ChapterId)
            else
                firstChapterId = chapter.ChapterId
            end
            local stages = self:GetStagesByChapterId(chapter.ChapterId)
            for _, stage in pairs(stages) do
                if self:IsStageFinish(stage.StageId) then
                    if curChapterId then
                        curChapterId = math.max(curChapterId, chapter.ChapterId)
                    else
                        curChapterId = chapter.ChapterId
                    end
                    break
                end
            end
        end
    end
    return curChapterId or firstChapterId
end

function XMaverick3Control:GetInfiniteChapter()
    return self._Model:GetInfiniteChapter()
end

function XMaverick3Control:GetTeachChapter()
    return self._Model:GetTeachChapter()
end

function XMaverick3Control:GetInfiniteStageScore(stageId)
    return self._Model:GetInfiniteStageScore(stageId)
end

function XMaverick3Control:GetClientConfigs(key)
    return self._Model:GetClientConfigs(key)
end

function XMaverick3Control:GetClientConfig(key, index)
    return self._Model:GetClientConfig(key, index)
end

function XMaverick3Control:GetStageProgress(stageId)
    if self:IsStageFinish(stageId) then
        return 100
    end
    local savedData = self._Model.ActivityData:GetStageSavedData(stageId)
    return savedData and savedData.StageProgress or 0
end

function XMaverick3Control:GetNeedOpenChapterDetailId()
    return self._Model:GetNeedOpenChapterDetailId()
end

function XMaverick3Control:GetCurSelectChapterId()
    local id = self._Model:GetCurSelectChapterId()
    if XTool.IsNumberValid(id) then
        return id
    end
    return self:GetCurChapterId()
end

function XMaverick3Control:GetShowRobotId()
    return self._Model:GetShowRobotId()
end

function XMaverick3Control:SetCurSelectChapterId(id)
    self._Model:SetCurSelectChapterId(id)
end

function XMaverick3Control:SaveShowRobotId(id)
    self._Model:SavetShowRobotId(id)
end

function XMaverick3Control:CloseChapterRed(chapterId)
    if self:IsChapterUnlock(chapterId) then
        XSaveTool.SaveData(string.format("Maverick3Chapter_%s_%s", chapterId, XPlayer.Id), true)
    end
end

--endregion

--region 出战

function XMaverick3Control:IsStagePlaying(stageId)
    return self._Model:IsStagePlaying(stageId)
end

function XMaverick3Control:GetRobotById(id)
    return self._Model:GetRobotById(id)
end

function XMaverick3Control:GetFightIndex()
    return self._Model:GetFightIndex()
end

function XMaverick3Control:SaveFightIndex(charIndex)
    self._Model:SaveFightIndex(charIndex)
end

--endregion

--region 角色

function XMaverick3Control:IsTalentUnlock(id)
    return self._Model:IsTalentUnlock(id)
end

function XMaverick3Control:GetSkillById(id)
    return self._Model:GetSkillById(id)
end

function XMaverick3Control:GetTalentById(id)
    return self._Model:GetTalentById(id)
end

function XMaverick3Control:GetTalentConfigs()
    return self._Model:GetTalentConfigs()
end

function XMaverick3Control:GetSelectSkillIndex(charIndex)
    return XSaveTool.GetData(string.format("Maverick3SkillIndex_%s_%s", charIndex, XPlayer.Id)) or 1
end

function XMaverick3Control:GetSelectTalentIndex(charIndex)
    return XSaveTool.GetData(string.format("Maverick3TalentIndex_%s_%s", charIndex, XPlayer.Id)) or 1
end

function XMaverick3Control:GetSelectOrnamentsId(charIndex)
    return self._Model:GetSelectOrnamentsId(charIndex)
end

function XMaverick3Control:GetSelectSlayId(charIndex)
    return self._Model:GetSelectSlayId(charIndex)
end

function XMaverick3Control:SaveSelectSkillIndex(charIndex, skillIndex)
    XSaveTool.SaveData(string.format("Maverick3SkillIndex_%s_%s", charIndex, XPlayer.Id), skillIndex)
end

function XMaverick3Control:SaveSelectTalentIndex(charIndex, talentIndex)
    XSaveTool.SaveData(string.format("Maverick3TalentIndex_%s_%s", charIndex, XPlayer.Id), talentIndex)
end

function XMaverick3Control:SaveSelectOrnamentsId(charIndex, id)
    self._Model:SaveSelectOrnamentsId(charIndex, id)
end

function XMaverick3Control:SaveSelectSlayId(charIndex, id)
    self._Model:SaveSelectSlayId(charIndex, id)
end

--endregion

--region 商店

function XMaverick3Control:IsShopRed()
    return self._Model:IsShopRed()
end

function XMaverick3Control:CloseShopRed()
    XSaveTool.SaveData(string.format("Maverick3ShopRedTime_%s", XPlayer.Id), XTime.GetServerNowTimestamp())
end

--endregion

--region 任务

function XMaverick3Control:IsDailyRewardCanGain()
    return self._Model:IsDailyRewardCanGain()
end

--endregion

--region 协议

---解锁天赋
function XMaverick3Control:RequestMaverick3UnlockTalent(talentId, cb)
    local request = { TalentId = talentId }
    XNetwork.CallWithAutoHandleErrorCode("Maverick3UnlockTalentRequest", request, function(res)
        self._Model:AddUnlockTalent(talentId)
        if cb then
            cb()
        end
    end)
end

---退出关卡重开（先发此协议再prefight）
function XMaverick3Control:RequestMaverick3ExitStage(stageId, cb)
    local request = { StageId = stageId }
    XNetwork.CallWithAutoHandleErrorCode("Maverick3ExitStageRequest", request, function(res)
        self._Model.ActivityData:UpdateStageSave(stageId, nil)
        if cb then
            cb()
        end
    end)
end

---获取排行榜信息
function XMaverick3Control:RequestMaverick3GetRank(stageId, cb)
    local request = { StageId = stageId }
    XNetwork.CallWithAutoHandleErrorCode("Maverick3GetRankRequest", request, function(res)
        self._Model:SetRankData(stageId, res)
        if cb then
            cb()
        end
    end)
end

--endregion

--region 剧情

function XMaverick3Control:IsAutoPlayStory(storyId)
    return XSaveTool.GetData(string.format("Maverick3Story_%s_%s", storyId, XPlayer.Id)) == nil
end

function XMaverick3Control:GetStoryById(id)
    return self._Model:GetStoryById(id)
end

function XMaverick3Control:GetStoryConfigs()
    return self._Model:GetStoryConfigs()
end

function XMaverick3Control:CloseAutoPlayStory(storyId)
    XSaveTool.SaveData(string.format("Maverick3Story_%s_%s", storyId, XPlayer.Id), true)
end

--endregion

--region 排行榜

function XMaverick3Control:IsRankEmpty()
    return self._Model:IsRankEmpty()
end

function XMaverick3Control:GetRankingSpecialIcon(rank)
    if type(rank) ~= "number" or rank < 1 or rank > 3 then
        return
    end
    return CS.XGame.ClientConfig:GetString("BabelTowerRankIcon" .. rank)
end

function XMaverick3Control:GetRankData(stageId)
    return self._Model:GetRankData(stageId)
end

function XMaverick3Control:GetMyRankData(stageId)
    return self._Model:GetMyRankData(stageId)
end

--endregion

return XMaverick3Control