---@class XBigWorldLoadingAgency : XAgency
---@field private _Model XBigWorldLoadingModel
local XBigWorldLoadingAgency = XClass(XAgency, "XBigWorldLoadingAgency")

function XBigWorldLoadingAgency:OnInit()
    -- 初始化一些变量

    self.LoadingType = {
        ImageMask = 1, -- 图片加载
        BlackTransition = 2, -- 带动画黑幕
        BlackMask = 3, -- 纯黑幕
    }
end

function XBigWorldLoadingAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
end

function XBigWorldLoadingAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldLoadingAgency:OpenBlackTransitionLoading()
    XMVCA.XBigWorldUI:Open("UiBigWorldShowLoading")
end

function XBigWorldLoadingAgency:CloseBlackTransitionLoading(callback)
    XMVCA.XBigWorldUI:Close("UiBigWorldShowLoading", callback)
end

function XBigWorldLoadingAgency:OpenImageMaskLoading(worldId, levelId)
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        XMVCA.XBigWorldUI:Open("UiBigWorldLoading", worldId, levelId)
    else
        XLog.Error("Open ImageMask Loading worldId or levelId is invalid!")
    end
end

function XBigWorldLoadingAgency:CloseImageMaskLoading(callback)
    XMVCA.XBigWorldUI:Close("UiBigWorldLoading", callback)
end

function XBigWorldLoadingAgency:OpenBlackMaskLoading(enableFinishCb, disableFinishCb)
    XMVCA.XBigWorldUI:Open("UiBigWorldBlackMaskLoading", enableFinishCb, disableFinishCb)
end

function XBigWorldLoadingAgency:CloseBlackMaskLoading()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BLACK_MASK_LOADING_CLOSE)
end

function XBigWorldLoadingAgency:OpenLoadingByType(loadingType, ...)
    if loadingType == self.LoadingType.ImageMask then
        self:OpenImageMaskLoading(...)
    elseif loadingType == self.LoadingType.BlackTransition then
        self:OpenBlackTransitionLoading()
    elseif loadingType == self.LoadingType.BlackMask then
        self:OpenBlackMaskLoading()
    end
end

function XBigWorldLoadingAgency:CloseLoadingByType(loadingType, callback)
    if loadingType == self.LoadingType.ImageMask then
        self:CloseImageMaskLoading(callback)
    elseif loadingType == self.LoadingType.BlackTransition then
        self:CloseBlackTransitionLoading(callback)
    elseif loadingType == self.LoadingType.BlackMask then
        self:CloseBlackMaskLoading(callback)
    end
end

function XBigWorldLoadingAgency:OnOpenBlackTransitionLoading()
    self:OpenLoadingByType(self.LoadingType.BlackTransition)
end

return XBigWorldLoadingAgency
