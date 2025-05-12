-- 入口气泡提示
---@class XUiPanelTerminalEntranceTips
local XUiPanelTerminalEntranceTips = XClass(nil, "XUiPanelTerminalEntranceTips")

local DelayTime = 5

function XUiPanelTerminalEntranceTips:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    
    ---@type UnityEngine.RectTransform
    self.DisableAnim = XUiHelper.TryGetComponent(self.Transform,"Animation/Disable")
end

function XUiPanelTerminalEntranceTips:Refresh()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DormQuest) then
        return
    end
    local data = self:GetShowData()
    if not data then
        return
    end
    self.GameObject:SetActiveEx(true)
    self.ImgDes:SetSprite(XUiHelper.GetClientConfig(data.Icon, XUiHelper.ClientConfigType.String))
    self.TxtName.text = XUiHelper.GetText(data.Content)
    self.TxtNum.text = data.Count
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self.DisableAnim:PlayTimelineAnimation(function()
            self.GameObject:SetActiveEx(false)
        end)
    end, XScheduleManager.SECOND * DelayTime)
end

function XUiPanelTerminalEntranceTips:GetShowData()
    local dispatchedCount, unDispatchCount = XDataCenter.DormQuestManager.GetEntranceShowData()
    if dispatchedCount > 0 then
        return { Count = dispatchedCount, Content = "DormQuestTerminalTeamRegress", Icon = "DormQuestTerminalTeamRegressIcon" }
    end
    if unDispatchCount > 0 then
        return { Count = unDispatchCount, Content = "DormQuestTerminalTeamFree", Icon = "DormQuestTerminalTeamFreeIcon" }
    end
    return nil
end

function XUiPanelTerminalEntranceTips:OnBtnClick()
    if XHomeDormManager.InDormScene() then
        XLuaUiManager.Open("UiDormTerminalSystem")
    else
        XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
            XLuaUiManager.Open("UiDormTerminalSystem")
        end)
    end
end

function XUiPanelTerminalEntranceTips:OnDisable()
    self.GameObject:SetActiveEx(false)
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiPanelTerminalEntranceTips