local XUiFubenNierEnter = XLuaUiManager.Register(XLuaUi, "UiFubenNierEnter")
local XUiNierMainLineBanner = require("XUi/XUiNieR/XUiNierMainLineBanner")

function XUiFubenNierEnter:OnAwake()

    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:RegisterClickEvent(self.BtnTrial, self.OnBtnTrialClick)
    self.BtnTongBlue.CallBack = function() self:OnBtnTongBlueClick() end
    self.BtnTeam.CallBack = function() self:OnBtnTeamClick() end
    self.BtnPOD.CallBack = function() self:OnBtnPODClick() end
    self.BtnRenWu.CallBack = function() self:OnBtnRenWuClick() end
    self.BtnShop.CallBack = function() self:OnBtnShopClick() end
    self:BindHelpBtn(self.BtnHelp, "NierEnterHelp")
    self.TiaoxingmaFinsh.gameObject:SetActiveEx(false)
    self.EasterEggBg.gameObject:SetActiveEx(false)
    self.UiNierMainLineBanner = XUiNierMainLineBanner.New(self.UiFubenMainLineBanner, self)
end

function XUiFubenNierEnter:OnStart()   
    self:AddRedPointEvent()
    XEventManager.AddEventListener(XEventId.EVENT_NIER_ACTIVITY_END, self.OnActivityEnd, self)
    XEventManager.AddEventListener(CS.XEventId.EVENT_UI_ALLOWOPERATE, self.OnActivityEnd, self)
end

function XUiFubenNierEnter:OnEnable()
    if XDataCenter.NieRManager.GetIsActivityEnd() then
        XScheduleManager.ScheduleOnce(function()
            if not self.GameObject:Exist() then return end
            XDataCenter.NieRManager.OnActivityEnd()
        end, 1)
    end
    local unlockCount,count = XDataCenter.NieRManager.GetCharacterCount()
    local nierPOD = XDataCenter.NieRManager.GetNieRPODData()
    self.BtnTeam:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnTeamNameStr"))
    self.BtnPOD:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnPODNameStr"))  
    self.BtnRenWu:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnRenWuNameStr"))
    self.BtnShop:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnShopNameStr"))  
    
    if self.TextBtnTrial then
        self.TextBtnTrial.text = CS.XTextManager.GetText("NieRBtnRepeatNameStr")
    end
    
    self.BtnTeam:SetNameByGroup(1, string.format("%s/%s",unlockCount, count))
    self.BtnPOD:SetNameByGroup(1, string.format("Lv.%s",nierPOD:GetNieRPODLevel()))  
    
    local easterEggPassed = XDataCenter.NieRManager.CheckNieREasterEggStagePassed()
    local needShowDelData = false
    if easterEggPassed then
        self.TiaoxingmaFinsh.gameObject:SetActiveEx(true)
        self.BtnTongBlue.gameObject:SetActiveEx(false)
        self.BtnTeam.gameObject:SetActiveEx(true)
        self.BtnPOD.gameObject:SetActiveEx(true)
        self.BtnRenWu.gameObject:SetActiveEx(true)
        self.BtnShop.gameObject:SetActiveEx(true)
        self.BtnTrial.gameObject:SetActiveEx(true)
        self.EasterEggBg.gameObject:SetActiveEx(false)
    else
        self.TiaoxingmaFinsh.gameObject:SetActiveEx(false)
        needShowDelData = XDataCenter.NieRManager.GetNieREasterEggStageShow()
        if needShowDelData then
            self.BtnTeam.gameObject:SetActiveEx(false)
            self.BtnPOD.gameObject:SetActiveEx(false)
            self.BtnRenWu.gameObject:SetActiveEx(false)
            self.BtnShop.gameObject:SetActiveEx(false)
            self.BtnTrial.gameObject:SetActiveEx(false)
            self.BtnTongBlue.gameObject:SetActiveEx(true)
            self.EasterEggBg.gameObject:SetActiveEx(true)
        else
            self.BtnTongBlue.gameObject:SetActiveEx(false)
            self.BtnTeam.gameObject:SetActiveEx(true)
            self.BtnPOD.gameObject:SetActiveEx(true)
            self.BtnRenWu.gameObject:SetActiveEx(true)
            self.BtnShop.gameObject:SetActiveEx(true)
            self.BtnTrial.gameObject:SetActiveEx(true)
            self.EasterEggBg.gameObject:SetActiveEx(false)
        end 
    end
    self.UiNierMainLineBanner:UpdateData(easterEggPassed, needShowDelData)
end

function XUiFubenNierEnter:OnDisable()
end

function XUiFubenNierEnter:OnDestroy()
    self.UiNierMainLineBanner:StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_NIER_ACTIVITY_END, self.OnActivityEnd, self)
    XEventManager.RemoveEventListener(CS.XEventId.EVENT_UI_ALLOWOPERATE, self.OnActivityEnd, self)
end

--添加点事件
function XUiFubenNierEnter:AddRedPointEvent()
    XRedPointManager.AddRedPointEvent(self.BtnRenWu, self.RefreshTaskRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_TASK_RED }, -1)
    XRedPointManager.AddRedPointEvent(self.BtnTeam, self.RefreshTeamRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED }, {CharacterId = -1, IsInfor = true, IsTeach = true})
    XRedPointManager.AddRedPointEvent(self.BtnTrial, self.RefreshRepeatRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_REPEAT_RED })
    XRedPointManager.AddRedPointEvent(self.BtnPOD, self.RefreshPODRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_POD_RED })
    
end

function XUiFubenNierEnter:OnActivityEnd()
    if not XDataCenter.NieRManager.GetIsActivityEnd() then return end
    XDataCenter.NieRManager.OnActivityEnd()
end

--任务按钮红点
function XUiFubenNierEnter:RefreshTaskRedDot(count)
    self.BtnRenWuRed.gameObject:SetActiveEx(count >= 0)
end

--尼尔角色按钮红点
function XUiFubenNierEnter:RefreshTeamRedDot(count)
    self.BtnTeamRed.gameObject:SetActiveEx(count >= 0)
end

--复刷关按钮红点
function XUiFubenNierEnter:RefreshRepeatRedDot(count)
    self.BtnTrialRed.gameObject:SetActiveEx(count >= 0)
end

--辅助机按钮红点
function XUiFubenNierEnter:RefreshPODRedDot(count)
    self.BtnPODRed.gameObject:SetActiveEx(count >= 0)
end

function XUiFubenNierEnter:OnBtnBackClick()
    self:Close()
end

function XUiFubenNierEnter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenNierEnter:OnBtnTrialClick()
    XLuaUiManager.Open("UiFubenNierRepeat")
end

function XUiFubenNierEnter:OnBtnTongBlueClick()
    XDataCenter.NieRManager.OpenNieREasterEggCom()
end

function XUiFubenNierEnter:OnBtnTeamClick()
    XLuaUiManager.Open("UiNierCharacterSel")
end

function XUiFubenNierEnter:OnBtnPODClick()
    XLuaUiManager.Open("UiFuBenNierWork")
end

function XUiFubenNierEnter:OnBtnRenWuClick()
    XLuaUiManager.Open("UiNierTask")
end

function XUiFubenNierEnter:OnBtnShopClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
    or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        XLuaUiManager.Open("UiNierShop")
    end
end