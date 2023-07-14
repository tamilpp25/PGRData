local XUiGridVoteItem = XClass(nil, "XUiGridVoteItem")
local toString = tostring
local toNumber = tonumber
function XUiGridVoteItem:Ctor(ui, currPlayerId, voteId, valueChangeCallback, voteSuccessCallback, rootUi)
    ---@type UnityEngine.GameObject
    self.GameObject = ui
    ---@type UnityEngine.Transform
    self.Transform = self.GameObject.transform
    self.RootUi = rootUi
    self.CurrPlayerId = currPlayerId
    self.ValueChangeCallback = valueChangeCallback
    self.VoteSuccessCallback = voteSuccessCallback
    self.VoteId = voteId
    self.VoteItem = XDataCenter.MoeWarManager.GetVoteItem(voteId)
    XTool.InitUiObject(self)
    self:InitUiView()
end

function XUiGridVoteItem:InitUiView()
    local itemId = self.VoteItem:GetVoteItemId()
    local itemTemplate = XDataCenter.ItemManager.GetItemTemplate(itemId)
    self.GridComponent = XUiGridCommon.New(self.RootUi, self.GridIcon)
    self.TxtName.text = XDataCenter.ItemManager.GetItemName(itemId)
    self.GridComponent:Refresh(itemTemplate)
    self.GridComponent:SetBtnNotClick(true)--临时屏蔽点击弹窗
    self.TxtNumber.text = XDataCenter.ItemManager.GetCount(itemId)
    self.TxtEffectNumber = self.Transform:Find("PanelDetails/GridDetails/TxtDetails/TxtNumber"):GetComponent("Text")
    self.GridReward.gameObject:SetActiveEx(self.VoteItem:IsLimitVote())
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self.TxtNumber.text = XDataCenter.ItemManager.GetCount(self.VoteItem:GetVoteItemId())
    end, self.TxtNumber)
    if self.ImgEffectIcon and self.ImgRewardIcon then
        self.ImgEffectIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
        self.ImgRewardIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarVoteReawrdIcon"))
        self.TxtRewardTitle.text = CS.XTextManager.GetText("MoeWarVoteRewardTitle")
        self.TxtEffectTitle.text = CS.XTextManager.GetText("MoeWarVoteEffectTitle")
    end
    self.BtnPoll:SetName(CS.XTextManager.GetText("MoeWarVoteButtonName"))
    if not self.AddInputHandler then
        self.AddInputHandler = self.BtnAdd.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    if not self.ReduceInputHandler then
        self.ReduceInputHandler = self.BtnReduce.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    self:RegisterButtonEvent()
    self:SetVoteNumber(0)
    self:UpdateLimitText()
end

function XUiGridVoteItem:UpdateLimitText()
    local itemName = XDataCenter.ItemManager.GetItemName(self.VoteItem:GetVoteItemId())
    local playerEntity = XDataCenter.MoeWarManager.GetPlayer(self.CurrPlayerId)
    if self.VoteItem:IsLimitVote() then
        self.TxtLimit.text = CS.XTextManager.GetText("MoeWarDailyLimitVoteTips", itemName, playerEntity:GetDailyVoteByItemId(self.VoteItem:GetVoteItemId()), self.VoteItem:GetDailyLimitCountByMatchId(XDataCenter.MoeWarManager.GetCurMatchId()))
    else
        self.TxtLimit.text = CS.XTextManager.GetText("MoeWarNotDailyLimitVoteTips", itemName)
    end
end

function XUiGridVoteItem:UpdateButtonState()
    local currValue = toNumber(self.TxtVoteNumber.text)
    self.BtnPoll:SetDisable(currValue == 0, currValue ~= 0)
end

function XUiGridVoteItem:SetVoteNumber(value)
    self.TxtVoteNumber.text = toString(value)
    self.TxtEffectNumber.text = toString(value * self.VoteItem:GetVoteFactor())
    local rewardValue = value * self.VoteItem:GetCoinFactor()
    if self.TxtRewardNumber then
        self.TxtRewardNumber.text = toString(rewardValue)
    end
    self:UpdateButtonState()
end

function XUiGridVoteItem:OnClickBtnAdd()
    if not self:CheckIsCanVote() then return end
    local currNumber = toNumber(self.TxtVoteNumber.text)
    local multiple = self.VoteItem:GetMultiple()
    local newValue = currNumber + multiple
    local playerEntity = XDataCenter.MoeWarManager.GetPlayer(self.CurrPlayerId)
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    local voteFactor = self.VoteItem:GetVoteFactor()
    if self.VoteItem:IsLimitVote() then
        local max = self.VoteItem:GetDailyLimitCountByMatchId(XDataCenter.MoeWarManager.GetCurMatchId()) - playerEntity:GetDailyVoteByItemId(self.VoteItem:GetVoteItemId())
        if max < 0 then
            max = 0
        end
        if newValue > max then newValue = max end
    end
    local itemCount = XDataCenter.ItemManager.GetCount(self.VoteItem:GetVoteItemId())
    if newValue > itemCount then newValue = itemCount end

    local dailyLimitCount = match:GetDailyLimitCount()
    local currCount = XDataCenter.MoeWarManager.GetDailyVoteCount()

    if newValue * voteFactor > (dailyLimitCount - currCount) then
        newValue = math.floor((dailyLimitCount - currCount) / (multiple * voteFactor)) * multiple
    end
    self:SetVoteNumber(newValue)
    if self.ValueChangeCallback then
        self.ValueChangeCallback(self.VoteId)
    end
end

function XUiGridVoteItem:OnClickBtnReduce()
    local currNumber = toNumber(self.TxtVoteNumber.text)
    local multiple = self.VoteItem:GetMultiple()
    local newValue = currNumber - multiple
    newValue = XMath.Clamp(newValue, 0, currNumber)
    self:SetVoteNumber(newValue)
    if self.ValueChangeCallback then
        self.ValueChangeCallback(self.VoteId)
    end
end

function XUiGridVoteItem:OnClickBtnMax()
    if not self:CheckIsCanVote() then return end
    local newValue = 0
    local multiple = self.VoteItem:GetMultiple()
    local voteItemId = self.VoteItem:GetVoteItemId()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    local voteFactor = self.VoteItem:GetVoteFactor()
    local playerEntity = XDataCenter.MoeWarManager.GetPlayer(self.CurrPlayerId)
    if self.VoteItem:IsLimitVote() then
        newValue = self.VoteItem:GetDailyLimitCountByMatchId(XDataCenter.MoeWarManager.GetCurMatchId()) - playerEntity:GetDailyVoteByItemId(self.VoteItem:GetVoteItemId())
        local itemCount = XDataCenter.ItemManager.GetCount(voteItemId)
        newValue = XMath.Clamp(newValue, 0, itemCount)
    else
        newValue = math.floor(XDataCenter.ItemManager.GetCount(voteItemId) / multiple) * multiple
    end

    local dailyLimitCount = match:GetDailyLimitCount()
    local currCount = XDataCenter.MoeWarManager.GetDailyVoteCount()

    if newValue * voteFactor > (dailyLimitCount - currCount) then
        newValue = math.floor((dailyLimitCount - currCount) / (multiple * voteFactor)) * multiple
    end

    self:SetVoteNumber(newValue)
    if self.ValueChangeCallback then
        self.ValueChangeCallback(self.VoteId)
    end
end

function XUiGridVoteItem:OnClickBtnVote()
    local count = toNumber(self.TxtVoteNumber.text)
    local ownCount = XDataCenter.ItemManager.GetCount(self.VoteItem:GetVoteItemId())
    if ownCount < count then
        return
    end
    local playerEntity = XDataCenter.MoeWarManager.GetPlayer(self.CurrPlayerId)
    playerEntity:RequestVote(self.VoteId, count, function(count) self.VoteSuccessCallback(tonumber(self.TxtEffectNumber.text), self.CurrPlayerId) end)
end

function XUiGridVoteItem:RegisterButtonEvent()
    --self.BtnAdd.CallBack = function() self:OnClickBtnAdd() end
    self.BtnMax.CallBack = function() self:OnClickBtnMax() end
    --self.BtnReduce.CallBack = function() self:OnClickBtnReduce() end
    self.BtnPoll.CallBack = function() self:OnClickBtnVote() end
    --增加特殊处理原长按是每帧执行一次，修改为每帧执行十次增加速度
    self.AddInputHandler:AddPressListener(function() for i = 1, 10 do self:OnClickBtnAdd() end end)
    self.AddInputHandler:AddPointerClickListener(handler(self,self.OnClickBtnAdd))
    self.ReduceInputHandler:AddPressListener(function() for i = 1, 10 do self:OnClickBtnReduce() end end)
    self.ReduceInputHandler:AddPointerClickListener(handler(self,self.OnClickBtnReduce))
end

function XUiGridVoteItem:CheckIsCanVote()
    local voteItemId = self.VoteItem:GetVoteItemId()
    local itemCount = XDataCenter.ItemManager.GetCount(voteItemId)
    local voteFactor = self.VoteItem:GetVoteFactor()
    local multiple = self.VoteItem:GetMultiple()
    if itemCount == 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("MoeWarDailyVoteItemNotEnoughTip", XDataCenter.ItemManager.GetItemName(voteItemId)))
        return false
    end
    if self.VoteItem:IsLimitVote() then
        local playerEntity = XDataCenter.MoeWarManager.GetPlayer(self.CurrPlayerId)
        local canVoteCount = self.VoteItem:GetDailyLimitCountByMatchId(XDataCenter.MoeWarManager.GetCurMatchId()) - playerEntity:GetDailyVoteByItemId(self.VoteItem:GetVoteItemId())
        if canVoteCount == 0 then
            XUiManager.TipText("MoeWarDailyVoteItemLimitTip")
            return false
        end
    end
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    local dailyLimitCount = match:GetDailyLimitCount()
    local currCount = XDataCenter.MoeWarManager.GetDailyVoteCount()
    if currCount >= dailyLimitCount then
        XUiManager.TipText("MoeWarDailyVoteLimitTip")
        return false
    end
    if dailyLimitCount - currCount < voteFactor * multiple then
        XUiManager.TipText("MoeWarDailyVoteLimitTip2")
        return false
    end

    return true
end

return XUiGridVoteItem