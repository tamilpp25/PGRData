local XUiFubenPractice = XLuaUiManager.Register(XLuaUi, "UiFubenPractice")

local ChildDetailUi = "UiPracticeSingleDetail"

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

    -- 初始化tabGroup
    self.BtnTabList = {}
    self.ChapterDetailList = XPracticeConfigs.GetPracticeChapterDetails()
    for id, chapterDetail in pairs(self.ChapterDetailList) do
        local chapter = XPracticeConfigs.GetPracticeChapterById(id)
        if not self.BtnTabList[id] then
            local tabGo = CS.UnityEngine.Object.Instantiate(self.BtnTabShortNew.gameObject)
            tabGo.transform:SetParent(self.UiContent, false)
            self.BtnTabList[id] = tabGo.transform:GetComponent("XUiButton")
        end
        self.BtnTabList[id].gameObject:SetActive(chapter.IsOpen == 1)
        self.BtnTabList[id]:SetNameByGroup(0, chapterDetail.Name)
    end
    self.BtnTabShortNew.gameObject:SetActive(false)

    self.BtnGroupList:Init(self.BtnTabList, function(id) self:SelectPanel(id) end)
end

function XUiFubenPractice:AddBtnsListeners()
    self:BindHelpBtn(self.BtnHelp, "Practice")
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnMaskDetail.CallBack = function() self:OnBtnMaskDetailClick() end
end

function XUiFubenPractice:OnResume(data)
    self.CurrentSelect = data
end

function XUiFubenPractice:OnStart(tabType)
    self:CheckTabConditions()
    self:SetAssetPanelActive(true)

    self.CurrentSelect = self.CurrentSelect or tabType or self:GetDefaultOpen()
    self.BtnGroupList:SelectIndex(self.CurrentSelect)
    --self.AnimEnable:PlayTimelineAnimation()
end

function XUiFubenPractice:OnReleaseInst()
    return self.CurrentSelect
end

function XUiFubenPractice:SetAssetPanelActive(isActive)
    self.AssetPanel.GameObject:SetActiveEx(isActive)
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

function XUiFubenPractice:CheckTabConditions()
    if not self.ChapterDetailList then return end
    for id, _ in pairs(self.ChapterDetailList) do
        local conditionId = XPracticeConfigs.GetPracticeChapterConditionById(id)
        self.BtnTabList[id]:SetButtonState(CS.UiButtonState.Normal)
        if conditionId ~= nil and conditionId > 0 then
            local ret = XConditionManager.CheckCondition(conditionId)
            if not ret then
                self.BtnTabList[id]:SetButtonState(CS.UiButtonState.Disable)
            end
        end
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

    self:CloseStageDetail()
    self.CurrentSelect = id
    self.CurrentType = XPracticeConfigs.GetPracticeChapterTypeById(id)

    self.PracticeBasics:SetPanelActive(self.CurrentType == XPracticeConfigs.PracticeType.Basics, id)
    self.PracticeAdvanced:SetPanelActive(self.CurrentType == XPracticeConfigs.PracticeType.Advanced, id)
    self.PracticeCharacter:SetPanelActive(self.CurrentType == XPracticeConfigs.PracticeType.Character, id)
end

function XUiFubenPractice:RefreshSelectPanel()
    if not self.CurrentSelect then return end
    if XPracticeConfigs.PracticeType.Basics == self.CurrentType then
        self.PracticeBasics:ShowPanelDetail()
    elseif XPracticeConfigs.PracticeType.Advanced == self.CurrentType then
        self.PracticeAdvanced:ShowPanelDetail()
    elseif XPracticeConfigs.PracticeType.Character == self.CurrentType then
        self.PracticeCharacter:ShowPanelDetail()
    end
end

function XUiFubenPractice:OpenStageDetail(stageId)
    self:OpenOneChildUi(ChildDetailUi, self)
    self:FindChildUiObj(ChildDetailUi):Refresh(stageId)
    self:SetAssetPanelActive(false)
end

function XUiFubenPractice:CloseStageDetail()
    if XLuaUiManager.IsUiShow(ChildDetailUi) then
        self:FindChildUiObj(ChildDetailUi):CloseWithAnimation()
        self:OnPracticeDetailClose()
        self:SetAssetPanelActive(true)
    end
end

function XUiFubenPractice:OnPracticeDetailClose()
    if XPracticeConfigs.PracticeType.Basics == self.CurrentType then
        self.PracticeBasics:OnPracticeDetailClose()
    elseif XPracticeConfigs.PracticeType.Advanced == self.CurrentType then
        self.PracticeAdvanced:OnPracticeDetailClose()
    elseif XPracticeConfigs.PracticeType.Character == self.CurrentType then
        self.PracticeCharacter:OnPracticeDetailClose()
    end
end

function XUiFubenPractice:SwitchBg(mode)
    local details = XPracticeConfigs.GetPracticeChapterDetailById(mode)
    if not details then return end
    self.RImgBg:SetRawImage(details.BgPath)
end