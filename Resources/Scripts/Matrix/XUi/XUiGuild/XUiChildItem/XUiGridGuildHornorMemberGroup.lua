local XUiGridGuildHornorMemberGroup = XClass(nil, "XUiGridGuildHornorMemberGroup")
local XUiGridGuildMemberCard = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildMemberCard")

function XUiGridGuildHornorMemberGroup:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.PageMemberList = {}
end

function XUiGridGuildHornorMemberGroup:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridGuildHornorMemberGroup:Refresh(memberPageList)
    self.MemberList = memberPageList
    for i = 1, XGuildConfig.RankBottomPageCount do
        if not self.PageMemberList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.UiGuildRank)
            local grid = XUiGridGuildMemberCard.New(ui, self.UiRoot)
            grid.Transform:SetParent(self.Transform, false)
            self.PageMemberList[i] = grid
        end
        self.PageMemberList[i].GameObject:SetActiveEx(true)
        self.PageMemberList[i]:RefreshNormalMember(self.MemberList[i])
    end
    -- for i = #self.MemberList + 1, #self.PageMemberList do
    --     self.PageMemberList[i].GameObject:SetActiveEx(false)
    -- end
end

return XUiGridGuildHornorMemberGroup