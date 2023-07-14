local XUiStageItem = XClass(nil, "XUiStageItem")

local XUiPanelStars = require("XUi/XUiFubenMainLineChapter/XUiPanelStars")

function XUiStageItem:Ctor(rootUi, ui, chapterIndex)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ChapterIndex = chapterIndex
    XTool.InitUiObject(self)
end

function XUiStageItem:SetNormalStage(stageId, stagePrefix, stageName)
    self.PanelStageNormal.gameObject:SetActiveEx(not self.IsLock)

    local indexText = XFubenCoupleCombatConfig.GetStageIndexText(stageId)
    self.TxtStageTitle.text = indexText ~= nil and indexText or string.format("%02d", self.Index)
    
    if self.IsLastOne then -- 双星第三期普通模式最后一关双前置锁UI处理
        self.PanelStageLock.gameObject:SetActiveEx(false)
        self.PanelHardLock.gameObject:SetActiveEx(self.IsLock)
        
        local preStageIdList = XFubenConfigs.GetPreStageId(stageId)
        for i = 1, #preStageIdList do
            XUiHelper.TryGetComponent(self.PanelHardLock, "Line/LineWhite" .. i).gameObject:SetActiveEx(XDataCenter.FubenManager.CheckStageIsPass(preStageIdList[i]))
        end
    else -- 普通锁处理
        self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
        self.PanelHardLock.gameObject:SetActiveEx(false)
    end
    self:SetPassStage()
    self:SetNodeSelect(false)
end

function XUiStageItem:SetPassStage()
    --XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
    local useList = XDataCenter.FubenCoupleCombatManager.GetStageUsedCharacter(self.StageId)
    if useList and next(useList) then
        self.PanelHead.gameObject:SetActiveEx(true)
        self.PanelStagePass.gameObject:SetActiveEx(true)
        for i, v in ipairs(useList) do
            self["RImgHead" .. i]:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(XRobotManager.GetCharacterId(v), true))
        end
    else
        self.PanelHead.gameObject:SetActiveEx(false)
        self.PanelStagePass.gameObject:SetActiveEx(false)
    end
end

function XUiStageItem:UpdateNode(stageId, index, chapterId)
    self.StageId = stageId
    self.Index = index
    self.GameObject:SetActiveEx(true)

    local chapterIndex = self.ChapterIndex
    local actCfg = XDataCenter.FubenCoupleCombatManager.GetCurrentActTemplate()

    local gridGo = self.Transform:LoadPrefab(actCfg.GridPrefab)
    local uiObj = gridGo.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end

    local stageGridBg = XFubenCoupleCombatConfig.GetStageGridBg(stageId)
    if stageGridBg then
        self.RImgNormalBg:SetRawImage(stageGridBg)
    end
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    self.IsLock = not stageInfo.Unlock

    -- 双星第三期判定本关实例是否是普通模式最后一个关卡
    if XFubenCoupleCombatConfig.GetChapterType(chapterId) == XFubenCoupleCombatConfig.ChapterType.Normal and XTool.IsNumberValid(XFubenCoupleCombatConfig.GetStageIsLastOne(stageId)) then
        self.IsLastOne = true
    end
    
    self:SetNormalStage(self.StageId)
end

function XUiStageItem:OnBtnStageClick()
    if not self.StageId then return end
    if not self.IsLock then
        self.RootUi:UpdateNodesSelect(self.StageId)
        -- 打开详细界面
        self.RootUi:OpenStageDetails(self.StageId)
        self.RootUi:PlayScrollViewMove(self.Transform)
    else
        -- 是否达到时间
        local isInOpenTime, desc = XDataCenter.FubenCoupleCombatManager.CheckStageOpen(self.StageId, true)
        if isInOpenTime then
            desc = CS.XTextManager.GetText("FubenPreStageNotPass")
        end
        XUiManager.TipMsg(desc)
    end
end

function XUiStageItem:SetNodeSelect(isSelect)
    if not self.IsLock then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiStageItem:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent("RectTransform").rect
        self.Transform.localPosition = CS.UnityEngine.Vector3(pos.x, pos.y - rect.height, pos.z)
    end
end

return XUiStageItem