local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local tableUnpack = table.unpack

XUi = XClass(nil, "XUi")

function XUi:Ctor(name, ui)
    self.Name = name
    self.CsUi = ui
    self.Transform = ui.Transform
    self.GameObject = ui.GameObject
    self.UiAnimation = ui.UiAnimation
end

function XUi:OnOpen()
end

function XUi:OnClose()
end

function XUi:OnShow()
end

function XUi:OnHide()
end

function XUi:SetUiSprite(image, name, callBack)
    if not XTool.UObjIsNil(self.CsUi) then
        self.CsUi:SetUiSprite(image, name, callBack)
    end
end

local TipMsgQueue --重复弹条提示队列
local ClearMsgEvent
local CurrentTipState -- 弹条状态

local TipState =    {
    IDLE = 1,
    SHOWING = 2,
    LOCK = 3
}

XUiManager = XUiManager or {}


function XUiManager.Init()
    CurrentTipState = TipState.IDLE
    TipMsgQueue = XQueue.New()
    XUiManager.IsHideFunc = CS.XRemoteConfig.IsHideFunc
end

local ClassTable = {}
local ClassObj = {}

function XUiManager.Register(name, super)
    super = super or XUi
    --CS.XUiManager.Register(name)
    local class = XClass(super, name)
    ClassTable[name] = class
    return class
end

function XUiManager.FindClassType(name)
    for k, v in pairs(ClassObj) do
        if k == name then
            return v
        end
    end
    return nil
end

function XUiManager.RemoveClassType(name)
    for k, _ in pairs(ClassObj) do
        if k == name then
            ClassObj[k] = nil
        end
    end
end

function XUiManager.New(name, ui)
    local baseName = name
    local class = ClassTable[baseName]
    if not class then
        baseName = string.match(baseName, '%w*[^(%d)$*]')       -- 解析包含数字后缀的界面
        class = ClassTable[baseName]
        if not class then
            XLog.Error("XUiManager.New error, class not exist, name: " .. name)
            return nil
        end
    end
    local obj = class.New(name, ui)
    ClassObj[name] = obj
    return obj
end

--XUiManager.XUiEvent = {
--    Show = 1,
--    Hide = 2,
--    Open = 3,
--    Close = 4,
--}
XUiManager.UiTipType = {
    Tip = 1,
    Wrong = 2,
    Success = 3,
}

XUiManager.DialogType = {
    Normal = "Normal",
    OnlyClose = "OnlyClose",
    OnlySure = "OnlySure",
    NoBtn = "NoBtn",
    NormalAndNoBtnTanchuangClose = "NormalAndNoBtnTanchuangClose",
}

XUiManager.IsHideFunc = false


function XUiManager.ClearTipMsgQueue()
    CurrentTipState = TipState.IDLE
    TipMsgQueue:Clear()
end

function XUiManager.TipMsgEnqueue(msg, type, cb, hideCloseMark)
    if CurrentTipState == TipState.IDLE then
        XUiManager.TipMsg(msg, type, cb, hideCloseMark)
    else
        local msgData = { msg, type, cb, hideCloseMark }
        TipMsgQueue:Enqueue(msgData)
        ClearMsgEvent = ClearMsgEvent or XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, XUiManager.ClearTipMsgQueue)
    end
end

function XUiManager.TipMsgDequeue()
    if CurrentTipState == TipState.SHOWING then return end
    local msgData = TipMsgQueue:Dequeue()
    if msgData then
        XUiManager.TipMsg(tableUnpack(msgData))
    else
        XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_ENABLE, XUiManager.ClearTipMsgQueue)
        ClearMsgEvent = nil
    end
end

function XUiManager.TipMsg(msg, type, cb, hideCloseMark, hideUnderlineInfo)
    if not msg then
        XLog.Error("XUiManager.TipMsg error, msg is nil")
        return
    end
    
    if not type then
        type = XUiManager.UiTipType.Tip
    end
    if CurrentTipState == TipState.SHOWING then return end
    CurrentTipState = TipState.SHOWING
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_small)
    local callback = function()
        if cb then cb() end
        CurrentTipState = TipState.IDLE
        XUiManager.TipMsgDequeue()
    end
    --CS.XUiManager.TipsManager:Push("UiTipLayer", true, true, msg, type)
    XLuaUiManager.Open("UiTipLayer", msg, type, callback, hideCloseMark, hideUnderlineInfo)
end

function XUiManager.TipText(key, type, isEnqueue, ...)
    if not type then
        type = XUiManager.UiTipType.Wrong
    end
    local text = XUiHelper.GetText(key, ...)
    if isEnqueue then
        XUiManager.TipMsgEnqueue(text, type)
    else
        XUiManager.TipMsg(text, type)
    end
end

function XUiManager.TipSuccess(msg, hideCloseMark)
    XUiManager.TipMsg(msg, XUiManager.UiTipType.Success, nil, hideCloseMark)
end

function XUiManager.TipError(msg)
    XUiManager.TipMsg(msg, XUiManager.UiTipType.Wrong)
end

function XUiManager.TipErrorWithHideUnderlineInfo(msg)
    XUiManager.TipMsg(msg, XUiManager.UiTipType.Wrong, nil, false, true)
end

function XUiManager.TipErrorWithKey(key, ...)
    XUiManager.TipError(XUiHelper.GetText(key, ...))
end

-- v2.0 Tip支持换行符，虽然怪，但策划说要换行那就加吧
function XUiManager.TipErrorReadTextWithNewLine(key, ...)
    XUiManager.TipError(XUiHelper.ReadTextWithNewLine(key, ...))
end

function XUiManager.TipCode(code, ...)
    local text = CS.XTextManager.GetCodeText(code, ...)
    if code == XCode.Success then
        XUiManager.TipSuccess(text)
    else
        XUiManager.TipError(text)
    end
end

-- 竖屏提示
function XUiManager.TipPortraitMsg(msg, cb, hideCloseMark)
    if string.IsNilOrEmpty(msg) then
        XLog.Error("XUiManager.TipPortraitMsg error, msg is nil")
        return
    end

    if CurrentTipState == TipState.SHOWING then return end
    CurrentTipState = TipState.SHOWING
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_small)
    local callback = function()
        if cb then cb() end
        CurrentTipState = TipState.IDLE
        XUiManager.TipMsgDequeue()
    end
    XLuaUiManager.Open("UiPortraitTip", msg, callback, hideCloseMark)
end

function XUiManager.TipPortraitText(key, cb, hideCloseMark, ...)
    local text = XUiHelper.GetText(key, ...)
    XUiManager.TipPortraitMsg(text, cb, hideCloseMark)
end


function XUiManager.DialogTip(title, content, dialogType, closeCallback, sureCallback, extraData, cancelCallback)
    if not title and not content then
        XLog.Error("XUiManager.DialogTip error, title and content is nil")
        return
    end

    dialogType = dialogType or XUiManager.DialogType.Normal

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_Big)

    --CS.XUiManager.DialogManager:Push("UiDialog", true, true, title, content, dialogType, closeCallback, sureCallback)
    XLuaUiManager.Open("UiDialog", title, content, dialogType, closeCallback, sureCallback, extraData, cancelCallback)
end

function XUiManager.DialogDragTip(title, content, dialogType, closeCallback, sureCallback, extraData)
    if not title and not content then
        XLog.Error("XUiManager.DialogTip error, title and content is nil")
        return
    end

    dialogType = dialogType or XUiManager.DialogType.Normal

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_Big)

    XLuaUiManager.Open("UiDialogDrag", title, content, dialogType, closeCallback, sureCallback, extraData)
end

--带今日内不再提示选项的提示框
function XUiManager.DialogHintTip(title, content, content2, closeCallback, sureCallback, hintInfo)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_Big)
    XLuaUiManager.Open("UiCueMark", title, content, content2, closeCallback, sureCallback, hintInfo)
end

--弹出系统提示
function XUiManager.SystemDialogTip(title, content, dialogType, closeCallback, sureCallback)
    if not title or not content then
        XLog.Error("XUiManager.SystemDialogTip error, title or content is nil")
        return
    end

    if not XUiManager.DialogType[dialogType] then
        XLog.Error("XUiManager.SystemDialogTip error, dialogType is error")
        return
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_Big)

    XLuaUiManager.Open("UiSystemDialog", title, content, dialogType, closeCallback, sureCallback)
end

-- 显示帮助界面
-- Param:cb 关闭帮助界面时执行的回调
function XUiManager.ShowHelpTip(helpDataKey, cb, jumpIndex, closeCb)
    local config = XHelpCourseConfig.GetHelpCourseTemplateByFunction(helpDataKey)
    if not config then
        return
    end

    if config.IsShowCourse == 1 then
        XLuaUiManager.Open("UiHelp", config, cb, jumpIndex, closeCb)
    else
        XUiManager.UiFubenDialogTip(config.Name, config.Describe)
    end
end

function XUiManager.ShowHelpTipNew(getHelpDataFunc, cb)
    if not getHelpDataFunc then
        XLog.Error("XUiManager.ShowHelpTipNew Error: GetHelpDataFunc is Nil")
        return
    end

    local helpData = getHelpDataFunc()
    if not helpData or not next(helpData) then
        return
    end

    XLuaUiManager.Open("UiHelpNew", helpData, cb)
end

function XUiManager.UiFubenDialogTip(title, content, closeCallback, sureCallback)
    if not title or not content then
        XLog.Error("XUiManager.UiFubenDialog error, title or content is nil")
        return
    end

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1100)
    XLuaUiManager.Open("UiFubenDialog", title, content, closeCallback, sureCallback)
end

function XUiManager.OpenBuyAssetPanel(id, successCallback, challengeCountData, buyAmount)
    XDataCenter.ItemManager.SelectBuyAssetType(id, successCallback, challengeCountData, buyAmount)
end

function XUiManager.OpenUiObtain(data, title, closeCallback, sureCallback, horizontalNormalizedPosition, customParams)
    -- 等待父级ui中列表异步刷新完成，以保证弹窗的截图效果正常
    if XUiManager.IsTableAsyncLoading() then
        XUiManager.WaitTableLoadComplete(function()
            XLuaUiManager.Open("UiObtain", data, title, closeCallback, sureCallback, horizontalNormalizedPosition, customParams)
        end)
    else
        XLuaUiManager.Open("UiObtain", data, title, closeCallback, sureCallback, horizontalNormalizedPosition, customParams)
    end
end

function XUiManager.OpenUiTipReward(data, title, closeCallback, sureCallback)
    XLuaUiManager.Open("UiTipReward", data, title, closeCallback, sureCallback)
end

function XUiManager.OpenUiTipRewardByRewardId(id, title, closeCallback, sureCallback, extraTip, preTitle)
    local data = XRewardManager.GetRewardList(id)
    if not data then return end
    XLuaUiManager.Open("UiTipReward", data, title, closeCallback, sureCallback, extraTip, preTitle)
end

function XUiManager.OpenMainUi()
    local guideFight = XDataCenter.GuideManager.GetNextGuideFight()
    if guideFight then
        XLuaUiManager.Close("UiGuide")
        XDataCenter.FubenManager.EnterGuideFight(guideFight.Id, guideFight.StageId, guideFight.NpcId, guideFight.Weapon)
    else
        XLuaUiManager.RunMain()
    end
end

--- 下载弹窗
---@param title string 标题
---@param content string 主内容
---@param subContent string 子内容
---@param confirmCallback function 确定按钮回调
---@param jumpCallback function 界面跳转回调
---@param closeCallback function 界面关闭回调
--------------------------
function XUiManager.DialogDownload(title, content, subContent, confirmCallback, jumpCallback, closeCallback)
    local uiName = "UiDownloadtips"
    if XLuaUiManager.IsUiShow(uiName) then
        return
    end
    XLuaUiManager.Open(uiName, title, content, subContent, confirmCallback, jumpCallback, closeCallback)
end

--- 左上角弹出提示
---@param title string 标题
---@param content string 主内容
---@param closeCb function 关闭回调
---@return void
--------------------------
function XUiManager.PopupLeftTip(title, content, closeCb)
    local uiName = "UiLeftPopupTip"
    if XLuaUiManager.IsUiShow(uiName) then
        XLuaUiManager.Close(uiName)
    end
    XLuaUiManager.Open(uiName, title, content, closeCb)
end

function XUiManager.CheckTopUi(type, name)
    local ui = CsXUiManager.Instance:GetTopUi(type)

    if not ui or not ui.UiData then
        return false
    end
    
    return ui.UiData.UiName == name
end

-- 点击空白区域关闭显示
function XUiManager.CreateBlankArea2Close(showTransfrom, closeCb)
    XLuaUiManager.Open("UiTopClickCloseArea", showTransfrom.transform, closeCb)
end

function XUiManager.OpenPopWebview(url, title)
    if XUserManager.IsKuroSdk() then
        -- 国服用KuroSDk的内嵌浏览器
        XHeroSdkManager.OpenWebview(url, title)
    else 
        -- 海外的注意了，UiLoginNotice打开协议这里格式可能会有问题，如果可以建议用WebView打开
        --如果是PC正常使用URL跳转，手机平台才用WEB VIEW打开
        XLuaUiManager.Open("UiLoginNotice", {
            HtmlUrl = url,
            Title = title and XUiHelper.RichTextToTextString(title) or CS.XTextManager.GetText("Agreement"),
            isFullUrl = true
        })
    end
end

function XUiManager.OpenGoodDetailUi(goodId, fromUiName, customData, hideSkipBtn)
    -- 匹配中
    --if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
    --    return
    --end
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(goodId)
    local uiType = XLuaUiManager.FindTopUi(fromUiName).UiProxy.Ui.UiData.UiType
    if goodsShowParams.RewardType == XRewardManager.XRewardType.Character then
        --从Tips的ui跳转需要关闭Tips的UI
        if uiType == CsXUiType.Tips then
            XLuaUiManager.Close(fromUiName)
        end
        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()
        XLuaUiManager.Open("UiCharacterDetail", goodId)
    elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
        XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(goodId)
        --从Tips的ui跳转需要关闭Tips的UI
        if uiType == CsXUiType.Tips then
            XLuaUiManager.Close(fromUiName)
        end
        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()
    elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Furniture then
        local cfg = XFurnitureConfigs.GetFurnitureReward(goodId)
        local furnitureRewardId = goodId
        local configId = cfg.FurnitureId
        XLuaUiManager.Open("UiFurnitureDetail", customData.InstanceId, configId, furnitureRewardId, nil, true)
    elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Fashion then
        local buyData
        if customData and customData.ItemCount and customData.ItemIcon and customData.BuyCallBack then
            buyData = {}
            local isHave, isLimitTime = XRewardManager.CheckRewardOwn(goodsShowParams.RewardType, goodsShowParams.TemplateId)
            buyData.IsHave = isHave and not isLimitTime
            buyData.ItemIcon = customData.ItemIcon
            buyData.ItemCount = customData.ItemCount
            buyData.BuyCallBack = customData.BuyCallBack
        end
        XLuaUiManager.Open("UiFashionDetail", goodId, false, buyData)
    elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Partner then
        --从Tips的ui跳转需要关闭Tips的UI
        if uiType == CsXUiType.Tips then
            XLuaUiManager.Close(fromUiName)
        end
        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()
        local partnerData = { Id = 0, TemplateId = goodId }
        local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData, true)
        XLuaUiManager.Open("UiPartnerPreview", partner)

    elseif XDataCenter.ItemManager.IsWeaponFashion(goodId) then
        local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(goodId)
        XLuaUiManager.Open("UiFashionDetail", weaponFashionId, true)
    elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Nameplate then
        XLuaUiManager.Open("UiNameplateTip", goodId, true, true)
    else
        XLuaUiManager.Open("UiTip", customData and customData or goodId, hideSkipBtn, fromUiName)
    end
end


local LoadTableHandler = nil
local LoadTableCBList = {}

function XUiManager.IsTableAsyncLoading()
    return CS.XDynamicTableNormal.IsAnyAsyncLoading and CS.XDynamicTableNormal.IsAnyAsyncLoading()
end

local function OnTableLoadComplete()
    for i, callback in ipairs(LoadTableCBList) do
        callback()
    end
    LoadTableCBList = {}
    
    CsXGameEventManager.Instance:RemoveEvent(XEventId.DYNAMIC_GRID_RELOAD_COMPLETED, LoadTableHandler)
    LoadTableHandler = nil
end

--等待异步列表刷新完成
function XUiManager.WaitTableLoadComplete(cb)
    -- XLog.Debug("Wait Table LoadComplete ...")
    table.insert(LoadTableCBList, cb)
    if LoadTableHandler == nil then
        LoadTableHandler = function(go)
            if XUiManager.IsTableAsyncLoading() then
                return
            end
            OnTableLoadComplete()
        end
    end
    CsXGameEventManager.Instance:RegisterEvent(XEventId.DYNAMIC_GRID_RELOAD_COMPLETED, LoadTableHandler)
    XUiManager.CheckAsyncCBList()
end

local LoadBgHandler = nil
local LoadBgCBList = {}

function XUiManager.IsBgAsyncLoading()
    return CS.XUiManager.IsAnyAsyncLoading and CS.XUiManager.IsAnyAsyncLoading()
end

local function OnBgLoadComplete()
    for i, callback in ipairs(LoadBgCBList) do
        callback()
    end
    LoadBgCBList = {}
    
    CsXGameEventManager.Instance:RemoveEvent(XEventId.UI_BG_LOAD_COMPLETED, LoadBgHandler)
    LoadBgHandler = nil
end

--等待ui的截图背景加载完成
function XUiManager.WaitBgLoadComplete(cb)
    -- XLog.Debug("Wait Bg LoadComplete ...")
    table.insert(LoadBgCBList, cb)
    if LoadBgHandler == nil then
        LoadBgHandler = function(go)
            if XUiManager.IsBgAsyncLoading() then
                return
            end
            OnBgLoadComplete()
        end
    end
    CsXGameEventManager.Instance:RegisterEvent(XEventId.UI_BG_LOAD_COMPLETED, LoadBgHandler)
    XUiManager.CheckAsyncCBList()
end

local MAX_ASYNC_TIME = 1000
local timeId = nil
-- 增加超时逻辑，保证回调正常
function XUiManager.CheckAsyncCBList()
    if timeId then
        XScheduleManager.UnSchedule(timeId)
    end
    timeId = XScheduleManager.ScheduleOnce(function()
        if LoadTableHandler then
            XLog.Warning("Load Table Aync too long, callback.")
            OnTableLoadComplete()
        end
        if LoadBgHandler then
            XLog.Warning("Load Bg Aync too long, callback.")
            OnBgLoadComplete()
        end
        timeId = nil
    end, MAX_ASYNC_TIME)
end

function XUiManager.GetUiRoot()
    return CS.XUiManager.GetUiRoot()
end

function XUiManager.GetTopUi(uiname)
    local ui = XLuaUiManager.FindTopUi(uiname)
    if ui == nil then
        return nil
    end
    ui = ui.UiProxy
    if ui == nil then
        return nil
    end
    return ui
end

--region 今天不再提示 弹窗


function XUiManager.ShowTodayNoMoreTips(params)
    local title = params.Title or CS.XTextManager.GetText("TipTitle")
    local content = params.Content
    if not content then
        XLog.Error("[XUiManager] 今天不再提示弹窗: 没传content喔, 检查下代码啦")
        content = ""
    end
    if not params.Key then
        XLog.Error("[XUiManager] 今天不再提示弹窗: 没传Key喔, 检查下代码啦")
        return
    end
    local key = params.Key .. "HintTipKey"
    local callback = params.Callback
    if not callback then
        XLog.Error("[XUiManager] 今天不再提示弹窗: 不callback,你想做咩啊?")
        return
    end

    --region   ------------------HintTip start-------------------
    local ClearHintTip = function()
        XSaveTool.RemoveData(key)
    end

    local HintTipStatus = function()
        local updateTime = XSaveTool.GetData(key)
        if not updateTime then
            return false
        end

        return XTime.GetServerNowTimestamp() < updateTime
    end

    local MarkHintTip = function(select)
        if select then
            if HintTipStatus() then
                return
            end
            local updateTime = XTime.GetSeverTomorrowFreshTime()
            XSaveTool.SaveData(key, updateTime)
        else
            ClearHintTip()
        end
    end
    --endregion------------------HintTip finish------------------

    local status = HintTipStatus()
    if status then
        callback()
        return
    end
    local hintInfo = {
        SetHintCb = MarkHintTip,
        Status = status,
    }
    XUiManager.DialogHintTip(title, XUiHelper.ReplaceTextNewLine(content), nil, ClearHintTip,
            callback,
            hintInfo
    )
end

--endregion 今天不再提示 弹窗

XUiManager.Init()