---@class XUiSettleEncorePrice
local XUiSettleEncorePrice = XClass(nil, "XUiSettleEncorePrice")

function XUiSettleEncorePrice:Ctor(ui, stageId, path)
    path = path or "SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/PanelInformation"
    self._UiParent = ui
    self._Panel = XUiHelper.TryGetComponent(ui.Transform, path, "RectTransform")
    if not self._Panel then
        XLog.Error("[XUiSettleEncorePrice] '再次挑战'无法显示血清，结算界面ui找不到PanelInformation")
        return
    end
    self._PanelEnough = XUiHelper.TryGetComponent(self._Panel, "TxtEnough", "RectTransform")
    self._PanelNotEnough = XUiHelper.TryGetComponent(self._Panel, "TxtNoEnough", "RectTransform")
    self._TxtChallengeAmountEnough = XUiHelper.TryGetComponent(self._PanelEnough, "TxtTim", "Text")
    self._TxtChallengeAmountNotEnough = XUiHelper.TryGetComponent(self._PanelNotEnough, "TxtTim", "Text")
    self._TxtActionPointEnough = XUiHelper.TryGetComponent(self._PanelEnough, "TxtSerum", "Text")
    self._TxtActionPointNotEnough = XUiHelper.TryGetComponent(self._PanelNotEnough, "TxtSerum", "Text")
    self:SetStage(stageId)
end

function XUiSettleEncorePrice:SetStage(stageId)
    if not self:MoveToEncoreBtn(stageId) then
        self:HidePriceUi()
        return
    end
    local price = XDataCenter.FubenManager.GetStageActionPointConsume(stageId)
    if price <= 0 then
        self:HidePriceUi()
        return
    end
    self:ShowPriceUi()
    -- 上一次挑战次数
    local challengeAmount = XDataCenter.FubenManager.GetFightChallengeCount()
    self:SetPrice(stageId, price * challengeAmount, challengeAmount)
end

function XUiSettleEncorePrice:SetPrice(stageId, totalPrice, challengeAmount)
    -- 挑战次数
    local maxChallengeAmount = XDataCenter.FubenManager.GetStageMaxChallengeCountSafely(stageId)
    local isChallengeAmountEnough = challengeAmount <= maxChallengeAmount
    self._TxtChallengeAmountEnough.gameObject:SetActiveEx(isChallengeAmountEnough)
    self._TxtChallengeAmountNotEnough.gameObject:SetActiveEx(not isChallengeAmountEnough)
    if isChallengeAmountEnough then
        self._TxtChallengeAmountEnough.text = challengeAmount
    else
        self._TxtChallengeAmountNotEnough.text = challengeAmount
    end

    -- 行动点数
    local actionPointAmount = XDataCenter.ItemManager.GetActionPointsNum()
    local isActionPointEnough = actionPointAmount >= totalPrice
    self._TxtActionPointEnough.gameObject:SetActiveEx(isActionPointEnough)
    self._TxtActionPointNotEnough.gameObject:SetActiveEx(not isActionPointEnough)
    if isActionPointEnough then
        self._TxtActionPointEnough.text = totalPrice
    else
        self._TxtActionPointNotEnough.text = totalPrice
    end
end

function XUiSettleEncorePrice:ShowPriceUi()
    self._Panel.gameObject:SetActiveEx(true)
end

function XUiSettleEncorePrice:HidePriceUi()
    self._Panel.gameObject:SetActiveEx(false)
end

-- “再次挑战” 按钮的位置根据配置stage决定
function XUiSettleEncorePrice:MoveToEncoreBtn(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local attachBtn
    if stageCfg.FunctionLeftBtn == XRoomSingleManager.BtnType.Again then
        attachBtn = self._UiParent.BtnLeft
    elseif stageCfg.FunctionRightBtn == XRoomSingleManager.BtnType.Again then
        -- 默认ui放在右边
        return true
    end
    if not attachBtn then
        return false
    end
    local rightBtnPos = self._UiParent.BtnRight.transform.localPosition
    local attachBtnPos = attachBtn.transform.localPosition
    local pricePanelPos = self._Panel.transform.localPosition
    local offset2Right = pricePanelPos - rightBtnPos
    local posShouldAttach = attachBtnPos + offset2Right
    self._Panel.transform.localPosition = posShouldAttach
    return true
end

return XUiSettleEncorePrice
