local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local BaseProxy = require("XUi/XUiExpedition/MainPage/DetailProxy/XUiExpeditionDetailProxy")
local BuffIconScript = require("XUi/XUiExpedition/MainPage/StageDetail/XUiExpeditionStageBuffIcon")
--普通战斗关卡详细代理
local XUiExpeditionBattleDetailProxy = XClass(BaseProxy, "XUiExpeditionBattleDetailProxy")

function XUiExpeditionBattleDetailProxy:InitPanel()
    self.Ui.PanelBattle.gameObject:SetActiveEx(true)
    self.Ui.PanelStory.gameObject:SetActiveEx(false)
    self:InitPanelBattle()
end

function XUiExpeditionBattleDetailProxy:InitPanelBattle()
    self.PanelBattle = {}
    XTool.InitUiObjectByUi(self.PanelBattle, self.Ui.PanelBattle)
    self:InitPanelDesc()
    self:InitPanelTargetList()
    self:InitPanelBottom()
    self:InitPanelBuff()
    self:InitPanelDrop()
    self:InitPanelTeam()
end
--================
--初始化关卡描述面板
--================
function XUiExpeditionBattleDetailProxy:InitPanelDesc()
    self.PanelDesc = {}
    XTool.InitUiObjectByUi(self.PanelDesc, self.PanelBattle.PanelDesc)
    self.PanelDesc.TxtStageTitle.text = self.Ui.EStage:GetStageName()
end
--================
--初始化目标提示面板
--================
function XUiExpeditionBattleDetailProxy:InitPanelTargetList()
    self.PanelTargetList = {}
    XTool.InitUiObjectByUi(self.PanelTargetList, self.PanelBattle.PanelTargetList)
    if not self.TargetGrids then
        self:InitTargetList()
    end
    local stageTarget = self.Ui.EStage:GetStageTargetDesc()
    for index, targetGrid in pairs(self.TargetGrids or {}) do
        local targetDesc = stageTarget and stageTarget[index]
        if targetDesc then
            targetGrid:Show()
            targetGrid:SetStarActive(false)
            targetGrid:SetText(targetDesc)
        else
            targetGrid:Hide()
        end
    end
end
--================
--初始化目标提示控件列表
--================
function XUiExpeditionBattleDetailProxy:InitTargetList()
    self.TargetGrids = {}
    local gridScript = require("XUi/XUiExpedition/MainPage/DetailProxy/XUiExpeditionTargetGrid")
    local i = 1
    while(true) do
        local gridGo = self.PanelTargetList["GridStar" .. i]
        if not gridGo then
            break
        end
        self.TargetGrids[i] = gridScript.New(gridGo)
        i = i + 1
    end
end
--================
--初始化界面下部按钮组
--================
function XUiExpeditionBattleDetailProxy:InitPanelBottom()
    self.PanelBottom = {}
    XTool.InitUiObjectByUi(self.PanelBottom, self.PanelBattle.PanelBottom)
    self.PanelBottom.PanelStageFightControl.gameObject:SetActiveEx(false)
    self.PanelBottom.TxtCostEnergy.text = 0
    self:SetPanelReset()
    self:InitButtons()
end
--================
--设置重置按钮显示
--================
function XUiExpeditionBattleDetailProxy:SetPanelReset()
    self.PanelBottom.PanelReset.gameObject:SetActiveEx(false)
end
--================
--设置按钮点击事件
--================
function XUiExpeditionBattleDetailProxy:InitButtons()
    self.PanelBottom.BtnEnter.CallBack = function() self:OnClickBtnEnter() end
end
--================
--出战按钮点击事件
--================
function XUiExpeditionBattleDetailProxy:OnClickBtnEnter()
    if not XDataCenter.ExpeditionManager.CheckHaveMember() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionNeedRecruitMember"))
        return
    end
    self:Hide()
    XLuaUiManager.Open("UiBattleRoleRoom", self.Ui.EStage:GetStageId())
end
--================
--初始化增益图标面板
--================
function XUiExpeditionBattleDetailProxy:InitPanelBuff()
    self.PanelBuff = {}
    XTool.InitUiObjectByUi(self.PanelBuff, self.PanelBattle.PanelBuff)
    if not self.PanelBuff.BuffList then self.PanelBuff.BuffList = {} end
    self.PanelBuff.GridBuff.gameObject:SetActiveEx(false)
    local i = 1
    self.PanelBuff.StageBuffCfgList = self.Ui.EStage:GetStageEvents()
    while(true) do
        if self.PanelBuff.StageBuffCfgList[i] then
            if not self.PanelBuff.BuffList[i] then
                self.PanelBuff.BuffList[i] = self:CreateBuffIcon()
            end
            self.PanelBuff.BuffList[i]:RefreshData(self.PanelBuff.StageBuffCfgList[i])
            self.PanelBuff.BuffList[i]:Show()
        elseif self.PanelBuff.BuffList[i] then
            self.PanelBuff.BuffList[i]:Hide()
        else
            break
        end
        i = i + 1
    end
    self.PanelBuff.ImgEmpty.gameObject:SetActiveEx(#self.PanelBuff.StageBuffCfgList == 0)
end
--================
--生成一个新的增益图标并返回该新增对象
--================
function XUiExpeditionBattleDetailProxy:CreateBuffIcon()
    local prefab = CS.UnityEngine.GameObject.Instantiate(self.PanelBuff.GridBuff.gameObject)
    prefab.transform:SetParent(self.PanelBuff.PanelBuffContent, false)
    return BuffIconScript.New(prefab, function() self:OnClickBuff() end)
end
--================
--点击增益图标时的事件
--================
function XUiExpeditionBattleDetailProxy:OnClickBuff()
    local BuffTipsType = XDataCenter.ExpeditionManager.BuffTipsType.StageBuff
    XLuaUiManager.Open("UiExpeditionBuffTips", BuffTipsType, self.PanelBuff.StageBuffCfgList)
end
--================
--初始化掉落列表
--================
function XUiExpeditionBattleDetailProxy:InitPanelDrop()
    local isFirstPass = self.Ui.EStage:GetFirstPass()
    if not self.PanelDrop then
        self.PanelDrop = {}
        XTool.InitUiObjectByUi(self.PanelDrop, self.PanelBattle.PanelDropList)
    end
    self.PanelDrop.GridCommonDrop.gameObject:SetActiveEx(false)
    self.PanelDrop.TxtDrop.gameObject:SetActiveEx(false)
    self.PanelDrop.TxtFirstDrop.gameObject:SetActiveEx(true)
    local rewardId = self.Ui.EStage:GetFirstRewardId()
    self.PanelDrop.TxtRecruit.gameObject:SetActiveEx(not isFirstPass)
    self.PanelDrop.TxtRecruit.text = self.Ui.EStage:GetDrawTimesRewardStr()
    self:CreateDropListByRewardId(rewardId)
    self.PanelDrop.ImgEmpty.gameObject:SetActiveEx(not rewardId or rewardId == 0)
    self.PanelDrop.GameObject:SetActiveEx(true)
end
--================
--根据奖励Id刷新首通掉落列表。
--若掉落列表不存在，则创建一个并刷新。
--若奖励Id不合法，则隐藏全部掉落图标组件并返回。
--@param rewardId：奖励表对应的Id
--================
function XUiExpeditionBattleDetailProxy:CreateDropListByRewardId(rewardId)
    if not rewardId or rewardId == 0 then --若没有奖励ID 或 没有查到对应奖励列表
        self:HideAllDropItem()
        return
    end
    local rewards = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        local index = 1
        while(true) do
            if rewards[index] then
                self:GetDropItem(index):Refresh(rewards[index], { ShowReceived = self.Ui.EStage:GetIsPass() })
            elseif self.PanelDrop.DropItems[index] then
                self:GetDropItem(index):Refresh(nil) --刷新空值可隐藏GridCommon组件
            else
                break
            end
            index = index + 1
        end
    end
end
--================
--根据序号获取掉落图标组件
--@param index：序号
--================
function XUiExpeditionBattleDetailProxy:GetDropItem(index)
    if not self.PanelDrop.DropItems then self.PanelDrop.DropItems = {} end
    if not self.PanelDrop.DropItems[index] then
        local ui = CS.UnityEngine.Object.Instantiate(self.PanelDrop.GridCommonDrop)
        local grid = XUiGridCommon.New(self.Ui, ui)
        grid.Transform:SetParent(self.PanelDrop.PanelDropContent, false)
        self.PanelDrop.DropItems[index] = grid
    end
    return self.PanelDrop.DropItems[index]
end
--================
--隐藏所有掉落图标组件
--================
function XUiExpeditionBattleDetailProxy:HideAllDropItem()
    for _, dropGrid in pairs(self.PanelDrop.DropItems or {}) do
        dropGrid:Refresh(nil) --刷新空值可隐藏GridCommon组件
    end
end
--================
--初始化通关队伍面板
--================
function XUiExpeditionBattleDetailProxy:InitPanelTeam()
    self.PanelBattle.PanelUsedTeam.gameObject:SetActiveEx(false)
end
--================
--根据通关角色ECharId列表刷新通关队员头像列表。
--若通关队员头像列表不存在，则创建一个并刷新。
--@param teamIds：通关队员头像列表
--================
function XUiExpeditionBattleDetailProxy:CreateTeamListByTeamDatas(teamData)
    if not self.PanelTeam.HeadIcons then
        local headScript = require("XUi/XUiExpedition/MainPage/DetailProxy/XUiExpeditionDetailHeadIcon")
        self.PanelTeam.HeadIcons = {}
        for i = 1, 3 do
            local ui = CS.UnityEngine.Object.Instantiate(self.PanelTeam.GridMember)
            local head = headScript.New(ui)
            head.Transform:SetParent(self.PanelTeam.PanelTeamContent, false)
            self.PanelTeam.HeadIcons[i] = head
        end
    end
    for i = 1, 3 do
        self.PanelTeam.HeadIcons[i]:RefreshData(teamData and teamData[i])
    end
end
return XUiExpeditionBattleDetailProxy