---@class XBigWorldUIAgency : XAgency
---@field private _Model XBigWorldUIModel
---@field private _QueueHelper XBigWorldQueueUiHelper
local XBigWorldUIAgency = XClass(XAgency, "XBigWorldUIAgency")

local XBigWorldUi = require("XModule/XBigWorldUI/Base/XBigWorldUi")

function XBigWorldUIAgency:OnInit()
    self._InputRefCount = 0
    self._FightUiCb = {}
end

function XBigWorldUIAgency:InitRpc()
end

function XBigWorldUIAgency:InitEvent()
end

function XBigWorldUIAgency:IsPauseFight(uiName)
    return self._Model:IsPauseFight(uiName)
end

function XBigWorldUIAgency:IsChangeInput(uiName)
    return self._Model:IsChangeInput(uiName)
end

function XBigWorldUIAgency:IsQueueUI(uiName)
    return self._Model:IsQueue(uiName)
end

function XBigWorldUIAgency:IsCloseLittleMap(uiName)
    return self._Model:IsCloseLittleMap(uiName)
end

function XBigWorldUIAgency:IsHideFightUi(uiName)
    return self._Model:IsHideFightUi(uiName)
end

function XBigWorldUIAgency:Open(uiName, ...)
    if self:IsQueueUI(uiName) then
        if not self._QueueHelper then
            self._QueueHelper = require("XModule/XBigWorldUI/Base/XBigWorldQueueUiHelper").New()
        end
        --XDataCenter.UiQueueManager.Open(uiName, ...)
        self._QueueHelper:Open(uiName, ...)
    else
        XLuaUiManager.Open(uiName, ...)
    end
end

function XBigWorldUIAgency:OpenWithCallback(uiName, callback, ...)
    XLuaUiManager.OpenWithCallback(uiName, callback, ...)
end

function XBigWorldUIAgency:OpenSingleUi(uiName, ...)
    if self:IsShow(uiName) then
        self:Close(uiName)
    elseif XLuaUiManager.IsUiLoad(uiName) then
        XLuaUiManager.Remove(uiName)
    end

    self:Open(uiName, ...)
end

function XBigWorldUIAgency:PopThenOpen(uiName, ...)
    XLuaUiManager.PopThenOpen(uiName, ...)
end

function XBigWorldUIAgency:CloseAllUntilTopUi(uiName, cb)
    local closeCb
    closeCb = function()
        local topUiName = self:GetTopUiName()
        if string.IsNilOrEmpty(topUiName) then
            return
        end
        if uiName == topUiName then
            if cb then cb() end
            return
        end
        self:Close(topUiName, closeCb)
    end
    closeCb()
end

function XBigWorldUIAgency:Close(uiName, callback)
    if callback then
        XLuaUiManager.CloseWithCallback(uiName, callback)
    else
        XLuaUiManager.Close(uiName)
    end
end

function XBigWorldUIAgency:SafeClose(uiName)
    XLuaUiManager.SafeClose(uiName)
end

function XBigWorldUIAgency:IsShow(uiName)
    return XLuaUiManager.IsUiShow(uiName)
end

function XBigWorldUIAgency:IsUiLoad(uiName)
    return XLuaUiManager.IsUiLoad(uiName)
end

function XBigWorldUIAgency:GetTopUiName()
    return XLuaUiManager.GetTopUiName()
end

function XBigWorldUIAgency:SetActive(uiName, isActive)
    XLuaUiManager.SetUiActive(uiName, isActive)
end

--- 注册UI
---@param super XLuaUi 为空时，默认参数为XBigWorldUI
---@return 
function XBigWorldUIAgency:Register(super, uiName)
    if XMain.IsEditorDebug then
        if super and not CheckClassSuper(super, XBigWorldUi)  then
            XLog.Error("父类必须继承自XBigWorldUi, UIName = " .. uiName)
            super = XBigWorldUi
        end
    end
    if not super then
        super = XBigWorldUi
    end
    return XLuaUiManager.Register(super, uiName)
end

function XBigWorldUIAgency:AddInputRefCount()
    --第一次调用
    if self._InputRefCount == 0 then
        XMVCA.XBigWorldGamePlay:ChangeSystemInput()
    end
    self._InputRefCount = self._InputRefCount  + 1
end

function XBigWorldUIAgency:SubInputRefCount()
    self._InputRefCount = self._InputRefCount  - 1
    --没有引用了
    if self._InputRefCount == 0 then
        XMVCA.XBigWorldGamePlay:ChangeFightInput()
    end
end

function XBigWorldUIAgency:ResetInputRefCount()
    self._InputRefCount = 0
    XMVCA.XBigWorldGamePlay:ChangeFightInput()
end

function XBigWorldUIAgency:ForceResetSystemInput()
    self._InputRefCount = 0
    XMVCA.XBigWorldGamePlay:ChangeSystemInput()
end

function XBigWorldUIAgency:HideOtherUi(uiName)
    local hideUiNames = self._Model:GetHideUiNames(uiName)

    if not XTool.IsTableEmpty(hideUiNames) then
        for _, hideUiName in ipairs(hideUiNames) do
            self:SetActive(hideUiName, false)
        end
    end
end

function XBigWorldUIAgency:ShowOtherUi(uiName)
    local hideUiNames = self._Model:GetHideUiNames(uiName)

    if not XTool.IsTableEmpty(hideUiNames) then
        for _, hideUiName in ipairs(hideUiNames) do
            self:SetActive(hideUiName, true)
        end
    end
end

-- region 常用接口

function XBigWorldUIAgency:TipCode(code, ...)
    XUiManager.TipCode(code, ...)
end

-- endregion

--region 通用界面

---@param data XBWPopupConfirmData
function XBigWorldUIAgency:OpenConfirmPopup(data)
    self:Open("UiBigWorldPopupConfirm", data)
end

function XBigWorldUIAgency:OpenConfirmPopupUiWithCmd(data)
    local confrimData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    if self._Model:IsNotRepeatConfirmPopup(data.Key) then
        self:SendConfirmPopupCloseCommand(data.Key, false, true, true)
    else
        confrimData:InitKey(data.Key):InitInfo(data.Title, data.Tips, true)
        confrimData:InitSureClick(data.SureText, nil, not data.IsOnlyCancel)
        confrimData:InitCancelAndCloseClick(data.CancelText, nil, true)

        self:OpenConfirmPopup(confrimData)
    end
end

---@param data XBWPopupQuitConfirmData
function XBigWorldUIAgency:OpenQuitConfirmPopup(data)
    self:Open("UiBigWorldPopupQuitShow", data)
end

function XBigWorldUIAgency:OpenQuitConfirmPopupWithCmd(data)
    local confrimData = XMVCA.XBigWorldCommon:GetPopupQuitConfirmData()

    confrimData:InitInfo(data.Title, data.Tips, true)
    confrimData:InitCancelAndCloseClick(data.CancelText)
    confrimData:InitSureClick(data.SureText)

    self:OpenQuitConfirmPopup(confrimData)
end

function XBigWorldUIAgency:OpenBigWorldObtain(rewardData, title, closeCb)
    self:Open("UiBigWorldObtain", rewardData, title, closeCb)
end

function XBigWorldUIAgency:OpenBigWorldObtainWithCmd(data)
    if not data then
        return
    end
    self:OpenBigWorldObtain(data.RewardData, data.Title, data.CloseCb)
end

function XBigWorldUIAgency:OpenDramaSkipPopup(content)
    self:Open("UiBigWorldPopupSkipDialogue", content)
end

function XBigWorldUIAgency:OpenDramaSkipPopupWithCmd(data)
    if not data then
        return
    end

    self:OpenDramaSkipPopup(data.Content)
end

function XBigWorldUIAgency:OpenLoadingMask(loadingType, ...)
    loadingType = loadingType or XMVCA.XBigWorldLoading.LoadingType.ImageMask

    XMVCA.XBigWorldLoading:OpenLoadingByType(loadingType, ...)
end

function XBigWorldUIAgency:CloseLoadingMask(loadingType, callback)
    loadingType = loadingType or XMVCA.XBigWorldLoading.LoadingType.ImageMask
    
    XMVCA.XBigWorldLoading:CloseLoadingByType(loadingType, callback)
end

--endregion

-- region X3C

function XBigWorldUIAgency:OnFightOpenUi(data)
    local uiName = data.UiName
    if string.IsNilOrEmpty(uiName) then
        return
    end
    local funcData = self._FightUiCb[uiName]
    local openCb = funcData and funcData.OpenCb or nil
    if openCb then openCb(data)  end
end

function XBigWorldUIAgency:OnFightCloseUi(data)
    local uiName = data.UiName
    if string.IsNilOrEmpty(uiName) then
        return
    end

    local funcData = self._FightUiCb[uiName]
    local closeCb = funcData and funcData.CloseCb or nil
    if closeCb then closeCb(data)  end
end

function XBigWorldUIAgency:AddFightUiCb(uiName, openCb, closeCb)
    local data = self._FightUiCb[uiName]
    if not data then
        data = {
            OpenCb = false,
            CloseCb = false,
        }
        self._FightUiCb[uiName] = data
    end
    data.OpenCb = openCb
    data.CloseCb = closeCb
end

function XBigWorldUIAgency:SendConfirmPopupCloseCommand(key, isSure, isNoLongerPopup, isBlocked)
    self._Model:SetIsNotRepeatConfirmPopup(key, isNoLongerPopup)

    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CONFIRM_POPUP_CLOSE_NOTIFY, {
        Key = key,
        IsSure = isSure or false,
        IsNoLongerPopup = isNoLongerPopup or false,
        IsBlocked = isBlocked or false,
    })
end

function XBigWorldUIAgency:SendQuitConfirmPopupCloseCommand(isSure)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUIT_CONFIRM_POPUP_CLOSE_NOTIFY, {
        IsSure = isSure or false,
    })
end

function XBigWorldUIAgency:SendDramaSkipPopupCloseCommand(isSkip)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DRAMA_SKIP_POPUP_CLOSE_NOTIFY, {
        IsSkip = isSkip or false,
    })
end

-- endregion

return XBigWorldUIAgency