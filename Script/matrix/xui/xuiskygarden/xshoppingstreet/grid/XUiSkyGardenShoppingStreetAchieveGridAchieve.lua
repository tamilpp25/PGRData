---@class XUiSkyGardenShoppingStreetAchieveGridAchieveGridAchieve : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field UiBigWorldItemGrid UnityEngine.RectTransform
---@field PanelComplete UnityEngine.RectTransform
---@field BtnClick XUiComponent.XUiButton
---@field ImgBar UnityEngine.UI.Image
local XUiSkyGardenShoppingStreetAchieveGridAchieveGridAchieve = XClass(XUiNode, "XUiSkyGardenShoppingStreetAchieveGridAchieveGridAchieve")
local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiSkyGardenShoppingStreetAchieveGridAchieveGridAchieve:OnStart()
    self._Rewards = {}
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetAchieveGridAchieveGridAchieve:ResetData(data, i)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.Data = data

    self.PanelComplete.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)

    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.tableData = config
    self.TxtTitle.text = config.Title
    self.TxtDetail.text = config.Desc
    
    local result = config.Result > 0 and config.Result or 1
    XTool.LoopMap(self.Data.Schedule, function(_, pair)
        self.ImgBar.fillAmount = pair.Value / result
        pair.Value = (pair.Value >= result) and result or pair.Value
    end)

    local rewards = XRewardManager.GetRewardList(config.RewardId)
    XTool.UpdateDynamicItem(self._Rewards, rewards, self.UiBigWorldItemGrid, XUiGridBWItem, self)
end

--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetAchieveGridAchieveGridAchieve:OnBtnClickClick()
    if self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved then
        return
    end

    local weaponCount = 0
    local chipCount = 0
    local rewards = XRewardManager.GetRewardList(self.tableData.RewardId)
    for i = 1, #rewards do
        local rewardsId = rewards[i].TemplateId
        if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
            weaponCount = weaponCount + 1
        elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
            chipCount = chipCount + 1
        end
    end
    if weaponCount > 0 and 
        XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or 
        chipCount > 0 and 
        XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
        return
    end
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        for i = 1, #rewards do
            if rewards[i].RewardType == XRewardManager.XRewardType.Nameplate then
                return
            end
        end
        XUiManager.OpenUiObtain(rewardGoodsList)
        self.Parent:RefreshAchieveList()
    end)
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetAchieveGridAchieveGridAchieve:_RegisterButtonClicks()
    self.BtnClick.CallBack = function() self:OnBtnClickClick() end
end
--endregion

return XUiSkyGardenShoppingStreetAchieveGridAchieveGridAchieve
