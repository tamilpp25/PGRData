-- 猜拳小游戏PK面板控件
local XUiFingerGuessPKPanel = XClass(nil, "XUiFingerGuessPKPanel")
local RESULT_TEXT = {
        WIN = "FingerGuessingResultWin",
        LOSE = "FingerGuessingResultLose",
        DRAW = "FingerGuessingResultDraw"
    }
local SHOW_TYPE = {
        Hero = "Hero",
        Enemy = "Enemy",
    }
local RESULT_TYPE
--================
--构造函数
--================
function XUiFingerGuessPKPanel:Ctor(uiGameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, uiGameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessPKPanel:InitPanel()
    self.ObjNextRound.gameObject:SetActiveEx(false)
    if not RESULT_TYPE then RESULT_TYPE = XDataCenter.FingerGuessingManager.DUEL_RESULT end
    self:SetResult(RESULT_TEXT.DRAW, SHOW_TYPE.Hero)
    self:SetResult(RESULT_TEXT.DRAW, SHOW_TYPE.Enemy)
end
--================
--出拳
--@param heroFingerId:我方出拳ID
--================
function XUiFingerGuessPKPanel:PlayFinger(heroFingerId, enemyFingerId, resultType)  
    local heroIcon
    local enemyIcon
    if resultType == RESULT_TYPE.Win then
        local fingerConfig = XFingerGuessingConfig.GetFingerConfigById(heroFingerId)
        heroIcon = fingerConfig.Icon
        enemyIcon = CS.XGame.ClientConfig:GetString("FingerGuessingLoseIcon" .. enemyFingerId)
    elseif resultType == RESULT_TYPE.Draw then
        local heroFingerConfig = XFingerGuessingConfig.GetFingerConfigById(heroFingerId)
        heroIcon = heroFingerConfig.Icon
        local enemyFingerConfig = XFingerGuessingConfig.GetFingerConfigById(enemyFingerId)
        enemyIcon = enemyFingerConfig.Icon
    else
        heroIcon = CS.XGame.ClientConfig:GetString("FingerGuessingLoseIcon" .. heroFingerId)
        local fingerConfig = XFingerGuessingConfig.GetFingerConfigById(enemyFingerId)
        enemyIcon = fingerConfig.Icon
    end
    self.ImgHeroFinger:SetSprite(heroIcon)
    self.ImgEnemyFinger:SetSprite(enemyIcon)
end
--================
--设置结果文本
--================
function XUiFingerGuessPKPanel:SetResult(resultType, showType)
    local name = "Txt" .. tostring(showType) .. "Result"
    local component = self[name]
    if component then
        component.text = CS.XTextManager.GetText(resultType)
    end
end

function XUiFingerGuessPKPanel:SetTurnText(turn)
    self.TxtTurnText.text = CS.XTextManager.GetText("FingerGuessingRoundStr", string.format("%02d", turn))
end

function XUiFingerGuessPKPanel:ShowPanel(fingerId, showRound, enemyFingerId, roundResult, isEnd, onFinishCallBack)
    self.GameObject:SetActiveEx(true)
    self.RootUi:PlayAnimation("PanelPKEnable")
    self:SetMask()  
    self:SetTurnText(showRound)
    if roundResult == RESULT_TYPE.Win then
        self:SetResult(RESULT_TEXT.WIN, SHOW_TYPE.Hero)
        self:SetResult(RESULT_TEXT.LOSE, SHOW_TYPE.Enemy)
        self:PlayFinger(fingerId, enemyFingerId, roundResult)
    elseif roundResult == RESULT_TYPE.Draw then
        self:SetResult(RESULT_TEXT.DRAW, SHOW_TYPE.Hero)
        self:SetResult(RESULT_TEXT.DRAW, SHOW_TYPE.Enemy)
        self:PlayFinger(fingerId, enemyFingerId, roundResult)
    else
        self:SetResult(RESULT_TEXT.LOSE, SHOW_TYPE.Hero)
        self:SetResult(RESULT_TEXT.WIN, SHOW_TYPE.Enemy)
        self:PlayFinger(fingerId, enemyFingerId, roundResult)
    end
    local nextRoundFunc = function()
        XScheduleManager.ScheduleOnce(function()
                if XTool.UObjIsNil(self.Transform) then
                    return
                end
                if not isEnd then
                    self.ObjNextRound.gameObject:SetActiveEx(true)
                    self.RootUi:PlayAnimation("NextEnable")
                end
                XScheduleManager.ScheduleOnce(function()
                    if XTool.UObjIsNil(self.Transform) then
                        return
                    end
                    self.GameObject:SetActiveEx(false)
                    self.ObjNextRound.gameObject:SetActiveEx(false)
                    self.TxtHeroResult.gameObject:SetActiveEx(false)
                    self.TxtEnemyResult.gameObject:SetActiveEx(false)
                    if isEnd then
                        if self.FinishCallBack then self.FinishCallBack() end
                        self:HideMask()
                    else
                        XScheduleManager.ScheduleOnce(function()
                            if XTool.UObjIsNil(self.Transform) then
                                return
                            end
                            if self.FinishCallBack then self.FinishCallBack() end
                                self:HideMask()
                            end, 500)
                    end
                    end, 1250)
            end, 0)
    end
    XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            self.TxtHeroResult.gameObject:SetActiveEx(true)
            self.TxtEnemyResult.gameObject:SetActiveEx(true)
            self.FinishCallBack = onFinishCallBack
            self.RootUi:PlayAnimation("WinFailEnable")
            XScheduleManager.ScheduleOnce(function()
                    if XTool.UObjIsNil(self.Transform) then
                        return
                    end
                    nextRoundFunc()
            end, 500)
        end,
        500
    )
end

function XUiFingerGuessPKPanel:SetMask()
    if self.HaveMask then return end
    self.HaveMask = true
    XLuaUiManager.SetMask(true)
end

function XUiFingerGuessPKPanel:HideMask()
    if not self.HaveMask then return end
    XLuaUiManager.SetMask(false)
    self.HaveMask = false
end

return XUiFingerGuessPKPanel