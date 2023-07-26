local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")
--二期黑白鲨Boss
---@class XUiGridStagePanda
local XUiGridStagePanda = XClass(XUiGridStage, "XUiGridStagePanda")
local CSTextManagerGetText = CS.XTextManager.GetText


function XUiGridStagePanda:Ctor(ui, base)
    --XUiGridStagePanda.Super:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Damage = 0
    self.IsSelect = false
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:DoSelect(false)
end

function XUiGridStagePanda:SetButtonCallBack()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

---@param nodeEntity XGWNode
function XUiGridStagePanda:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
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
            self.ImgClear.gameObject:SetActiveEx(false)
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


function XUiGridStagePanda:ShowStageName(IsShow)
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

function XUiGridStagePanda:DoPathMark(IsSelect)
    if self.PanelNumber then
        local IsHide = self:GetIsHide("PanelNumber", self.IsPathEdit, self.IsActionPlaying)
        self.PanelNumber.gameObject:SetActiveEx(IsSelect and not IsHide)
    end
end

function XUiGridStagePanda:OnBtnStageClick(selectedNodeId)
    if self.IsPathEdit then
        self.Base:AddPath(self.StageNode:GetId(), self)
    else
        if self.StageNode:GetIsPlayerNode() and not self.StageNode:GetIsDead() then
            XLuaUiManager.Open("UiGuildWarPandaStageDetail", self.StageNode, false, selectedNodeId)
        else
            XLuaUiManager.Open("UiGuildWarStageDetail", self.StageNode, false)
        end    
    end
end

return XUiGridStagePanda