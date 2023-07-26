
local XUiFubenNierLineChapter = XLuaUiManager.Register(XLuaUi, "UiFubenNierLineChapter")
local PanelMainlineChapter = require("XUi/XUiNieR/XUiMainLine/XUiPanelMainlineChapter")

function XUiFubenNierLineChapter:OnAwake()

    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.BtnTongBlue.CallBack = function() self:OnBtnTongBlueClick() end
    self.BtnTeam.CallBack = function() self:OnBtnTeamClick() end
    self.BtnPOD.CallBack = function() self:OnBtnPODClick() end
    self.BtnRenWu.CallBack = function() self:OnBtnRenWuClick() end
    self.BtnShop.CallBack = function() self:OnBtnShopClick() end
    self.BtnTongBlue.gameObject:SetActiveEx(false)
    self:BindHelpBtn(self.BtnHelp, "NierLineChapterHelp")

    self.XUiNieRLineBanner = PanelMainlineChapter.New(self.PanelMainlineChapter, self)
    -- self.UiNierMainLineBanner:UpdateData()
    
end

function XUiFubenNierLineChapter:OnStart(curChapterId)
    self.CurChapterId = curChapterId
    self:AddRedPointEvent()
end

function XUiFubenNierLineChapter:OnEnable()

    if XDataCenter.NieRManager.GetIsActivityEnd() then
        XScheduleManager.ScheduleOnce(function()
            if not self.GameObject or  not self.GameObject:Exist() then return end
            XDataCenter.NieRManager.OnActivityEnd()
        end, 1)
    else

        if XDataCenter.NieRManager.CheckFirstNieREasterEggStageShow() then
            XScheduleManager.ScheduleOnce(function()
               if not self.GameObject or  not self.GameObject:Exist() then return end
               self:Close()
            end, 1)
        else
            self.CurChapterData = XDataCenter.NieRManager.GetChapterDataById(self.CurChapterId)
            local unlockCount, count = XDataCenter.NieRManager.GetCharacterCount()
            local nierPOD = XDataCenter.NieRManager.GetNieRPODData()

            self.BtnTeam:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnTeamNameStr"))
            self.BtnPOD:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnPODNameStr"))
            self.BtnRenWu:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnRenWuNameStr"))
            self.BtnShop:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnShopNameStr"))


            self.BtnTeam:SetNameByGroup(1, string.format("%s/%s", unlockCount, count))
            self.BtnPOD:SetNameByGroup(1, string.format("Lv.%s", nierPOD:GetNieRPODLevel()))
            self.XUiNieRLineBanner:UpdateAllInfo()

            XDataCenter.NieRManager.CheckNieRMainLineUITips()
        end
    end
end

function XUiFubenNierLineChapter:OnDisable()
    
end


function XUiFubenNierLineChapter:OnDestroy()
    --self.XUiNieRLineBanner:StopTween()
end

--添加点事件
function XUiFubenNierLineChapter:AddRedPointEvent()
    XRedPointManager.AddRedPointEvent(self.BtnRenWu, self.RefreshTaskRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_TASK_RED }, -1)
    XRedPointManager.AddRedPointEvent(self.BtnTeam, self.RefreshTeamRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED }, {CharacterId = -1, IsInfor = true, IsTeach = true})
    XRedPointManager.AddRedPointEvent(self.BtnPOD, self.RefreshPODRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_POD_RED })
end

--任务按钮红点
function XUiFubenNierLineChapter:RefreshTaskRedDot(count)
    self.BtnRenWuRed.gameObject:SetActiveEx(count >= 0)
end

--尼尔角色按钮红点
function XUiFubenNierLineChapter:RefreshTeamRedDot(count)
    self.BtnTeamRed.gameObject:SetActiveEx(count >= 0)
end

--辅助机按钮红点
function XUiFubenNierLineChapter:RefreshPODRedDot(count)
    self.BtnPODRed.gameObject:SetActiveEx(count >= 0)
end

function XUiFubenNierLineChapter:OnBtnBackClick()
    self:Close()
end

function XUiFubenNierLineChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenNierLineChapter:OnBtnTongBlueClick()
    XLog.Debug("OnBtnTongBlueClick")
end

function XUiFubenNierLineChapter:OnBtnTeamClick()
    XLuaUiManager.Open("UiNierCharacterSel")
end

function XUiFubenNierLineChapter:OnBtnPODClick()
    XLuaUiManager.Open("UiFuBenNierWork")
end

function XUiFubenNierLineChapter:OnBtnRenWuClick()
    local skipId = self.CurChapterData:GetNieRChapterTaskSkipId()
    if skipId and skipId ~= 0 then
        XFunctionManager.SkipInterface(skipId)
    else
        XLuaUiManager.Open("UiNierTask")
    end
end

function XUiFubenNierLineChapter:OnBtnShopClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
    or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        XLuaUiManager.Open("UiNierShop")
    end
end

function XUiFubenNierLineChapter:GetNieRLineBanner()
    return self.XUiNieRLineBanner
end