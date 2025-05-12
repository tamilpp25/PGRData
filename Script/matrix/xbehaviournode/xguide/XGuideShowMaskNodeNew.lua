---@class XGuideShowMaskNodeNew : XLuaBehaviorNode 控制遮罩显示（新）
---@field IsShowMask boolean 是否显示
---@field IsBlockRayCast boolean 是否开启射线检测（无用参数）
local XGuideShowMaskNodeNew = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideIsBlockRayCast", 
        CsBehaviorNodeType.Action, true, false)
--显示对话头像
function XGuideShowMaskNodeNew:OnAwake()


    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end


    if self.Fields["IsShowMask"] == nil or self.Fields["IsBlockRayCast"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.IsShowMask = self.Fields["IsShowMask"]
    self.IsBlockRayCast = self.Fields["IsBlockRayCast"]
end

function XGuideShowMaskNodeNew:OnEnter()
    self.AgentProxy:ShowMaskNew(self.IsShowMask, self.IsBlockRayCast)
    self.Node.Status = CsNodeStatus.SUCCESS
end