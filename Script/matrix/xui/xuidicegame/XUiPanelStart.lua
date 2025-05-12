local XUiPanelReward = require("XUi/XUiDiceGame/XUiPanelReward")
local XUiPanelStart = XClass(nil, "XUiPanelStart")

---@param root XUiDiceGame
---@field protected BtnStart XUiComponent.XUiButton
---@field protected BgImg UnityEngine.UI.RawImage
---@field protected PanelReward UnityEngine.RectTransform
function XUiPanelStart:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.OnBtnStartClick)

    self.RewardPanel = XUiPanelReward.New(self.PanelReward, self.Root)
    self.GameObject:SetActiveEx(false)
    self.TimerId = 0
end

function XUiPanelStart:OnBtnStartClick()
    local itemId = XDataCenter.DiceGameManager.GetCoinItemId()
    local coinCnt = XDataCenter.ItemManager.GetCount(itemId)
    if coinCnt < 1 then
        local tips = XUiHelper.GetText("DiceGameNoEnoughCoinHint", "1")
        XUiManager.TipError(tips)
        return
    end

    self.Root:UpdatePanel(2, true, 1) --跳转面板
end

function XUiPanelStart:OnEnable()
    local timeLeft = XDataCenter.DiceGameManager.GetDiceGameTimeLeft()
    self.TxtTime.text = XUiHelper.GetTime(timeLeft, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiPanelStart:SetActive(active, refreshReward, playAnim, disableFinishCb)
    if active then
        self.GameObject:SetActiveEx(true)
        self:OnEnable()
        if playAnim then
            self.Root:PlayAnimationWithMask("PanelStartEnable", function()
                if refreshReward then
                    self.RewardPanel:UpdatePanel(false)
                end
            end)
        else
            if refreshReward then
                self.RewardPanel:UpdatePanel(false)
            end
        end
        self.TimerId = XScheduleManager.ScheduleOnce(function()
            self.RewardPanel:UpdateGridPosition()-- 等待异形屏组件适配宽度后再计算坐标，避免初始化时计算坐标与实际适配后界面宽度不匹配。
        end, 100)
    else
        if playAnim and self.GameObject.activeInHierarchy then
            self.Root:PlayAnimationWithMask("PanelStartDisable", function()
                self.GameObject:SetActiveEx(false)
                if disableFinishCb then disableFinishCb() end
            end)
        else
            self.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelStart:OnDestroy()
    if self.TimerId > 0 then
        XScheduleManager.UnSchedule(self.TimerId)
        self.TimerId = 0
    end
end

return XUiPanelStart