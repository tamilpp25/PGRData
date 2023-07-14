local XUiSameColorGameChangeColor = XLuaUiManager.Register(XLuaUi, "UiSameColorGameChangeColor")
local XUiGridColorChangeBall = require("XUi/XUiSameColorGame/Battle/XUiGridColorChangeBall")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiSameColorGameChangeColor:OnStart(role, title, conditionFun, closeCallBack, selectCallBack)
    self.Role = role
    self.Title = title
    self.ConditionFun = conditionFun
    self.CloseCallBack = closeCallBack
    self.SelectCallBack = selectCallBack
    self:SetButtonCallBack()
    self.GridBallList = {}
    self:UpdatePanel()
end

function XUiSameColorGameChangeColor:UpdatePanel()
    self.GridBall.gameObject:SetActiveEx(false)
    local ballList = self.Role:GetBalls()
    for _,ball in pairs(ballList) do
        if not self.ConditionFun or (self.ConditionFun and self.ConditionFun(ball)) then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridBall,self.PanelBallParent)
            obj.gameObject:SetActiveEx(true)
            local grid = XUiGridColorChangeBall.New(obj, self)
            grid:UpdateGrid(ball)
            table.insert(self.GridBallList, grid)
        end
    end
    self.TxtTitle.text = string.gsub(self.Title, "\\n", "\n")
end

function XUiSameColorGameChangeColor:SetButtonCallBack()
    self.BtnCancel.CallBack = function() self:OnClickBtnBack() end
end

function XUiSameColorGameChangeColor:OnClickBtnBack()
    self:Close()
    if self.CloseCallBack then
        self.CloseCallBack()
    end
end

function XUiSameColorGameChangeColor:SelectBall(targetBallData)
    if self.SelectCallBack then
        self.SelectCallBack(targetBallData, function ()
                self:Close()
        end) 
    end
end