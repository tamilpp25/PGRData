---@class XGoldenMinerSystemTimeLineAnim
local XGoldenMinerSystemTimeLineAnim = XClass(nil, "XGoldenMinerSystemTimeLineAnim")

---@param game XGoldenMinerGame
function XGoldenMinerSystemTimeLineAnim:Update(game, time)
    for _, entity in pairs(game.HookEntityList) do
        self:UpdateAnim(entity, time)
    end
    for _, entity in pairs(game.StoneEntityList) do
        self:UpdateAnim(entity, time)
    end
end

function XGoldenMinerSystemTimeLineAnim:UpdateAnim(entity, time)
    ---@type XGoldenMinerComponentTimeLineAnim
    local anim = entity.Anim
    if not anim then
        return
    end
    if self:CheckBePlayIsNone(anim) and self:CheckCurPlayIsNone(anim) then
        return
    end

    -- 动画播放
    if not self:CheckCurPlayIsNone(anim) then
        local curPlayableDirector = self:GetAnimObj(anim, anim.CurAnim)
        anim.CurAnimDuration = anim.CurAnimDuration + time
        if anim.CurAnimDuration >= curPlayableDirector.playableAsset.duration then
            if anim.FinishCallBack then anim.FinishCallBack() end
            self:ResetCurPlay(anim)
        end
    end
    
    if self:CheckBePlayIsNone(anim) then
        return
    end

    local bePlayableDirector = self:GetAnimObj(anim, anim.BePlayAnim)
    if not bePlayableDirector then
        if anim.BeFinishCallBack then
            anim.BeFinishCallBack()
        end
        self:ResetBePlay(anim)
        self:ResetCurPlay(anim)
        return
    end

    if self:CheckCurPlayIsNone(anim) then
        anim.CurAnim = anim.BePlayAnim
        anim.FinishCallBack = anim.BeFinishCallBack
        self:_PlayAnim(bePlayableDirector)
    else    -- 动画打断
        local curPlayableDirector = self:GetAnimObj(anim, anim.CurAnim)
        curPlayableDirector:Evaluate()
        curPlayableDirector:Stop()
        if not anim.IsBreakCurPlay and anim.FinishCallBack then
            anim.FinishCallBack()
        end
        anim.CurAnim = anim.BePlayAnim
        anim.FinishCallBack = anim.BeFinishCallBack
        self:_PlayAnim(bePlayableDirector)
    end

    self:ResetBePlay(anim)
end

--region Anim
function XGoldenMinerSystemTimeLineAnim:PlayAnim(entity, animName, finishCallBack, isBreak)
    ---@type XGoldenMinerComponentTimeLineAnim
    local anim = entity.Anim
    if not anim then
        if finishCallBack then
            finishCallBack()
        end
        return
    end
    anim.BePlayAnim = animName
    anim.BeFinishCallBack = finishCallBack
    anim.IsBreakCurPlay = isBreak
end

---@param anim XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:ResetBePlay(anim)
    anim.BePlayAnim = XGoldenMinerConfigs.GAME_ANIM.NONE
    anim.BeFinishCallBack = false
end

---@param anim XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:ResetCurPlay(anim)
    anim.CurAnimDuration = 0
    anim.CurAnim = XGoldenMinerConfigs.GAME_ANIM.NONE
    anim.FinishCallBack = false
end

---@param anim XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:CheckCurPlayIsNone(anim)
    return anim.CurAnim == XGoldenMinerConfigs.GAME_ANIM.NONE
end

---@param anim XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:CheckBePlayIsNone(anim)
    return anim.BePlayAnim == XGoldenMinerConfigs.GAME_ANIM.NONE
end

---@param playableDirector UnityEngine.Playables.PlayableDirector
---@param directorWrapMode number UnityEngine.Playables.DirectorWrapMode
function XGoldenMinerSystemTimeLineAnim:_PlayAnim(playableDirector, directorWrapMode)
    if not playableDirector then
        return
    end
    if not directorWrapMode then
        directorWrapMode = CS.UnityEngine.Playables.DirectorWrapMode.Hold
    end
    if playableDirector.extrapolationMode ~= directorWrapMode then
        playableDirector.extrapolationMode = directorWrapMode
    end
    
    playableDirector:Stop()
    playableDirector:Evaluate()
    playableDirector:Play()
end

---@param anim XGoldenMinerComponentTimeLineAnim
---@return UnityEngine.Playables.PlayableDirector
function XGoldenMinerSystemTimeLineAnim:GetAnimObj(anim, animName)
    if not anim.AnimRoot then
        return false
    end
    return XUiHelper.TryGetComponent(anim.AnimRoot, animName, "PlayableDirector")
end
--endregion

return XGoldenMinerSystemTimeLineAnim