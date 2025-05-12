local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelAuthentication
---@field _Control XReCallActivityControl
local XUiPanelAuthentication = XClass(nil, "XUiPanelAuthentication")

local GridType = {
    Invite = 0,--填写邀请码奖励格子
    Share = 1,--分享活动奖励格子
}
function XUiPanelAuthentication:Ctor(ui, parent, control)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self._Control = control
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.GridCommon1.gameObject:SetActiveEx(false)
    self.GridCommon2.gameObject:SetActiveEx(false)
    self.GridList1 = {}
    self.GridList2 = {}
end

--设置奖励
function XUiPanelAuthentication:SetupReward(rewardId,gridType)
    local rewards = XRewardManager.GetRewardList(rewardId)

    if not rewards then
        return
    end

    local GridCommon
    local PanelReward
    local GridList
    if gridType == GridType.Invite then
        GridCommon = self.GridCommon1
        PanelReward = self.PanelDropContent1
        GridList = self.GridList1
    else
        GridCommon = self.GridCommon2
        PanelReward = self.PanelDropContent2
        GridList = self.GridList2
    end

    --显示的奖励
    local start = 0
    if rewards then
        for i, item in ipairs(rewards) do
            start = i
            local grid
            if GridList[i] then
                grid = GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(GridCommon)
                grid = XUiGridCommon.New(self.Parent, ui)
                grid.Transform:SetParent(PanelReward, false)
                GridList[i] = grid
            end
            if gridType == GridType.Share then
                grid:Refresh(item,{ShowReceived = self._Control:GetIsGetShareReward()})
            else
                grid:Refresh(item)
            end
            grid.GameObject:SetActive(true)
        end
    end

    for j = start + 1, #GridList do
        GridList[j].GameObject:SetActive(false)
    end
end

function XUiPanelAuthentication:OnBtnReceiveClick()
    local code = self.InputField.text
    if string.IsNilOrEmpty(code) then
        XUiManager.TipText("ReCallActivityNeedInputRightCode")
        return
    end
    if code and code ~= "" then
        code = string.upper(code)
    end
    if code == self._Control:PlayIdToHexUpper() then
        XUiManager.TipText("HoldRegressionInvite")
        return 
    end
    if not self._Control:GetCurInviteInTime() then
        XUiManager.TipText("CommonActivityEnd")
        return 
    end
    self._Control:InviteCodeRequest(code)
end

function XUiPanelAuthentication:AutoAddListener()
    self.BtnReceive.CallBack = function() self:OnBtnReceiveClick() end
    self.BtnCopy.CallBack = function() self:OnBtnCopyClick() end
    self.BtnShare.CallBack = function() self:OnBtnShareClick() end
end

function XUiPanelAuthentication:Refresh()
    if self._Control:GetInviteId() ~= 0 then
        self.PanelAuthentication.gameObject:SetActive(true)
        self.PanelInvite.gameObject:SetActive(false)
        self.TeamInfoText.text = CS.XTextManager.GetText("HoldRegressionteam",self._Control:GetInviteId())
    else
        if self._Control:GetIsRegression() then
            self.PanelAuthentication.gameObject:SetActive(false)
            self.PanelInvite.gameObject:SetActive(true)
        else
            self.PanelAuthentication.gameObject:SetActive(true)
            self.PanelInvite.gameObject:SetActive(false)
            self.TeamInfoText.text = CS.XTextManager.GetText("HoldRegressionInviteCodetip")
        end
    end 
    local activityId = self._Control:GetActivityId()
    local config = self._Control:GetActivityConfigById(activityId)
    if config then
        self:SetupReward(config.RegressionRewardId,GridType.Invite)
        self:SetupReward(config.InviteRewardId,GridType.Share)
    end
    self.CodeText.text = CS.XTextManager.GetText("HoldRegressionInviteCode",self._Control:PlayIdToHexUpper())
end

function XUiPanelAuthentication:OnBtnCopyClick()
    XTool.CopyToClipboard(self._Control:PlayIdToHexUpper())
end

function XUiPanelAuthentication:OnBtnShareClick()
    if not self._Control:GetCurInviteInTime() then
        XUiManager.TipText("CommonActivityEnd")
        return 
    end
    XLuaUiManager.Open("UiReCallActivityShare")
end

return XUiPanelAuthentication