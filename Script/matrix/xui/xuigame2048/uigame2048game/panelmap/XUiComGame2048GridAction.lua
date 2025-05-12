--- 2048玩法中分管方块动画的组件
---@class XUiComGame2048GridAction: XUiNode
---@field Parent XUiGridGame2048Grid
local XUiComGame2048GridAction = XClass(XUiNode, 'XUiComGame2048GridAction')

function XUiComGame2048GridAction:OnStart()
    self._EndCurAnimationHandler = handler(self, self.EndCurSubAnimation)
    self._OnAnimationBeginHandler = handler(self, self._OnAnimationBegin)

    self._MoveTime = self._Control:GetClientConfigNum('MoveTweenTimer')
    self._MergeTweenBiggerTime = self._Control:GetClientConfigNum('MergeTweenTimer', 1)
    self._MergeTweenSmallerTime = self._Control:GetClientConfigNum('MergeTweenTimer', 2)
    self._MergeTweenTargetSize = self._Control:GetClientConfigNum('MergeTweenTargetScale')

    self._BornTweenFirtPartTime = self._Control:GetClientConfigNum('BornTweenTimer', 1)
    self._BornTweenLastPartTime = self._Control:GetClientConfigNum('BornTweenTimer', 2)
    self._BornTweenTargetSize = self._Control:GetClientConfigNum('BornTweenTargetScale')

    self:ResetEffects()
end 

function XUiComGame2048GridAction:OnDisable()
    self:StopCurAnimation()
    self.EffectAppear.gameObject:SetActiveEx(false)
end

function XUiComGame2048GridAction:ResetEffects()
    self.EffectDispel.gameObject:SetActiveEx(false)

    if self.EffectDoubling then
        self.EffectDoubling.gameObject:SetActiveEx(false)
    end

    if self.EffectMerge then
        self.EffectMerge.gameObject:SetActiveEx(false)
    end

    if self.EffectTransfer then
        self.EffectTransfer.gameObject:SetActiveEx(false)
    end

    if self.EffectExValueChang then
        self.EffectExValueChang.gameObject:SetActiveEx(false)
    end
end

function XUiComGame2048GridAction:UpdateConfigParams(type)
    if type == XMVCA.XGame2048.EnumConst.GridType.Normal then
        self._DispelHideTime = self._Control:GetClientConfigNum('EffectDispelHideGridTime')
        self._DispelPlayTime = self._Control:GetClientConfigNum('EffectDispelTime')
    elseif type == XMVCA.XGame2048.EnumConst.GridType.Rock then
        self._DispelHideTime = self._Control:GetClientConfigNum('EffectRockDispelHideTime')
        self._DispelPlayTime = self._Control:GetClientConfigNum('EffectRockDispelTime')
        self._EffectRockShakeTime = self._Control:GetClientConfigNum('EffectRockShakeTime')
        self._EffectRockShakeStrengthVec3 = Vector3(
                self._Control:GetClientConfigNum('EffectRockShakeStrengthVec3', 1),
                self._Control:GetClientConfigNum('EffectRockShakeStrengthVec3', 2),
                self._Control:GetClientConfigNum('EffectRockShakeStrengthVec3', 3))
    else
        self._DispelHideTime = self._Control:GetClientConfigNum('EffectBombDispelHideTime')
        self._DispelPlayTime = self._Control:GetClientConfigNum('EffectBombDispelTime')
    end
end

function XUiComGame2048GridAction:StopCurAnimation()
    -- 插值动画
    if self._CurAnimTimeId then
        XScheduleManager.UnSchedule(self._CurAnimTimeId)
        self._CurAnimTimeId = nil
    end

    -- DOTWeen动画
    if self._CurTweener then
        if self._CurTweener:IsActive() then
            self._CurTweener:Kill(true)
        end
        self._CurTweener = nil
    end

    if self._CurAnimCallBack then
        local cb = self._CurAnimCallBack
        self._CurAnimCallBack = nil

        cb()
    end
    
    -- 子动画计数器
    self._AnimationCounter = 0
    
    -- 激活型效果结点隐藏
    self:ResetEffects()
end

function XUiComGame2048GridAction:_EndCurAnimation()
    -- 插值动画
    if self._CurAnimTimeId then
        self._CurAnimTimeId = nil
    end

    -- DOTWeen动画
    if self._CurTweener then
        self._CurTweener = nil
    end

    if self._CurAnimCallBack then
        local cb = self._CurAnimCallBack
        self._CurAnimCallBack = nil

        cb()
    end

    -- 子动画计数器
    self._AnimationCounter = 0
end

function XUiComGame2048GridAction:EndCurSubAnimation()
    self._AnimationCounter = self._AnimationCounter - 1

    if self._AnimationCounter <= 0 then
        self:_EndCurAnimation()
    end
end

function XUiComGame2048GridAction:_OnAnimationBegin()
    self._AnimationCounter = self._AnimationCounter + 1
end

--- 平移插值动画
function XUiComGame2048GridAction:DoMove(fromTrans, toTrans, cb)
    if not fromTrans or not toTrans then
        if cb then
            cb()
        end
        return
    end

    self:StopCurAnimation()

    self._CurAnimCallBack = cb
    self._AnimationCounter = 1
    
    self.Transform.position = fromTrans.position
    
    self._CurAnimTimeId = XUiHelper.DoWorldMove(self.Transform, toTrans.position, self._MoveTime, XUiHelper.EaseType.Linear, self._EndCurAnimationHandler)
end

--- 合成动画
function XUiComGame2048GridAction:DoMerge(cb, isPlayAnimation, type)
    self:StopCurAnimation()

    self._CurAnimCallBack = cb
    self._AnimationCounter = 1

    if isPlayAnimation then
        self.Parent:PlayAnimation("GridBlockMerge", self._EndCurAnimationHandler, self._OnAnimationBeginHandler)
    end
    
    self._CurAnimTimeId = self:DoScale(self.Transform, Vector3.one, Vector3.one * self._MergeTweenTargetSize, self._MergeTweenBiggerTime, XUiHelper.EaseType.Sin, function()
        self._CurAnimTimeId = self:DoScale(self.Transform, Vector3.one * self._MergeTweenTargetSize, Vector3.one, self._MergeTweenSmallerTime, XUiHelper.EaseType.Sin, self._EndCurAnimationHandler)
    end)

    if type == XMVCA.XGame2048.EnumConst.MergeEffectType.Doubling then
        if self.EffectDoubling then
            self.EffectDoubling.gameObject:SetActiveEx(true)
        end
    elseif type == XMVCA.XGame2048.EnumConst.MergeEffectType.Transfer then
        if self.EffectTransfer then
            self.EffectTransfer.gameObject:SetActiveEx(true)
        end
    else
        if self.EffectMerge then
            self.EffectMerge.gameObject:SetActiveEx(true)
        end
    end
end

--- 新生成动画
function XUiComGame2048GridAction:DoBorn(cb)
    self:StopCurAnimation()

    self._CurAnimCallBack = cb
    self._AnimationCounter = 1
    
    -- 重新激活触发特效
    self.EffectAppear.gameObject:SetActiveEx(true)

    self._CurAnimTimeId = self:DoScale(self.Transform, Vector3.one, Vector3.one * self._BornTweenTargetSize, self._BornTweenFirtPartTime, XUiHelper.EaseType.Sin, function()
        self._CurAnimTimeId = self:DoScale(self.Transform, Vector3.one * self._BornTweenTargetSize, Vector3.one, self._BornTweenLastPartTime, XUiHelper.EaseType.Sin, self._EndCurAnimationHandler)
    end)
end

--- 消除动画
function XUiComGame2048GridAction:DoDispel(cb)
    self:StopCurAnimation()

    self._CurAnimCallBack = cb
    self._AnimationCounter = 1

    self.EffectDispel.gameObject:SetActiveEx(true)
    if XTool.IsNumberValid(self._DispelHideTime) then
        -- 分数方块的隐藏特效，当特效完全覆盖方块UI时需要隐藏方块UI
        self._CurAnimTimeId = XScheduleManager.ScheduleOnce(function()
            -- 隐藏
            if self.TxtNum then
                self.TxtNum.gameObject:SetActiveEx(false)
            end
            
            if self.Image then
                self.Image.gameObject:SetActiveEx(false)
            end

            if self.ImgIcon then
                self.ImgIcon.gameObject:SetActiveEx(false)
            end

            if self.GridPoint then
                self.GridPoint.gameObject:SetActiveEx(false)
            end

            local delayTime = self._DispelPlayTime - self._DispelHideTime

            if delayTime < 0 then
                delayTime = 0
            end

            self._CurAnimTimeId = XScheduleManager.ScheduleOnce(self._EndCurAnimationHandler, delayTime * XScheduleManager.SECOND)
        end, self._DispelHideTime * XScheduleManager.SECOND)
    else
        self._CurAnimTimeId = XScheduleManager.ScheduleOnce(self._EndCurAnimationHandler, self._DispelPlayTime * XScheduleManager.SECOND)
    end
end

--- 碰撞动画
function XUiComGame2048GridAction:DoShake(cb)
    self:StopCurAnimation()

    self._CurAnimCallBack = cb
    self._AnimationCounter = 1
    
    self._CurTweener = self.Transform:DOShakePosition(self._EffectRockShakeTime, self._EffectRockShakeStrengthVec3):OnComplete(self._EndCurAnimationHandler)
end

return XUiComGame2048GridAction