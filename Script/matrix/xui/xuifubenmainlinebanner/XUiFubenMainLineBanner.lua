local XUiPanelChapterBfrt = require("XUi/XUiFubenMainLineBanner/XUiPanelChapterBfrt")
local XUiPanelChapterExtra = require("XUi/XUiFubenMainLineBanner/XUiPanelChapterExtra")
local XUiPanelChapterDP = require("XUi/XUiFubenMainLineBanner/XUiPanelChapterDP")
local XUiPanelChapterDz = require("XUi/XUiFubenMainLineBanner/XUiPanelChapterDz")
local XUiPanelMainLineBanner = require("XUi/XUiFubenMainLineBanner/XUiPanelMainLineBanner")

local XUiFubenMainLineBanner = XLuaUiManager.Register(XLuaUi, "UiFubenMainLineBanner")

local TAB_BTN_INDEX = {
    MAINLINE = 1,
    DZ = 2,
    DP = 3,
    BFRT = 4,
    EXTRA = 5
}

function XUiFubenMainLineBanner:OnAwake()
    self:InitAutoScript()
    self.MainLineBanner = XUiPanelMainLineBanner.New(self.PanelChapterList, self.ParentUi)
    self.ChapterDz = XUiPanelChapterDz.New(self.PanelChapterDz, self)
    self.ChapterBfrt = XUiPanelChapterBfrt.New(self.PanelChapterBfrt, self.ParentUi)
    self.ChapterExtra = XUiPanelChapterExtra.New(self.PanelChapterEX, self.ParentUi, self)
    self.ChapterDP = XUiPanelChapterDP.New(self.PanelChapterDP, self.ParentUi) --故事集
    self.IsShowDifficultPanel = false
    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_SELECTCOVER_CHANGE, self.OnCoverChapterChanged, self)
    self:InitTabBtnGroup()

    --副本类型：普通，隐藏
    self.TYPE = {
        NORMAL = XDataCenter.FubenManager.DifficultNormal,
        HARD = XDataCenter.FubenManager.DifficultHard,
    }
end

function XUiFubenMainLineBanner:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_SELECTCOVER_CHANGE, self.OnCoverChapterChanged)
end

function XUiFubenMainLineBanner:OnEnable()
    self.PanelTab:SelectIndex(self.CurrentSelect or TAB_BTN_INDEX.MAINLINE)

    self.CurDiff = XDataCenter.FubenMainLineManager.GetCurDifficult()
    self.CurExtraDifficult = XDataCenter.ExtraChapterManager.GetCurDiffcult()
    self.CurDPDifficult = XDataCenter.ShortStoryChapterManager.GetCurDifficult()
    self.MainLineBanner:SetPlayerPrefsPosX(self.TYPE)
    self:Refresh(false)
    self:PlayAnimation("QIEHuan")
end

function XUiFubenMainLineBanner:SetSelectIndex(defaultTab)
    self.CurrentSelect = defaultTab or TAB_BTN_INDEX.MAINLINE
end

function XUiFubenMainLineBanner:Refresh(playAnimation)
    if self.CurrentSelect == TAB_BTN_INDEX.MAINLINE then
        self:RefreshMainLine(playAnimation)
    elseif self.CurrentSelect == TAB_BTN_INDEX.DZ then
        self:RefreshPrequel(playAnimation)
    elseif self.CurrentSelect == TAB_BTN_INDEX.BFRT then
        self:RefreshBfrt(playAnimation)
    elseif self.CurrentSelect == TAB_BTN_INDEX.EXTRA then
        self:RefreshExtra(playAnimation)
    elseif self.CurrentSelect == TAB_BTN_INDEX.DP then
        self:RefreshShortStory(playAnimation)
    end

    -- 难度toggle
    self:UpdateDifficultToggles()
end

function XUiFubenMainLineBanner:OnCoverChapterChanged()
    -- if self.ChapterDz then
    --     self.ChapterDz:OnCoverChanged(chooseInfo)
    -- end
end

--@endregion
-- auto
-- Automatic generation of code, forbid to edit
function XUiFubenMainLineBanner:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiFubenMainLineBanner:AutoInitUi()
    self.PanelChapterList = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelChapterList")
    self.PanelChapterDz = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelChapterDz")
    self.BtnCloseDifficult = self.Transform:Find("FullScreenBackground/MainLineChapter3d/BtnCloseDifficult"):GetComponent("Button")
    self.PanelTopDifficult = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelTopDifficult")
    self.BtnNormal = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelTopDifficult/BtnNormal"):GetComponent("Button")
    self.PanelNormalOn = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelTopDifficult/BtnNormal/PanelNormalOn")
    self.PanelNormalOff = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelTopDifficult/BtnNormal/PanelNormalOff")
    self.BtnHard = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelTopDifficult/BtnHard"):GetComponent("Button")
    self.PanelHardOn = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelTopDifficult/BtnHard/PanelHardOn")
    self.PanelHardOff = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelTopDifficult/BtnHard/PanelHardOff")
end

function XUiFubenMainLineBanner:AutoAddListener()
    self:RegisterClickEvent(self.BtnCloseDifficult, self.OnBtnCloseDifficultClick)
    self:RegisterClickEvent(self.BtnNormal, self.OnBtnNormalClick)
    self:RegisterClickEvent(self.BtnHard, self.OnBtnHardClick)
end
-- auto
function XUiFubenMainLineBanner:InitTabBtnGroup()
    local tabGroup = {
        self.BtnTabZX,
        self.BtnTabDZ,
        self.BtnTabDP,
        self.BtnTabJD,
        self.BtnTabFW,
    }
    self.BtnTabDZ:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Prequel))
    self.BtnTabJD:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenNightmare))
    self.BtnTabFW:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Extra))
    self.BtnTabDP:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShortStory)) 
    self.PanelTab:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)

    -- 功能屏蔽
    self.BtnTabDZ.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Prequel))
    if XUiManager.IsHideFunc then
        self:HideFunc()
    end
end

--  隐藏外篇、故事集、间章、据点按钮
function XUiFubenMainLineBanner:HideFunc()
    self.BtnTabFW.gameObject:SetActiveEx(false)
    self.BtnTabDZ.gameObject:SetActiveEx(false)
    self.BtnTabJD.gameObject:SetActiveEx(false)
    self.BtnTabDP.gameObject:SetActiveEx(false)
end

function XUiFubenMainLineBanner:OnClickTabCallBack(tabIndex)
    if self.CurrentSelect and self.CurrentSelect == tabIndex then
        return
    end

    if tabIndex == TAB_BTN_INDEX.MAINLINE then
        self:RefreshMainLine(true)
    elseif tabIndex == TAB_BTN_INDEX.DZ then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Prequel) then
            return
        end
        self:RefreshPrequel(true)
    elseif tabIndex == TAB_BTN_INDEX.BFRT then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenNightmare) then
            return
        end
        self:RefreshBfrt(true)
    elseif tabIndex == TAB_BTN_INDEX.EXTRA then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Extra) then
            return
        end
        self:RefreshExtra(true)
    elseif tabIndex == TAB_BTN_INDEX.DP then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShortStory) then
            return
        end
        self:RefreshShortStory(true)
    end
    self.CurrentSelect = tabIndex
    self:UpdateDifficultToggles()
end

function XUiFubenMainLineBanner:HidePanelChapter()
    self.PanelTopDifficult.gameObject:SetActiveEx(false)
    self.PanelChapterList.gameObject:SetActiveEx(false)
    self.PanelChapterBfrt.gameObject:SetActiveEx(false)
    self.PanelChapterEX.gameObject:SetActiveEx(false)
    self.PanelChapterDP.gameObject:SetActiveEx(false)
    self.PanelChapterDz.gameObject:SetActiveEx(false)
end

-- 断章
function XUiFubenMainLineBanner:RefreshPrequel(playAnimation)
    self:HidePanelChapter()
    self.PanelChapterDz.gameObject:SetActiveEx(true)
    self.ChapterDz:SetupCoverDatas(self.DefaultCoverId, self.DefaultChapterId)
    if playAnimation and (not self.DefaultCoverId) then
        self:PlayAnimation("DzQieHuanEnable")
    end
    self.DefaultCoverId = nil
    self.DefaultChapterId = nil
end

function XUiFubenMainLineBanner:RefreshBfrt()
    self:HidePanelChapter()
    self.PanelChapterBfrt.gameObject:SetActiveEx(true)
    self.ChapterBfrt:SetupBfrtChapters()
end

function XUiFubenMainLineBanner:RefreshMainLine(playAnimation)
    self:HidePanelChapter()
    if not XUiManager.IsHideFunc then
        self.PanelTopDifficult.gameObject:SetActiveEx(true)
    end
    self.PanelChapterList.gameObject:SetActiveEx(true)
    self.MainLineBanner:SetupDynamicTable(self.CurDiff)
    if playAnimation then
        self:PlayAnimation("ListQieHuanEnable")
    end
end

function XUiFubenMainLineBanner:RefreshExtra(playAnimation)
    self:HidePanelChapter()
    if not XUiManager.IsHideFunc then
        self.PanelTopDifficult.gameObject:SetActiveEx(true)
    end
    self.PanelChapterEX.gameObject:SetActiveEx(true)
    self.ChapterExtra:UpdateCoverData(self.CurExtraDifficult)
    if playAnimation then
        self:PlayAnimation("EXQieHuanEnable")
    end
end

function XUiFubenMainLineBanner:RefreshShortStory(playAnimation)
    self:HidePanelChapter()
    local chapterIds = XFubenShortStoryChapterConfigs.GetChapterIdsByDifficult(self.TYPE.HARD)
    if not XUiManager.IsHideFunc and not XTool.IsTableEmpty(chapterIds) then
        self.PanelTopDifficult.gameObject:SetActiveEx(true)
    end
    self.PanelChapterDP.gameObject:SetActiveEx(true)
    self.ChapterDP:UpdateCoverData(self.CurDPDifficult)
    if playAnimation then
        self:PlayAnimation("DPQieHuanEnable")
    end
end

function XUiFubenMainLineBanner:OnBtnCloseDifficultClick()
    self:UpdateDifficultToggles()
end

function XUiFubenMainLineBanner:OnBtnNormalClick()
    self:OnBtnNormalAndHardClick(self.TYPE.NORMAL)
end

function XUiFubenMainLineBanner:OnBtnHardClick()
    self:OnBtnNormalAndHardClick(self.TYPE.HARD)
end

function XUiFubenMainLineBanner:OnBtnNormalAndHardClick(difficultType)
    if self.IsShowDifficultPanel then
        if self.CurrentSelect == TAB_BTN_INDEX.MAINLINE then
            self:SetCurMainLineDifficult(difficultType)
        elseif self.CurrentSelect == TAB_BTN_INDEX.EXTRA then
            self:SetCurExtraDifficult(difficultType)
        elseif self.CurrentSelect == TAB_BTN_INDEX.DP then
            self:SetCurShortStoryDifficult(difficultType)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
end

function XUiFubenMainLineBanner:SetCurMainLineDifficult(difficult)
    if self.CurDiff == difficult then return end
    -- 检查困难开启
    if difficult == self.TYPE.HARD and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenDifficulty) then
        return
    end
    self.CurDiff = difficult
    XDataCenter.FubenMainLineManager.SetCurDifficult(self.CurDiff)
    self:RefreshForChangeDiff()
end

function XUiFubenMainLineBanner:SetCurExtraDifficult(difficult)
    if self.CurExtraDifficult == difficult then return end
    -- 检查困难开启
    if difficult == self.TYPE.HARD and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenDifficulty) then
        return
    end
    self.CurExtraDifficult = difficult
    XDataCenter.ExtraChapterManager.SetCurDifficult(self.CurExtraDifficult)
    self:RefreshForChangeDiff()
end

function XUiFubenMainLineBanner:SetCurShortStoryDifficult(difficult)
    if self.CurDPDifficult == difficult then return end
    -- 检查困难开启
    if difficult == self.TYPE.HARD and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenDifficulty) then
        return
    end
    self.CurDPDifficult = difficult
    XDataCenter.ShortStoryChapterManager.SetCurDifficult(self.CurDPDifficult)
    self:RefreshForChangeDiff()
end

function XUiFubenMainLineBanner:UpdateDifficultToggles(showAll)
    if showAll then
        self:SetBtnToggleActive(true, true, true)
        self.BtnCloseDifficult.gameObject:SetActiveEx(true)
    else
        if self.CurrentSelect == TAB_BTN_INDEX.MAINLINE then
            self:UpdateDifficultToggleActive(self.CurDiff)
        elseif self.CurrentSelect == TAB_BTN_INDEX.EXTRA then
            self:UpdateDifficultToggleActive(self.CurExtraDifficult)
        elseif self.CurrentSelect == TAB_BTN_INDEX.DP then
            self:UpdateDifficultToggleActive(self.CurDPDifficult)
        end
        self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    end

    self.IsShowDifficultPanel = showAll
end

function XUiFubenMainLineBanner:UpdateDifficultToggleActive(difficult)
    if difficult == self.TYPE.NORMAL then
        self:SetBtnToggleActive(true, false, false)
        self.BtnNormal.transform:SetAsFirstSibling()
    elseif difficult == self.TYPE.HARD then
        self:SetBtnToggleActive(false, true, false)
        self.BtnHard.transform:SetAsFirstSibling()
    else
        self:SetBtnToggleActive(false, false, true)
    end
end

function XUiFubenMainLineBanner:SetBtnToggleActive(isNormal, isHard)
    self.BtnNormal.gameObject:SetActiveEx(isNormal)

    self.BtnHard.gameObject:SetActiveEx(isHard)
    if isHard then
        local hardOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty)
        self.PanelHardOn.gameObject:SetActiveEx(hardOpen)
        self.PanelHardOff.gameObject:SetActiveEx(not hardOpen)
    end
end

function XUiFubenMainLineBanner:RefreshForChangeDiff()
    self:PlayAnimation("ListQieHuanEnable")
    self:Refresh(true)
end

function XUiFubenMainLineBanner:OnGetEvents()
    return { XEventId.EVENT_FUBEN_PREQUEL_AUTOSELECT, XEventId.EVENT_FUBEN_MAINLINE_TAB_SELECT, XEventId.EVENT_FUBEN_MAINLINE_DIFFICUTY_SELECT }
end

function XUiFubenMainLineBanner:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_FUBEN_PREQUEL_AUTOSELECT then
        self.DefaultCoverId = args[1]
        self.DefaultChapterId = args[2]
        self.PanelTab:SelectIndex(TAB_BTN_INDEX.DZ)

    elseif evt == XEventId.EVENT_FUBEN_MAINLINE_TAB_SELECT then
        self.PanelTab:SelectIndex(args[1])

    elseif evt == XEventId.EVENT_FUBEN_MAINLINE_DIFFICUTY_SELECT then
        self.CurrentSelect = nil
        self.CurDiff = self.TYPE.HARD
        XDataCenter.FubenMainLineManager.SetCurDifficult(self.CurDiff)
        self.PanelTab:SelectIndex(TAB_BTN_INDEX.MAINLINE)
        self:UpdateDifficultToggles()
    end
end