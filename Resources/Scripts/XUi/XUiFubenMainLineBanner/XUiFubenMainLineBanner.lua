local XUiPanelChapterBfrt = require("XUi/XUiFubenMainLineBanner/XUiPanelChapterBfrt")
local XUiPanelChapterExtra = require("XUi/XUiFubenMainLineBanner/XUiPanelChapterExtra")
local XUiFubenMainLineBanner = XLuaUiManager.Register(XLuaUi, "UiFubenMainLineBanner")

local CSGameConfig = CS.XGame.ClientConfig

local TAB_BTN_INDEX = {
    MAINLINE = 1,
    DZ = 2,
    BFRT = 3,
    EXTRA = 4,
}

--grid里的itme定位X坐标偏移量
local GRID_ITEM_OFFSET_X = 1.7


function XUiFubenMainLineBanner:OnAwake()
    self:InitAutoScript()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetProxy(XUiGridMainLineBanner)
    self.DynamicTable:SetDelegate(self)
    self.GridMainLineBanner.gameObject:SetActiveEx(false)
    self.ChapterDz = XUiPanelChapterDz.New(self.PanelChapterDz, self)
    self.ChapterBfrt = XUiPanelChapterBfrt.New(self.PanelChapterBfrt, self.ParentUi)
    self.ChapterExtra = XUiPanelChapterExtra.New(self.PanelChapterEX, self.ParentUi, self)
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
    self.CurDiff = XDataCenter.FubenMainLineManager.GetCurDifficult()
    self.CurExtraDifficult = XDataCenter.ExtraChapterManager.GetCurDiffcult()
    self:SetPlayerPrefsPosX()
    self:Refresh(false)
    self:PlayAnimation("QIEHuan")
end

function XUiFubenMainLineBanner:OnStart(defaultTab)
    self.PanelTab:SelectIndex(defaultTab or TAB_BTN_INDEX.MAINLINE)
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
    end

    -- 难度toggle
    self:UpdateDifficultToggles()
end

function XUiFubenMainLineBanner:OnCoverChapterChanged()
    -- if self.ChapterDz then
    --     self.ChapterDz:OnCoverChanged(chooseInfo)
    -- end
end

--动态列表事件
function XUiFubenMainLineBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateChapterGrid(self.PageDatas[index], self.CurDiff)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:ClickChapterGrid(self.PageDatas[index], index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not XDataCenter.GuideManager.CheckIsInGuide() then
            self:AutoScroll()
        end
    end
end

--设置动态列表
function XUiFubenMainLineBanner:SetupDynamicTable(index)
    if not self.CurDiff then return end
    self.PageDatas = XDataCenter.FubenMainLineManager.GetChapterMainTemplates(self.CurDiff)

    -- 远程配置屏蔽，只保留第一关
    if XUiManager.IsHideFunc then
        local temp = self.PageDatas[1]
        self.PageDatas = {}
        self.PageDatas[1] = temp
    end
    
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(index)
end

--@region 动态列表自动跳转
function XUiFubenMainLineBanner:SetPlayerPrefsPosX()
    self.PlayerPrefsPosX = {}

    for _, type in pairs(self.TYPE) do
        local keyX = self:GetPlayerPrefsKey(type)
        if CS.UnityEngine.PlayerPrefs.HasKey(keyX) then
            self.PlayerPrefsPosX[type] = CS.UnityEngine.PlayerPrefs.GetFloat(keyX)
        end
    end
end

--优先选择上一次操作的界面，否则选择最新的章节
function XUiFubenMainLineBanner:AutoScroll()
    local rt = self.PanelChapterContent:GetComponent("RectTransform")
    local posX = self.PlayerPrefsPosX[self.CurDiff]

    if not posX then
        posX = self:GetTheLatestChapterPosX()
    end

    rt:DOAnchorPosX(posX, 0.5)
end

function XUiFubenMainLineBanner:GetTheLatestChapterPosX()
    if self.PageDatas then
        local index = 0
        for i, pageDatas in ipairs(self.PageDatas) do
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(pageDatas.Id, self.CurDiff)
            if chapterInfo.Unlock then
                index = i
            end
        end

        return self:GetChapterPosXByIndex_X(index)
    else
        return 0
    end
end

--获取grid里对应item的坐标X轴
function XUiFubenMainLineBanner:GetChapterPosXByIndex_X(index)
    if index >= 2 then
        --使其贴近最右侧显示
        index = index - GRID_ITEM_OFFSET_X
    else
        index = 0
    end

    local dynamicTableNormal = self.PanelChapterList.gameObject:GetComponent(typeof(CS.XDynamicTableNormal))
    return -1 * (dynamicTableNormal.GridSize.x + dynamicTableNormal.Spacing.x) * index
end

function XUiFubenMainLineBanner:SaveScrollPos(index)
    local keyX = self:GetPlayerPrefsKey(self.CurDiff)
    CS.UnityEngine.PlayerPrefs.SetFloat(keyX, self:GetChapterPosXByIndex_X(index))
end

function XUiFubenMainLineBanner:GetPlayerPrefsKey(curDiff)
    --CurDiff：普通副本或隐藏副本
    return string.format("%s-%s-%s", "DynamicTable_MainLineChapterPosX", tostring(XPlayer.Id), curDiff)
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
    self.PanelChapterContent = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelChapterList/Viewport/PanelChapterContent")
    self.GridMainLineBanner = self.Transform:Find("FullScreenBackground/MainLineChapter3d/PanelChapterList/Viewport/GridMainLineBanner")
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
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
end
-- auto
function XUiFubenMainLineBanner:InitTabBtnGroup()
    local tabGroup = {
        self.BtnTabZX,
        self.BtnTabDZ,
        self.BtnTabJD,
        self.BtnTabFW,
    }
    self.BtnTabDZ:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Prequel))
    self.BtnTabJD:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenNightmare))
    self.BtnTabFW:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Extra))
    self.PanelTab:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)

    -- 功能屏蔽
    self.BtnTabDZ.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Prequel))
    if XUiManager.IsHideFunc then
        self:HideFunc()
    end
end

---
---  隐藏外篇、间章、据点按钮
function XUiFubenMainLineBanner:HideFunc()
    self.BtnTabFW.gameObject:SetActiveEx(false)
    self.BtnTabDZ.gameObject:SetActiveEx(false)
    self.BtnTabJD.gameObject:SetActiveEx(false)
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
    end
    self.CurrentSelect = tabIndex
end

-- 断章
function XUiFubenMainLineBanner:RefreshPrequel(playAnimation)
    self.PanelTopDifficult.gameObject:SetActiveEx(false)
    self.PanelChapterList.gameObject:SetActiveEx(false)
    self.PanelChapterBfrt.gameObject:SetActiveEx(false)
    self.PanelChapterEX.gameObject:SetActiveEx(false)
    self.PanelChapterDz.gameObject:SetActiveEx(true)
    self.BtnHelp.gameObject:SetActive(false)
    self.ChapterDz:SetupCoverDatas(self.DefaultCoverId, self.DefaultChapterId)
    if playAnimation and (not self.DefaultCoverId) then
        self:PlayAnimation("DzQieHuanEnable")
    end
    self.DefaultCoverId = nil
    self.DefaultChapterId = nil
end

function XUiFubenMainLineBanner:RefreshBfrt()
    self.PanelTopDifficult.gameObject:SetActiveEx(false)
    self.PanelChapterList.gameObject:SetActiveEx(false)
    self.PanelChapterDz.gameObject:SetActiveEx(false)
    self.PanelChapterBfrt.gameObject:SetActiveEx(true)
    self.PanelChapterEX.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActive(true)
    self.ChapterBfrt:SetupBfrtChapters()
end

function XUiFubenMainLineBanner:RefreshMainLine(playAnimation)
    self:UpdateMainLineDifficultToggles()
    if XUiManager.IsHideFunc then
        self.PanelTopDifficult.gameObject:SetActiveEx(false)
    else
        self.PanelTopDifficult.gameObject:SetActiveEx(true)
    end
    self.PanelChapterList.gameObject:SetActiveEx(true)
    self.PanelChapterBfrt.gameObject:SetActiveEx(false)
    self.PanelChapterDz.gameObject:SetActiveEx(false)
    self.PanelChapterEX.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActive(false)
    self:SetupDynamicTable()
    if playAnimation then
        self:PlayAnimation("ListQieHuanEnable")
    end
end

function XUiFubenMainLineBanner:RefreshExtra(playAnimation)
    self:UpdateExtraDifficultToggles()
    self.PanelChapterDz.gameObject:SetActiveEx(false)
    if XUiManager.IsHideFunc then
        self.PanelTopDifficult.gameObject:SetActiveEx(false)
    else
        self.PanelTopDifficult.gameObject:SetActiveEx(true)
    end
    self.PanelChapterList.gameObject:SetActiveEx(false)
    self.PanelChapterBfrt.gameObject:SetActiveEx(false)
    self.PanelChapterEX.gameObject:SetActiveEx(true)
    self.BtnHelp.gameObject:SetActive(false)
    self.ChapterExtra:UpdateCoverData(self.CurExtraDifficult)
    if playAnimation then
        self:PlayAnimation("EXQieHuanEnable")
    end
end

function XUiFubenMainLineBanner:OnBtnCloseDifficultClick()
    self:UpdateDifficultToggles()
end

function XUiFubenMainLineBanner:OnBtnNormalClick()
    if self.IsShowDifficultPanel then
        if self.CurrentSelect == TAB_BTN_INDEX.MAINLINE then
            self:SetCurMainLineDifficult(self.TYPE.NORMAL)
        elseif self.CurrentSelect == TAB_BTN_INDEX.EXTRA then
            self:SetCurExtraDifficult(self.TYPE.NORMAL)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
end

function XUiFubenMainLineBanner:OnBtnHardClick()
    if self.IsShowDifficultPanel then
        if self.CurrentSelect == TAB_BTN_INDEX.MAINLINE then
            self:SetCurMainLineDifficult(self.TYPE.HARD)
        elseif self.CurrentSelect == TAB_BTN_INDEX.EXTRA then
            self:SetCurExtraDifficult(self.TYPE.HARD)
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

-- 选中一个 chapter grid，需要设置层级、状态
function XUiFubenMainLineBanner:ClickChapterGrid(chapterMain, index)
    local chapter = XDataCenter.FubenMainLineManager.GetChapterCfgByChapterMain(chapterMain.Id, self.CurDiff)
    local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(chapterMain.Id, self.CurDiff)
    if chapterInfo.Unlock then
        self.ParentUi:PushUi(function()
            if chapterMain.Id == XDataCenter.FubenMainLineManager.TRPGChapterId then
                local uiName = XDataCenter.TRPGManager.GetMainName()
                XLuaUiManager.Open(uiName)
            else
                XLuaUiManager.Open("UiFubenMainLineChapter", chapter)
            end
        end)

        self:SaveScrollPos(index)
    elseif chapterInfo.IsActivity then
        local chapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMain.Id, self.CurDiff)
        local ret, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
        end
    else
        if self.CurDiff == XDataCenter.FubenManager.DifficultNightmare then
            XUiManager.TipMsg(CS.XTextManager.GetText("BfrtChapterUnlockCondition"))
        elseif chapterMain.Id == XDataCenter.FubenMainLineManager.TRPGChapterId then
            XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MainLineTRPG)
        else
            local chapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMain.Id, self.CurDiff)
            local isOpen, desc = XDataCenter.FubenMainLineManager.CheckOpenCondition(chapterId)
            if not isOpen then
                XUiManager.TipMsg(desc)
                return
            end
            self:ChapterLockTipMsg(chapterInfo)
        end
    end
end

function XUiFubenMainLineBanner:ChapterLockTipMsg(chapterInfo)
    local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
    XUiManager.TipMsg(tipMsg)
end

function XUiFubenMainLineBanner:UpdateDifficultToggles(showAll)
    if showAll then
        self:SetBtnTogleActive(true, true, true)
        self.BtnCloseDifficult.gameObject:SetActiveEx(true)
    else
        if self.CurrentSelect == TAB_BTN_INDEX.MAINLINE then
            self:UpdateMainLineDifficultToggles()
        elseif self.CurrentSelect == TAB_BTN_INDEX.EXTRA then
            self:UpdateExtraDifficultToggles()
        end
        self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    end

    self.IsShowDifficultPanel = showAll
end

function XUiFubenMainLineBanner:UpdateMainLineDifficultToggles()
    if self.CurDiff == self.TYPE.NORMAL then
        self:SetBtnTogleActive(true, false, false)
        self.BtnNormal.transform:SetAsFirstSibling()
    elseif self.CurDiff == self.TYPE.HARD then
        self:SetBtnTogleActive(false, true, false)
        self.BtnHard.transform:SetAsFirstSibling()
    else
        self:SetBtnTogleActive(false, false, true)
    end
end

function XUiFubenMainLineBanner:UpdateExtraDifficultToggles()
    if self.CurExtraDifficult == self.TYPE.NORMAL then
        self:SetBtnTogleActive(true, false, false)
        self.BtnNormal.transform:SetAsFirstSibling()
    elseif self.CurExtraDifficult == self.TYPE.HARD then
        self:SetBtnTogleActive(false, true, false)
        self.BtnHard.transform:SetAsFirstSibling()
    else
        self:SetBtnTogleActive(false, false, true)
    end
end

function XUiFubenMainLineBanner:SetBtnTogleActive(isNormal, isHard)
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
    elseif evt == XEventId.EVENT_FUBEN_EXTRA_DIFFICUTY_SELECT then
        self.CurrentSelect = nil
        self.CurExtraDifficult = self.TYPE.HARD
        XDataCenter.ExtraChapterManager.SetCurDifficult(self.CurExtraDifficult)
        self.PanelTab:SelectIndex(TAB_BTN_INDEX.EXTRA)
        self:UpdateDifficultToggles()
    end
end

--据点点击了帮助按钮
function XUiFubenMainLineBanner:OnBtnHelpClick()
    local helpContent = CSGameConfig:GetString("BfrtShowHelpTip01")
    XUiManager.ShowHelpTip(helpContent)
end