---@class XUiTheatre3AchvPanelReward : XUiNode
---@field _Control XTheatre3Control
local XUiTheatre3AchvPanelReward = XClass(XUiNode, "XUiTheatre3AchvPanelReward")

function XUiTheatre3AchvPanelReward:OnStart()
    ---@type UnityEngine.Transform
    self.UpdateEffect = self.TxtName2.transform:Find("Effect")
    self.UpdateEffect.gameObject:SetActiveEx(false)
    self:_InitRewardData()
    self:AddBtnListener()
end

--region Data
---@class XUiTheatre3AchvPanelRewardData
---@field RewardId number
---@field ProcessMaxLimit number
---@field ProcessMinLimit number

function XUiTheatre3AchvPanelReward:_InitRewardData()
    self._IsFirst = true
    self._CurRewardLevel = 1
    ---@type XUiTheatre3AchvPanelRewardData[]
    self._RewardDataList = {}
    local rewardIdList = self._Control:GetCfgAchievementRewardIdList()
    local needCountList = self._Control:GetCfgAchievementNeedCountList()
    for i, rewardId in ipairs(rewardIdList) do
        ---@type XUiTheatre3AchvPanelRewardData
        local rewardData = {}
        rewardData.RewardId = rewardId
        rewardData.ProcessMaxLimit = needCountList[i]
        rewardData.ProcessMinLimit = i == 1 and 0 or self._RewardDataList[i - 1].ProcessMaxLimit
        self._RewardDataList[i] = rewardData
    end
end

function XUiTheatre3AchvPanelReward:_GetRewardLevel(finishCount)
    for i, data in ipairs(self._RewardDataList) do
        local inLevel = finishCount >= data.ProcessMinLimit and finishCount <= data.ProcessMaxLimit
        if inLevel and not self._Control:CheckAchievementIsGet(i) then
            return i
        end
    end
    return 0
end
--endregion

--region Ui - Reward
function XUiTheatre3AchvPanelReward:Refresh(finishCount)
    self._CurRewardLevel = self:_GetRewardLevel(finishCount)
    if not self._RewardDataList[self._CurRewardLevel] then
        self:_RefreshEmpty()
        return
    end
    local levelProcessValue = finishCount - self._RewardDataList[self._CurRewardLevel].ProcessMinLimit
    local levelProcessLimit = self._RewardDataList[self._CurRewardLevel].ProcessMaxLimit - self._RewardDataList[self._CurRewardLevel].ProcessMinLimit
    self.UpdateEffect.gameObject:SetActiveEx(false)
    if self._IsFirst then
        self:_RefreshPanel(levelProcessValue, levelProcessLimit)
        self._IsFirst = false
    else
        self:_RefreshUpdateEffect(levelProcessValue, levelProcessLimit)
    end
end

function XUiTheatre3AchvPanelReward:_RefreshEmpty()
    local descConfig = XBiancaTheatreConfigs.GetTheatreClientConfig("AchievementRewardAllGet")
    local rewardId = self._RewardDataList[#self._RewardDataList].RewardId
    local rewardItems = XRewardManager.GetRewardList(rewardId)
    local rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
    self.TxtName.gameObject:SetActiveEx(false)
    self.ImgProgress2.fillAmount = 1
    self.TxtName2.text = descConfig and descConfig.Values[1]
    self.RImgIcon:SetRawImage(XEntityHelper.GetItemIcon(rewardGoodsList[1].TemplateId))
end

function XUiTheatre3AchvPanelReward:_RefreshPanel(levelProcessValue, levelProcessLimit)
    local rewardId = self._RewardDataList[self._CurRewardLevel].RewardId
    local rewardItems = XRewardManager.GetRewardList(rewardId)
    local rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
    self._LevelProcessValue = levelProcessValue
    self._LevelProcessLimit = levelProcessLimit
    self.TxtName2.text = levelProcessLimit - levelProcessValue
    self.ImgProgress2.fillAmount = levelProcessValue / levelProcessLimit
    self.RImgIcon:SetRawImage(XEntityHelper.GetItemIcon(rewardGoodsList[1].TemplateId))
    self:_CheckAutoRecvAchievement()
end

function XUiTheatre3AchvPanelReward:_RefreshUpdateEffect(levelProcessValue, levelProcessLimit)
    if self._LevelProcessLimit - self._LevelProcessValue == levelProcessLimit - levelProcessValue then
        return
    end
    local oldFillAmount = self._LevelProcessValue / self._LevelProcessLimit
    local changeFillAmount = levelProcessValue / levelProcessLimit - oldFillAmount
    XUiHelper.Tween(0.5, function(f)
        -- 防止动画还没结束就关闭界面导致计时器报错
        if XTool.UObjIsNil(self.Transform) then return end
        self.ImgProgress2.fillAmount = oldFillAmount + changeFillAmount * f
    end, function()
        self.UpdateEffect.gameObject:SetActiveEx(false)
        self.UpdateEffect.gameObject:SetActiveEx(true)
        self:_RefreshPanel(levelProcessValue, levelProcessLimit)
    end)
end

function XUiTheatre3AchvPanelReward:_CheckAutoRecvAchievement()
    if not self._RewardDataList[self._CurRewardLevel] or self._Control:CheckAchievementIsGet(self._CurRewardLevel) then
        return
    end
    if self._LevelProcessValue > 0 and self._LevelProcessValue == self._LevelProcessLimit then
        self._Control:RequestAchievementReward(self._CurRewardLevel)
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3AchvPanelReward:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.RImgIcon, self.OnClickRewardDetail)
end

function XUiTheatre3AchvPanelReward:OnClickRewardDetail()
    local rewardId
    if not self._RewardDataList[self._CurRewardLevel] then
        rewardId = self._RewardDataList[#self._RewardDataList].RewardId
    else
        rewardId = self._RewardDataList[self._CurRewardLevel].RewardId
    end
    if not rewardId then
        return
    end
    local rewardList = XRewardManager.GetRewardList(rewardId)
    XLuaUiManager.Open("UiTheatre3Tips", rewardList[1].TemplateId)
end
--endregion

return XUiTheatre3AchvPanelReward