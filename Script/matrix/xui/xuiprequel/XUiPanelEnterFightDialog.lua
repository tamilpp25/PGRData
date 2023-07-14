XUiPanelEnterFightDialog = XClass(nil, "XUiPanelEnterFightDialog")

function XUiPanelEnterFightDialog:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelEnterFightDialog:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelEnterFightDialog:AutoInitUi()
    self.BtnMaskB = self.Transform:Find("BtnMask"):GetComponent("Button")
    self.PanelStory = self.Transform:Find("PanelStory")
    self.TxtStoryName = self.Transform:Find("PanelStory/TxtStoryName"):GetComponent("Text")
    self.TxtStoryDec = self.Transform:Find("PanelStory/TxtStoryDec"):GetComponent("Text")
    self.RImgStory = self.Transform:Find("PanelStory/RImgStory"):GetComponent("RawImage")
    self.BtnEnterStory = self.Transform:Find("PanelStory/BtnEnterStory"):GetComponent("Button")
    self.PanelFight = self.Transform:Find("PanelFight")
    self.TxtFightName = self.Transform:Find("PanelFight/TxtFightName"):GetComponent("Text")
    self.TxtFightDec = self.Transform:Find("PanelFight/TxtFightDec"):GetComponent("Text")
    self.RImgFight = self.Transform:Find("PanelFight/RImgFight"):GetComponent("RawImage")
    self.BtnEnterFight = self.Transform:Find("PanelFight/BtnEnterFight"):GetComponent("Button")
end

function XUiPanelEnterFightDialog:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelEnterFightDialog:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelEnterFightDialog:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelEnterFightDialog:AutoAddListener()
    self:RegisterClickEvent(self.BtnMaskB, self.OnBtnMaskBClick)
    self:RegisterClickEvent(self.BtnEnterStory, self.OnBtnEnterStoryClick)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
end
-- auto
function XUiPanelEnterFightDialog:OnBtnMaskBClick()
    self:OnCloseDialog()
end

function XUiPanelEnterFightDialog:OnBtnEnterStoryClick()
    if self:PreCheckChapterCondition() then return end

    self:OnCallback()
end

function XUiPanelEnterFightDialog:OnBtnEnterFightClick()
    if self:PreCheckChapterCondition() then return end

    self:OnCallback()
end

function XUiPanelEnterFightDialog:PreCheckChapterCondition()
    if self.StageId then
        local chapterId = XDataCenter.PrequelManager.GetChapterIdByStageId(self.StageId)
        if chapterId then
            local unlockDescription = XDataCenter.PrequelManager.GetChapterUnlockDescription(chapterId)
            if unlockDescription then
                XUiManager.TipMsg(unlockDescription)
                self:OnCloseDialog()
                return true
            end
        end
    end
    return false
end

function XUiPanelEnterFightDialog:OnShowStoryDialog(stageId, callback)
    self.StageId = stageId
    self.Callback = callback
    self.PanelStory.gameObject:SetActiveEx(true)
    self.PanelFight.gameObject:SetActiveEx(false)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtStoryName.text = stageCfg.Name
    self.TxtStoryDec.text = stageCfg.Description
    self.RImgStory:SetRawImage(stageCfg.Icon)
end

function XUiPanelEnterFightDialog:OnShowFightDialog(stageId, callback)
    self.StageId = stageId
    self.Callback = callback
    self.PanelFight.gameObject:SetActiveEx(true)
    self.PanelStory.gameObject:SetActiveEx(false)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtFightName.text = stageCfg.Name
    self.TxtFightDec.text = stageCfg.Description
    self.RImgFight:SetRawImage(stageCfg.Icon)
end

function XUiPanelEnterFightDialog:OnCallback()
    if self.Callback then
        self.Callback()
    end
    self:OnCloseDialog()
end

function XUiPanelEnterFightDialog:OnCloseDialog()
    if XTool.UObjIsNil(self.GameObject) then return end
    self.GameObject:SetActiveEx(false)
end


return XUiPanelEnterFightDialog