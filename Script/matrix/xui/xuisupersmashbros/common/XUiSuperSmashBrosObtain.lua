
local XUiSuperSmashBrosObtain = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosObtain")

function XUiSuperSmashBrosObtain:OnStart(score, rewardList, addTeamItem, onCloseCb)
    self.Items = {}
    self.OnCloseCb = onCloseCb
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, handler(self, self.OnBtnCancelClick))
    self:RefreshScore(score)
    self:RefreshRewards(rewardList)
    self:RefreshTeamItem(addTeamItem)
end

function XUiSuperSmashBrosObtain:RefreshScore(score)
    self.TxtPoint.text = score
end

function XUiSuperSmashBrosObtain:RefreshRewards(rewardList)
    self.GridCommon.gameObject:SetActive(false)
    rewardList = XRewardManager.MergeAndSortRewardGoodsList(rewardList)
    XUiHelper.CreateTemplates(self, self.Items, rewardList, XUiGridCommon.New, self.GridCommon, self.PanelContent, function(grid, data)
            grid:Refresh(data, nil, nil, false)
        end)
end

function XUiSuperSmashBrosObtain:RefreshTeamItem(addTeamItem)
    if (not addTeamItem) or (addTeamItem == 0) then return end
    local script = require("XUi/XUiSuperSmashBros/Common/XUiSSBDisplayItem")
    local go = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelContent)
    local grid = script.New(go)
    grid:Refresh(XDataCenter.SuperSmashBrosManager.GetLevelItem(), addTeamItem)
end

function XUiSuperSmashBrosObtain:OnBtnCancelClick()
    self:Close()
end

function XUiSuperSmashBrosObtain:OnDestroy()
    if self.OnCloseCb then
        self.OnCloseCb()
    end
end