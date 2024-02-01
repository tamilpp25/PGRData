---@class XGoldenMinerSystemTimeLineAnim:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemTimeLineAnim = XClass(XEntityControl, "XGoldenMinerSystemTimeLineAnim")

--region Override
function XGoldenMinerSystemTimeLineAnim:EnterGame()
    local hookEntityList = self._MainControl:GetHookEntityUidList()
    if not XTool.IsTableEmpty(hookEntityList) then
        for _, uid in ipairs(hookEntityList) do
            local hookEntity = self._MainControl:GetHookEntityByUid(uid)
            self:_CreateAnimComponent(hookEntity, hookEntity:GetComponentHook().Transform)
        end
    end
    local stoneEntityUidDir = self._MainControl:GetStoneEntityUidDirByType()
    if not XTool.IsTableEmpty(stoneEntityUidDir) then
        for uid, _ in ipairs(stoneEntityUidDir) do
            local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
            if stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MOUSE) then
                self:_CreateAnimComponent(stoneEntity, stoneEntity:GetTransform())
            end
        end
    end
end

function XGoldenMinerSystemTimeLineAnim:OnUpdate(time)
    local hookEntityList = self._MainControl:GetHookEntityUidList()
    if not XTool.IsTableEmpty(hookEntityList) then
        for _, uid in ipairs(hookEntityList) do
            self:_UpdateAnim(self._MainControl:GetHookEntityByUid(uid), time)
        end
    end
    local stoneEntityUidDir = self._MainControl:GetStoneEntityUidDirByType()
    if not XTool.IsTableEmpty(stoneEntityUidDir) then
        for uid, _ in ipairs(stoneEntityUidDir) do
            self:_UpdateAnim(self._MainControl:GetStoneEntityByUid(uid), time)
        end
    end
end

function XGoldenMinerSystemTimeLineAnim:OnRelease()
end
--endregion

--region Create
---@param entity XEntity
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:_CreateAnimComponent(entity, transform)
    if not transform or XTool.UObjIsNil(transform) then
        return false
    end
    ---@type XGoldenMinerComponentTimeLineAnim
    local anim = entity:AddChildEntity(self._MainControl.COMPONENT_TYPE.TIME_LINE)
    anim.AnimRoot = XUiHelper.TryGetComponent(transform, "Animation")
    anim.CurAnim = XEnumConst.GOLDEN_MINER.GAME_ANIM.NONE
    anim.FinishCallBack = false
    anim.BePlayAnim = XEnumConst.GOLDEN_MINER.GAME_ANIM.NONE
    anim.BeFinishCallBack = false
    return anim
end
--endregion

--region Update
---@param entity XEntity
function XGoldenMinerSystemTimeLineAnim:_UpdateAnim(entity, time)
    if not entity then
        return
    end
    ---@type XGoldenMinerComponentTimeLineAnim
    local anim = entity.GetComponentAnim and entity:GetComponentAnim()
    if not anim then
        return
    end
    if self:_CheckBePlayIsNone(anim) and self:_CheckCurPlayIsNone(anim) then
        return
    end

    -- 动画播放
    if not self:_CheckCurPlayIsNone(anim) then
        local curPlayableDirector = self:_GetAnimObj(anim, anim.CurAnim)
        anim.CurAnimDuration = anim.CurAnimDuration + time
        if anim.CurAnimDuration >= curPlayableDirector.playableAsset.duration then
            if anim.FinishCallBack then anim.FinishCallBack() end
            self:_ResetCurPlay(anim)
        end
    end
    
    if self:_CheckBePlayIsNone(anim) then
        return
    end

    local bePlayableDirector = self:_GetAnimObj(anim, anim.BePlayAnim)
    if not bePlayableDirector then
        if anim.BeFinishCallBack then
            anim.BeFinishCallBack()
        end
        self:_ResetBePlay(anim)
        self:_ResetCurPlay(anim)
        return
    end

    if self:_CheckCurPlayIsNone(anim) then
        anim.CurAnim = anim.BePlayAnim
        anim.FinishCallBack = anim.BeFinishCallBack
        self:_PlayAnim(bePlayableDirector)
    else    -- 动画打断
        local curPlayableDirector = self:_GetAnimObj(anim, anim.CurAnim)
        curPlayableDirector:Evaluate()
        curPlayableDirector:Stop()
        if not anim.IsBreakCurPlay and anim.FinishCallBack then
            anim.FinishCallBack()
        end
        anim.CurAnim = anim.BePlayAnim
        anim.FinishCallBack = anim.BeFinishCallBack
        self:_PlayAnim(bePlayableDirector)
    end

    self:_ResetBePlay(anim)
end
--endregion

--region Play
---@param entity XEntity
function XGoldenMinerSystemTimeLineAnim:PlayAnim(entity, animName, finishCallBack, isBreak)
    ---@type XGoldenMinerComponentTimeLineAnim
    local anim = entity.GetComponentAnim and entity:GetComponentAnim()
    if not anim then
        if finishCallBack then
            finishCallBack()
        end
        return
    end
    if anim.CurAnim == animName then
        return
    end
    anim.BePlayAnim = animName
    anim.BeFinishCallBack = finishCallBack
    anim.IsBreakCurPlay = isBreak
end

---@param anim XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:_ResetBePlay(anim)
    anim.BePlayAnim = XEnumConst.GOLDEN_MINER.GAME_ANIM.NONE
    anim.BeFinishCallBack = false
end

---@param anim XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:_ResetCurPlay(anim)
    anim.CurAnimDuration = 0
    anim.CurAnim = XEnumConst.GOLDEN_MINER.GAME_ANIM.NONE
    anim.FinishCallBack = false
end

---@param anim XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:_CheckCurPlayIsNone(anim)
    return anim.CurAnim == XEnumConst.GOLDEN_MINER.GAME_ANIM.NONE
end

---@param anim XGoldenMinerComponentTimeLineAnim
function XGoldenMinerSystemTimeLineAnim:_CheckBePlayIsNone(anim)
    return anim.BePlayAnim == XEnumConst.GOLDEN_MINER.GAME_ANIM.NONE
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
function XGoldenMinerSystemTimeLineAnim:_GetAnimObj(anim, animName)
    if not anim.AnimRoot then
        return false
    end
    return XUiHelper.TryGetComponent(anim.AnimRoot, animName, "PlayableDirector")
end
--endregion

return XGoldenMinerSystemTimeLineAnim