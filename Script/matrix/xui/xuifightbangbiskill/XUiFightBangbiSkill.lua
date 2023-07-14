local State = {
    NotActive = 1,  --未激活
    CanActive = 2,  --可激活
    Actived = 3,    --已激活
}
local MAX_COUNT = 6
local ANIMA_TIME = 1000     --动画时长（毫秒）

--角色记忆模块界面
local XUiFightBangbiSkill = XLuaUiManager.Register(XLuaUi, "UiFightBangbiSkill")

function XUiFightBangbiSkill:OnStart()
    self.AreaEffectObjectQueue = XQueue.New()
    self.StateDic = {}
    self.UnLockList = {}            --未激活节点的列表
    self.ActivationList = {}        --可激活节点的列表
    self.LockList = {}              --已激活节点的列表
    self.AreaRawImageList = {}      --进度图片节点的列表
    self.AreaEffectList = {}        --进度特效节点的列表
    self.BtnActivationList = {}     --激活按钮的列表
    self.BtnClickEffectList = {}    --点击特效节点的列表
    for i = 1, MAX_COUNT do
        self.UnLockList[i] = XUiHelper.TryGetComponent(self["Skill" .. i], "UnLock")
        self.ActivationList[i] = XUiHelper.TryGetComponent(self["Skill" .. i], "Activation")
        self.LockList[i] = XUiHelper.TryGetComponent(self["Skill" .. i], "Lock")
        self.AreaRawImageList[i] = XUiHelper.TryGetComponent(self["PanelArea" .. i], "RawImage")
        self.AreaEffectList[i] = XUiHelper.TryGetComponent(self["PanelArea" .. i], "Effect")
        self.BtnClickEffectList[i] = XUiHelper.TryGetComponent(self["Skill" .. i], "Activation/Bg2/BtnActivation/Effect")
        self.BtnActivationList[i] = XUiHelper.TryGetComponent(self["Skill" .. i], "Activation/Bg2/BtnActivation", "XUiButton")

        self.BtnClickEffectList[i].gameObject:SetActiveEx(false)
        self.AreaEffectList[i].gameObject:SetActiveEx(false)
        self.AreaRawImageList[i].gameObject:SetActiveEx(false)
        
        local index = i
        self:RegisterClickEvent(self.BtnActivationList[i], function()
            self:OnBtnActivationClick(index)
        end)
    end
end

function XUiFightBangbiSkill:OnDisable()
    self:StopTimer()
    self.StateDic = {}
    self.AreaEffectObjectQueue:Clear()
    for i = 1, MAX_COUNT do
        self.AreaEffectList[i].gameObject:SetActiveEx(false)
    end
end

function XUiFightBangbiSkill:SetCanActive(index)
    self:SetState(index, State.CanActive)
end

function XUiFightBangbiSkill:SetActived(index)
    self:SetState(index, State.Actived)
end

function XUiFightBangbiSkill:SetState(index, state)
    --按钮状态
    self.UnLockList[index].gameObject:SetActiveEx(state == State.NotActive)
    self.ActivationList[index].gameObject:SetActiveEx(state == State.CanActive)
    self.LockList[index].gameObject:SetActiveEx(state == State.Actived)
    --首次打开界面是激活状态时显示进度
    if not self.StateDic[index] and state == State.Actived then
        self.AreaEffectObjectQueue:Enqueue(self.AreaEffectList[index].gameObject)
        self:CheckPlayAnima()
    end
    self.StateDic[index] = state
end

function XUiFightBangbiSkill:OnBtnActivationClick(index)
    self.BtnClickEffectList[index].gameObject:SetActiveEx(true)
    self:SetActived(index)
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.GuideClick, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.GuideClick, CS.XOperationClickType.KeyUp)
    end
end

function XUiFightBangbiSkill:CheckPlayAnima()
    if self.Timer then
        return
    end

    local effectObj = self.AreaEffectObjectQueue:Dequeue()
    if not effectObj then
        return
    end
    effectObj:SetActiveEx(true)
    
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self:StopTimer()
        self:CheckPlayAnima()
    end, ANIMA_TIME)
end

function XUiFightBangbiSkill:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end