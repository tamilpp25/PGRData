local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiDlcHuntPersonalSettlement:XLuaUi
local XUiDlcHuntPersonalSettlement = XLuaUiManager.Register(XLuaUi, "UiDlcHuntPersonalSettlement")

function XUiDlcHuntPersonalSettlement:OnAwake()
    self:RegisterClickEvent(self.BtnDlcBlue, self.OnClickQuitTeam)
    self:RegisterClickEvent(self.BtnDlcYellow, self.Close)
    self:RegisterClickEvent(self.Button, self.HideBadgeTip)
    self:HideBadgeTip()
end

---@param data XDlcHuntSettle
function XUiDlcHuntPersonalSettlement:OnStart(data)
    if not data then
        return
    end
    self.Text.text = data.Name
    self.TxtDifficulty2.text = data.PassedTime

    local myData = data:GetMyData()

    --region 徽章
    local badgeList = myData.Badge
    local uiBadge = self.GridReward1
    for i = 1, #badgeList do
        local dataBadge = badgeList[i]
        local uiObject = CS.UnityEngine.Object.Instantiate(uiBadge, uiBadge.transform.parent)
        local badgeGrid = { Transform = uiObject.transform }
        XTool.InitUiObject(badgeGrid)
        badgeGrid.RawImage:SetRawImage(dataBadge.Icon)
        XUiHelper.RegisterClickEvent(badgeGrid, badgeGrid.Button, function()
            self:ShowBadgeTip(badgeGrid.Transform, dataBadge)
        end)
    end
    uiBadge.gameObject:SetActiveEx(false)
    --endregion 徽章

    --region 战斗信息
    for i = 1, 5 do
        local ui = self["WinCount" .. i]
        if ui then
            local detailValue = myData.DetailValue[i]
            if detailValue then
                local uiText = XUiHelper.TryGetComponent(ui.transform, "TxtModeName", "Text")
                uiText.text = detailValue
            else
                ui.gameObject:SetActiveEx(false)
            end
        end
    end
    --endregion 战斗信息

    --region 获得奖励
    local rewardList = data.RewardList
    for i = 1, #rewardList do
        local uiReward = CS.UnityEngine.Object.Instantiate(self.GridReward, self.GridReward.transform.parent)
        local gridCommon = XUiGridCommon.New(self, uiReward)
        gridCommon:Refresh(rewardList[i])
    end
    self.GridReward.gameObject:SetActiveEx(false)
    --endregion 获得奖励
end

function XUiDlcHuntPersonalSettlement:OnClickQuitTeam()
    XDataCenter.DlcRoomManager.Quit()
    self:Close()
end

function XUiDlcHuntPersonalSettlement:ShowBadgeTip(uiTargetTransform, dataBadge)
    self.Prompt.gameObject:SetActiveEx(true)
    self.Button.gameObject:SetActiveEx(true)
    self.Text1.text = dataBadge.Name
    self.Text2.text = dataBadge.Desc
    self.Prompt.transform.position = uiTargetTransform.position
end

function XUiDlcHuntPersonalSettlement:HideBadgeTip()
    self.Prompt.gameObject:SetActiveEx(false)
    self.Button.gameObject:SetActiveEx(false)
end

return XUiDlcHuntPersonalSettlement
