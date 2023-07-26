local XUiLvRewardGrid = XClass(nil, "XUiLvRewardGrid")

--肉鸽玩法二期等级奖励面板的格子
function XUiLvRewardGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiLvRewardGrid:Init(rootUi)
    self.RootUi = rootUi
end

--lvRewardId：BiancaTheatreLevelReward表的Id
function XUiLvRewardGrid:Refresh(lvRewardId)
    local rewardId = XBiancaTheatreConfigs.GetLevelRewardId(lvRewardId)
    local rewardList = XRewardManager.GetRewardList(rewardId)
    local reward = rewardList[1] --读取第一个
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(reward.TemplateId)
    if not goodsShowParams then
        XLog.Error(string.format("获取道具数据有误，肉鸽奖励表Id：%s，rewardId：%s", lvRewardId, rewardId))
        return
    end
    
    local isRare = XBiancaTheatreConfigs.GetLevelRewardDisplayType(lvRewardId) 
            == XBiancaTheatreConfigs.RewardDisplayType.Rare
    local received = XDataCenter.BiancaTheatreManager.CheckRewardReceived(lvRewardId)
    local canGet = XDataCenter.BiancaTheatreManager.CheckRewardAbleToReceive(lvRewardId)
    local showNormal = not canGet or received
    local showLight = not received and canGet
    --已领取
    self.Disable.gameObject:SetActiveEx(received)
    self.EffectRareLight.gameObject:SetActiveEx(not received)
    self.EffectRare.gameObject:SetActiveEx(not received)
    self.EffectNormal.gameObject:SetActiveEx(not received)
    --普通 && 未领取
    self.Normal.gameObject:SetActiveEx(not isRare and showNormal)
    self.NormaLlight.gameObject:SetActiveEx(not isRare and showLight)
    --稀有 && 未领取
    self.Rare.gameObject:SetActiveEx(isRare and showNormal)
    self.RareLlight.gameObject:SetActiveEx(isRare and showLight)
    -- 等级
    self.PanelGrid:SetNameByGroup(0, lvRewardId)
    -- 名字
    local name = goodsShowParams.RewardType == XArrangeConfigs.Types.Character and goodsShowParams.TradeName or goodsShowParams.Name
    local count = reward.Count
    self.PanelGrid:SetNameByGroup(1, name)
    -- 描述
    self.PanelGrid:SetNameByGroup(2, XBiancaTheatreConfigs.GetLevelRewardDesc(lvRewardId))
    --数量
    self.PanelGrid:SetNameByGroup(3, "x" .. count)
    -- 图标
    -- local icon = goodsShowParams.Icon
    local icon = goodsShowParams.BigIcon
    self.PanelGrid:SetRawImage(icon)
end

function XUiLvRewardGrid:OnClickGrid(lvId, cb)
    if not XTool.IsNumberValid(lvId) then
        return
    end
    local canGet = XDataCenter.BiancaTheatreManager.CheckRewardAbleToReceive(lvId)
    if canGet then
        XDataCenter.BiancaTheatreManager.RequestGetReward(lvId, cb)
    else
        local rewardId = XBiancaTheatreConfigs.GetLevelRewardId(lvId)
        local rewardList = XRewardManager.GetRewardList(rewardId)
        local reward = rewardList[1] --读取第一个
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(reward.TemplateId)
        if not goodsShowParams then
            XLog.Error(string.format("获取道具数据有误，肉鸽奖励表Id：%s，rewardId：%s", lvId, rewardId))
            return
        end
        XLuaUiManager.Open("UiBiancaTheatreTips", goodsShowParams)
    end
    
end


return XUiLvRewardGrid