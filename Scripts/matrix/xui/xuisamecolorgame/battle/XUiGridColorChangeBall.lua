local XUiGridColorChangeBall = XClass(nil, "XUiGridColorChangeBall")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridColorChangeBall:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    
end

function XUiGridColorChangeBall:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridColorChangeBall:OnBtnClick()
    local ballData = {
        ItemId = self.Ball:GetBallId(),
        PositionX = 0,
        PositionY = 0
    }
    self.Base:SelectBall(ballData)
end

function XUiGridColorChangeBall:UpdateGrid(ball)
    self.Ball = ball
    self.Bg:SetRawImage(ball:GetBg())
    self.SkillIcon:SetRawImage(ball:GetIcon())
end

return XUiGridColorChangeBall