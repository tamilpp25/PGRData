local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelRegressionBase = require("XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionBase")

--- 回归玩家错过活动
local XUiPanelRegressionActivity = XClass(XUiPanelRegressionBase, "XUiPanelRegressionActivity")
local ButtonState = {
    Normal = CS.UiButtonState.Normal,
    Select = CS.UiButtonState.Select
}

--region   ------------------重写父类方法 start-------------------
function XUiPanelRegressionActivity:OnEnable()
    self:RefreshView()
end

function XUiPanelRegressionActivity:Show()
    self:Open()
end

function XUiPanelRegressionActivity:Hide()
    self:Close()
end

function XUiPanelRegressionActivity:InitUi()
    self.GridList = {}
    self.GridTag = {}
    self.Index = 1
    self.ActivityList = self.ViewModel:GetActivityContent()
    self.MaxIndex = #self.ActivityList
    self.BtnTag.enabled = false
    for i = 1, self.MaxIndex do
        local ui = i == 1 and self.BtnTag or XUiHelper.Instantiate(self.BtnTag, self.PanelCub)
        ui.gameObject.name = string.format("BtnTag%d", i)
        self.GridTag[i] = ui.transform:GetComponent("XUiButton")
    end
end

function XUiPanelRegressionActivity:InitCb()
    self.BtnSkip.CallBack = function() 
        self:OnBtnSkipClick()
    end
    
    self.BtnNext.CallBack = function() 
        self:OnChangeActivity(1)
    end

    self.BtnPrevious.CallBack = function()
        self:OnChangeActivity(-1)
    end
end

--endregion------------------重写父类方法 finish------------------

function XUiPanelRegressionActivity:OnBtnSkipClick()
    if not XTool.IsNumberValid(self.SkipId) then
        return
    end
    XFunctionManager.SkipInterface(self.SkipId)
end

function XUiPanelRegressionActivity:OnChangeActivity(step)
    local index = self.Index + step
    self.Index = CS.UnityEngine.Mathf.Clamp(index, 1, self.MaxIndex)
    self.AnimSwitch.transform:PlayTimelineAnimation()
    self:RefreshView()
end

function XUiPanelRegressionActivity:RefreshView()
    if not XDataCenter.Regression3rdManager.CheckActivityLocalRedPointData() then
        XDataCenter.Regression3rdManager.MarkActivityLocalRedPointData()
    end
    self:RefreshTag()
    self.BtnPrevious.gameObject:SetActiveEx(self.Index > 1)
    self.BtnNext.gameObject:SetActiveEx(self.Index < self.MaxIndex)
    local template = self.ActivityList[self.Index]
    self.SkipId = template.SkipId
    self.BtnSkip:SetRawImage(template.ImgPath)
    local itemIds = template.ItemId
    local empty = XTool.IsTableEmpty(itemIds)
    self.PanelReward.gameObject:SetActiveEx(not empty)
    if empty then
        return
    end
    for _, grid in pairs(self.GridList) do
        grid.GameObject:SetActiveEx(false)
    end
    for idx, itemId in ipairs(itemIds) do
        local grid = self.GridList[idx]
        if not grid then
            local ui = idx == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.RewardList)
            grid = XUiGridCommon.New(self.RootUi, ui)
            self.GridList[idx] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId))
    end
end

function XUiPanelRegressionActivity:RefreshTag()
    for i, btnTag in ipairs(self.GridTag) do
        btnTag:SetButtonState(i == self.Index and ButtonState.Select or ButtonState.Normal)
    end
end

return XUiPanelRegressionActivity