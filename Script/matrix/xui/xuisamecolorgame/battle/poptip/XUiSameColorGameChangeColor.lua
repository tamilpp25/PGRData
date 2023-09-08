local XUiSameColorGameChangeBallGrid = require("XUi/XUiSameColorGame/Battle/PopTip/XUiSameColorGameChangeBallGrid")

---@class XUiSameColorGameChangeColor:XLuaUi
local XUiSameColorGameChangeColor = XLuaUiManager.Register(XLuaUi, "UiSameColorGameChangeColor")
---@param role XSCRole
function XUiSameColorGameChangeColor:OnStart(role, title, conditionFun, closeCallBack, selectCallBack)
    self.Role = role
    self.Title = title
    self.ConditionFun = conditionFun
    self.CloseCallBack = closeCallBack
    self.SelectCallBack = selectCallBack
    self:SetButtonCallBack()
    ---@type XUiSameColorGameChangeBallGrid[]
    self.GridBallList = {}
    if not self.TxtWorldDesc then
        ---@type UnityEngine.UI.Text
        self.TxtWorldDesc = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/TxtWorldDesc", "Text")
    end
    self:UpdatePanel()
end

function XUiSameColorGameChangeColor:UpdatePanel()
    self.GridBall.gameObject:SetActiveEx(false)
    local ballList = self.Role:GetBalls()
    for _,ball in pairs(ballList) do
        if not self.ConditionFun or (self.ConditionFun and self.ConditionFun(ball)) then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridBall,self.PanelBallParent)
            obj.gameObject:SetActiveEx(true)
            ---@type XUiSameColorGameChangeBallGrid
            local grid = XUiSameColorGameChangeBallGrid.New(obj, self)
            grid:UpdateGrid(ball)
            table.insert(self.GridBallList, grid)
        end
    end
    self.TxtTitle.text = string.gsub(self.Title, "\\n", "\n")
    if self.TxtWorldDesc then
        local battleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
        local prefSkill = battleManager:GetPrepSkill()
        if prefSkill then
            self.TxtWorldDesc.text = XUiHelper.ReplaceTextNewLine(prefSkill:GetDesc(battleManager:IsTimeType()))
            self.TxtWorldDesc.gameObject:SetActiveEx(true)
        else
            self.TxtWorldDesc.gameObject:SetActiveEx(false)
        end
    end
end

function XUiSameColorGameChangeColor:SetButtonCallBack()
    self.BtnCancel.CallBack = function() self:OnClickBtnBack() end
    self.BtnClose.CallBack = function() self:OnClickBtnBack() end
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