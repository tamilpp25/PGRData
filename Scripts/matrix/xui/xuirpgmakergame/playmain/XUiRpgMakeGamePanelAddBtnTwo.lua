local XUiRpgMakeGamePanelAddBtnTwo = XClass(nil, "XUiRpgMakeGamePanelAddBtnTwo")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CloseTotalTime = CS.XGame.ClientConfig:GetInt("RpgMakerGamePlayMainShowObjectTipsStayTime")

--是否获取提示的二次弹窗
function XUiRpgMakeGamePanelAddBtnTwo:Ctor(ui, closeCb, clickHintCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.CloseCallBack = closeCb
    self.ClickHintCb = clickHintCb

    self.TxtWord.text = CSXTextManagerGetText("RpgMakerGameSecondHintTitle")

    self.BtnNo.CallBack = function() self:Hide() end
    XUiHelper.RegisterClickEvent(self, self.BtnHint, self.OnBtnHintClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAnswer, self.OnBtnAnswerClick)
end

function XUiRpgMakeGamePanelAddBtnTwo:OnBtnHintClick()
    if self.StageDb and self.StageDb:IsUnlockHint() then
        self:ShowHint()
        return
    end
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapUnlockHint(self.StageId, XRpgMakerGameConfigs.XRpgMakerGameRoleAnswerType.Hint, 
        handler(self, self.ShowHint))
end

function XUiRpgMakeGamePanelAddBtnTwo:ShowHint()
    self:Hide()
    if self.ClickHintCb then
        self.ClickHintCb()
    end
end

function XUiRpgMakeGamePanelAddBtnTwo:OnBtnAnswerClick()
    if self.StageDb and self.StageDb:IsUnlockAnswer() then
        self:ShowAnswer()
        return
    end

    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapUnlockHint(self.StageId, XRpgMakerGameConfigs.XRpgMakerGameRoleAnswerType.Answer, 
        handler(self, self.ShowAnswer))
end

function XUiRpgMakeGamePanelAddBtnTwo:ShowAnswer()
    local enterStageDb = XDataCenter.RpgMakerGameManager:GetRpgMakerGameEnterStageDb()
    local mapId = enterStageDb:GetMapId()
    XLuaUiManager.Open("UiRpgMakerGameMapTip", mapId)
    self:Hide(true)
end

function XUiRpgMakeGamePanelAddBtnTwo:Show(stageId)
    self.StageId = stageId
    self.StageDb = XDataCenter.RpgMakerGameManager.GetRpgMakerActivityStageDb(stageId)
    self:UpdateCoin()
    self.GameObject:SetActiveEx(true)
end

function XUiRpgMakeGamePanelAddBtnTwo:UpdateCoin()
    local stageId = self.StageId
    local stageDb = self.StageDb
    local itemId = XDataCenter.ItemManager.ItemId.RpgMakerGameHintCoin
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(itemId)

    local isUnlockHint = self.StageDb and self.StageDb:IsUnlockHint()
    local hintCost = XRpgMakerGameConfigs.GetStageHintCost(stageId)
    self.HintNorTextNum.text = hintCost
    self.HintPreTextNum.text = hintCost
    self.HintNorIcon:SetRawImage(itemIcon)
    self.HintPreIcon:SetRawImage(itemIcon)
    if self.HintNorPanel then
        self.HintNorPanel.gameObject:SetActiveEx(not isUnlockHint)
    end
    if self.HintPrePanel then
        self.HintPrePanel.gameObject:SetActiveEx(not isUnlockHint)
    end

    local isUnlcokAnswer = self.StageDb and self.StageDb:IsUnlockAnswer()
    local answerCost = XRpgMakerGameConfigs.GetStageAnswerCost(stageId)
    self.AnswerNorTextNum.text = answerCost
    self.AnswerPreTextNum.text = answerCost
    self.AnswerNorIcon:SetRawImage(itemIcon)
    self.AnswerPreIcon:SetRawImage(itemIcon)
    self.AnswerNorPanel.gameObject:SetActiveEx(not isUnlcokAnswer)
    self.AnswerPrePanel.gameObject:SetActiveEx(not isUnlcokAnswer)
end

function XUiRpgMakeGamePanelAddBtnTwo:Hide(isNotCallBack)
    if not isNotCallBack and self.CloseCallBack then
        self.CloseCallBack()
    end
    self.GameObject:SetActiveEx(false)
end

return XUiRpgMakeGamePanelAddBtnTwo