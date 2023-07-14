local XUiSlotMachineRewardItem = XClass(nil, "XUiSlotMachineRewardItem")

function XUiSlotMachineRewardItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiSlotMachineRewardItem:Init()
    self.CommonGrid = XUiGridCommon.New(self.RootUi, self.Reward)
    if not self.CommonGrid.TxtCount then
        self.CommonGrid.TxtCount = XUiHelper.TryGetComponent(self.CommonGrid.Transform, "PanelTxt/TxtCount", "Text")
    end
    self.BtnActive.CallBack = function ()
        if self.BtnActiveCb then self.BtnActiveCb() end
    end
end

function XUiSlotMachineRewardItem:OnCreat(data)
    local rewardData = XRewardManager.GetRewardList(data.RewardId)[1]
    self.CommonGrid:Refresh(rewardData)
    self.TxtValue.text = data.RewardScore
end

function XUiSlotMachineRewardItem:SetTakedState(rewardState)
    if rewardState == XSlotMachineConfigs.RewardTakeState.NotFinish then
        self.BtnActive.gameObject:SetActiveEx(false)
        self.ImgRe.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(false)
    elseif rewardState == XSlotMachineConfigs.RewardTakeState.NotTook then
        self.BtnActive.gameObject:SetActiveEx(true)
        self.ImgRe.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(true)
    elseif rewardState == XSlotMachineConfigs.RewardTakeState.Took then
        self.BtnActive.gameObject:SetActiveEx(false)
        self.ImgRe.gameObject:SetActiveEx(true)
        self.PanelEffect.gameObject:SetActiveEx(false)
    end
end

function XUiSlotMachineRewardItem:SetBtnActiveCallBack(cb)
    self.BtnActiveCb = cb
end

function XUiSlotMachineRewardItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiSlotMachineRewardItem