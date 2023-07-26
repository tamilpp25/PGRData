-- 猜拳小游戏PK面板控件
local XUiFingerGuessPKPanel = XClass(nil, "XUiFingerGuessPKPanel")
local RESULT_INFO = {
        [0] = {
            Text = "FingerGuessingResultWin",
            Image = "WinAirBubble",
            Bg = "WinAirBubbleBg",
            GuessBg = "WinGuessBg"
        },
        [1] = {
            Text = "FingerGuessingResultDraw",
            GuessBg = "WinGuessBg"
        },
        [2] = {
            Text = "FingerGuessingResultLose",
            Image= "LoseAirBubble",
            Bg = "LoseAirBubbleBg",
            GuessBg = "LoseGuessBg"
        },
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
    self:SetResultView(RESULT_TYPE.Draw, SHOW_TYPE.Hero)
    self:SetResultView(RESULT_TYPE.Draw, SHOW_TYPE.Enemy)
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

function XUiFingerGuessPKPanel:SetResultView(roundResult, showType)
    local info = RESULT_INFO[roundResult]
    local isDraw = roundResult == RESULT_TYPE.Draw
    local panelName = string.format("Panel%sResult", showType)
    if self[panelName] then
        self[panelName].gameObject:SetActiveEx(not isDraw)
    end
    -- 猜拳背景
    local guessBgName = string.format("RImg%sBg", showType)
    if self[guessBgName] then
        local icon = XFingerGuessingConfig.GetClientConfigValueByKey(info.GuessBg)
        self[guessBgName]:SetRawImage(icon)
    end
    if isDraw then
        return
    end
    -- 文本
    local textName = string.format("Txt%sResult", showType)
    if self[textName] then
        self[textName].text = XUiHelper.GetText(info.Text)
    end
    -- 图片
    local imgName = string.format("Img%sResult", showType)
    if self[imgName] then
        local icon = XFingerGuessingConfig.GetClientConfigValueByKey(info.Image)
        self[imgName]:SetSprite(icon)
    end
    -- 背景
    local bgName = string.format("RImg%sResultBg", showType)
    if self[bgName] then
        local icon = XFingerGuessingConfig.GetClientConfigValueByKey(info.Bg)
        self[bgName]:SetRawImage(icon)
    end
end

function XUiFingerGuessPKPanel:SetTurnText(turn)
    if self.RImgRound then
        local icon = XFingerGuessingConfig.GetClientConfigValueByKey(string.format("Round0%s", turn))
        self.RImgRound:SetRawImage(icon)
    end
end

function XUiFingerGuessPKPanel:ShowPanel(fingerId, showRound, enemyFingerId, roundResult, isEnd, onFinishCallBack)
    self.GameObject:SetActiveEx(true)
    self.RootUi:PlayAnimation("PanelPKEnable")
    self:SetMask()  
    self:SetTurnText(showRound)
    if roundResult == RESULT_TYPE.Win then
        self:SetResultView(RESULT_TYPE.Win, SHOW_TYPE.Hero)
        self:SetResultView(RESULT_TYPE.Lose, SHOW_TYPE.Enemy)
        self:PlayFinger(fingerId, enemyFingerId, roundResult)
    elseif roundResult == RESULT_TYPE.Draw then
        self:SetResultView(RESULT_TYPE.Draw, SHOW_TYPE.Hero)
        self:SetResultView(RESULT_TYPE.Draw, SHOW_TYPE.Enemy)
        self:PlayFinger(fingerId, enemyFingerId, roundResult)
    else
        self:SetResultView(RESULT_TYPE.Lose, SHOW_TYPE.Hero)
        self:SetResultView(RESULT_TYPE.Win, SHOW_TYPE.Enemy)
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
                    --if isEnd then
                        if self.FinishCallBack then self.FinishCallBack() end
                        self:HideMask()
                    --else
                    --    XScheduleManager.ScheduleOnce(function()
                    --        if XTool.UObjIsNil(self.Transform) then
                    --            return
                    --        end
                    --        if self.FinishCallBack then self.FinishCallBack() end
                    --            self:HideMask()
                    --        end, 500)
                    --end
                    end, 1250)
            end, 0)
    end
    XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            self.FinishCallBack = onFinishCallBack
            --self.RootUi:PlayAnimation("WinFailEnable")
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