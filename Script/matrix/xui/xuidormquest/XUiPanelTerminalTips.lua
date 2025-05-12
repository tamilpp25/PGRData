---@class XUiPanelTerminalTips
local XUiPanelTerminalTips = XClass(nil, "XUiPanelTerminalTips")

function XUiPanelTerminalTips:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.ImgTips01.gameObject:SetActiveEx(false)
    self.ImgTips02.gameObject:SetActiveEx(false)

    -- 延迟时间
    self.DelayTime = XUiHelper.GetClientConfig("DormQuestTerminalTipDelayTime", XUiHelper.ClientConfigType.Int)
end

function XUiPanelTerminalTips:ShowFileTips()
    XDataCenter.DormQuestManager.SetIsHaveNewQuestFile(false)
    self.GameObject:SetActiveEx(true)
    self.ImgTips02.gameObject:SetActiveEx(true)
    self.FileTimer = XScheduleManager.ScheduleOnce(function()
        --隐藏
        self.ImgTips02.gameObject:SetActiveEx(false)
        self.GameObject:SetActiveEx(false)
    end, XScheduleManager.SECOND * self.DelayTime)
end

function XUiPanelTerminalTips:ShowUpgradeTips()
    XDataCenter.DormQuestManager.SaveTerminalShowUpgradeTip(true)
    self.GameObject:SetActiveEx(true)
    self.ImgTips01.gameObject:SetActiveEx(true)
    self.UpgradeTimer = XScheduleManager.ScheduleOnce(function()
        -- 隐藏
        self.ImgTips01.gameObject:SetActiveEx(false)
        self.GameObject:SetActiveEx(false)
    end, XScheduleManager.SECOND * self.DelayTime)
end

function XUiPanelTerminalTips:ShowAutoQuestSuccess()
    XDataCenter.DormQuestManager.SaveTerminalShowUpgradeTip(true)
    self.GameObject:SetActiveEx(true)
    self.ImgTips03.gameObject:SetActiveEx(true)
    self.UpgradeTimer = XScheduleManager.ScheduleOnce(function()
        -- 隐藏
        self.ImgTips03.gameObject:SetActiveEx(false)
        self.GameObject:SetActiveEx(false)
    end, XScheduleManager.SECOND * self.DelayTime)
end

function XUiPanelTerminalTips:OnDisable()
    self.GameObject:SetActiveEx(false)
    if self.FileTimer then
        XScheduleManager.UnSchedule(self.FileTimer)
        self.FileTimer = nil
    end
    if self.UpgradeTimer then
        XScheduleManager.UnSchedule(self.UpgradeTimer)
        self.UpgradeTimer = nil
    end
end

return XUiPanelTerminalTips