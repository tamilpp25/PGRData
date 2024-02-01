---@class XUiMainLine2GridStage : XUiNode
---@field private _Control XMainLine2Control
local XUiMainLine2GridStage = XClass(XUiNode, "XUiMainLine2GridStage")

function XUiMainLine2GridStage:OnStart()

end

function XUiMainLine2GridStage:Refresh(stageId)
    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(stageId)
    self.RImgIcon:SetRawImage(stageCfg.StoryIcon)
end

return XUiMainLine2GridStage