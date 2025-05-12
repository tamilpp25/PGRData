local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiGridWordItem = XClass(nil, "XUiGridWordItem")

function XUiGridWordItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
end

function XUiGridWordItem:Init()
    self:AutoRegisterBtn()
    XUiButtonLongClick.New(self.Pointer, 5, self, nil, function()
        if self.OnDragCallBack then self.OnDragCallBack() end
    end, function()
        if self.OnDragUpCallBack then self.OnDragUpCallBack() end
    end, false)
    self.ImgChoce.gameObject:SetActiveEx(false)
    self.EffectOpen.gameObject:SetActiveEx(false)
    self:SetEffectPromptActiveEx(false)
    self:SetEffectErrorActiveEx(false)
    self.OnDragCallBack = nil
    self.OnDragUpCallBack = nil
    self.EffectDelayTime = XDataCenter.CoupletGameManager.GetEffectOpenDelay()
end

function XUiGridWordItem:OnCreate(data)
    self.ImgChoce.gameObject:SetActiveEx(false)
    self:SetEffectErrorActiveEx(false)
    self.Data = data
    if data.Id == 0 then
        self.ImgUnder.gameObject:SetActiveEx(false)
        self.RawImage.gameObject:SetActiveEx(false)
        self.BtnChars.gameObject:SetActiveEx(true)
        self:SetEffectPromptActiveEx(XDataCenter.CoupletGameManager.CheckCanExchangeWord())
    else
        self.ImgUnder.gameObject:SetActiveEx(true)
        self.RawImage.gameObject:SetActiveEx(true)
        self.BtnChars.gameObject:SetActiveEx(false)
        local imageWord = XCoupletGameConfigs.GetCoupletWordImageById(data.Id)
        self.RawImage:SetRawImage(imageWord)
        self:SetEffectPromptActiveEx(false)
    end
end

function XUiGridWordItem:SetOnDragCallBack(cb)
    self.OnDragCallBack = cb
end

function XUiGridWordItem:SetOnDragUpCallBack(cb)
    self.OnDragUpCallBack = cb
end

function XUiGridWordItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

function XUiGridWordItem:DontShow()
    self.RawImage.gameObject:SetActiveEx(false)
    self.BtnChars.gameObject:SetActiveEx(false)
end

function XUiGridWordItem:SetLight(bool)
    self.ImgChoce.gameObject:SetActiveEx(bool)
end

function XUiGridWordItem:SetEffectPromptActiveEx(bool)
    self.EffectPrompt.gameObject:SetActiveEx(bool)
end

function XUiGridWordItem:SetEffectErrorActiveEx(bool)
    self.EffectError.gameObject:SetActiveEx(bool)
end

function XUiGridWordItem:PlayGetWordAnimation()
    self.RawImageEnable.gameObject:PlayTimelineAnimation()
end

function XUiGridWordItem:AutoRegisterBtn()
    self.BtnChars.CallBack = function () self:OnBtnChatsClick() end
end

function XUiGridWordItem:OnBtnChatsClick()
    if not self.Data then
        return
    end

    XDataCenter.CoupletGameManager.GetCoupletWord(self.Data.Index, function ()
        self.EffectOpen.gameObject:SetActiveEx(true)
        XScheduleManager.ScheduleOnce(function ()
            XScheduleManager.ScheduleOnce(function () self.EffectOpen.gameObject:SetActiveEx(false) end, 500) -- 延迟关闭特效
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_COUPLET_GAME_GET_WORD, self.Data.Index)
        end, self.EffectDelayTime)
    end)
end

return XUiGridWordItem