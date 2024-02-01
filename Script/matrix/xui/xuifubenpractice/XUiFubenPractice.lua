local XUiFubenPractice = XLuaUiManager.Register(XLuaUi, "UiFubenPractice")
local XUiPanelPracticeBoss = require("XUi/XUiFubenPractice/XUiPanelPracticeBoss")
local XUiPanelPracticeBasics = require("XUi/XUiFubenPractice/XUiPanelPracticeBasics")
local XUiPanelPracticeAdvanced = require("XUi/XUiFubenPractice/XUiPanelPracticeAdvanced")
local XUiPanelPracticeCharacter = require("XUi/XUiFubenPractice/XUiPanelPracticeCharacter")
local ChildDetailUi = "UiPracticeSingleDetail"
local ChildBossDetailUi = "UiPracticeBossDetail"
local ChildCharacterDetailUi = "UiFubenPracticeCharacterDetail"

function XUiFubenPractice:OnAwake()
    self:InitViews()
    self:AddBtnsListeners()

    XEventManager.AddEventListener(XEventId.EVENT_PRACTICE_ON_DATA_REFRESH, self.RefreshSelectPanel, self)
end

function XUiFubenPractice:InitViews()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.PracticeBasics = XUiPanelPracticeBasics.New(self, self.PanelBasics)
    self.PracticeAdvanced = XUiPanelPracticeAdvanced.New(self, self.PanelAdvanced)
    self.PracticeCharacter = XUiPanelPracticeCharacter.New(self, self.PanelCharacter)
    self.PracticeBoss = XUiPanelPracticeBoss.New(self, self.PanelBoss)

    -- 初始化tabGroup
    self.BtnTabList = {}
    self.ChapterDetailList = XPracticeConfigs.GetPracticeChapterDetails()
    for id, chapterDetail in pairs(self.ChapterDetailList) do
        local chapter = XPracticeConfigs.GetPracticeChapterById(id)
        if not self.BtnTabList[id] then
            if not XTool.IsNumberValid(chapterDetail.SubTag) then
                local tabGo = CS.UnityEngine.Object.Instantiate(self.BtnTabShortNew.gameObject)
                tabGo.transform:SetParent(self.UiContent, false)
                self.BtnTabList[id] = tabGo.transform:GetComponent("XUiButton")
            else
                --二级节点
                if XPracticeConfigs.GetPracticeChapterTypeById(id) == XPracticeConfigs.PracticeType.Boss
                        and not XDataCenter.PracticeManager.CheckPracticeStagesVisibleByChapterId(id) then
                    goto continue
                end

                local tabGo = CS.UnityEngine.Object.Instantiate(self.BtnTabShortSecond.gameObject)
                tabGo.transform:SetParent(self.UiContent, false)
                self.BtnTabList[id] = tabGo.transform:GetComponent("XUiButton")
                self.BtnTabList[id].SubGroupIndex = chapterDetail.SubTag
            end
        end
        self.BtnTabList[id].gameObject:SetActiveEx(chapter.IsOpen == 1)
        self.BtnTabList[id]:SetNameByGroup(0, chapterDetail.Name)
        :: continue ::
    end
    self.BtnTabShortNew.gameObject:SetActiveEx(false)
    self.BtnTabShortSecond.gameObject:SetActiveEx(false) 

    self.BtnGroupList:Init(self.BtnTabList, function(id) self:SelectPanel(id) end)
    self:RefreshBtnMainTabShow()
end

function XUiFubenPractice:AddBtnsListeners()
    self:BindHelpBtn(self.BtnHelp, "Practice")
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnMaskDetail.CallBack = function() self:OnBtnMaskDetailClick() end
end

function XUiFubenPractice:OnResume(data)
    self.CurrentSelect = data.CurrentSelect
    self.SelectStageId = data.SelectStageId
end

function XUiFubenPractice:OnStart(tabType, stageId)
    self:CheckTabConditions()
    self:SetAssetPanelActive(true)

    self.CurrentSelect = self.CurrentSelect or (XTool.IsNumberValid(tabType) and tabType or self:GetDefaultOpen())
    if not self.SelectStageId then
        self:SetSelectStageId(stageId)
    end
    self.BtnGroupList:SelectIndex(self.CurrentSelect)
    --self.AnimEnable:PlayTimelineAnimation()
end

function XUiFubenPractice:OnReleaseInst()
    return {CurrentSelect = self.CurrentSelect, SelectStageId = self.SelectStageId}
end

function XUiFubenPractice:SetAssetPanelActive(isActive)
    if isActive then
        self.AssetPanel:Open()
    else
        self.AssetPanel:Close()
    end
end

function XUiFubenPractice:GetDefaultOpen()
    local chapterDetailList = XPracticeConfigs.GetPracticeChapterDetails()
    local default = XPracticeConfigs.PracticeType.Basics
    for id, _ in ipairs(chapterDetailList) do
        local chapter = XPracticeConfigs.GetPracticeChapterById(id)
        if chapter.IsOpen == 1 then
            default = id
            break
        end
    end
    return default
end

function XUiFubenPractice:OnEnable()
    if XPracticeConfigs.PracticeType.Boss == self.CurrentType and XDataCenter.PracticeManager.GetIsChallengeWin() then
        local childUiObj = self:FindChildUiObj(ChildBossDetailUi)
        if childUiObj then
            childUiObj:CloseWithAnimation(true)
        end
        XDataCenter.PracticeManager.ChallengeLose()
    end

    self:CheckRedPoint()
end

function XUiFubenPractice:OnDisable()
    if not self.CurrentSelect then return end
    self:OnPracticeDetailClose()
end

function XUiFubenPractice:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_PRACTICE_ON_DATA_REFRESH, self.RefreshSelectPanel, self)
end

function XUiFubenPractice:OnBtnBackClick()
    self:Close()
end

function XUiFubenPractice:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenPractice:OnBtnMaskDetailClick()
    self:CloseStageDetail()
end

function XUiFubenPractice:RefreshBtnMainTabShow()--主按钮的显示
    local showMainTag = false
    local mainTag
    for id, v in pairs(self.BtnTabList) do
        local param = XDataCenter.PracticeManager.CheckUnLockBtnState(id)
        if param ~= nil then
            if type(param) == "number" then
                mainTag = id
            else
                showMainTag = showMainTag or param
            end
        end
    end
    self.BtnTabList[mainTag].gameObject:SetActiveEx(showMainTag)
end

function XUiFubenPractice:CheckTabConditions()
    if not self.ChapterDetailList then return end
    for id, _ in pairs(self.ChapterDetailList) do
        if not self.BtnTabList[id] then
            goto continue
        end

        local conditionId = XPracticeConfigs.GetPracticeChapterConditionById(id)
        self.BtnTabList[id]:SetButtonState(CS.UiButtonState.Normal)
        if conditionId ~= nil and conditionId > 0 then
            local ret = XConditionManager.CheckCondition(conditionId)
            if not ret then
                self.BtnTabList[id]:SetButtonState(CS.UiButtonState.Disable)
            end
        end
        :: continue ::
    end
end

function XUiFubenPractice:SelectPanel(id)
    local chapterDetail = self.ChapterDetailList[id]
    if chapterDetail then
        local conditionId = XPracticeConfigs.GetPracticeChapterConditionById(chapterDetail.Id)
        if conditionId ~= nil and conditionId > 0 then
            local ret, desc = XConditionManager.CheckCondition(conditionId)
            if not ret then
                XUiManager.TipMsg(desc)
                return
            end
        end
    end

    if chapterDetail and chapterDetail.Type == XPracticeConfigs.PracticeType.Boss then
        if not XMVCA.XSubPackage:CheckSubpackage() then
            self.BtnGroupList:SelectIndex(self.CurrentSelect, false)
            return 
        end
    end

        --切换标签或关卡胜利，重置当前选择的关卡Id
    if self.CurrentSelect and self.CurrentSelect ~= id or XDataCenter.PracticeManager.GetIsChallengeWin() then
        self:SetSelectStageId()
        XDataCenter.PracticeManager.ChallengeLose()
    end

    self:CloseStageDetail()
    self.CurrentSelect = id
    self.CurrentType = XPracticeConfigs.GetPracticeChapterTypeById(id)

    if self.CurrentType == XPracticeConfigs.PracticeType.Boss then
        XDataCenter.PracticeManager.SaveClickBossNewChallenger(id)
        self:CheckBossRedPoint()
    end

    self.PracticeBasics:SetPanelActive(self.CurrentType == XPracticeConfigs.PracticeType.Basics, id)
    self.PracticeAdvanced:SetPanelActive(self.CurrentType == XPracticeConfigs.PracticeType.Advanced, id)
    self.PracticeCharacter:SetPanelActive(self.CurrentType == XPracticeConfigs.PracticeType.Character, id, self.SelectStageId)
    self.PracticeBoss:SetPanelActive(self.CurrentType == XPracticeConfigs.PracticeType.Boss, id, self.SelectStageId)
end

function XUiFubenPractice:RefreshSelectPanel()
    if not self.CurrentSelect then return end
    if XPracticeConfigs.PracticeType.Basics == self.CurrentType then
        self.PracticeBasics:ShowPanelDetail()
    elseif XPracticeConfigs.PracticeType.Advanced == self.CurrentType then
        self.PracticeAdvanced:ShowPanelDetail()
    elseif XPracticeConfigs.PracticeType.Character == self.CurrentType then
        self.PracticeCharacter:ShowPanelDetail()
    elseif XPracticeConfigs.PracticeType.Boss == self.CurrentType then
        self.PracticeBoss:ShowPanelDetail()
    end
end

function XUiFubenPractice:OpenStageDetail(stageId)
    if XPracticeConfigs.PracticeType.Boss == self.CurrentType then
        self:OpenOneChildUi(ChildBossDetailUi, self)
        self:FindChildUiObj(ChildBossDetailUi):OpenRefresh(stageId)
    elseif XPracticeConfigs.PracticeType.Character == self.CurrentType then
        XLuaUiManager.Open(ChildCharacterDetailUi, stageId)
    else
        self:OpenOneChildUi(ChildDetailUi, self)
        self:FindChildUiObj(ChildDetailUi):Refresh(stageId)
    end
    self:SetAssetPanelActive(false)
end

function XUiFubenPractice:CloseStageDetail()
    if XLuaUiManager.IsUiShow(ChildDetailUi) then
        self:FindChildUiObj(ChildDetailUi):CloseWithAnimation()
    end
    if XLuaUiManager.IsUiShow(ChildBossDetailUi) then
        self:FindChildUiObj(ChildBossDetailUi):CloseWithAnimation()
    end
    if XLuaUiManager.IsUiShow(ChildCharacterDetailUi) then
        XLuaUiManager.Close(ChildCharacterDetailUi)
    end
    self:OnPracticeDetailClose()
    self:SetAssetPanelActive(true)
end

function XUiFubenPractice:OnPracticeDetailClose()
    if XPracticeConfigs.PracticeType.Basics == self.CurrentType then
        self.PracticeBasics:OnPracticeDetailClose()
    elseif XPracticeConfigs.PracticeType.Advanced == self.CurrentType then
        self.PracticeAdvanced:OnPracticeDetailClose()
    elseif XPracticeConfigs.PracticeType.Character == self.CurrentType then
        self.PracticeCharacter:OnPracticeDetailClose()
    elseif XPracticeConfigs.PracticeType.Boss == self.CurrentType then
        self.PracticeBoss:OnPracticeDetailClose()
    end
end

function XUiFubenPractice:SwitchBg(mode)
    local details = XPracticeConfigs.GetPracticeChapterDetailById(mode)
    if not details then return end
    self.RImgBg:SetRawImage(details.BgPath)
end

function XUiFubenPractice:SetSelectStageId(selectStageId)
    self.SelectStageId = selectStageId
end

function XUiFubenPractice:CheckRedPoint()
    self:CheckBossRedPoint()
end

function XUiFubenPractice:CheckBossRedPoint()
    local type
    local chapter
    local isParentShowRed = false
    local parentBtnTab
    local isChildShowRed

    for chapterDetailId, btnTab in pairs(self.BtnTabList) do
        type = XPracticeConfigs.GetPracticeChapterTypeById(chapterDetailId)
        chapter = XPracticeConfigs.GetPracticeChapterById(chapterDetailId)
        if XTool.IsNumberValid(chapter.IsOpen) and type == XPracticeConfigs.PracticeType.Boss then
            if btnTab.SubGroupIndex < 0 then
                parentBtnTab = btnTab
            else
                isChildShowRed = not XDataCenter.PracticeManager.CheckBossNewChallengerRedPoint(chapterDetailId)
                btnTab:ShowReddot(isChildShowRed)
            end

            if isChildShowRed then
                isParentShowRed = true
            end
        end
    end

    if parentBtnTab then
        parentBtnTab:ShowReddot(isParentShowRed)
    end
end