-- 猜拳小游戏得分面板控件
local XUiFingerGuessScorePanel = XClass(nil, "XUiFingerGuessScorePanel")
local INITIAL_SCORE = 0
local SCORE_TYPE = {
        Hero = "Hero",
        Enemy = "Enemy",
    }
--================
--构造函数
--================
function XUiFingerGuessScorePanel:Ctor(uiGameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, uiGameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessScorePanel:InitPanel()
    self.TxtHeroName.text = self.RootUi.GameController:GetHeroName()
    self.TxtEnemyName.text = self.RootUi.Stage:GetStageName()
    self.ImgHeroIcon:SetSprite(self.RootUi.GameController:GetPlayerPortraits())
    self.ImgEnemyIcon:SetSprite(self.RootUi.Stage:GetRobotPortraits())
    if self.TxtHeroScoreAnima then self.TxtHeroScoreAnima.gameObject:SetActiveEx(false) end
    if self.TxtEnemyScoreAnima then self.TxtEnemyScoreAnima.gameObject:SetActiveEx(false) end
    self:RefreshScore()
end
--================
--关卡更新时
--================
function XUiFingerGuessScorePanel:OnStageRefresh()
    self:RefreshScore(true)
end
--================
--刷新得分
--================
function XUiFingerGuessScorePanel:RefreshScore(needAnima)
    self:SetScore(self.RootUi.Stage:GetHeroScore(), SCORE_TYPE.Hero, needAnima)
    self:SetScore(self.RootUi.Stage:GetEnemyScore(), SCORE_TYPE.Enemy, needAnima)
end
--================
--设置面板
--================
function XUiFingerGuessScorePanel:SetScore(score, setType, needAnima)
    if self["Pre" .. tostring(setType) .. "Score"] then
        if self["Pre" .. tostring(setType) .. "Score"] < score then
            if setType == SCORE_TYPE.Hero then
                local obj = self["Txt" .. tostring(setType) .. "ScoreAnima"]
                if obj then
                    obj.gameObject:SetActiveEx(true)
                    self.RootUi:PlayAnimation("TxtLeftEnable")
                    XScheduleManager.ScheduleOnce(function()
                        obj.gameObject:SetActiveEx(false)  
                    end, 500)
                end
            elseif setType == SCORE_TYPE.Enemy then
                local obj = self["Txt" .. tostring(setType) .. "ScoreAnima"]
                if obj then
                    obj.gameObject:SetActiveEx(true)
                    self.RootUi:PlayAnimation("TxtRightEnable")
                    XScheduleManager.ScheduleOnce(function()
                            obj.gameObject:SetActiveEx(false)
                        end, 500)
                end
            end
        end
    end
    local name = "Txt" .. tostring(setType) .. "Score"
    local component = self[name]
    if component then
        component.text = CS.XTextManager.GetText("FingerGuessingScoreStr", score)
    end
    self["Pre" .. tostring(setType) .. "Score"] = score
end

return XUiFingerGuessScorePanel