---@class XBigWorldCommonAgency : XAgency
---@field private _Model XBigWorldCommonModel
local XBigWorldCommonAgency = XClass(XAgency, "XBigWorldCommonAgency")

function XBigWorldCommonAgency:OnInit()
    -- 初始化一些变量
    ---@type XBWPopupConfirmData
    self._ConfirmPopupData = false
    ---@type XBWPopupQuitConfirmData
    self._QuitConfirmPopupData = false
end

function XBigWorldCommonAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
end

function XBigWorldCommonAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

---@return XBWPopupConfirmData
function XBigWorldCommonAgency:GetPopupConfirmData()
    if not self._ConfirmPopupData then
        local XBWPopupConfirmData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupConfirmData")

        self._ConfirmPopupData = XBWPopupConfirmData.New()
    end

    self._ConfirmPopupData:Clear()

    return self._ConfirmPopupData
end

---@return XBWPopupQuitConfirmData
function XBigWorldCommonAgency:GetPopupQuitConfirmData()
    if not self._QuitConfirmPopupData then
        local XBWPopupQuitConfirmData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupQuitConfirmData")

        self._QuitConfirmPopupData = XBWPopupQuitConfirmData.New()
    end

    self._QuitConfirmPopupData:Clear()

    return self._QuitConfirmPopupData
end

function XBigWorldCommonAgency:CreateShadyController(uiTransform, isAutoOpen)
    local transform = uiTransform:FindTransform("SafeAreaContentPane")

    if not transform then
        transform = uiTransform
    end

    local shadyUrl = XMVCA.XBigWorldResource:GetAssetUrl("Shady")
    local shady = transform:LoadPrefab(shadyUrl)
    local controller = shady.gameObject:GetComponent(typeof(CS.XUiShadyController))

    if XTool.UObjIsNil(controller) then
        controller = shady.gameObject:AddComponent(typeof(CS.XUiShadyController))
    end

    controller:SetTarget(shady.transform, "DarkEnable")

    if isAutoOpen then
        controller:Open()
    end

    return controller
end

-- region X3C

function XBigWorldCommonAgency:OnOpenLeaveInstLevelPopup(data)
    local confrimData = XMVCA.XBigWorldCommon:GetPopupQuitConfirmData()
    local title = ""
    local tips = ""
    local cancelText = ""
    local sureText = ""

    if data.IsSaveProgress then
        title = XMVCA.XBigWorldService:GetText("InstLevelTipHaveSaveTitle")
        tips = XMVCA.XBigWorldService:GetText("InstLevelTipHaveSaveText")
        sureText = XMVCA.XBigWorldService:GetText("InstLevelTipHaveSaveSureText")
        cancelText = XMVCA.XBigWorldService:GetText("InstLevelTipHaveSaveCancelText")
    else
        title = XMVCA.XBigWorldService:GetText("InstLevelTipTitle")
        tips = XMVCA.XBigWorldService:GetText("InstLevelTipText")
        sureText = XMVCA.XBigWorldService:GetText("InstLevelTipSureText")
        cancelText = XMVCA.XBigWorldService:GetText("InstLevelTipCancelText")
    end

    confrimData:InitInfo(title, tips, true)
    confrimData:InitCancelAndCloseClick(cancelText)
    confrimData:InitSureClick(sureText, function()
        XMVCA.XBigWorldGamePlay:RequestLeaveInstLevel()
    end)

    XMVCA.XBigWorldUI:OpenQuitConfirmPopup(confrimData)
end

-- endregion

return XBigWorldCommonAgency
