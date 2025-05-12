---@class XUiTransfiniteBattleSettlement:XLuaUi
local XUiTransfiniteBattleSettlement = XLuaUiManager.Register(XLuaUi, "UiTransfiniteBattleSettlement")

function XUiTransfiniteBattleSettlement:Ctor()
    ---@type XTransfiniteResult
    self._Result = false
    self.LastOperationType = nil
end

function XUiTransfiniteBattleSettlement:OnAwake()
    self:RegisterClickEvent(self.BtnAgain, self.OnClickRechallenge)
    self:RegisterClickEvent(self.BtnContinue, self.OnClickGoOn)
    self:RegisterClickEvent(self.BtnBack, self.OnClickBack)
    self:SetMouseVisible()
end

function XUiTransfiniteBattleSettlement:SetMouseVisible()
    -- 这里只有PC端开启了键鼠以后才能获取到设备
    if CS.XFight.Instance and CS.XFight.Instance.InputSystem then
        local inputKeyboard = CS.XFight.Instance.InputSystem:GetDevice(typeof(CS.XInputKeyboard))
        inputKeyboard.HideMouseEvenByDrag = false
    end
    CS.UnityEngine.Cursor.lockState = CS.UnityEngine.CursorLockMode.None
    CS.UnityEngine.Cursor.visible = true
end

---@param result XTransfiniteResult
function XUiTransfiniteBattleSettlement:OnStart(result)
    self._Result = result
end

function XUiTransfiniteBattleSettlement:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_TRANSFINITE_HIDE_SETTLE, self.Hide, self)
    self:Update()
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
    CS.XJoystickLSHelper.ForceResponse = true
end

function XUiTransfiniteBattleSettlement:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRANSFINITE_HIDE_SETTLE, self.Hide, self)
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
    CS.XJoystickLSHelper.ForceResponse = false
end

function XUiTransfiniteBattleSettlement:Update()
    local result = self._Result
    if not result then
        return
    end
    if self.TxtWinNumber.TextToSprite then
        self.TxtWinNumber:TextToSprite(result:GetWinAmount())
    end
    self.TxtBattelTime.text = XUiHelper.GetTime(result:GetClearTime())
    self.TxtNew.gameObject:SetActiveEx(result:IsNewRecord())

    if result:IsShowExtraCondition() then
        self.PanelExtraTask.gameObject:SetActiveEx(true)
        if result:IsCompleteExtraCondition() then
            self.PanelLose.gameObject:SetActiveEx(false)
            self.PanelWin.gameObject:SetActiveEx(true)
            self.TxtWin.text = result:GetCondition()
        else
            self.PanelLose.gameObject:SetActiveEx(true)
            self.PanelWin.gameObject:SetActiveEx(false)
            self.TxtLose.text = result:GetCondition()
        end
    else
        self.PanelExtraTask.gameObject:SetActiveEx(false)
    end

    if result:IsFinalStage() then
        self.BtnContinue:SetNameByGroup(0, XUiHelper.GetText("TransfiniteSettle"))
    end
end

function XUiTransfiniteBattleSettlement:Rechallenge()
    XDataCenter.TransfiniteManager.ExitFight()
    XDataCenter.TransfiniteManager.RequestRechallenge(self._Result)
end

function XUiTransfiniteBattleSettlement:OnClickRechallenge()
    self:Rechallenge()
end

function XUiTransfiniteBattleSettlement:_GoOn()
    XDataCenter.TransfiniteManager.RequestChallengeNextStage(self._Result)
end

function XUiTransfiniteBattleSettlement:OnClickGoOn()
    local result = self._Result
    if result:IsNextStageLock() then
        XUiManager.DialogTip(nil, XUiHelper.GetText("TransfiniteLockGoOn"), nil, nil, function()
            self:Rechallenge()
        end)
        return
    end
    local textAlert
    local isExtraMissionIncomplete = result:IsExtraMissionIncomplete()
    local isSomeoneDead = (not result:IsFinalStage()) and result:IsSomeoneDead()
    if isExtraMissionIncomplete and isSomeoneDead then
        textAlert = "TransfiniteLockGoOn3"

    elseif isExtraMissionIncomplete and not isSomeoneDead then
        textAlert = "TransfiniteLockGoOn2"

    elseif not isExtraMissionIncomplete and isSomeoneDead then
        textAlert = "TransfiniteLockGoOn4"
    end

    if textAlert then
        local sureCallback = function()
            self:_GoOn()
        end
        local extraData = {
            sureText = XUiHelper.GetText("TransfiniteGoOn"),
            closeText = XUiHelper.GetText("TransfiniteRechallenge"),
        }
        local cancelCallback = function()
            self:Rechallenge()
        end
        XUiManager.DialogTip(nil, XUiHelper.GetText(textAlert), nil, nil, sureCallback, extraData, cancelCallback)
        return
    end
    self:_GoOn()
end

function XUiTransfiniteBattleSettlement:OnClickBack()
    local text
    if self._Result:IsSomeoneDead() then
        text = "TransfiniteSave2"
    else
        text = "TransfiniteSave"
    end
    XUiManager.DialogTip(nil, XUiHelper.GetText(text), nil, nil, function()
        XDataCenter.TransfiniteManager.ExitFight()
        XDataCenter.TransfiniteManager.RequestConfirmResult(self._Result, XDataCenter.TransfiniteManager.CloseUiSettle)
    end, nil, function()
        XDataCenter.TransfiniteManager.ExitFight()
        self:Close()
    end)
end

function XUiTransfiniteBattleSettlement:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiTransfiniteBattleSettlement