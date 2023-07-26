local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")
--三期双子节点
---@class XUiGridStageTwins
local XUiGridStageTwins = XClass(XUiGridStage, "XUiGridStageTwins")
local CSTextManagerGetText = CS.XTextManager.GetText


function XUiGridStageTwins:Ctor(ui, base)
    --XUiGridStageTwins.Super:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Damage = 0
    self.IsSelect = false
    self:InitUI()
    self:SetButtonCallBack()
    self:DoSelect(false)
end

function XUiGridStageTwins:InitUI()
    XTool.InitUiObject(self)
    
    self.PanelUiMixBoss = {}
    XTool.InitUiObjectByUi(self.PanelUiMixBoss,self.PanelMixBoss)
    self.PanelUiMixBoss.gameObject = self.PanelUiMixBoss.GameObject
    
    self.PanelUiDoubleBoss = {}
    XTool.InitUiObjectByUi(self.PanelUiDoubleBoss,self.PanelDoubleBoss)
    self.PanelUiDoubleBoss.gameObject = self.PanelUiDoubleBoss.GameObject
end

function XUiGridStageTwins:SetButtonCallBack()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

---@param nodeEntity XGWNode
function XUiGridStageTwins:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
    self.StageNode = nodeEntity
    self.IsPathEdit = IsPathEdit
    self.IsActionPlaying = IsActionPlaying
    if nodeEntity then
        self:UpdateBoss(self.StageNode:GetIsMerge(),IsPathEdit,IsActionPlaying)
        --显示关闭区域名字
        self:ShowStageName(self.IsSelect or nodeEntity:GetIsPlayerNode())
        --名字
        if self.TxtName1 then
            self.TxtName1.text = nodeEntity:GetName()
        end
        --名字阴影
        if self.TxtName2 then
            self.TxtName2.text = nodeEntity:GetName()
        end
        --英文名
        if self.TxtName3 then
            self.TxtName3.text = nodeEntity:GetNameEn()
        end
        --是否通关
        if self.ImgClear then
            self.ImgClear.gameObject:SetActiveEx(self.StageNode:GetIsDead())
        end
        --是否在作战中
        if self.PanelBattle then
            local IsHide = self:GetIsHide("PanelBattle",IsPathEdit, IsActionPlaying)
            self.PanelBattle.gameObject:SetActiveEx(nodeEntity:GetIsInBattle() and not IsHide)
        end
        --玩家是否在当前区域
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
        --设置此节点是否是计划路线中节点
        self:DoPathMark(self.StageNode:GetIsPlanNode())
    end
end

function XUiGridStageTwins:UpdateBoss(isMerge,IsPathEdit,IsActionPlaying)
    --隐藏最大生命值血条
    local IsHideBlood = self:GetIsHide("PanelBlood",IsPathEdit, IsActionPlaying)
    --隐藏当前生命值血条
    local IsHideRevive = self:GetIsHide("PanelRevive",IsPathEdit, IsActionPlaying)
    --合体后展示
    if isMerge then
        self.PanelUiDoubleBoss.gameObject:SetActiveEx(false)
        self.PanelUiMixBoss.gameObject:SetActiveEx(true)
        --设置隐藏
        self.PanelUiMixBoss.PanelBlood.gameObject:SetActiveEx(not IsHideBlood)
        if self.StageNode:GetIsDead() then
            self.PanelUiMixBoss.PanelBlood.gameObject:SetActiveEx(false)
        else
            local Hp = self.StageNode:GetHP()
            local MaxHp = self.StageNode:GetMaxHP()
            self.PanelUiMixBoss.ImgHp.fillAmount = Hp / MaxHp
        end
    else --非合体
        self.PanelUiDoubleBoss.gameObject:SetActiveEx(true)
        self.PanelUiMixBoss.gameObject:SetActiveEx(false)
        --设置左隐藏
        self.PanelUiDoubleBoss.PanelBlood01.gameObject:SetActiveEx(not IsHideBlood)
        --self.PanelUiDoubleBoss.PanelRevive01.gameObject:SetActiveEx(not IsHideRevive)
        --设置右隐藏
        self.PanelUiDoubleBoss.PanelBlood02.gameObject:SetActiveEx(not IsHideBlood)
        --self.PanelUiDoubleBoss.PanelRevive02.gameObject:SetActiveEx(not IsHideRevive)
        --左节点Hp
        local childNode1 = self.StageNode:GetChildByIndex(1)
        local Hp = childNode1:GetHP()
        local MaxHp = childNode1:GetMaxHP()
        self.PanelUiDoubleBoss.ImgHp1.fillAmount = Hp / MaxHp
        --右节点HP
        local childNode2 = self.StageNode:GetChildByIndex(2)
        Hp = childNode2:GetHP()
        MaxHp = childNode2:GetMaxHP()
        self.PanelUiDoubleBoss.ImgHp2.fillAmount = Hp / MaxHp
    end
end

function XUiGridStageTwins:OnBtnStageClick(selectedNodeId, isAuto)
    if self.IsPathEdit then
        self.Base:AddPath(self.StageNode:GetId(), self)
    else
        if self.StageNode:GetIsPlayerNode() and not self.StageNode:GetIsDead() and XDataCenter.GuildWarManager.CheckRoundIsInTime() then
            if isAuto then return end
            XLuaUiManager.Open("UiGuildWarTwinsPanel", self.StageNode, false, selectedNodeId)
        else
            XLuaUiManager.Open("UiGuildWarStageDetail", self.StageNode, false)
        end
    end
end

function XUiGridStageTwins:ShowAction(actType, cb)
    if actType == XGuildWarConfig.GWActionType.BossMerge then
        self:DoBossMerge(cb)
    end
end

function XUiGridStageTwins:DoBossMerge(cb)
    --self.Damage,表演
    local callBack = function()
        self:UpdateBoss(true,false,true)
        if not self.BaseHitTimer then
            self.BaseHitTimer = XScheduleManager.ScheduleOnce(function()
                self.BaseHitTimer = nil
                if cb then cb() end
            end, XScheduleManager.SECOND)
        end
    end
    if self.IconMix then
        self:UpdateBoss(false,false,true)
        self.IconMix:PlayTimelineAnimation(callBack)
    else
        if callBack then callBack() end
    end
end

return XUiGridStageTwins