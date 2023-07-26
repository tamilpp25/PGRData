local XUiPanelCombatMembers = XClass(nil, "XUiPanelCombatMembers")

local MAX_CHAR_COUNT = 3

function XUiPanelCombatMembers:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.MemberList = XDataCenter.FubenSimulatedCombatManager.GetCurrentResList(XFubenSimulatedCombatConfig.ResType.Member)
    self:InitView()
    self:UpdateView()
end

function XUiPanelCombatMembers:InitView()
    self.MemberNoneList = {}
    self.MemberGridList = {}
    self.IconList = {}
    self.TxtStarList = {}

    for i = 1, MAX_CHAR_COUNT do
        self.MemberNoneList[i] = self.Transform:Find("Member"..i.."/None")
        self.MemberGridList[i] = self.Transform:Find("Member"..i.."/Member")
        self.IconList[i] = self.MemberGridList[i]:Find("RImg"):GetComponent("RawImage")
        self.TxtStarList[i] = self.MemberGridList[i]:Find("StarInformation"):GetComponent("Text")
    end
    
end

function XUiPanelCombatMembers:UpdateView()
    for i = 1, MAX_CHAR_COUNT do
        self.MemberNoneList[i].gameObject:SetActiveEx(false)
        self.MemberGridList[i].gameObject:SetActiveEx(false)
    end
    
    local index = 0
    for _,v in ipairs(self.MemberList) do
        if v.BuyMethod and index < MAX_CHAR_COUNT then
            index = index + 1
            self.MemberGridList[index].gameObject:SetActiveEx(true)
            local resInfo = XFubenSimulatedCombatConfig.GetMemberById(v.Id)
            self.IconList[index]:SetRawImage(XRobotManager.GetRobotSmallHeadIcon(resInfo.RobotId))
            self.TxtStarList[index].text = resInfo.Star
        end
    end
    for i = index + 1, MAX_CHAR_COUNT do
        self.MemberNoneList[i].gameObject:SetActiveEx(true)
    end
end

return XUiPanelCombatMembers