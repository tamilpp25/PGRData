---@class XGuideOpenDormitoryNode : XLuaBehaviorNode 打开宿舍选中某一间房
---@field DormId number 房间Id
local XGuideOpenDormitoryNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "OpenDormitory", CsBehaviorNodeType.Action, true, false)

function XGuideOpenDormitoryNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["DormId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.DormId = self.Fields["DormId"]
end

function XGuideOpenDormitoryNode:OnEnter()
    XLuaUiManager.Open("UiDormSecond", XDormConfig.VisitDisplaySetType.MySelf, self.DormId)
    XHomeDormManager.SetSelectedRoom(self.DormId, true)
    self.Node.Status = CsNodeStatus.SUCCESS
end
