---@class XUiTemple2CheckBoardRole : XUiNode
---@field _Control XTemple2Control
local XUiTemple2CheckBoardRole = XClass(XUiNode, "XUiTemple2CheckBoardRole")

function XUiTemple2CheckBoardRole:OnStart()
    if self.Bubble then
        self.Bubble.gameObject:SetActive(false)
    end
end

--function XUiTemple2CheckBoardRole:OnDisable()
--if self._Timer then
--    XScheduleManager.UnSchedule(self._Timer)
--    self._Timer = nil
--end
--end

function XUiTemple2CheckBoardRole:SetIcon(icon)
    if self.Image.SetSprite then
        self.Image:SetSprite(icon)
    end
end

function XUiTemple2CheckBoardRole:SetEmoj(image)
    if image then
        self.ImageBubble:SetSprite(image)
        if self.Bubble then
            self.Bubble.gameObject:SetActive(true)
        end
    else
        if self.Bubble then
            self.Bubble.gameObject:SetActive(false)
        end
    end

    --if self._Timer then
    --    XScheduleManager.UnSchedule(self._Timer)
    --end
    --self._Timer = XScheduleManager.ScheduleOnce(function()
    --    self.Bubble.gameObject:SetActive(false)
    --end)
end

return XUiTemple2CheckBoardRole