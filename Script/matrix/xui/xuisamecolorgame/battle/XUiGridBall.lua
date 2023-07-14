local XUiGridBall = XClass(nil, "XUiGridBall")
local CSTextManagerGetText = CS.XTextManager.GetText
local TweenSpeed = 0.1
local Vector3 = CS.UnityEngine.Vector3

local WaitTime = {
    ["Before"] = 300,
    ["After"] = 100,
    }

function XUiGridBall:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Row = 1
    self.Col = 1
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.EffectGain.gameObject:SetActiveEx(false)
    self.EffectReduction.gameObject:SetActiveEx(false)
    self.EffectTiShi.gameObject:SetActiveEx(false)
    self.Select.gameObject:SetActiveEx(false)
end

function XUiGridBall:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridBall:OnBtnClick()
    self.Base:DoSelectBall(self)
end

function XUiGridBall:UpdateGrid(ball)
    self.Ball = ball
    self.Bg:SetRawImage(ball:GetBg())
    self.Icon:SetRawImage(ball:GetIcon())
end

function XUiGridBall:MoveToGridPos(gridPos, cb)
    local tagPos = gridPos.Transform.localPosition
    local selfPos = self.Transform.localPosition
    local power = Vector3(tagPos.x - selfPos.x, tagPos.y - selfPos.y, tagPos.z - selfPos.z).magnitude / gridPos.Transform.sizeDelta.y
    if self.BallMoveTimer then
        XScheduleManager.UnSchedule(self.BallMoveTimer)
        self.BallMoveTimer = nil
    end
    self.BallMoveTimer = XUiHelper.DoMove(self.Transform, tagPos, TweenSpeed * power, XUiHelper.EaseType.Sin,function()
            self.BallMoveTimer = nil
            self.Row = gridPos.Row
            self.Col = gridPos.Col
            if cb then cb() end
    end)
end

function XUiGridBall:EqualPosToGridPos(gridPos)
    if XTool.UObjIsNil(self.Transform) or XTool.UObjIsNil(gridPos.Transform) then
        --XLog.Error("Ball:")
        --XLog.Error(self.Transform)
        --XLog.Error("Pos:")
        --XLog.Error(gridPos)
        return
    end
    self.Transform.localPosition = gridPos.Transform.localPosition
    self.Row = gridPos.Row
    self.Col = gridPos.Col
end

function XUiGridBall:PlayWait(waitName, cb)
    self:ShowWaitEffect(waitName)
    XScheduleManager.ScheduleOnce(function()
            if cb then cb() end
        end, WaitTime[waitName])
end


function XUiGridBall:SelectEffect()
    local effectType = XSameColorGameConfigs.BuffType.None
    local buffList = self.BattleManager:GetShowBuffList()
    
    for _,buff in pairs(buffList or {}) do
        for _,targetColor in pairs(buff:GetTargetColorList() or {}) do
            if targetColor == self.Ball:GetColor() then
                if not (effectType and effectType == XSameColorGameConfigs.BuffType.NoDamage) then
                    effectType = buff:GetType()
                end
            end
        end
    end
    
    self:ShowEffect(effectType)
end

function XUiGridBall:ShowEffect(type)
    self.EffectGain.gameObject:SetActiveEx(type == XSameColorGameConfigs.BuffType.AddDamage)
    self.EffectReduction.gameObject:SetActiveEx(type == XSameColorGameConfigs.BuffType.NoDamage)
end

function XUiGridBall:CloseEffect()
    self.EffectGain.gameObject:SetActiveEx(false)
    self.EffectReduction.gameObject:SetActiveEx(false)
    self.EffectTiShi.gameObject:SetActiveEx(false)
end

function XUiGridBall:ShowWaitEffect(waitName)
    if waitName == "Before" then
        self.EffectTiShi.gameObject:SetActiveEx(false)
        self.EffectTiShi.gameObject:SetActiveEx(true)
    end
end

function XUiGridBall:ShowSelect(IsShow)
    self.Select.gameObject:SetActiveEx(IsShow)
end

function XUiGridBall:GetPositionIndex()
    return {x = self.Col, y = self.Row}
end

function XUiGridBall:GetBallId()
    return self.Ball:GetBallId()
end


function XUiGridBall:StopTween()
    if self.BallMoveTimer then
        XScheduleManager.UnSchedule(self.BallMoveTimer)
        self.BallMoveTimer = nil
        return true
    end
    return false
end

return XUiGridBall