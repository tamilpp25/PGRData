-- 选择关卡界面规则解说面板
local XUiFingerGuessSSExplainPanel = XClass(nil, "XUiFingerGuessSSExplainPanel")
local CHINESE_NUMBER = {
    [1] = "one",
    [2] = "two",
    [3] = "three",
    [4] = "four",
    [5] = "five",
    [6] = "six",
    [7] = "seven",
    [8] = "eight",
    [9] = "nine",
    [10] = "ten",
    [11] = "eleven",
    [12] = "twelve"
    }
local INITIAL_TEXT = "Text initial complete."
--================
--构造函数
--================
function XUiFingerGuessSSExplainPanel:Ctor(gameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessSSExplainPanel:InitPanel()
    self:SetTxtTitle(0, 0)
    self.TxtDescription.text = INITIAL_TEXT
end
--================
--选择关卡时
--================
function XUiFingerGuessSSExplainPanel:OnStageSelected()
    self:SetTxtTitle(self.RootUi.StageSelected:GetRoundNum(), self.RootUi.StageSelected:GetWinScore())
    self.TxtDescription.text = self.RootUi.StageSelected:GetDescription()
end
--================
--设置规则Title
--================
function XUiFingerGuessSSExplainPanel:SetTxtTitle(total, winPoint)
    self.TxtTitle.text = CS.XTextManager.GetText("FingerGuessingRuleTitle", CHINESE_NUMBER[total] or total, CHINESE_NUMBER[winPoint] or winPoint)
end

return XUiFingerGuessSSExplainPanel