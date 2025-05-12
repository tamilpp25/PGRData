---@class XGuideShowMaskNode : XLuaBehaviorNode 控制遮罩显示（旧）
---@field IsShowMask boolean 是否显示
---@field IsBlockRayCast boolean 是否开启射线检测（无用参数）
local XGuideShowMaskNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideShowMask",CsBehaviorNodeType.Action,true,false)

function XGuideShowMaskNode:OnAwake()


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

function XGuideShowMaskNode:OnEnter()

    self.AgentProxy:ShowMask(self.IsShowMask,self.IsBlockRayCast)
    self.Node.Status = CsNodeStatus.SUCCESS
end

