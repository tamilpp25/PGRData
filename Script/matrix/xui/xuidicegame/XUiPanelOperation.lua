local XUiPanelDice = require("XUi/XUiDiceGame/XUiPanelDice")
---@class XUiPanelOperation
---@field public GameObject UnityEngine.GameObject
---@field public Transform UnityEngine.Transform
---@field protected CurSelectedOperation XDiceGameOperation
---@field protected OperationBtnGroup XUiButtonGroup
---@field protected GridBtnOption XUiComponent.XUiButton
---@field protected BtnReThrow XUiComponent.XUiButton
---@field protected BtnConfirm XUiComponent.XUiButton
---@field protected TxtCoinCost UnityEngine.UI.Text
---@field protected TxtCountTitle UnityEngine.UI.Text
---@field protected TxtCountNum UnityEngine.UI.Text
---@field protected TxtResult UnityEngine.UI.Text
---@field protected TxtResultNum UnityEngine.UI.Text
---@field protected TxtOperationDesc UnityEngine.UI.Text
local XUiPanelOperation = XClass(nil, "XUiPanelOperation")

local OPERATION_TITLE_LETTER_MAP = {
    [XDiceGameConfigs.OperationType.A] = "A.",
    [XDiceGameConfigs.OperationType.B] = "B.",
    [XDiceGameConfigs.OperationType.C] = "C.",
}
local TWEEN_TIME_COUNT = 0.5
local _, COLOR_TIP = CS.UnityEngine.ColorUtility.TryParseHtmlString("#FF4343")
local COLOR_WHITE = CS.UnityEngine.Color.white

---@param root XUiDiceGame
function XUiPanelOperation:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)

    self.DicePanel = XUiPanelDice.New(self.PanelDice, self.Root)
    self.TxtThrowResultTitle = self.Transform:Find("TitleText1"):GetComponent("Text")
    self.ThrowResultTitle = self.TxtThrowResultTitle.text

    self.OperationBtnGroup = self.PanelOption ---@type XUiButtonGroup
    self.OperationBtn = self.GridBtnOption.gameObject
    self.OperationBtn:SetActiveEx(false)

    self.OperationEntityDict = XDataCenter.DiceGameManager.GetOperationEntityDict()
    self.OperationBtns = {} ---@type table<number, XUiComponent.XUiButton>
    for id, operation in pairs(self.OperationEntityDict) do
        local buttonGo = CSObjectInstantiate(self.OperationBtn, self.OperationBtnGroup.transform) ---@type UnityEngine.GameObject
        buttonGo:SetActiveEx(true)
        self.OperationBtns[id] = buttonGo:GetComponent("XUiButton")
        self:InitOperationButton(self.OperationBtns[id], operation)
    end
    self.OperationBtnGroup:Init(self.OperationBtns, function(groupIndex)
        self:OnBtnOperationClick(groupIndex)
    end)
    self.OperationBtnGroup:CancelSelect()

    XUiHelper.RegisterClickEvent(self, self.BtnReThrow, self.OnBtnThrowClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)

    self.CoinItemId = XDataCenter.DiceGameManager.GetCoinItemId()
    self.CurSelection = 0
    self.DefaultSelection = XSaveTool.GetData(self:GetDefaultSelectionDataKey())
    self.HasConfirmed = false
    self:InitBottomView()
end

---@param button XUiComponent.XUiButton
---@param operation XDiceGameOperation
function XUiPanelOperation:InitOperationButton(button, operation)
    local operationTitleVerb = CSXTextManagerGetText("DiceGameOperationTitleVerb")
    local operationTitleRight = CSXTextManagerGetText(operation:GetFormulaText(), operation:GetScoreRate())
    local letterText = OPERATION_TITLE_LETTER_MAP[operation:GetType()]
    button:SetNameByGroup(0, operationTitleRight)
    button:SetNameByGroup(1, letterText)
    button:SetNameByGroup(2, operationTitleVerb)
    button:ShowTag(true)

    local layerObjects = { button.NormalObj,button.PressObj,button.SelectObj }
    for i = 1, #layerObjects do
        local iconRoot = layerObjects[i].transform:Find("PanelOptionTextInfo/PanelIcon")
        local iconPrefab = iconRoot:Find("RImgIcon").gameObject
        for _, v in ipairs(operation:GetPointIconPaths()) do
            CSObjectInstantiate(iconPrefab, iconRoot):GetComponent("RawImage"):SetRawImage(v)
        end
        iconPrefab:SetActiveEx(false)
    end
end

function XUiPanelOperation:InitBottomView()
    self.TxtResultNum.text = "0"
    self.TxtOperationDesc.text = ""
    self.TxtCountTitle.gameObject:SetActiveEx(false)
    self.TxtCountNum.gameObject:SetActiveEx(false)
    local operationA = XDataCenter.DiceGameManager.GetOperationBySelection(XDiceGameConfigs.OperationType.A)
    for _, v in ipairs(operationA:GetPointIconPaths()) do
        CSObjectInstantiate(self.PointIcon.gameObject, self.PointIconRoot):GetComponent("RawImage"):SetRawImage(v)
    end
    self.PointIcon.gameObject:SetActiveEx(false)
    self.PointIconRoot.gameObject:SetActiveEx(false)
    self.TxtCoinCost.text = tostring(XDataCenter.DiceGameManager.GetCoinCost())
    self.BtnConfirm:SetDisable(true, false)
    self.TagCoinCost.gameObject:SetActiveEx(false)
    self.RImgCoinIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.CoinItemId))
    self:UpdateCoinCountColor(self.CoinItemId, XDataCenter.ItemManager.GetCount(self.CoinItemId))

    self.GameObject:SetActiveEx(false)
end

function XUiPanelOperation:OnBtnOperationClick(groupIndex)
    self.CurSelection = groupIndex
    self.CurSelectedOperation = XDataCenter.DiceGameManager.GetOperationBySelection(groupIndex)
    self.DefaultSelection = self.CurSelection
    self:UpdateBottomView(self.OperationEntityDict[groupIndex])
    self:ShowOperationTipEffect(self.CurSelection <= 0)
end

function XUiPanelOperation:OnBtnConfirmClick()
    if self.BtnConfirm.ButtonState == CS.UiButtonState.Disable
    or not self.CurSelectedOperation
    or self.HasConfirmed == true then
        return
    end

    local manager = XDataCenter.DiceGameManager ---@type XDiceGameManager
    if not manager.HasEnoughCoin() then
        XUiManager.TipMsg(CSXTextManagerGetText("DiceGameNoEnoughCoinHint", manager.GetCoinCost()))
        return
    end

    local operationType = self.CurSelectedOperation:GetType()
    local selectionDelta = manager.GetSelectionCountDeltaByOperationType(operationType)
    local flagDelta, tipFlagCost, tweenDataGroup = manager.GetFlagCountDeltaByOperationType(operationType)
    manager.DiceGameConfirmSelectionRequest(operationType, function()
        if tipFlagCost then
            local flagCost = self.CurSelectedOperation:GetFlagRequired()
            local score = self.CurSelectedOperation:GetFlagToScore()
            XUiManager.TipMsg(CSXTextManagerGetText("DiceGameCostFlagHint", flagCost, score))
        end

        if tweenDataGroup then
            self:TweenCountIncrease(tweenDataGroup[1], #tweenDataGroup > 1 and tweenDataGroup[2] or nil)
        else
            self.Root:UpdatePanel(1, true, 3)
        end

        manager.ClearThrowResult()

        local easterEgg = XDataCenter.DiceGameManager.CheckEasterEggByScore()
        if easterEgg then
            self.Root:PopupEasterEgg(easterEgg)
        end
    end, flagDelta, selectionDelta)
    self.HasConfirmed = true
    XLog.Debug("DiceGame.SendOperationType:" .. operationType .. tostring(self.HasConfirmed))
end

function XUiPanelOperation:OnBtnThrowClick(pointerEventData)
    XDataCenter.DiceGameManager.DiceGameThrowDiceRequest(function()
        if pointerEventData then --ReThrow
            self:SetActive(false, false, true)
        end

        self.DicePanel:PlayThrowAnimation(function()
            self:OnEnable(true)
            local easterEgg = XDataCenter.DiceGameManager.CheckEasterEggByThrowResult()
            if easterEgg then
                self.Root:PopupEasterEgg(easterEgg)
            end
        end)
    end)
end

function XUiPanelOperation:TweenCountIncrease(tweenData, decreaseData)
    local tweenDeltaRatio = XMath.Clamp(math.abs(tweenData.delta) / self.CurSelectedOperation:GetFlagRequired(), 0.5, 1.0)
    local tweenTime = TWEEN_TIME_COUNT * tweenDeltaRatio
    XUiHelper.Tween(tweenTime, function(t)
        local var = math.floor(tweenData.base + tweenData.delta * t)
        self.TxtCountTitle.text = CSXTextManagerGetText(self.CurSelectedOperation:GetCountText())
        self.TxtCountNum.text = tostring(var)
    end, function()
        if decreaseData then
            self:TweenCountDecrease(decreaseData)
        else
            XScheduleManager.ScheduleOnce(function()
                self.Root:UpdatePanel(1, true, 3)
            end, 300)
        end
    end)
end

function XUiPanelOperation:TweenCountDecrease(tweenData)
    local tweenDeltaRatio = XMath.Clamp(math.abs(tweenData.delta) / self.CurSelectedOperation:GetFlagRequired(), 0.25, 1.0)
    local tweenTime = TWEEN_TIME_COUNT * tweenDeltaRatio
    XScheduleManager.ScheduleOnce(function()
        XUiHelper.Tween(tweenTime, function(t)
            local var = math.floor(tweenData.base + tweenData.delta * t)
            self.TxtCountTitle.text = CSXTextManagerGetText(self.CurSelectedOperation:GetCountText())
            self.TxtCountNum.text = tostring(var)
        end, function()
            XScheduleManager.ScheduleOnce(function()
                self.Root:UpdatePanel(1, true, 3)
            end, 300)
        end)
    end, 300)
end

---@param operation XDiceGameOperation
function XUiPanelOperation:UpdateBottomView(operation)
    local operationType = operation:GetType()
    local pointCount = XDataCenter.DiceGameManager.GetPointCount(operationType)
    self.TxtResult.text = CSXTextManagerGetText(operation:GetResultText())
    self.TxtResultNum.text = tostring(operation:GetResultValue(pointCount)) --score or flag

    self.PointIconRoot.gameObject:SetActiveEx(operationType == XDiceGameConfigs.OperationType.A)
    if operationType == XDiceGameConfigs.OperationType.C then
        self.TxtOperationDesc.text = CSXTextManagerGetText(operation:GetDescText(), operation:GetFlagRequired(), operation:GetFlagToScore())
    else
        self.TxtOperationDesc.text = CSXTextManagerGetText(operation:GetDescText())
    end

    local countTextActive = operationType ~= XDiceGameConfigs.OperationType.A
    self.TxtCountTitle.gameObject:SetActiveEx(countTextActive)
    self.TxtCountNum.gameObject:SetActiveEx(countTextActive)
    if countTextActive then
        self.TxtCountTitle.text = CSXTextManagerGetText(operation:GetCountText())
        self.TxtCountNum.text = tostring(operation:GetSpecialCount())
    end

    local hasSelectedOperation = self.OperationBtnGroup.CurSelectId ~= -1
    self.BtnConfirm:SetDisable(not hasSelectedOperation, hasSelectedOperation)
    self.TagCoinCost.gameObject:SetActiveEx(hasSelectedOperation)
end

function XUiPanelOperation:ShowOperationTipEffect(active)
    for id, btn in ipairs(self.OperationBtns) do
        btn.transform:Find("TagEffect").gameObject:SetActiveEx(active)
    end
end

function XUiPanelOperation:UpdateCoinCountColor(id, count)
    local manager = XDataCenter.DiceGameManager
    local coinItemId = manager.GetCoinItemId()
    local coinCost = manager.GetCoinCost()
    if id ~= coinItemId then
        XLog.Error("DiceGame.PanelOperation.UpdateCoinCountColor: itemId:" .. id .. " does not match coinItemId:" .. coinItemId)
        return
    end

    if count < coinCost then
        self.TxtCoinCost.color = COLOR_TIP
    else
        self.TxtCoinCost.color = COLOR_WHITE
    end
end

function XUiPanelOperation:OnEnable(playAnimResultEnable)
    self:SelectDefault()
    self:ShowOperationTipEffect(self.CurSelection <= 0)
    self.DicePanel:SetResultViewActive(true)
    if playAnimResultEnable then
        self.DicePanel:UpdateDiceView(true,function()
            self.GameObject:SetActiveEx(true)
            self.Root:PlayAnimationWithMask("PanelOperationEnable")
        end)
    else
        self.DicePanel:UpdateDiceView(false)
        self.GameObject:SetActiveEx(true)
        self.Root:PlayAnimationWithMask("PanelOperationEnable")
    end
end

function XUiPanelOperation:SetActive(active, needThrowDice, playAnim, disableFinishCb)
    if active then
        if needThrowDice then -- jump from StartPanel
            self:OnBtnThrowClick(nil, true)
        else -- jump from MainUi (game has throwResult already)
            self:OnEnable(false)
        end
        self.HasConfirmed = false
    else
        self.DicePanel:SetResultViewActive(false)
        if playAnim and self.GameObject.activeInHierarchy then
            self.Root:PlayAnimationWithMask("PanelOperationDisable", function()
                self.GameObject:SetActiveEx(false)
                if disableFinishCb then disableFinishCb() end
            end)
        else
            self.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelOperation:SelectDefault()
    if self.DefaultSelection then
        self.OperationBtnGroup:SelectIndex(self.DefaultSelection, true)
    end
end

function XUiPanelOperation:SaveDefaultSelectionData()
    XSaveTool.SaveData(self:GetDefaultSelectionDataKey(), self.DefaultSelection)
end

function XUiPanelOperation.RemoveDefaultSelectionData()
    XSaveTool.RemoveData(XUiPanelOperation.GetDefaultSelectionDataKey())
end

function XUiPanelOperation.GetDefaultSelectionDataKey()
    return string.format("%s_DiceGame%d_DefaultSelection", XPlayer.Id, XDataCenter.DiceGameManager.GetActivityId())
end

return XUiPanelOperation