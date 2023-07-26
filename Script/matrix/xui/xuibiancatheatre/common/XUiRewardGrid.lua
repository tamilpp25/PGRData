--肉鸽2.0 通用节点奖励格子
local XUiRewardGrid = XClass(nil, "XUiRewardGrid")

function XUiRewardGrid:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb
    XUiHelper.InitUiClass(self, ui)
    self:RegisterButtonEvent()

    if self.ImgQuality then
        self.ImgQuality.gameObject:SetActiveEx(false)
    end
    if self.Icon then
        self.Icon.gameObject:SetActiveEx(false)
    end
    self:InitTap()
    self.DefaultDescColor = self.TxtDes and self.TxtDes.color
end

function XUiRewardGrid:RegisterButtonEvent()
    XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnClick)
end

function XUiRewardGrid:InitTap()
    if self.Tap then self.Tap.gameObject:SetActiveEx(false) end
    if self.Tap1 then self.Tap1.gameObject:SetActiveEx(false) end
    if self.Tap2 then self.Tap2.gameObject:SetActiveEx(false) end
    if self.Tap3 then self.Tap3.gameObject:SetActiveEx(false) end
    if self.Tap4 then self.Tap4.gameObject:SetActiveEx(false) end
end

--rewardNode：XARewardNode
function XUiRewardGrid:Refresh(rewardNode)
    self.RewardNode = rewardNode
    if not rewardNode or rewardNode:IsReceived() then
        self.GameObject:SetActiveEx(false)
        return
    end

    local name, desc, icon
    local quality, qualityIcon
    local rewardType = rewardNode:GetRewardType()
    local configId = rewardNode:GetConfigId()
    if rewardType == XBiancaTheatreConfigs.XNodeRewardType.ItemBox then
        name = XBiancaTheatreConfigs.GetItemBoxName(configId)
        desc = XBiancaTheatreConfigs.GetItemBoxDesc(configId)
        icon = XBiancaTheatreConfigs.GetItemBoxIcon(configId)
    elseif rewardType == XBiancaTheatreConfigs.XNodeRewardType.Ticket then
        name = XBiancaTheatreConfigs.GetRecruitTicketName(configId)
        desc = XBiancaTheatreConfigs.GetRecruitTicketDesc(configId)
        icon = XBiancaTheatreConfigs.GetRecruitTicketIcon(configId)
        quality = XBiancaTheatreConfigs.GetRecruitTicketQuality(configId)
        qualityIcon = XArrangeConfigs.GeQualityPath(quality)
    elseif rewardType == XBiancaTheatreConfigs.XNodeRewardType.Gold then
        name = XBiancaTheatreConfigs.GetGoldName(configId)
        desc = XBiancaTheatreConfigs.GetGoldDesc(configId)
        icon = XBiancaTheatreConfigs.GetGoldIcon(configId)
    end
    self.Name = name
    self.IconCfg = icon
    self.Desc = desc
    self.Quality = quality
    self.Color = quality and XBiancaTheatreConfigs.GetQualityTextColor(quality) or self.DefaultDescColor

    --名字
    if self.TxtDes then
        self.TxtDes.text = name
        if self.Color then
            self.TxtDes.color = self.Color
        end
    end
    --描述
    if self.TxtProgress then
        self.TxtProgress.text = desc
    end
    --图标
    if icon and self.RImgIcon then
        self.RImgIcon:SetRawImage(icon)
    end
    --品质图标
    if self.ImgQuality then
        if qualityIcon then
            self.ImgQuality:SetSprite(qualityIcon)
            self.ImgQuality.gameObject:SetActiveEx(true)
        else
            self.ImgQuality.gameObject:SetActiveEx(false)
        end
    end
    -- 标签
    local tag = self.RewardNode:GetTagType()
    if self.Tap2 then self.Tap2.gameObject:SetActiveEx(tag == XBiancaTheatreConfigs.NodeRewardTagType.Team) end
    if self.Tap3 then self.Tap3.gameObject:SetActiveEx(tag == XBiancaTheatreConfigs.NodeRewardTagType.Difficulty) end
    if self.Tap4 then self.Tap4.gameObject:SetActiveEx(tag == XBiancaTheatreConfigs.NodeRewardTagType.Luck) end
    self.GameObject:SetActiveEx(true)
end

function XUiRewardGrid:OnBtnClick()
    if self.ClickCb then
        self.ClickCb(self)
        return
    end
    local custemData = {
        Name = self.Name,
        Icon = self.IconCfg,
        Desc = self.Desc,
        Count = self.RewardNode:GetCount(),
        Color = self.Color
    }
    XLuaUiManager.Open("UiBiancaTheatreTips", nil, nil, custemData)
end

function XUiRewardGrid:GetRewardNode()
    return self.RewardNode
end

return XUiRewardGrid