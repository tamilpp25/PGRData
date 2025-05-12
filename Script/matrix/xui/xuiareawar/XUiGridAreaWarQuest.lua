local XUiGridAreaWarBlockCommon = require("XUi/XUiAreaWar/XUiGridAreaWarBlockCommon")

---@class XUiGridAreaWarQuest : XUiGridAreaWarBlockCommon 探索任务
local XUiGridAreaWarQuest = XClass(XUiGridAreaWarBlockCommon, "XUiGridAreaWarQuest")

local Fight2RescueState = {
    None = 1,
    Waiting = 2,
    Finish = 3,
}

function XUiGridAreaWarQuest:InitUi(transform3D, clickCb)
    self.ClickCb = clickCb
    self.Transform3D = transform3D
    self.FightState = Fight2RescueState.None

    self.SyncPlayFight2Rescue = function()
        if not self.IsBeRescued then
            return
        end
        if self.FightState == Fight2RescueState.Finish 
                or self.FightState == Fight2RescueState.Waiting 
        then
            return
        end
        if XTool.UObjIsNil(self.EffectConvert) then
            return
        end
        local valid = false
        while true do
            self.FightState = Fight2RescueState.Waiting
            if XTool.UObjIsNil(self.GameObject) 
                    or XTool.UObjIsNil(self.EffectConvert) then
                break
            end
            if self.GameObject.activeInHierarchy then
                valid = true
                break
            end
            asynWaitSecond(0.2)
        end

        asynWaitSecond(2)
        if valid then
            self:TrySetActive(self.EffectConvert, false)
            self:TrySetActive(self.EffectConvert, true)
            self.FightState = Fight2RescueState.Finish
            self:TrySetActive(self.EffectClear, true)
        end
        asynWaitSecond(2)
        self:TrySetActive(self.EffectConvert, false)
    end
    self:TrySetActive(self.EffectLocation, false)
    self:TrySetActive(self.EffectConvert, false)
end

function XUiGridAreaWarQuest:Refresh(questId)
    self.QuestId = questId
    
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    local quest = personal:GetQuest(questId)
    self.IsBeRescued = quest:IsBeRescued()
    self:TrySetActive(self.EffectNormal, true)
    self:TrySetActive(self.EffectClear, self.IsBeRescued and self.FightState == Fight2RescueState.Finish)
end

function XUiGridAreaWarQuest:OnClick()
    if self.ClickCb then
        self.ClickCb(self.QuestId)
    end
end

function XUiGridAreaWarQuest:GetBindParam()
    return self.Transform3D
end

function XUiGridAreaWarQuest:TryRemove()

    if not XTool.UObjIsNil(self.Transform) then
        XUiHelper.Destroy(self.Transform.gameObject)
        self.Transform = nil
    end
end

function XUiGridAreaWarQuest:IsSameTransform(transform)
    if XTool.UObjIsNil(transform) then
        return false
    end

    if XTool.UObjIsNil(self.Transform3D) then
        return false
    end
    
    return self.Transform3D:GetInstanceID() == transform:GetInstanceID()
end

function XUiGridAreaWarQuest:TryPlayReward()
    RunAsyn(self.SyncPlayFight2Rescue)
end

return XUiGridAreaWarQuest