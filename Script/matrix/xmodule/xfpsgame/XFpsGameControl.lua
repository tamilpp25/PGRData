---@class XFpsGameControl : XControl
---@field private _Model XFpsGameModel
local XFpsGameControl = XClass(XControl, "XFpsGameControl")

function XFpsGameControl:OnInit()

end

function XFpsGameControl:AddAgencyEvent()

end

function XFpsGameControl:RemoveAgencyEvent()

end

function XFpsGameControl:OnRelease()

end

--region 活动

function XFpsGameControl:GetActivityGameEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XFpsGameControl:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
end

function XFpsGameControl:GetChapterOpenTime(chapterId)
    return self._Model:GetChapterOpenTime(chapterId)
end

function XFpsGameControl:CheckChapterOpen(chapterId, isTip)
    return self._Model:CheckChapterOpen(chapterId, isTip)
end

function XFpsGameControl:IsEnterMainPanel()
    return self._Model:IsEnterMainPanel()
end

function XFpsGameControl:SetEnterMainPanel()
    self._Model:SetEnterMainPanel()
end

--endregion

--region 关卡

function XFpsGameControl:IsNewScore(stageId, score)
    return self._Model:IsNewScore(stageId, score)
end

function XFpsGameControl:GetStagesByChapter(chapterId)
    return self._Model:GetStagesByChapter(chapterId)
end

function XFpsGameControl:IsStageUnlock(stageId)
    return self._Model:IsStageUnlock(stageId)
end

function XFpsGameControl:GetStageStar(stageId)
    return self._Model:GetStageStar(stageId)
end

function XFpsGameControl:GetCurUnpassStage(chapterId)
    local datas = self:GetStagesByChapter(chapterId)
    local stageId = 0
    for _, data in pairs(datas) do
        local id = data.StageId
        if not self._Model:IsStagePass(id) and self:IsStageUnlock(id) then
            if stageId < id then
                stageId = id
            end
        end
    end
    return stageId
end

function XFpsGameControl:IsStagePass(stageId)
    return self._Model:IsStagePass(stageId)
end

function XFpsGameControl:GetTeachStageId()
    local stages = self._Model:GetStages()
    for _, stage in pairs(stages) do
        if stage.ChapterId == 0 then
            return stage.StageId
        end
    end
    return nil
end

function XFpsGameControl:GetWeaponKey()
    return string.format("FpsGameWeapon_%s", XPlayer.Id)
end

function XFpsGameControl:GetCharacterKey()
    return string.format("FpsGameCharIdx_%s", XPlayer.Id)
end

function XFpsGameControl:GetCallRedPointKey(stageId)
    return string.format("FpsGameCallRedPoint_%s_%s", XPlayer.Id, stageId)
end

function XFpsGameControl:EnterFight(stageId, battleWeapon, battleCharacterId)
    self._Model:SetBattleData(battleWeapon, battleCharacterId)
    XMVCA.XFuben:EnterFightByStageId(stageId, nil, false, 1, nil)
end

function XFpsGameControl:EnterFightAgain()
    local fightData = XMVCA.XFuben:GetCurFightResult()
    XMVCA.XFuben:EnterFightByStageId(fightData.StageId, nil, false, 1, nil)
end

function XFpsGameControl:IsWeaponUnlock(weaponId)
    return self._Model:IsWeaponUnlock(weaponId)
end

function XFpsGameControl:GetStarsCount(starsMark)
    return self._Model:GetStarsCount(starsMark)
end

function XFpsGameControl:GetBattleCharacterId()
    return self._Model:GetBattleCharacterId()
end

function XFpsGameControl:GetStageHistoryScore(stageId)
    return self._Model:GetStageHistoryScore(stageId)
end

function XFpsGameControl:IsChapterRewardGain(chapterId)
    return self._Model:IsChapterRewardGain(chapterId)
end

function XFpsGameControl:SetTriggerEnableCameraAnim()
    self._Model:SetTriggerEnableCameraAnim()
end

function XFpsGameControl:GetTriggerEnableCameraAnim()
    return self._Model:GetTriggerEnableCameraAnim()
end

--endregion

--region 奖励

function XFpsGameControl:IsRewardGain(chapterId, rewardId)
    return self._Model:IsRewardGain(chapterId, rewardId)
end

function XFpsGameControl:GetRewardsByChapter(chapterId)
    local chapter = self._Model:GetChapterById(chapterId)
    return self._Model:GetRewardsByGroup(chapter.StarRewardGroupId)
end

---获取章节获得的星数和总星数
function XFpsGameControl:GetProgress(chapter)
    return self._Model:GetProgress(chapter)
end

function XFpsGameControl:GetCanGainRewardIds(chapterId)
    local rewardIds = {}
    local rewards = self:GetRewardsByChapter(chapterId)
    local cur = self:GetProgress(chapterId)
    for _, reward in pairs(rewards) do
        if cur >= reward.Star then
            if not self:IsRewardGain(chapterId, reward.Id) then
                table.insert(rewardIds, reward.Id)
            end
        end
    end
    return rewardIds
end

--endregion

--region 配置表

function XFpsGameControl:GetClientConfigById(key, index)
    index = index or 1
    local config = self._Model:GetClientConfigById(key)
    return config.Values[index]
end

function XFpsGameControl:GetChapterById(id)
    return self._Model:GetChapterById(id)
end

function XFpsGameControl:GetStageById(id)
    return self._Model:GetStageById(id)
end

function XFpsGameControl:GetWeaponById(id)
    return self._Model:GetWeaponById(id)
end

function XFpsGameControl:GetWeapons()
    return self._Model:GetWeapons()
end

function XFpsGameControl:GetScoreById(id)
    return self._Model:GetScoreById(id)
end

function XFpsGameControl:GetScoreLevel(score)
    return self._Model:GetScoreLevel(score)
end

--endregion

--region 协议

function XFpsGameControl:FpsGameGetChapterRewardRequest(chapterId, cb)
    local request = { ChapterId = chapterId }
    local rewardIds = self:GetCanGainRewardIds(chapterId)
    XNetwork.CallWithAutoHandleErrorCode("FpsGameGetChapterRewardRequest", request, function(res)
        self._Model:AddChapterReward(chapterId, rewardIds)
        XUiManager.OpenUiObtain(res.RewardGoodsList, nil, cb)
    end)
end

--endregion

return XFpsGameControl