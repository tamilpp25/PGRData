local XUiPanelExpeditionBaseRoleDetails = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiPanelExpeditionBaseRoleDetails")
local XUiPanelExpeditionRecruitRoleDetails = XClass(XUiPanelExpeditionBaseRoleDetails, "XUiPanelExpeditionRecruitRoleDetails")
local XEChara = require("XEntity/XExpedition/XExpeditionCharacter")

function XUiPanelExpeditionRecruitRoleDetails:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnRecruit, self.OnBtnRecruitClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStar, self.OnBtnRecruitClick)
end

function XUiPanelExpeditionRecruitRoleDetails:OnBtnRecruitClick()
    self.RootUi:Close()
    XDataCenter.ExpeditionManager.RecruitMember(self.GridIndex)
end

function XUiPanelExpeditionRecruitRoleDetails:Refresh(eChara, gridIndex)
    self:RefreshStar(eChara, gridIndex)
    self.RootUi:PlayAnimation("PanelRoleDetails1Enable")
end

function XUiPanelExpeditionRecruitRoleDetails:RefreshStar(eChara, gridIndex)
    -- 当前角色的BaseId
    local eBaseId = eChara:GetBaseId()
    -- 招募商店角色等级
    local RecruitRank = eChara:GetRank()
    -- 已招募角色
    local teamChara = XDataCenter.ExpeditionManager.GetCharaByEBaseId(eBaseId)
    self.BtnRecruit.gameObject:SetActiveEx(not teamChara)
    self.BtnStar.gameObject:SetActiveEx(teamChara)
    self.PanelStar.gameObject:SetActiveEx(teamChara)
    local tempChara = eChara
    if teamChara then
        -- 已招募角色当前等级
        local teamRank = teamChara:GetRank()
        self.TxtStarLevel.text = teamRank
        -- 升级后的等级
        local targetRank = teamRank + RecruitRank
        local maxRank = XExpeditionConfig.GetCharacterMaxRankByBaseId(eBaseId)
        if targetRank > maxRank then
            targetRank = maxRank
        end
        self.TxtEndLevel.text = targetRank
        -- 刷新Ui界面信息为升级后的信息
        tempChara = self:GetCharaData(eBaseId, targetRank)
    end
    -- 刷新详情信息
    self.Super.Refresh(self, tempChara, gridIndex)
end

function XUiPanelExpeditionRecruitRoleDetails:GetCharaData(baseId, rank)
    if self.UpStarChara then
        self.UpStarChara:ResetData(rank)
        self.UpStarChara:RefreshData(baseId)
    else
        self.UpStarChara = XEChara.New(baseId, rank)
    end
    return self.UpStarChara
end
return XUiPanelExpeditionRecruitRoleDetails