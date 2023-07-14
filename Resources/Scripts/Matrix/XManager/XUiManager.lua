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

function XUiManager.TipMsg(msg, type, cb, hideCloseMark)
    if not msg then
        XLog.Error("XUiManager.TipMsg error, msg is nil")
        return
    end

    if not type then
        type = XUiManager.UiTipType.Tip
    end
    if CurrentTipState == TipState.SHOWING then return end
    CurrentTipState = TipState.SHOWING
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_small)
    local callback = function()
        if cb then cb() end
        CurrentTipState = TipState.IDLE
        XUiManager.TipMsgDequeue()
    end
    --CS.XUiManager.TipsManager:Push("UiTipLayer", true, true, msg, type)
    XLuaUiManager.Open("UiTipLayer", msg, type, callback, hideCloseMark)
end

function XUiManager.TipText(key, type, isEnqueue)
    if not type then
        type = XUiManager.UiTipType.Wrong
    end
    local text = CS.XTextManager.GetText(key)
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

function XUiManager.TipCode(code, ...)
    local text = CS.XTextManager.GetCodeText(code, ...)
    if code == XCode.Success then
        XUiManager.TipSuccess(text)
    else
        XUiManager.TipError(text)
    end
end

function XUiManager.DialogTip(title, content, dialogType, closeCallback, sureCallback, extraData)
    if not title and not content then
        XLog.Error("XUiManager.DialogTip error, title and content is nil")
        return
    end

    dialogType = dialogType or XUiManager.DialogType.Normal

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)

    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)

    --CS.XUiManager.DialogManager:Push("UiDialog", true, true, title, content, dialogType, closeCallback, sureCallback)
    CsXUiManager.Instance:Open("UiDialog", title, content, dialogType, closeCallback, sureCallback, extraData)
end

function XUiManager.DialogDragTip(title, content, dialogType, closeCallback, sureCallback, extraData)
    if not title and not content then
        XLog.Error("XUiManager.DialogTip error, title and content is nil")
        return
    end
    
    dialogType = dialogType or XUiManager.DialogType.Normal

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)

    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)

    CsXUiManager.Instance:Open("UiDialogDrag", title, content, dialogType, closeCallback, sureCallback, extraData)
end

--带今日内不再提示选项的提示框
function XUiManager.DialogHintTip(title, content, content2, closeCallback, sureCallback, hintInfo)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)
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

    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)

    CsXUiManager.Instance:Open("UiSystemDialog", title, content, dialogType, closeCallback, sureCallback)
end

-- 显示帮助界面
-- Param:cb 关闭帮助界面时执行的回调
function XUiManager.ShowHelpTip(helpDataKey, cb)
    local config = XHelpCourseConfig.GetHelpCourseTemplateByFunction(helpDataKey)
    if not config then
        return
    end

    if config.IsShowCourse == 1 then
        XLuaUiManager.Open("UiHelp", config, cb)
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

    CS.XAudioManager.PlaySound(1100)
    XLuaUiManager.Open("UiFubenDialog", title, content, closeCallback, sureCallback)
end

function XUiManager.OpenBuyAssetPanel(id, successCallback)
    XDataCenter.ItemManager.SelectBuyAssetType(id, successCallback, nil, nil)
end

function XUiManager.OpenUiObtain(data, title, closeCallback, sureCallback)
    XLuaUiManager.Open("UiObtain", data, title, closeCallback, sureCallback)
end

function XUiManager.OpenUiTipReward(data, title, closeCallback, sureCallback)
    XLuaUiManager.Open("UiTipReward", data, title, closeCallback, sureCallback)
end

function XUiManager.OpenUiTipRewardByRewardId(id, title, closeCallback, sureCallback)
    local data = XRewardManager.GetRewardList(id)
    if not data then return end
    XLuaUiManager.Open("UiTipReward", data, title, closeCallback, sureCallback)
end

function XUiManager.WhenUiLoaded(cb)
    CS.XUiManager.WhenUiLoaded(cb)
end

function XUiManager.LoadUiWithCb(name, root, cb, cache, ...)
    cache = cache and true or false
    local result = CS.XUiManager.Load(name, root, cb, cache, ...)
    return result
end

function XUiManager.PushLoadUiWithCb(name, root, cb, cache, ...)
    cache = cache and true or false
    return CS.XUiManager.PushLoad(name, root, cb, cache, ...)
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

function XUiManager.CheckTopUi(type, name)
    local ui = CsXUiManager.Instance:GetTopUi(type)
    return ui.UiData.UiName == name
end

function XUiManager.OpenPopWebview(url, title)
    --如果是PC正常使用URL跳转，手机平台才用WEB VIEW打开
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or
    CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        CS.UnityEngine.Application.OpenURL(url)
    else
        XLuaUiManager.Open("UiLoginNotice", {
            HtmlUrl = url,
            Title = title and XUiHelper.RichTextToTextString(title) or CS.XTextManager.GetText("Agreement"),
            isFullUrl = true
        })
    end
end

XUiManager.Init()