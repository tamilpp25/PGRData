local XUiMedalUnlock = XLuaUiManager.Register(XLuaUi, "UiMedalUnlock")
local CLOSE_TIME = 2
local IsInClose
function XUiMedalUnlock:OnStart()

    if XPlayer.NewMedalInfo then
        self.TxtMedalName.text = XMedalConfigs.GetMeadalConfigById(XPlayer.NewMedalInfo.Id).Name
        self.TxtUid.text = XPlayer.Id
        self.TxtName.text = XPlayer.Name
        self.BtnSkip.CallBack = function()
            self:OnBtnSkip()
        end
        self:AddBtnUnlockCallBack()
        IsInClose = false
    else
        local function action()
            self:OnOpenMedalDetail()
        end
        XScheduleManager.ScheduleOnce(action, 0)
    end
end

function XUiMedalUnlock:OnDestroy()

end

function XUiMedalUnlock:AddBtnUnlockCallBack()
    self.BtnUnlock.CallBack = function()
        self:OnBtnUnlock()
    end
end

function XUiMedalUnlock:OnBtnSkip()
    self:OnOpenMedalDetail()
end

function XUiMedalUnlock:OnBtnUnlock()
    if not IsInClose then
        self:AddCloseTimer()
        self:PlayAnimation("AnimEnableTwo")
    end
end

function XUiMedalUnlock:AddCloseTimer()
    IsInClose = true
    local time = 0
    local function action()
        time = time + 1
        if time == CLOSE_TIME then
            self:OnOpenMedalDetail()
        end
    end
    XScheduleManager.Schedule(action, XScheduleManager.SECOND, CLOSE_TIME, 0)
end

function XUiMedalUnlock:OnOpenMedalDetail()
    local info = XPlayer.NewMedalInfo and XDataCenter.MedalManager.GetMedalById(XPlayer.NewMedalInfo.Id) or nil
    if info then
        XLuaUiManager.Open("UiMeadalDetail",info , XDataCenter.MedalManager.InType.Normal)
        XLuaUiManager.Remove( "UiMedalUnlock")
    else
        XLuaUiManager.Remove( "UiMedalUnlock")
    end
end