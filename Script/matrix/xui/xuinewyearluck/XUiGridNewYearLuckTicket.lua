local XUiGridNewYearLuckTicket = XClass(nil,"XUiGridNewYearLuckTicket")

---@param transform UnityEngine.RectTransform
function XUiGridNewYearLuckTicket:Ctor(transform,type,index,parent)
    self.GameObject = transform.gameObject
    self.Transform = transform
    self.Type = type
    self.Index = index
    self.Parent = parent
    ---@type XNewYearLuckLevel
    self.TicketEntity = XDataCenter.NewYearLuckManager.GetLevelEntity(type, index)
    self:Init()
    self:Refresh()
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.NewYearLuckManager.GetUseItemId(),function() 
        self:Refresh()
    end,self.GameObject)
end

function XUiGridNewYearLuckTicket:Init()
    self.TxtNum = self.GameObject:FindTransform("NumText"):GetComponent("Text")
    ---@type XUiComponent.XUiButton
    self.BtnLottery = self.GameObject:FindTransform("BtnLottery"):GetComponent("XUiButton")
    self.LockNor = self.GameObject:FindTransform("LockNor")
    self.LockPre = self.GameObject:FindTransform("LockPre")
    self.Open = self.GameObject:FindTransform("Open")
    self.OpenAnimation = self.Open:FindTransform("TimeLine")
    self.TagOpen = self.GameObject:FindTransform("TagOpen")
    self.TagLv = self.GameObject:FindTransform("TagLv")
    self.TxtLv = self.TagLv:FindTransform("Text"):GetComponent("Text")
    self.GridItem = self.GameObject:FindTransform("Grid256New")
    self.Expire = self.GameObject:FindTransform("Expire")
    self.Effect = self.GameObject:FindTransform("Effect")
    self.Red = self.GameObject:FindTransform("Red")
    self.BtnLottery.CallBack = function() 
        self:OnClickTicket()
    end
end

function XUiGridNewYearLuckTicket:Refresh()
    local price = XDataCenter.NewYearLuckManager.GetLevelPrice(self.Type, self.Index)
    local itemCount = XDataCenter.ItemManager.GetCount(XDataCenter.NewYearLuckManager.GetUseItemId())
    local isShowNormal = price <= itemCount and (not self.TicketEntity:IsDraw()) and (not self.TicketEntity:IsRewarded()) and (not XDataCenter.NewYearLuckManager.IsCanReward())
    local isShowPre = price > itemCount and (not self.TicketEntity:IsDraw()) and (not self.TicketEntity:IsRewarded()) and (not XDataCenter.NewYearLuckManager.IsCanReward())
    local useItemId = XDataCenter.NewYearLuckManager.GetUseItemId()
    local icon = XDataCenter.ItemManager.GetItemIcon(useItemId)
    if icon then
        self.BtnLottery:SetRawImage(icon)
    end
    self.BtnLottery:SetNameByGroup(0, price)
    if self.TicketEntity:IsDraw() then
        self.BtnLottery:SetNameByGroup(1, self.TicketEntity:GetLuckNumber())
    end
    self.LockNor.gameObject:SetActiveEx(isShowNormal)
    self.Red.gameObject:SetActiveEx(isShowNormal)
    self.LockPre.gameObject:SetActiveEx(isShowPre)
    self.Open.gameObject:SetActiveEx(self.TicketEntity:IsDraw())
    self.TagOpen.gameObject:SetActiveEx(self.TicketEntity:IsRewarded())
    self.TagLv.gameObject:SetActiveEx(self.TicketEntity:IsRewarded())
    self.Expire.gameObject:SetActiveEx((not self.TicketEntity:IsDraw()) and (not self.TicketEntity:IsRewarded()) and XDataCenter.NewYearLuckManager.IsCanReward())
    self.Effect.gameObject:SetActiveEx((self.TicketEntity:IsDraw() and XDataCenter.NewYearLuckManager.IsCanReward()) or isShowNormal)
    local levelCfg = self.TicketEntity:GetLevelConfig()
    if not levelCfg then
        return
    end
    self.TxtLv.text = levelCfg.RewardLevel
    if not self.GridCommon then
        self.GridCommon = XUiGridCommon.New(self.Parent, self.GridItem)
    end
    local rewardList = XRewardManager.GetRewardList(levelCfg.RewardId)
    if not rewardList then
        return
    end
    self.GridCommon:Refresh(rewardList[1])
end

function XUiGridNewYearLuckTicket:OnClickTicket()
    local price = XDataCenter.NewYearLuckManager.GetLevelPrice(self.Type, self.Index)
    local itemCount = XDataCenter.ItemManager.GetCount(XDataCenter.NewYearLuckManager.GetUseItemId())
    local isExpire = (not self.TicketEntity:IsDraw()) and (not self.TicketEntity:IsRewarded()) and XDataCenter.NewYearLuckManager.IsCanReward()
    local isNormal = price <= itemCount and (not self.TicketEntity:IsDraw()) and (not self.TicketEntity:IsRewarded()) and (not XDataCenter.NewYearLuckManager.IsCanReward())
    local isPre = price > itemCount and (not self.TicketEntity:IsDraw()) and (not self.TicketEntity:IsRewarded()) and (not XDataCenter.NewYearLuckManager.IsCanReward())
    if isExpire then
        XUiManager.TipText("NewYearLuckExpire")
        return
    end
    if isPre then
        XUiManager.TipText("NewYearLuckItemNotEnough")
        return
    end
    if isNormal then
        self.TicketEntity:LotteryRequest(self.Type,function()
            self.OpenAnimation.gameObject:SetActiveEx(true)
            self:Refresh()
        end)
    end
    if XDataCenter.NewYearLuckManager.IsCanReward() and self.TicketEntity:IsDraw() then
        self.TicketEntity:AwardRequest(function(rewardList)
            self:Refresh()
            XUiManager.OpenUiTipReward(rewardList)
        end)
    end
end

return XUiGridNewYearLuckTicket