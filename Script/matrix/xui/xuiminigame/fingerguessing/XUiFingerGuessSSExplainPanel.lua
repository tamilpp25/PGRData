-- 选择关卡界面规则解说面板
local XUiFingerGuessSSExplainPanel = XClass(nil, "XUiFingerGuessSSExplainPanel")
local CHINESE_NUMBER = {
    [1] = "一",
    [2] = "两",
    [3] = "三",
    [4] = "四",
    [5] = "五",
    [6] = "六",
    [7] = "七",
    [8] = "八",
    [9] = "九",
    [10] = "十",
    [11] = "十一",
    [12] = "十二"
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