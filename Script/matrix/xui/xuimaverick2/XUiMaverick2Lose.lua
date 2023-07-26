local XUiMaverick2Lose = XLuaUiManager.Register(XLuaUi, "UiMaverick2Lose")

function XUiMaverick2Lose:OnAwake()
    self:InitButtons()
end

function XUiMaverick2Lose:OnStart(restartCb)
    self.RestartCb = restartCb
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    self.StageId = beginData.StageId
    local stagCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtStageName.text = stagCfg.Name
end

function XUiMaverick2Lose:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_FINISH_LOSEUI_CLOSE)
end


function XUiMaverick2Lose:InitButtons()
    self.BtnLose.onClick:AddListener(function() self:Close() end)
    self.BtnRestart.CallBack = function() self:OnClickBtnRestart() end
end

function XUiMaverick2Lose:OnClickBtnRestart()
    self:Close()
    if self.RestartCb then
        self.RestartCb()
    end
end