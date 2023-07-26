--虚像地平线招募界面招募显示列表控件
local XUiExpeditionRecruitShopGrid = XClass(nil, "XUiExpeditionRecruitShopGrid")
local XUiGridExpeditionRecruitFeature = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoomChar/XUiGridExpeditionRecruitFeature")
local UiButtonState = CS.UiButtonState

function XUiExpeditionRecruitShopGrid:Ctor(ui, modelPanel, rootUi, gridIndex)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self.ModelPanel = modelPanel
    self.RootUi = rootUi
    self.GridIndex = gridIndex
    self.TxtName.text = ""
    self.GameObject:SetActiveEx(false)
    self.GridFeature.gameObject:SetActiveEx(false)
    self.GridFeatureList = {}
end

function XUiExpeditionRecruitShopGrid:RefreshDatas(pos, playEffect)
    if not pos then
        self.GameObject:SetActiveEx(false)
        self.ModelPanel:HideRoleModel()
        return
    end
    self.GameObject:SetActiveEx(true)
    self.EChara = XDataCenter.ExpeditionManager.GetRecruitMemberByPos(pos)
    local isBlank = not self.EChara or self.EChara:GetIsBlank()
    if isBlank then
        self.GameObject:SetActiveEx(false)
        self.ModelPanel:HideRoleModel()
        return
    end
    self.TxtName.gameObject:SetActiveEx(self.EChara and not isBlank)
    local recruitMembers = XDataCenter.ExpeditionManager.GetRecruitMembers()
    if recruitMembers:GetIsPicked() then
        self.IsPicked = true
        self.BtnRankUp.gameObject:SetActiveEx(false)
        if recruitMembers:GetRecruitPos() ~= pos then
            self.BtnRecruit.gameObject:SetActiveEx(false)
        else
            self.BtnRecruit.gameObject:SetActiveEx(true)
            self.BtnRecruit:SetButtonState(UiButtonState.Disable)
        end
    else
        self.IsPicked = false
        local team = XDataCenter.ExpeditionManager.GetTeam()
        local isExistInTeam = not isBlank and team:CheckInTeamByEBaseId(self.EChara:GetBaseId())
        self.BtnRecruit.gameObject:SetActiveEx(not isExistInTeam)
        self.BtnRankUp.gameObject:SetActiveEx(isExistInTeam)
        if isExistInTeam then
            self.BtnRecruit.gameObject:SetActiveEx(false)
        else
            self.BtnRecruit:SetButtonState(UiButtonState.Normal)
        end
    end
    
    self:UpdateGridFeature()
    
    if not self.EChara or isBlank then self:UpdateRoleModel() return end
    self.TxtName.text = self.EChara:GetCharaFullName()
    self:UpdateRoleModel(self.EChara:GetCharacterId(), self.EChara:GetRobotId(), playEffect)
    self.TxtLevel.text = self.EChara:GetRankStr()
end

--更新模型
function XUiExpeditionRecruitShopGrid:UpdateRoleModel(charId, robotId, playEffect)
    if not charId or not robotId then return end
    self.GameObject:SetActiveEx(true)
    if not self.ShowEffect then
        self.ShowEffect = {}
        self.ShowEffect[1] = self.ModelPanel.Transform:Find("ImgEffectHuanren1")
        self.ShowEffect[2] = self.ModelPanel.Transform:Find("ImgEffectHuanren2")
        self.ShowEffect[3] = self.ModelPanel.Transform:Find("ImgEffectHuanren3")
    end
    if playEffect then
        for i in pairs(self.ShowEffect) do
            self.ShowEffect[i].gameObject:SetActiveEx(false)
        end
        for i = #self.ShowEffect, 1, -1 do
            local checkRank = XExpeditionConfig.GetRankByRankWeightId(i)
            if self.EChara:GetRank() >= checkRank then
                self.ShowEffect[i].gameObject:SetActiveEx(true)
                break
            end
        end
    end
    self.ModelPanel:ShowRoleModel()
    local callback = function()
        self.ModelReady = true
    end
    self.ModelReady = false
    local robotConfig = XRobotManager.GetRobotTemplate(robotId)
    self.ModelPanel:UpdateRobotModelNew(robotId, charId, callback, robotConfig.FashionId, robotConfig.WeaponId)
end

function XUiExpeditionRecruitShopGrid:OnClick()
    if not self.EChara then return end
    if self.EChara:GetIsBlank() then return end
    if self.IsPicked then return end
    self.RootUi:OpenRoleDetailsPanel(self.EChara, XExpeditionConfig.MemberDetailsType.RecruitMember, self.GridIndex)
end

function XUiExpeditionRecruitShopGrid:UpdateGridFeature()
    local comboList = XDataCenter.ExpeditionManager.GetComboList():GetActiveComboIdsByEChara(self.EChara, true)
    if XTool.IsTableEmpty(comboList) then
        return
    end
    for i = 1, #comboList do
        local comboId = comboList[i]
        local panel = self.GridFeatureList[i]
        if not panel then
            local go = XUiHelper.Instantiate(self.GridFeature, self.PanelFeature)
            panel = XUiGridExpeditionRecruitFeature.New(go, self.RootUi)
            self.GridFeatureList[i] = panel
        end
        panel:Refresh(comboId)
        panel.GameObject:SetActiveEx(true)
    end

    for i = #comboList + 1, #self.GridFeatureList do
        self.GridFeatureList[i].GameObject:SetActiveEx(false)
    end
end

return XUiExpeditionRecruitShopGrid