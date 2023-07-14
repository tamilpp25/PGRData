---@class XStageItem
local XStageItem = XClass(nil, "XStageItem")

function XStageItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XStageItem:SetNormalStage()
    self.PanelStageNormal.gameObject:SetActiveEx(not self.IsLock)
    if not self.IsLock then
        self.RImgFightActiveNor:SetRawImage(self.FStage:GetIcon())
    end
    if self.ImgStoryNor then
        self.ImgStoryNor:SetRawImage(self.FStage:GetIcon())
    end
    self.TxtStageOrder.text = self.FStage:GetOrderName()
    -- SetLockStage
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
end


function XStageItem:SetPassStage()
    self.PanelStagePass.gameObject:SetActiveEx(self.FStage:GetIsPass())
end

function XStageItem:UpdateNode(festivalId, stageId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then return end
    self.FestivalId = festivalId
    self.StageId = stageId
    self.FStage = fStage
    self.FChapter = fStage:GetChapter()
    self.StageIndex = fStage:GetOrderIndex()
    local stagePrefabName = fStage:GetStagePrefab()
    local isOpen, description = self.FStage:GetCanOpen()
    self.GameObject:SetActiveEx(isOpen)
    local gridGameObject = self.Transform:LoadPrefab(stagePrefabName)
    local uiObj = gridGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end
    self.IsLock = not isOpen
    self.Description = description
    self:SetNormalStage()
    self:SetPassStage()
    local isEgg = self.FStage:GetIsEggStage()
    self.ImgStageOrder.gameObject:SetActiveEx(not isEgg)
    if self.ImgStageHide then
        self.ImgStageHide.gameObject:SetActiveEx(isEgg)
    end
    if self.ImgHideLine then
        self.ImgHideLine.gameObject:SetActiveEx(isEgg)
    end

end

function XStageItem:OnBtnStageClick()
    if self.FStage then
        if not self.IsLock then
            self.RootUi:UpdateNodesSelect(self.StageId)
            -- 打开详细界面
            self.RootUi:OpenStageDetails(self.StageId, self.FestivalId)
        else
            XUiManager.TipMsg(self.Description)
        end

    end
end

function XStageItem:SetNodeSelect(isSelect)
    if not self.IsLock and self.ImageSelected then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XStageItem:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent("RectTransform").rect
        self.Transform.localPosition = CS.UnityEngine.Vector3(pos.x, pos.y - rect.height, pos.z)
    end
end

return XStageItem