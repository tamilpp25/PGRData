XUiPanelPracticeCharacter = XClass(nil, "XUiPanelPracticeCharacter")
local XUguiDragProxy = CS.XUguiDragProxy

function XUiPanelPracticeCharacter:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AddBtnsListeners()
end

function XUiPanelPracticeCharacter:AddBtnsListeners()
    self.BtnActDesc.CallBack = function() self:OnBtnActDescClick() end
end

function XUiPanelPracticeCharacter:InitViews(id)
    self.CharacterDetail = XPracticeConfigs.GetPracticeChapterDetailById(id)
    self.CharacterChapter = XPracticeConfigs.GetPracticeChapterById(id)
    self.ChapterId = id
    self.CharacterChapterGO = self.PanelPrequelStages:LoadPrefab(self.CharacterDetail.PracticeContentPrefab)
    local uiObj = self.CharacterChapterGO.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end

    self.CharacterStages = {}
    for i = 1, #self.CharacterChapter.StageId do
        local characterStage = self.CharacterContent:Find(string.format("Stage%d", i))
        if not characterStage then
            XLog.Error("XUiPanelPracticeChapter:InitViews() 函数错误: 游戏物体CharacterContent下找不到名字为：" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        characterStage.gameObject:SetActiveEx(true)
        local gridStageGO = characterStage:LoadPrefab(self.CharacterDetail.PracticeGridPrefab)
        self.CharacterStages[i] = XUiPracticeBasicsStage.New(self.RootUi, gridStageGO, self)
    end

    local indexChapter = #self.CharacterChapter.StageId + 1
    local extraStage = self.CharacterContent:Find(string.format("Stage%d", indexChapter))
    while extraStage do
        extraStage.gameObject:SetActive(false)
        indexChapter = indexChapter + 1
        extraStage = self.CharacterContent:Find(string.format("Stage%d", indexChapter))
    end

    local dragProxy = self.CharacterScrollRect:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.CharacterScrollRect.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiPanelPracticeCharacter:OnDragProxy(dragType)
    if dragType == 0 then
        self.RootUi:CloseStageDetail()
    end
end

function XUiPanelPracticeCharacter:SetPanelActive(value, id)
    self.GameObject:SetActiveEx(false) -- 打开之前要先关一次(要不复用这个界面PanelStageContent大小会有问题)
    self.GameObject:SetActive(value)
    if value then
        self:InitViews(id)
        self:ShowPanelDetail()
        self.RootUi:PlayAnimation("PanelCharacterQieHuan")
    end
end

function XUiPanelPracticeCharacter:OnBtnActDescClick()
    XUiManager.UiFubenDialogTip(CS.XTextManager.GetText("DormDes"), XPracticeConfigs.GetPracticeDescriptionById(self.ChapterId))
end

function XUiPanelPracticeCharacter:ShowPanelDetail()
    self.TxtMode.text = self.CharacterDetail.Name

    self:UpdateNodes()
    self.RootUi:SwitchBg(self.ChapterId)
end

function XUiPanelPracticeCharacter:UpdateNodes()
    self.Nodes = XDataCenter.PracticeManager.GetSortedChapterStage(self.ChapterId)
    --self:SortCharacterChapterStages(self.CharacterChapter.StageId)

    for i = 1, #self.Nodes do
        local node = self.Nodes[i]
        self.CharacterStages[i].GameObject:SetActive(true)
        self.CharacterStages[i]:UpdateNode(node.StageId, XPracticeConfigs.PracticeType.Character)
    end

    for i = #self.Nodes + 1, #self.CharacterStages do
        self.CharacterStages[i].GameObject:SetActive(false)
    end

    if self.CharacterScrollRect then
        self.CharacterScrollRect.horizontalNormalizedPosition = 0
    end
end

function XUiPanelPracticeCharacter:PlayScrollViewMove(gridTransform)
    self.CharacterScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridRect = gridTransform:GetComponent("RectTransform")
    self.CharacterViewport.raycastTarget = false
    local diffX = gridRect.localPosition.x + self.CharacterContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local tarPos = self.CharacterContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.CharacterContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiPanelPracticeCharacter:OnPracticeDetailClose()
    self.CharacterScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self.CharacterViewport.raycastTarget = true
end

return XUiPanelPracticeCharacter