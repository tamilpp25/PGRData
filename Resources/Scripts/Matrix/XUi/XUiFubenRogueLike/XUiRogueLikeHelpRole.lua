local XUiRogueLikeHelpRole = XLuaUiManager.Register(XLuaUi, "UiRogueLikeHelpRole")
local XUiGridHelpRoleItem = require("XUi/XUiFubenRogueLike/XUiGridHelpRoleItem")

function XUiRogueLikeHelpRole:OnAwake()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self.HelpRoleList = {}
end

function XUiRogueLikeHelpRole:OnDestroy()

end

function XUiRogueLikeHelpRole:OnEnable()
    XDataCenter.FubenRogueLikeManager.CheckRogueLikeDayResetOnUi("UiRogueLikeHelpRole")
end

function XUiRogueLikeHelpRole:OnDisable()
    XDataCenter.FubenRogueLikeManager.ResetNewRobots()
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_ASSISTROBOT_CHANGED)
end

function XUiRogueLikeHelpRole:OnStart()
    local assistRobots = XDataCenter.FubenRogueLikeManager.GetAssistRobots()
    self.TxtHavet.text = #assistRobots
    self.TxtTotal.text = string.format("/%d", XDataCenter.FubenRogueLikeManager.GetMaxRobotCount())
    self.SortedAssistRobots = {}
    local index = 0
    for _, v in pairs(assistRobots) do
        index = index + 1
        table.insert(self.SortedAssistRobots, {
            RobotId = v.Id,
            Priority = index,
            IsNew = XDataCenter.FubenRogueLikeManager.IsRobotNew(v) and 1 or 0
        })
    end
    table.sort(self.SortedAssistRobots, function(robotA, robotB)
        if robotA.IsNew == robotB.IsNew then
            return robotA.Priority < robotB.Priority
        end
        return robotA.IsNew > robotB.IsNew
    end)

    for i = 1, #self.SortedAssistRobots do
        local robotId = self.SortedAssistRobots[i].RobotId
        if not self.HelpRoleList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.HelpRole.gameObject)
            ui.transform:SetParent(self.PanelHelpHead, false)
            self.HelpRoleList[i] = XUiGridHelpRoleItem.New(ui, self)
        end
        self.HelpRoleList[i].GameObject:SetActiveEx(true)
        self.HelpRoleList[i]:UpdateHelpRoleInfo(robotId)
    end
    for i = #self.SortedAssistRobots + 1, #self.HelpRoleList do
        self.HelpRoleList[i].GameObject:SetActiveEx(false)
    end
end

function XUiRogueLikeHelpRole:OnBtnCloseClick()
    self:Close()
end