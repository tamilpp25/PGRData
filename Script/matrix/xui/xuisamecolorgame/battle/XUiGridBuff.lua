local XUiGridBuff = XClass(nil, "XUiGridBuff")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridBuff:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridBuff:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridBuff:OnBtnClick()
    if self.IsBossSkill then
        XLuaUiManager.Open("UiSameColorGameSkillDetails", self.Entity)
    else
        XLuaUiManager.Open("UiSameColorGameEffectDetails")
    end
end

function XUiGridBuff:UpdateGrid(entity, IsBossSkill)
    self.Entity = entity
    self.IsBossSkill = IsBossSkill
    
    if entity then
        self.RawBuffIcon:SetRawImage(entity:GetIcon())
        if IsBossSkill then
            local countDown = entity:GetTriggerRound() - self.BattleManager:GetBattleRound()
            self.CountDownText.text = CSTextManagerGetText("SCBuffRoundText", countDown)
        else
            self.CountDownText.text = CSTextManagerGetText("SCBuffRoundText", entity:GetCountDown())
        end
    end

    self.GameObject:SetActiveEx(entity)
end

function XUiGridBuff:DoCountdown()
    if self.Entity then
        self.RawBuffIcon:SetRawImage(self.Entity:GetIcon())
        local countDown = 0
        if self.IsBossSkill then
            countDown = self.Entity:GetTriggerRound() - self.BattleManager:GetBattleRound()
            self.CountDownText.text = CSTextManagerGetText("SCBuffRoundText", countDown)
        else
            countDown = self.Entity:GetCountDown()
            self.CountDownText.text = CSTextManagerGetText("SCBuffRoundText", countDown)
        end
        self.GameObject:SetActiveEx(countDown > -1)
    end
end

return XUiGridBuff