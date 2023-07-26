local XUiInvertCardRewardItem = XClass(nil, "XUiInvertCardRewardItem")

function XUiInvertCardRewardItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiInvertCardRewardItem:Init()
    self.CommonGrid = XUiGridCommon.New(self.RootUi, self.GridCommon)
    self.BtnActive.CallBack = function ()
        if self.BtnActiveCb then self.BtnActiveCb() end
    end
end

function XUiInvertCardRewardItem:OnCreat(data)
    local rewardItemId = XRewardManager.GetRewardList(data.RewardId)[1]
    self.CommonGrid:Refresh(rewardItemId)
    self.TxtValue.text = XInvertCardGameConfig.GetStageFinishProgressById(data.StageId)[data.Index]
end

function XUiInvertCardRewardItem:SetTakedState(rewardState)
    if rewardState == XInvertCardGameConfig.InvertCardGameRewardTookState.NotFinish then
        self.BtnActive.gameObject:SetActiveEx(false)
        self.ImgRe.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(false)
    elseif rewardState == XInvertCardGameConfig.InvertCardGameRewardTookState.NotTook then
        self.BtnActive.gameObject:SetActiveEx(true)
        self.ImgRe.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(true)
    elseif rewardState == XInvertCardGameConfig.InvertCardGameRewardTookState.Took then
        self.BtnActive.gameObject:SetActiveEx(false)
        self.ImgRe.gameObject:SetActiveEx(true)
        self.PanelEffect.gameObject:SetActiveEx(false)
    end
end

function XUiInvertCardRewardItem:SetBtnActiveCallBack(cb)
    self.BtnActiveCb = cb
end

function XUiInvertCardRewardItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiInvertCardRewardItem