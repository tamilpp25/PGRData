local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPokerGuessing2Character = require("XUi/XUiPokerGuessing2/Game/XUiPokerGuessing2Character")
local XUiPokerGuessing2Card = require("XUi/XUiPokerGuessing2/Game/XUiPokerGuessing2Card")

---@class XUiPokerGuessing2Main : XLuaUi
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2Main = XLuaUiManager.Register(XLuaUi, "UiPokerGuessing2Main")

function XUiPokerGuessing2Main:OnAwake()
    ---@type XUiPokerGuessing2Card[]
    self._EnemyPreviewCards = {  }

    self._GridRewards = { XUiGridCommon.New(self.Grid256New) }

    ---@type XUiPokerGuessing2Card[]
    self._Cards = {
        XUiPokerGuessing2Card.New(self.Card1, self),
        XUiPokerGuessing2Card.New(self.Card2, self)
    }
    for i = 1, #self._Cards do
        self._Cards[i]:KeepTheCardFaceUp(true)
    end
    self:BindExitBtns()

    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe({
        XDataCenter.ItemManager.ItemId.PokerGuessing2ItemId
    }, self.PanelSpecialTool, self)
    ---@type XUiPokerGuessing2Character
    self._Player = XUiPokerGuessing2Character.New(self.PanelRight, self, true)
    ---@type XUiPokerGuessing2Character
    self._Enemy = XUiPokerGuessing2Character.New(self.PanelLeft, self)
    XUiHelper.RegisterClickEvent(self, self.BtnPlay, self.OnClickPlay, nil, true)
    self.BtnPlay02 = self.BtnPlay02 or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelBottom/BtnPlay02", "XUiButton")
    XUiHelper.RegisterClickEvent(self, self.BtnPlay02, self.OnClickPlay, nil, true)
    self:BindHelpBtn(nil, "PokerGuessing2Help")
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.OnClickLeftStage, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnRight, self.OnClickRightStage, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnClickSelectRole, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnClickTask, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnClickStory, nil, true)
    self.BtnShop:ShowReddot(false)
    self.RewardReceive = self.RewardReceive or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelLeft/PanelReward/Finish", "RectTransform")
end

function XUiPokerGuessing2Main:OnStart()
    self._Control:PlayFirstTimeStory()
    self._Control:SelectDefaultStage()
end

function XUiPokerGuessing2Main:OnEnable()
    self:UpdateStage()
    self:UpdatePlayer()
    self:UpdateEnemy()
    self:UpdateReward()
    self:UpdateStageCards()
    self:UpdateBtnTaskRedPoint()
    self._Control:UpdateTime()
    self:UpdateTime()
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_TIME, self.UpdateTime, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_SELECT_CHARACTER, self.UpdatePlayer, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_MAIN_ENEMY, self.UpdateEnemy, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_CLOSED, self.CheckGuide, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_SUMMARY_CLOSED, self.CheckGuide, self)
end

function XUiPokerGuessing2Main:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_TIME, self.UpdateTime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_SELECT_CHARACTER, self.UpdatePlayer, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_MAIN_ENEMY, self.UpdateEnemy, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_UI_CLOSED, self.CheckGuide, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_UI_SUMMARY_CLOSED, self.CheckGuide, self)
end

function XUiPokerGuessing2Main:UpdateStage()
    local data = self._Control:GetUiMain()
    local desc = data.StageDesc
    if desc == "" then
        self.TxtDetail1.transform.parent.gameObject:SetActiveEx(false)
    else
        self.TxtDetail1.text = desc
    end

    local index = data.StageIndex
    local maxIndex = data.StageMaxIndex
    self.TxtStageIndex.text = string.format("%s/%s", index, maxIndex)

    local enemyDialogue = data.EnemyDialogue
    self._Enemy:Speak(enemyDialogue)

    -- 新增按钮 第二次挑战改为 "重温对局"
    if data.IsPassed then
        if self.BtnPlay02 then
            self.BtnPlay02.gameObject:SetActiveEx(true)
            self.BtnPlay.gameObject:SetActiveEx(false)
        else
            self.BtnPlay.gameObject:SetActiveEx(true)
        end
        self.RewardReceive.gameObject:SetActiveEx(true)
    else
        if data.IsOpen then
            self.BtnPlay02.gameObject:SetActiveEx(false)
            self.BtnPlay.gameObject:SetActiveEx(true)
        else
            self.BtnPlay02.gameObject:SetActiveEx(false)
            self.BtnPlay.gameObject:SetActiveEx(false)
        end
        self.RewardReceive.gameObject:SetActiveEx(false)
    end
end

function XUiPokerGuessing2Main:OnClickPlay()
    if self._Control:IsPreStagePassed() then
        self._Control:StartGame()
    else
        -- 提示不可挑战 前置关卡未完成
        XUiManager.TipText("FubenPreStageNotPass")
    end
end

function XUiPokerGuessing2Main:OnClickHelp()
    self._Control:UseTips()
end

function XUiPokerGuessing2Main:UpdateEnemy()
    local enemy = self._Control:GetEnemy()
    self._Enemy:Update(enemy)
    self._Enemy:UpdateTimeForLockedStage()
end

function XUiPokerGuessing2Main:UpdatePlayer()
    self._Player:Update(self._Control:GetPlayer())
end

function XUiPokerGuessing2Main:UpdateTime()
    local time = self._Control:GetTime()
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
    self._Enemy:UpdateTimeForLockedStage()
end

function XUiPokerGuessing2Main:UpdateReward()
    local rewards = self._Control:GetRewards()
    local onlyOneReward = { rewards[1] }
    XTool.UpdateDynamicGridCommon(self._GridRewards, onlyOneReward, self.Grid256New, self)
end

function XUiPokerGuessing2Main:UpdateStageCards()
    local icons = self._Control:GetStageCards()
    XTool.UpdateDynamicItem(self._Cards, icons, self.Card1, XUiPokerGuessing2Card, self)
end

function XUiPokerGuessing2Main:OnClickLeftStage()
    self._Control:MoveToLeftStage()
    self:UpdateStage()
    self:UpdateEnemy()
    self:UpdateStageCards()
    self:UpdateReward()
end

function XUiPokerGuessing2Main:OnClickRightStage()
    self._Control:MoveToRightStage()
    self:UpdateStage()
    self:UpdateEnemy()
    self:UpdateStageCards()
    self:UpdateReward()
end

function XUiPokerGuessing2Main:OnClickSelectRole()
    XLuaUiManager.Open("UiPokerGuessing2PopupSelectRole")
end

function XUiPokerGuessing2Main:OnClickTask()
    XLuaUiManager.Open("UiPokerGuessing2Task")
end

function XUiPokerGuessing2Main:OnClickStory()
    XLuaUiManager.Open("UiPokerGuessing2Story")
end

function XUiPokerGuessing2Main:UpdateBtnTaskRedPoint()
    ---@type XUiComponent.XUiButton
    local btn = self.BtnTask
    btn:ShowReddot(XMVCA.XPokerGuessing2:HasTaskCanReceive())
end

function XUiPokerGuessing2Main:CheckGuide()
    XDataCenter.GuideManager.CheckGuideOpen()
end

return XUiPokerGuessing2Main
