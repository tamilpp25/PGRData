---@class XUiGridStage
---@field ComDragonRage XUiGridComDragonRage @龙怒玩法关卡组件
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
    
    self.ComDragonRage = require('XUi/XUiGuildWar/Map/XUiGridStageCom/XUiGridComDragonRage').New(self)
end

function XUiGridStage:SetButtonCallBack()
    self.BtnStage.CallBack = function()
        if not self.StageNode then
            XLog.Error("[XUiGridStageTerm4] stageNode is empty, i dont know how it occur")
            XDataCenter.GuildWarManager.GetActivityData()
            return
        end
        self:OnBtnStageClick()
    end
end

---@param nodeEntity XGWNode
function XUiGridStage:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
    self.StageNode = nodeEntity
    self.IsPathEdit = IsPathEdit
    self.IsActionPlaying = IsActionPlaying
    if nodeEntity then
        if self.Icon then
            self.Icon:SetRawImage(nodeEntity:GetIcon())  
        end

        if self.BgImg then
            local iconPath = nodeEntity:GetBgIcon()

            if not string.IsNilOrEmpty(iconPath) then
                self.BgImg:SetSprite(iconPath)
            end
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
            self.ImgClear.gameObject:SetActiveEx(
                (not nodeEntity:GetIsSentinelNode() and not nodeEntity:GetIsInBattle()) 
                and nodeEntity:GetIsDead() and not IsHide
            )
        end
        
        if self.PanelBattle then
            local IsHide = self:GetIsHide("PanelBattle",IsPathEdit, IsActionPlaying)
            self.PanelBattle.gameObject:SetActiveEx(nodeEntity:GetIsInBattle() and not IsHide)
        end
        
        if self.PanelMe then
            local IsHide = self:GetIsHide("PanelMe",IsPathEdit, IsActionPlaying)
            local isActive = nodeEntity:GetIsPlayerNode() and not IsHide
            self.PanelMe.gameObject:SetActiveEx(isActive)
            
            -- 在重新编辑后, 不播放特效
            if isActive then
                local objEffectRefresh = XUiHelper.TryGetComponent(self.PanelMe, "EffectRefresh")
                if isPathEditOver then
                    objEffectRefresh.gameObject:SetActiveEx(false)
                else
                    objEffectRefresh.gameObject:SetActiveEx(true)
                end
            end
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
        
        self:DoPathMark(self.StageNode:GetIsPlanNode())
    end
end

--- 龙怒系统存在隐藏节点（不显示但其他移动等逻辑依然有效）
function XUiGridStage:SetNodeEntityOnly(nodeEntity)
    self.StageNode = nodeEntity
end

--获取节点关卡索引名
function XUiGridStage:GetStageIndexName()
    return self.StageNode and self.StageNode:GetStageIndexName()
end

--获取节点ID
function XUiGridStage:GetNodeId()
    self.StageNode:GetId()
end

--获取是否计划路线中的节点
function XUiGridStage:GetIsPlanNode()
    return nodeEntity:GetIsPlanNode()
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
        --第三期不需要显示节点的路线感叹号
        self.PanelNumber.gameObject:SetActiveEx(false)
        --self.PanelNumber.gameObject:SetActiveEx(IsSelect and not IsHide)
    end
end

--isAuto 是否自动跳转
function XUiGridStage:OnBtnStageClick(selectedNodeId, isAuto)
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
    if actType == XGuildWarConfig.GWActionType.BaseBeHit then
        self:DoBaseHit(cb)
    elseif actType == XGuildWarConfig.GWActionType.NodeChangeToRelic then
        self.ComDragonRage:PlayRelicChangeShow(cb)    
    elseif actType == XGuildWarConfig.GWActionType.DragonRageFull then
        self.ComDragonRage:PlayDragonRageChangeShow(cb)    
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
    
    self.ComDragonRage:StopTween()
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