--大秘境跃升
local XUiRiftJumpResults = XLuaUiManager.Register(XLuaUi, "UiRiftJumpResults")
local XUiGridRiftJumpRes = require("XUi/XUiRift/Grid/XUiGridRiftJumpRes")

function XUiRiftJumpResults:OnAwake()
    self.GridResList = {}

    self:InitButton()
end

function XUiRiftJumpResults:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

--- func desc
---@param triggerJump 跃升领取的奖励层数 etc: 10 - 15 层没首通，但是解锁。此时pass = 10， 打了13,这时候jump = 13 - 10 = 3
function XUiRiftJumpResults:OnStart(triggerJump, closeCb)
    self.TriggerJumpNum = triggerJump
    self.CloseCb = closeCb 
end

function XUiRiftJumpResults:OnEnable()
    local lastFightStage = XDataCenter.RiftManager.GetLastFightXStage()
    -- 领取了从 A层到B层的跃升奖励
    local targetFightLayer = lastFightStage:GetParent():GetParent()
    local jumpToId = targetFightLayer:GetId()
    local jumpOrgId = jumpToId - self.TriggerJumpNum

    -- 所以这些层是跃升后领取奖励的层
    for id = jumpOrgId + 1, jumpToId - 1 do
        local grid = self.GridResList[id]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridItem, self.GridItem.parent)
            local xFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(id)
            grid = XUiGridRiftJumpRes.New(ui, xFightLayer, self)
            self.GridResList[id] = grid
        end
        grid.GameObject:SetActive(true)
    end
    self.GridItem.gameObject:SetActive(false)

    -- 标题
    self.TxtNum.text = CS.XTextManager.GetText("RiftJumpFromTo", jumpOrgId + 1, jumpToId - 1)
end

function XUiRiftJumpResults:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

return XUiRiftJumpResults