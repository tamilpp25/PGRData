--================
--功能解锁弹窗
--================
local XUiRiftFuncUnlockTips = XLuaUiManager.Register(XLuaUi, "UiRiftFuncUnlockTips")

function XUiRiftFuncUnlockTips:OnAwake()
    self.RewardList = nil
    self.GridRewardList = {}
    XTool.InitUiObject(self)
    self.GridUnlockIcon.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiRiftFuncUnlockTips:OnStart(rewardList)
    self.RewardList = rewardList
    self:Refresh()
end

function XUiRiftFuncUnlockTips:Refresh()
    for i, item in ipairs(self.RewardList) do
        local grid
        if self.GridRewardList[i] then
            grid = self.GridRewardList[i]
        else
            grid = CS.UnityEngine.Object.Instantiate(self.GridUnlockIcon, self.GridUnlockIcon.parent)
            grid.gameObject:SetActiveEx(true)
            self.GridRewardList[i] = grid
        end

        local templateId = item.TemplateId
        local count = item.Count

        local itemUiObject = grid:GetComponent("UiObject")
        itemUiObject:GetObject("TxtName").text = XItemConfigs.GetItemNameById(templateId)

        local icon = XItemConfigs.GetItemIconById(templateId)
        itemUiObject:GetObject("RImgIcon"):SetRawImage(icon)

        local txtNum = itemUiObject:GetObject("TxtNum")
        txtNum.text = "X" .. count
        txtNum.gameObject:SetActiveEx(true)

        XUiHelper.RegisterClickEvent(self, itemUiObject:GetObject("RImgIcon"), function()
            self:OnBtnItemClick(templateId, count)
        end)
    end
end

-- 点击特权解锁道具
function XUiRiftFuncUnlockTips:OnBtnItemClick(itemId, count)
    local data = {
        Id = itemId,
        Count = count,
    }
    XLuaUiManager.Open("UiTip", data)
end