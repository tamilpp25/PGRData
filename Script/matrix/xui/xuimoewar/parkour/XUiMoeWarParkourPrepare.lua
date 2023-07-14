
local XUiMoeWarParkourPrepare = XLuaUiManager.Register(XLuaUi, "UiMoeWarParkourPrepare")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local MAX_LABEL_MEMBER = 3 --最大标签数

function XUiMoeWarParkourPrepare:OnAwake()
    self:InitCb()
end

function XUiMoeWarParkourPrepare:OnStart(stage)
    self.Stage = stage
    self:InitView()
end

function XUiMoeWarParkourPrepare:InitCb()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    self.BtnAddRole.CallBack = function() self:OnBtnOccupyClick() end
    self.BtnChange.CallBack = function() self:OnBtnOccupyClick() end
end 

function XUiMoeWarParkourPrepare:InitView()
    self.TextTitle.text = self.Stage:GetName()
    self.TxtExplain.text = self.Stage:GetDesc()
    
    local rewardId = XDataCenter.MoeWarManager.GetParkourRewardId()

    if XTool.IsNumberValid(rewardId) and not self.Stage:IsTeachStage() then
        local rewards = XRewardManager.GetRewardListNotCount(rewardId)
        for i, reward in ipairs(rewards or {}) do
            local ui = i == 1 and self.RewardGrid or CS.UnityEngine.Object.Instantiate(self.RewardGrid, self.PanelReward, false)
            local grid = XUiGridCommon.New(self, ui)
            grid:Refresh(reward)
            grid.GameObject:SetActiveEx(true)
        end
    else
        self.RewardGrid.gameObject:SetActiveEx(false)
    end
    
    self.Team = XDataCenter.MoeWarManager.GetParkourTeam()
    local roleId = self.Team:GetEntityIdByTeamPos(self.Team:GetFirstFightPos())
    local helperId = XMoeWarConfig.GetHelperIdByRobotId(roleId)
    local isOwn = XDataCenter.MoeWarManager.CheckHelperIsOwn(helperId)
    if isOwn then
        self:RefreshRole(helperId)
    else
        self:RefreshRole()
    end
    
end 

function XUiMoeWarParkourPrepare:OnBtnStartClick()
    if not self.Team or self.Team:GetIsEmpty() then
        XUiManager.TipText("MoeWarParkourFightNotCharacter")
        return
    end
    
    if XDataCenter.MoeWarManager.CheckRespondItemIsMax() then
        return
    end
    
    --XDataCenter.MoeWarManager.RefreshLastMoodValue(self.HelperId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.Stage:GetId()) 
    XDataCenter.FubenManager.EnterMoeWarFight(stageCfg, self.Team, true)
end 

function XUiMoeWarParkourPrepare:OnBtnOccupyClick()
    RunAsyn(function()
        XLuaUiManager.Open("UiMoeWarParkourPerson", self.HelperId)
        local signalCode, helperId = XLuaUiManager.AwaitSignal("UiMoeWarParkourPerson", "UpdateParkourEntityId", self)
        if signalCode ~= XSignalCode.SUCCESS then return end
        self:RefreshRole(helperId)
    end)
    
end

function XUiMoeWarParkourPrepare:RefreshRole(helperId)
    local hasRole = XTool.IsNumberValid(helperId)
    self.BtnAddRole.gameObject:SetActiveEx(not hasRole)
    self.BtnChange.gameObject:SetActiveEx(hasRole)
    self.HelperId = helperId
    if hasRole then
        local robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
        local charId = XEntityHelper.GetCharacterIdByEntityId(robotId)
        --名称
        self.TxtName.text = XEntityHelper.GetCharacterLogName(charId)
        --头像
        self.RImgHead:SetRawImage(XMoeWarConfig.GetMoeWarPreparationHelperCirleIcon(helperId))
        --心情
        local curMoodValue = XDataCenter.MoeWarManager.GetMoodValue(helperId)
        local moodUpLimit = XMoeWarConfig.GetPreparationHelperMoodUpLimit(helperId)
        self.TxtMoodAdd.text = string.format("%d/%d", curMoodValue, moodUpLimit)
        self.ImgCurEnergy.fillAmount = curMoodValue / moodUpLimit
        local moodId = XMoeWarConfig.GetCharacterMoodId(curMoodValue)
        self.ImgCurEnergy.color = XMoeWarConfig.GetCharacterMoodColor(moodId)
        --心情图标
        self.ImgMood:SetSprite(XMoeWarConfig.GetCharacterMoodIcon(moodId))
        --角色标签
        local helperLabelIds = XMoeWarConfig.GetMoeWarPreparationHelperLabelIds(helperId)
        for idx = 1, MAX_LABEL_MEMBER do
            local uiLabel = self["RoleText"..idx]
            local labelId = helperLabelIds[idx]
            local isShow = XTool.IsNumberValid(labelId)
            uiLabel.gameObject:SetActiveEx(isShow)
            if isShow then
                uiLabel.text = XMoeWarConfig.GetPreparationStageTagLabelById(labelId)
            end
        end
        self.Team:UpdateEntityTeamPos(robotId, self.Team:GetFirstFightPos(), true)
    else
        self.Team:UpdateEntityTeamPos(0, self.Team:GetFirstFightPos(), true)
    end
end 