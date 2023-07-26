---@class XUiPanelTerminalLevelUpgrade
local XUiPanelTerminalLevelUpgrade = XClass(nil, "XUiPanelTerminalLevelUpgrade")

-- 3秒后自动关闭
local AutoCloseTime = 3

function XUiPanelTerminalLevelUpgrade:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnDarkBg, self.OnBtnDarkBgClick)
end

function XUiPanelTerminalLevelUpgrade:Refresh(oldLevel, curLevel)
    self.GameObject:SetActiveEx(true)
    ---@type XDormQuestTerminal
    local oldTerminalViewModel = XDataCenter.DormQuestManager.GetDormQuestTerminalViewModel(oldLevel)
    ---@type XDormQuestTerminal
    local curTerminalViewModel = XDataCenter.DormQuestManager.GetDormQuestTerminalViewModel(curLevel)

    local oldLevelDesc, oldTeamCount, oldQuestCount = oldTerminalViewModel:GetQuestTerminalPropertyData()
    local curLevelDesc, curTeamCount, curQuestCount = curTerminalViewModel:GetQuestTerminalPropertyData()
    self.TxtCurLevel.text = curLevelDesc
    self.TxtOldLevel.text = oldLevelDesc
    self:UpdatePropertyData(self.GridTeamUpgrade, oldTeamCount, curTeamCount)
    self:UpdatePropertyData(self.GridQuestUpgrade, oldQuestCount, curQuestCount)

    self:StartTimer()
end

-- 刷新属性数据
function XUiPanelTerminalLevelUpgrade:UpdatePropertyData(prefab, oldValue, curValue)
    local grid = {}
    XTool.InitUiObjectByUi(grid, prefab)
    grid.TxtOldValue.text = oldValue
    grid.TxtCurValue.text = curValue
end

-- 倒计时
function XUiPanelTerminalLevelUpgrade:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self.GameObject:SetActiveEx(false)
    end, XScheduleManager.SECOND * AutoCloseTime)
end

function XUiPanelTerminalLevelUpgrade:OnBtnDarkBgClick()
    self:StopTimer()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelTerminalLevelUpgrade:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPanelTerminalLevelUpgrade:OnDisable()
    self:StopTimer()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelTerminalLevelUpgrade