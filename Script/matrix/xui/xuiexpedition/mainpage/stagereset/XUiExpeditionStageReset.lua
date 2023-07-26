--虚像地平线关卡重置
local XUiExpeditionStageReset = XLuaUiManager.Register(XLuaUi, "UiExpeditionReset")

function XUiExpeditionStageReset:OnStart(eStage, onResetCallback)
    self.EStage = eStage
    self.OnResetCb = onResetCallback
    self:InitPanel()
end

function XUiExpeditionStageReset:InitPanel()
    self:InitPanelConsume()
    self:InitPanelTeam()
    self:InitButtons()
end

function XUiExpeditionStageReset:InitPanelConsume()
    self.ConsumePanel = {}
    XTool.InitUiObjectByUi(self.ConsumePanel, self.PanelConsume)
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local itemId = eActivity:GetResetStageConsumeId()
    local haveCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = eActivity:GetResetStageConsumeCount()
    if needCount == 0 then --没消耗时隐藏消耗显示
        self.PanelConsume.gameObject:SetActiveEx(false)
        return
    end
    if haveCount >= needCount then
        self.ConsumePanel.TxtNumber.text = needCount
    else
        self.ConsumePanel.TxtNumber.text = XUiHelper.GetText("CommonRedText", needCount)
    end
    local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
    self.ConsumePanel.RImgIcon:SetRawImage(icon)
end

function XUiExpeditionStageReset:InitPanelTeam()
    self.TeamPanel = {}
    XTool.InitUiObjectByUi(self.TeamPanel, self.PanelTeam)
    local teamDatas = self.EStage:GetPassTeamData()
    self.TeamPanel.GridMember.gameObject:SetActiveEx(false)
    self:CreateTeamListByTeamDatas(teamDatas)
end

--================
--根据通关角色ECharId列表刷新通关队员头像列表。
--若通关队员头像列表不存在，则创建一个并刷新。
--@param teamIds：通关队员头像列表
--================
function XUiExpeditionStageReset:CreateTeamListByTeamDatas(teamDatas)
    if not self.HeadIcons then
        local headScript = require("XUi/XUiExpedition/MainPage/DetailProxy/XUiExpeditionDetailHeadIcon")
        self.HeadIcons = {}
        for i = 1, 3 do
            local ui = CS.UnityEngine.Object.Instantiate(self.TeamPanel.GridMember)
            local head = headScript.New(ui)
            head.Transform:SetParent(self.TeamPanel.PanelContent, false)
            self.HeadIcons[i] = head
        end
    end
    for i = 1, 3 do
        self.HeadIcons[i]:RefreshData(teamDatas and teamDatas[i])
    end
end

function XUiExpeditionStageReset:InitButtons()
    self.BtnTanchuangClose.CallBack = handler(self, self.OnClickClose)
    self.BtnConfirm.CallBack = handler(self, self.OnClickConfirm)
    self.BtnClose.CallBack = handler(self, self.OnClickCancel)
end

function XUiExpeditionStageReset:OnClickClose()
    self:Close()
end

function XUiExpeditionStageReset:OnClickConfirm()
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local itemId = eActivity:GetResetStageConsumeId()
    local haveCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = eActivity:GetResetStageConsumeCount()
    if needCount > haveCount then
        XUiManager.TipMsg(XUiHelper.GetText("CommonCoinNotEnough"))
        return
    end
    XDataCenter.ExpeditionManager.ResetStage(self.EStage,function()
            self:Close()
            if self.OnResetCb then
                self.OnResetCb()
            end
        end)
end

function XUiExpeditionStageReset:OnClickCancel()
    self:Close()
end