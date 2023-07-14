local XUiGridStage = XClass(nil, "XUiGridStage")
local CSTextManagerGetText = CS.XTextManager.GetText

local EditHideList = {
    PanelBattle = true,
    PanelMe = true,
    PanelBlood = true,
    PanelRevive = true,
    ImgClear = true,
    }

local PlayingHideList = {
    PanelBattle = true,
    PanelMe = true,
    PanelBlood = true,
    PanelRevive = true,
    ImgClear = true,
    PanelNumber = true,
}

local BaseHitWaitTime = 1

function XUiGridStage:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Damage = 0
    self.IsSelect = false
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:DoSelect(false)
end

function XUiGridStage:SetButtonCallBack()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

function XUiGridStage:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying)
    self.StageNode = nodeEntity
    self.IsPathEdit = IsPathEdit
    self.IsActionPlaying = IsActionPlaying
    if nodeEntity then
        if self.Icon then
            self.Icon:SetRawImage(nodeEntity:GetIcon())  
        end
        
        if self.ImgHp then
            self.ImgHp.fillAmount = nodeEntity:GetHP() / nodeEntity:GetMaxHP()
        end
        
        if self.ImgRb then
            self.ImgRb.fillAmount = nodeEntity:GetRebuildProgress()
        end
        
        if self.TxtName1 then
            self.TxtName1.text = nodeEntity:GetName()
        end
        
        if self.TxtName2 then
            self.TxtName2.text = nodeEntity:GetName()
        end
        
        if self.TxtName3 then
            self.TxtName3.text = nodeEntity:GetNameEn()
        end
        
        if self.ImgClear then
            local IsHide = self:GetIsHide("ImgClear",IsPathEdit, IsActionPlaying)
            self.ImgClear.gameObject:SetActiveEx((not nodeEntity:GetIsSentinelNode() and not nodeEntity:GetIsInBattle()) and nodeEntity:GetIsDead() and not IsHide)
        end
        
        if self.PanelBattle then
            local IsHide = self:GetIsHide("PanelBattle",IsPathEdit, IsActionPlaying)
            self.PanelBattle.gameObject:SetActiveEx(nodeEntity:GetIsInBattle() and not IsHide)
        end
        
        if self.PanelMe then
            local IsHide = self:GetIsHide("PanelMe",IsPathEdit, IsActionPlaying)
            self.PanelMe.gameObject:SetActiveEx(nodeEntity:GetIsPlayerNode() and not IsHide)
        end
        
        if self.PanelBlood then
            local IsHide = self:GetIsHide("PanelBlood",IsPathEdit, IsActionPlaying)
            self.PanelBlood.gameObject:SetActiveEx(nodeEntity:GetStutesType() == XGuildWarConfig.NodeStatusType.Alive and not IsHide)
        end
        
        if self.PanelRevive then
            local IsHide = self:GetIsHide("PanelRevive",IsPathEdit, IsActionPlaying)
            self.PanelRevive.gameObject:SetActiveEx(nodeEntity:GetStutesType() == XGuildWarConfig.NodeStatusType.Revive and not IsHide)
        end

        self:ShowStageName(self.IsSelect or nodeEntity:GetIsPlayerNode())
        
        self:DoPathMark(nodeEntity:GetIsTargetNode())
    end
end

function XUiGridStage:GetStageIndexName()
    return self.StageNode and self.StageNode:GetStageIndexName()
end

function XUiGridStage:SetDamage(damage)
    self.Damage = damage
end

function XUiGridStage:DoSelect(IsSelect, IsShowSelectTag)
    self.IsSelect = IsSelect
    
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(IsSelect and IsShowSelectTag)
    end
    
    if IsSelect then
        self:ShowStageName(true)
    else
        self:ShowStageName(self.StageNode and self.StageNode:GetIsPlayerNode())
    end
end

function XUiGridStage:ShowStageName(IsShow)
    if self.TxtName1 then
        self.TxtName1.gameObject:SetActiveEx(IsShow)
    end
    if self.TxtName2 then
        self.TxtName2.gameObject:SetActiveEx(IsShow)
    end
    if self.TxtName3 then
        self.TxtName3.gameObject:SetActiveEx(IsShow)
    end
end

function XUiGridStage:DoPathMark(IsSelect)
    if self.PanelNumber then
        local IsHide = self:GetIsHide("PanelNumber", self.IsPathEdit, self.IsActionPlaying)
        self.PanelNumber.gameObject:SetActiveEx(IsSelect and not IsHide)
    end
end

function XUiGridStage:OnBtnStageClick()
    if self.IsPathEdit then
        if self.StageNode:GetIsBaseNode() then
            XUiManager.TipText("GuildWarBaseMarkHint")
            return
        end
        self.Base:AddPath(self.StageNode:GetId(), self)
    else
        XLuaUiManager.Open("UiGuildWarStageDetail", self.StageNode, false)
    end
end

function XUiGridStage:ShowAction(actType, cb)
    if actType == XGuildWarConfig.MosterActType.BaseHit then
        self:DoBaseHit(cb)
    end
end

function XUiGridStage:DoBaseHit(cb)
    --self.Damage,表演
    local callBack = function()
        if not self.BaseHitTimer then
            self.BaseHitTimer = XScheduleManager.ScheduleOnce(function()
                    self.BaseHitTimer = nil
                    if cb then cb() end
                end, XScheduleManager.SECOND * BaseHitWaitTime)
        end
    end
    
    if self.HouseHit then
        self.HouseHit:PlayTimelineAnimation(callBack)
    else
        if callBack then callBack() end
    end
end

function XUiGridStage:StopTween()
    if self.BaseHitTimer then
        XScheduleManager.UnSchedule(self.BaseHitTimer)
        self.BaseHitTimer = nil
    end
end

function XUiGridStage:GetIsHide(name, IsPathEdit, IsActionPlaying)
    if IsPathEdit and not IsActionPlaying then
        return EditHideList[name]
    elseif not IsPathEdit and IsActionPlaying then
        return PlayingHideList[name]
    else
        return false
    end
end

return XUiGridStage