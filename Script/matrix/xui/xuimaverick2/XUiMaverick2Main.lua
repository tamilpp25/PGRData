-- 异构阵线2.0主界面
local XUiMaverick2Main = XLuaUiManager.Register(XLuaUi, "UiMaverick2Main")
local CSXAudioManager = CS.XAudioManager
local CSXGoInputHandler = CS.XGoInputHandler

function XUiMaverick2Main:OnAwake()
    self.Timer = nil -- 倒计时定时器

    self:InitUiObject()
    self:SetButtonCallBack()
end

function XUiMaverick2Main:OnStart()

end

function XUiMaverick2Main:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()

    self:RefreshChapterBgAndBgm()
end

function XUiMaverick2Main:OnDisable()
    self:StopTimer()
end

function XUiMaverick2Main:OnDestroy()

end

function XUiMaverick2Main:InitUiObject()
    self.BtnEnterArrowLeft1 = self.BtnEnter1.transform:Find("Normal/Bg01")
    self.BtnEnterArrowRight1 = self.BtnEnter1.transform:Find("Normal/Bg02")
    self.BtnEnterArrowLeft2 = self.BtnEnter2.transform:Find("Normal/Bg01")
    self.BtnEnterArrowRight2 = self.BtnEnter2.transform:Find("Normal/Bg02")
    self.BtnRoleGoInput = self.BtnRole.gameObject:AddComponent(typeof(CSXGoInputHandler))
    self.BtnTaskGoInput = self.BtnTask.gameObject:AddComponent(typeof(CSXGoInputHandler))
    self.BtnRankGoInput = self.BtnRank.gameObject:AddComponent(typeof(CSXGoInputHandler))
end

function XUiMaverick2Main:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter1, self.OnBtnEnterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter2, self.OnBtnEnterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRole, function() XLuaUiManager.Open("UiMaverick2Character")  end)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, function() XLuaUiManager.Open("UiMaverick2Task") end)
    XUiHelper.RegisterClickEvent(self, self.BtnRank, function() XDataCenter.Maverick2Manager.OpenUiRank() end)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, function() XDataCenter.Maverick2Manager.OpenUiShop() end)
    self:BindHelpBtn(self.BtnHelp, XMaverick2Configs.GetHelpKey())

    self.BtnRoleGoInput:AddPointerDownListener(function(eventData) self:OnBtnDown() end)
    self.BtnRoleGoInput:AddPointerUpListener(function(eventData) self:OnBtnUpOrExit() end)
    self.BtnRoleGoInput:AddPointerExitListener(function(eventData) self:OnBtnUpOrExit() end)

    self.BtnTaskGoInput:AddPointerDownListener(function(eventData) self:OnBtnDown() end)
    self.BtnTaskGoInput:AddPointerUpListener(function(eventData) self:OnBtnUpOrExit() end)
    self.BtnTaskGoInput:AddPointerExitListener(function(eventData) self:OnBtnUpOrExit() end)

    self.BtnRankGoInput:AddPointerDownListener(function(eventData) self:OnBtnDown() end)
    self.BtnRankGoInput:AddPointerUpListener(function(eventData) self:OnBtnUpOrExit() end)
    self.BtnRankGoInput:AddPointerExitListener(function(eventData) self:OnBtnUpOrExit() end)
end


function XUiMaverick2Main:OnBtnEnterClick()
    local key = self:GetIsEnteredKey()
    XSaveTool.SaveData(key, true)

    local chapterId = XDataCenter.Maverick2Manager.GetLastSelChapterId()
    XDataCenter.Maverick2Manager.PlayChapterMovie(chapterId, function()
        XLuaUiManager.Open("UiMaverick2Explore")
    end)
end

function XUiMaverick2Main:OnBtnDown()
    self.BtnEnterArrowLeft1.gameObject:SetActiveEx(false)
    self.BtnEnterArrowRight1.gameObject:SetActiveEx(false)
    self.BtnEnterArrowLeft2.gameObject:SetActiveEx(false)
    self.BtnEnterArrowRight2.gameObject:SetActiveEx(false)
end

function XUiMaverick2Main:OnBtnUpOrExit()
    self.BtnEnterArrowLeft1.gameObject:SetActiveEx(true)
    self.BtnEnterArrowRight1.gameObject:SetActiveEx(true)
    self.BtnEnterArrowLeft2.gameObject:SetActiveEx(true)
    self.BtnEnterArrowRight2.gameObject:SetActiveEx(true)
end

function XUiMaverick2Main:Refresh()
    -- 活动倒计时
    self:StartTimer()

    -- 刷新按钮
    self:RefreshBtnEnter()
    self:RefreshBtnRole()
    self:RefreshBtnTask()
    self:RefreshBtnShop()
end

---------------------------------------- 倒计时 begin ----------------------------------------

function XUiMaverick2Main:StartTimer()
    if self.Timer then return end

    self:RefreshActivityTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiMaverick2Main:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMaverick2Main:RefreshActivityTime()
    local endTime = XDataCenter.Maverick2Manager.GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    if nowTime >= endTime then
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end
end
---------------------------------------- 倒计时 end ----------------------------------------

-- 刷新进入按钮
function XUiMaverick2Main:RefreshBtnEnter()
    local key = self:GetIsEnteredKey()
    local isEnter = XSaveTool.GetData(key) == true
    self.BtnEnter1.gameObject:SetActiveEx(not isEnter)
    self.BtnEnter2.gameObject:SetActiveEx(isEnter)
end

-- 刷新角色按钮
function XUiMaverick2Main:RefreshBtnRole()
    local have = XDataCenter.Maverick2Manager.HaveCharacterData()
    self.BtnRole.gameObject:SetActiveEx(have)
end

-- 刷新任务按钮
function XUiMaverick2Main:RefreshBtnTask()
    local isRed = XDataCenter.Maverick2Manager.CheckTaskCanReward()
    self.BtnTask:ShowReddot(isRed)
end

-- 刷新商店按钮
function XUiMaverick2Main:RefreshBtnShop()
    local isRed = XDataCenter.Maverick2Manager.IsShowShopRed()
    self.BtnShop:ShowReddot(isRed)
end

function XUiMaverick2Main:GetIsEnteredKey()
    return XDataCenter.Maverick2Manager.GetActivitySaveKey() .. "XUiMaverick2Main_IsEntered"
end

-- 刷新背景图和bgm
function XUiMaverick2Main:RefreshChapterBgAndBgm()
    XDataCenter.Maverick2Manager.PlayBGM()

    local chapterId = XDataCenter.Maverick2Manager.GetLastUnlockChapterId()
    local chapterCfg = XMaverick2Configs.GetMaverick2Chapter(chapterId, true)
    self.RawBg:SetRawImage(chapterCfg.Background)

    -- 刷新特效
    local showEffect = chapterCfg.BackgroundEffect and chapterCfg.BackgroundEffect ~= ""
    self.Effect.gameObject:SetActiveEx(showEffect)
    if showEffect then
        self.Effect:LoadUiEffect(chapterCfg.BackgroundEffect)
    end
end
