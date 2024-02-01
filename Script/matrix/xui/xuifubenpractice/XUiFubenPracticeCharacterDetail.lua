local XUiPanelPracticeMainline = require("XUi/XUiFubenPractice/XUiPanelPracticeMainline")
local XUiFubenPracticeCharacterDetail = XLuaUiManager.Register(XLuaUi, "UiFubenPracticeCharacterDetail")
local ChildDetailUi = "UiPracticeCharacterDetail"

function XUiFubenPracticeCharacterDetail:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiFubenPracticeCharacterDetail:OnStart(groupId, defaultStageId)
    self.GroupId = groupId
    self.DefaultStageId = defaultStageId
    self:LoadPrefab(groupId)
end

function XUiFubenPracticeCharacterDetail:LoadPrefab(groupId)
    -- 预制体
    local prefabPath = XPracticeConfigs.GetPracticeGroupPrefabName(groupId)
    if prefabPath then
        local go = self.PanelChapter:LoadPrefab(prefabPath)
        self.PracticeMainline = XUiPanelPracticeMainline.New(go, groupId, handler(self, self.CloseStageDetailCb), handler(self, self.ShowStageDetail))
        self.PracticeMainline:Refresh()
        if XTool.IsNumberValid(self.DefaultStageId) then
            self.PracticeMainline:OnSelectStageByStageId(self.DefaultStageId)
        end
    end
end

function XUiFubenPracticeCharacterDetail:CloseStageDetailCb()
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self.AssetPanel:Open()
    if XLuaUiManager.IsUiShow(ChildDetailUi) then
        self:FindChildUiObj(ChildDetailUi):CloseWithAnimation()
    end
end

function XUiFubenPracticeCharacterDetail:ShowStageDetail(stageId)
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    self.AssetPanel:Close()
    self.StageId = stageId
    self:OpenOneChildUi(ChildDetailUi, self)
    self:FindChildUiObj(ChildDetailUi):Refresh(stageId)
end


function XUiFubenPracticeCharacterDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.SceneBtnBack, self.OnSceneBtnBack)
    XUiHelper.RegisterClickEvent(self, self.SceneBtnMainUi, self.OnSceneBtnMainUi)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.OnBtnCloseDetail)
    self:BindHelpBtn(self.BtnHelp, "PracticeCharacterDetail")
end

function XUiFubenPracticeCharacterDetail:OnSceneBtnBack()
    self:Close()
end

function XUiFubenPracticeCharacterDetail:OnSceneBtnMainUi()
    XLuaUiManager.RunMain()
end

-- 关闭关卡详情界面
function XUiFubenPracticeCharacterDetail:OnBtnCloseDetail()
    self.PracticeMainline:CancelSelect()
end

return XUiFubenPracticeCharacterDetail