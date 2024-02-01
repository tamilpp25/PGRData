
---@class XUiBlackRockChessSetUp : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessSetUp = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessSetUp")

function XUiBlackRockChessSetUp:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBlackRockChessSetUp:OnStart()
end

function XUiBlackRockChessSetUp:InitUi()
end

function XUiBlackRockChessSetUp:InitCb()
    
    self.BtnContinue.CallBack = function() 
        self:OnBtnContinueClick()
    end
    
    self.BtnSetUp.CallBack = function() 
        self:OnBtnSetUpClick()
    end
    
    self.BtnRePlay.CallBack = function() 
        self:OnBtnRePlayClick()
    end
end

function XUiBlackRockChessSetUp:InitView()
end

function XUiBlackRockChessSetUp:OnBtnContinueClick()
    self:Close()
end

function XUiBlackRockChessSetUp:OnBtnSetUpClick()
    --系统设置
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Setting) then
        return
    end
    XLuaUiManager.PopThenOpen("UiSet", false, 4)
end

function XUiBlackRockChessSetUp:OnBtnRePlayClick()
    local content = self._Control:GetSecondaryConfirmationText(2)
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, nil, nil, function()
        --将战斗界面隐藏
        XLuaUiManager.Open("UiBiancaTheatreBlack")
        self._Control:RequestReset(function()
            XLuaUiManager.Remove("UiBiancaTheatreBlack")
            self:Close()
        end)
    end)
end