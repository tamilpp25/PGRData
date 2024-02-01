---@class XGoldenMinerComponentMussel:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentMussel = XClass(XEntity, "XGoldenMinerComponentMussel")

--region Override
function XGoldenMinerComponentMussel:OnInit()
    self.Status = XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.NONE
    
    self.CanHide = true
    self.InitIsOpen = true
    self.IsGrabbed = false
    
    self.HideTime = 0
    self.OpenTime = 0
    self.CurTime = 0

    ---@type UnityEngine.Transform
    self.AnimOpen = false
    ---@type UnityEngine.Transform
    self.AnimClose = false
    ---@type UnityEngine.Transform
    self.GrabCarry = false
    ---@type UnityEngine.Collider2D
    self.OpenCollider = false
    ---@type UnityEngine.Collider2D
    self.CloseCollider = false
    ---@type XGoInputHandler
    self.OpenGoInputHandler = false
    ---@type XGoInputHandler
    self.CloseGoInputHandler = false
end

function XGoldenMinerComponentMussel:OnRelease()
    self.AnimOpen = nil
    self.AnimClose = nil
    self.GrabCarry = nil
    self.OpenCollider = nil
    self.CloseCollider = nil
    if self.OpenGoInputHandler then
        self.OpenGoInputHandler:RemoveAllListeners()
        self.OpenGoInputHandler = nil
    end
    if self.CloseGoInputHandler then
        self.CloseGoInputHandler:RemoveAllListeners()
        self.CloseGoInputHandler = nil
    end
end
--endregion

return XGoldenMinerComponentMussel