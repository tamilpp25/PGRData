-- local XUiGridTRPGTestAction = require("XUi/XUiTRPG/XUiGridTRPGTestAction")
local tonumber = tonumber
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiTRPGFightTips = XLuaUiManager.Register(XLuaUi, "UiTRPGFightTips")

function XUiTRPGFightTips:OnAwake()
    self:AutoAddListener()
    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiTRPGFightTips:OnStart(cardId, cardIndex, stageId, challengeLevel, qucikRewardId)
    self.CardId = cardId
    self.CardIndex = cardIndex
    self.StageId = stageId
    self.ChallengeLevel = challengeLevel
    self.QucikRewardId = qucikRewardId
    self.ItemGrids = {}
end

function XUiTRPGFightTips:OnEnable()

    self:UpdateUi()
end

function XUiTRPGFightTips:OnDisable()

end

function XUiTRPGFightTips:OnDestroy()
    local cardIndex = self.CardIndex
end

function XUiTRPGFightTips:UpdateUi()
    local cardId = self.CardId
    local stageId = self.StageId
    local challengeLevel = self.ChallengeLevel

    local icon = XTRPGConfigs.GetMazeCardIconR(cardId)
    self.RImgBg:SetRawImage(icon)

    local isQuickFight = XDataCenter.TRPGManager.CheckQuickFight(challengeLevel)
    self.BtnEnter.gameObject:SetActiveEx(not isQuickFight)
    self.BtnQuickFight.gameObject:SetActiveEx(isQuickFight)

    local canGiveUp = XTRPGConfigs.CheckMazeCardType(cardId, XTRPGConfigs.CardType.Fight)
    self.BtnGiveUp.gameObject:SetActiveEx(canGiveUp)

    local des = isQuickFight and XTRPGConfigs.GetMazeCardQuickFightDes(cardId) or XTRPGConfigs.GetMazeCardFightDes(cardId)
    self.TxtDes.text = des

    local name = XDataCenter.FubenManager.GetStageName(stageId)
    self.TxtChapter.text = name

    if self.TxtCardOrder then
        local cardOrder = XTRPGConfigs.GetMazeCardOrder(cardId)
        self.TxtCardOrder.text = cardOrder
    end

    if self.TxtCardName then
        local cardName = XTRPGConfigs.GetMazeCardName(cardId)
        self.TxtCardName.text = cardName
    end

    if self.TxtLevel then
        if challengeLevel and challengeLevel > 0 then
            self.TxtLevel.text = challengeLevel
            self.TxtLevel.transform.parent.gameObject:SetActiveEx(true)
        else
            self.TxtLevel.transform.parent.gameObject:SetActiveEx(false)
        end
    end

    local rewardId
    if isQuickFight then
        rewardId = self.QucikRewardId
    else
        local cfg = XDataCenter.FubenManager.GetStageLevelControl(stageId)
        rewardId = cfg and cfg.FinishRewardShow
        if not rewardId or rewardId == 0 then
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            rewardId = stageCfg.FinishRewardShow
        end
    end

    local rewardCount = 0
    if rewardId and rewardId ~= 0 then
        local rewards = XRewardManager.GetRewardList(rewardId)
        for index, item in ipairs(rewards) do
            local grid = self.ItemGrids[index]
            if not grid then
                local ui = CSUnityEngineObjectInstantiate(self.GridCommon, self.PanelRewardContent)
                grid = XUiGridCommon.New(self, ui)
                self.ItemGrids[index] = grid
            end

            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
            rewardCount = rewardCount + 1
        end
    end

    for index = rewardCount + 1, #self.ItemGrids do
        local grid = self.ItemGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

end

function XUiTRPGFightTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnGiveUp, self.OnBtnBtnGiveUp)
    self:RegisterClickEvent(self.BtnEnter, self.OnClickBtnEnter)
    self:RegisterClickEvent(self.BtnQuickFight, self.OnClickBtnQuickFight)
end

function XUiTRPGFightTips:OnBtnBackClick()
    self:Close()
end

function XUiTRPGFightTips:OnBtnBtnGiveUp()
    local callBack = function()
        self:Close()
        local cardIndex = self.CardIndex
        XDataCenter.TRPGManager.TRPGMazeGiveUpChallengeRequest(cardIndex)
    end
    local title = CSXTextManagerGetText("TRPGMazeGiveUpFightTipTitle")
    local content = CSXTextManagerGetText("TRPGMazeGiveUpFightTipContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callBack)
end

function XUiTRPGFightTips:OnClickBtnEnter()
    self:Close()
    local stageId = self.StageId
    XLuaUiManager.Open("UiBattleRoleRoom", stageId)
end

function XUiTRPGFightTips:OnClickBtnQuickFight()
    local cardIndex = self.CardIndex
    XDataCenter.TRPGManager.TRPGMazeQuickChallengeRequest(cardIndex)
    self:Close()
end