local XUiMentorGiftTisp = XLuaUiManager.Register(XLuaUi, "UiMentorGiftTisp")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiMentorGiftTisp:OnStart()
    self:SetButtonCallBack()
    self:ShowPanel()
end

function XUiMentorGiftTisp:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end
end

function XUiMentorGiftTisp:OnBtnTaskClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Task) then
        return
    end
    XLuaUiManager.Open("UiTask")
end

function XUiMentorGiftTisp:ShowPanel()
    local activationItemId = XMentorSystemConfigs.GetMentorSystemData("ActivationItemId")
    local itemCount = XMentorSystemConfigs.GetMentorSystemData("ActivationRewardCount")
    
    local activExpMaxCount = XMentorSystemConfigs.GetMentorSystemData("ActivationCount")
    local activExpId = XDataCenter.ItemManager.ItemId.DailyActiveness
    
    local activExp = XDataCenter.ItemManager.GetItem(activExpId)
    local activExpCount = activExp and math.min(activExp:GetCount(), activExpMaxCount) or 0
    local activationPercent = activExpCount/activExpMaxCount
    
    local giftReward = XRewardManager.CreateRewardGoods(activationItemId, itemCount)
    local gridGift = XUiGridCommon.New(self, self.GridGift)
    gridGift:Refresh(giftReward)
    
    self.TxtCurCount.text = activExpCount
    self.TxtNeedCount.text = string.format("/%d",activExpMaxCount)
    self.ImgProgress.fillAmount = activationPercent
    self.TxtDescription.text = CSXTextManagerGetText("MentorTeacherGiftDesc")
    self.TxtWorldDesc.text = CSXTextManagerGetText("MentorTeacherGiftHint")
end