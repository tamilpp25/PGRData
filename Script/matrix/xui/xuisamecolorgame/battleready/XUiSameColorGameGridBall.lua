---@class XUiSameColorGameGridBall
local XUiSameColorGameGridBall = XClass(nil, "XUiSameColorGameGridBall")

function XUiSameColorGameGridBall:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param ball XSCBall
function XUiSameColorGameGridBall:SetData(ball)
    self.RImgIcon:SetRawImage(ball:GetIcon())
    self.RImgBg:SetRawImage(ball:GetBg())
    self.TxtFactor.text = math.floor(ball:GetScore()) .. "%"
end

return XUiSameColorGameGridBall