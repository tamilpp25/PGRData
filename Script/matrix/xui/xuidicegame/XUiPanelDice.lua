---@class XUiPanelDice
---@field public ImgDiceAnimEnable UnityEngine.Transform
---@field public PanelResult UnityEngine.Transform
local XUiPanelDice = XClass(nil, "XUiPanelDice")

local tailDiceFrameNames = {
    "ImgDiceAn103",
    "ImgDiceAn102",
    "ImgDiceAn100",
}

function XUiPanelDice:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)
end

function XUiPanelDice:UpdateDiceView(playAnimEnable, animFinishCb)
    local manager = XDataCenter.DiceGameManager
    local points = manager.GetThrowResult()

    for i = 1, manager.GetDiceCount() do
        local imgPath = XDiceGameConfigs.GetDiceGamePointById(points[i]).ImgPath
        self["ImgDice" .. i]:SetRawImage(imgPath)
    end

    if playAnimEnable then
        self.Root:PlayAnimation("PanelResultEnable", animFinishCb)
    end
end

function XUiPanelDice:PlayThrowAnimation(finishCb, beginCb)
    local manager = XDataCenter.DiceGameManager
    local points = manager.GetThrowResult()
   	
	for i = 1, manager.GetDiceCount() do
        --SetRawImage requires gameObject is active
		self:SetAnimSubNodeActive(self["DiceAnimation" .. i], true)
		self:SetThrowAnimTailFrames(self["DiceAnimation" .. i], points[i])
	end
	
	XScheduleManager.ScheduleOnce(function()
        for i = 1, manager.GetDiceCount() do
            self:SetAnimSubNodeActive(self["DiceAnimation" .. i], false)
        end
        self:SetDiceAnimNodeActive(true)
        self.ImgDiceAnimEnable:PlayTimelineAnimation(function()
            self:SetDiceAnimNodeActive(false)
            if finishCb then finishCb() end
        end, beginCb)
	end, 1) --execute in next frame to make sure XLoadRawImage has initialized completely.
end

---@param animationNode UiObject
function XUiPanelDice:SetAnimSubNodeActive(animationNode, active)
    for i = 1, #tailDiceFrameNames do
		animationNode:GetObject(tailDiceFrameNames[i]).gameObject:SetActiveEx(active)
    end
    animationNode:GetComponent("CanvasGroup").alpha = active and 0 or 1.0
end

function XUiPanelDice:SetThrowAnimTailFrames(animationNode, point)
	local tailFrames = XDiceGameConfigs.GetDiceAnimationById(point).TailFrames
	for i = 1, #tailDiceFrameNames do
		animationNode:GetObject(tailDiceFrameNames[i]):SetRawImage(tailFrames[i], nil, false)
	end
end

function XUiPanelDice:SetResultViewActive(active)
    self.PanelResult.gameObject:SetActiveEx(active)
end

function XUiPanelDice:SetDiceAnimNodeActive(value)
    for i = 1, XDataCenter.DiceGameManager.GetDiceCount() do
        local animNode = self["DiceAnimation" .. i]
        animNode.gameObject:SetActiveEx(value)
    end
end

return XUiPanelDice