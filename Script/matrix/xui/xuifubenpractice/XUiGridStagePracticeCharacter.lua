local XUiGridStagePracticeCharacter = XClass(nil,"XUiGridStagePracticeCharacter")

function XUiGridStagePracticeCharacter:Ctor(ui, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = cb
    XTool.InitUiObject(self)

    self:RegisterUiEvents()
end

function XUiGridStagePracticeCharacter:UpdateStage(stageId, groupId)
    self.GroupId = groupId
    self.StageId = stageId
    self:Refresh()
end

function XUiGridStagePracticeCharacter:Refresh()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    -- 关卡名称
    if self.TxtPracticeName then
        self.TxtPracticeName.text = stageCfg.Description
    end
    -- 图标
    if self.RImgBg then
        self.RImgBg:SetRawImage(stageCfg.Icon)
    end
    -- 通关标志
    if self.PanelStagePass then
        self.PanelStagePass.gameObject:SetActiveEx(stageInfo.Passed)
    end
    -- 名称
    if self.TxtStageOrder then
        self.TxtStageOrder.text = stageCfg.Name
    end
    -- 角色类型
    if self.ImgType then
        local characterId = XPracticeConfigs.GetPracticeGroupCharacterId(self.GroupId)
        if XTool.IsNumberValid(characterId) then
            local characterType = XMVCA.XCharacter:GetCharDetailCareer(characterId)
            self.ImgType:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(characterType))
        else
            local generalSkillId = XPracticeConfigs.GetGeneralSkillIdByGroupId(self.GroupId)
            if XTool.IsNumberValid(generalSkillId) then
                self.ImgType:SetRawImage(XPracticeConfigs.GetPracticeGroupIcon(self.GroupId))
            end
        end
    end
end

function XUiGridStagePracticeCharacter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStage)
end

function XUiGridStagePracticeCharacter:OnBtnStage()
    if self.ClickCb then
        self.ClickCb(self)
    end
end

--- 是否显示选中框
function XUiGridStagePracticeCharacter:SetSelect(isSelect)
    self.ImageSelected.gameObject:SetActiveEx(isSelect)
end

return XUiGridStagePracticeCharacter