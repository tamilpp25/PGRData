---@class XUiSameColorGameChangeBallGrid
local XUiSameColorGameChangeBallGrid = XClass(nil, "XUiSameColorGameChangeBallGrid")
---@param base XUiSameColorGameChangeColor
function XUiSameColorGameChangeBallGrid:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiSameColorGameChangeBallGrid:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiSameColorGameChangeBallGrid:OnBtnClick()
    local ballData = {
        ItemId = self.Ball:GetBallId(),
        PositionX = 0,
        PositionY = 0
    }
    self.Base:SelectBall(ballData)
end

function XUiSameColorGameChangeBallGrid:UpdateGrid(ball)
    self.Ball = ball
    XUiHelper.GetUiSetIcon(self.Bg, ball:GetBg())
    self.SkillIcon:SetRawImage(ball:GetIcon())
end

return XUiSameColorGameChangeBallGrid