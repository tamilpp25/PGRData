local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdActivityResult = XLuaUiManager.Register(XLuaUi, "UiStrongholdActivityResult")

function XUiStrongholdActivityResult:OnAwake()
    self:AutoAddListener()
end

function XUiStrongholdActivityResult:OnStart()
    self:InitView()
end

function XUiStrongholdActivityResult:InitView()
    local finishCount = XDataCenter.StrongholdManager.GetLastFinishCount()
    local totalCount = XDataCenter.StrongholdManager.GetAllGroupCount()
    self.TxtEndProgress.text = finishCount .. "/" .. totalCount

    local minerCount = XDataCenter.StrongholdManager.GetLastMinerCount()
    self.TxtEndPeople.text = minerCount

    local totalMineral = XDataCenter.StrongholdManager.GetLastMineralCount()
    self.TxtEndMineral.text = totalMineral

    local assistNum = XDataCenter.StrongholdManager.GetLastAssistCount()
    local assistRewardValue = XDataCenter.StrongholdManager.GetLastAssistRewardValue()
    self.TxtEndAssist.text = CsXTextManagerGetText("StrongholdRecordAssist", assistNum, assistRewardValue)
end

function XUiStrongholdActivityResult:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
end