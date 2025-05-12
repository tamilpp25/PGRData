local XPanelQualityWholeV2P6 = XClass(XUiNode, "XPanelQualityWholeV2P6")

function XPanelQualityWholeV2P6:OnStart()
    self:InitButton()
    
    local xUiPanelEvoSkillTips = require("XUi/XUiCharacterV2P6/Grid/XUiPanelEvoSkillTips")
    self.PanelEvoSkillTips = xUiPanelEvoSkillTips.New(self.PanelEvoSkillTips, self)
end

function XPanelQualityWholeV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnOverview, self.OnBtnOverviewClick)
end

function XPanelQualityWholeV2P6:OnEnable()
    self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Quality)
    self.Parent.ParentUi.PanelModel:SetDynamicTableActive(true)
    -- 进化技能提示
    self.PanelEvoSkillTips:CheckShow(self.Parent.ParentUi.CurCharacter.Id)

    -- 进化演出锁，进化球演出相关逻辑
    if self.Parent.IsEvoPerform then
        return
    end
    -- 自动定位到角色当前品质的品质球
    local characterId = self.Parent.ParentUi.CurCharacter.Id
    local character = self.Parent.ParentUi.CurCharacter
    local initQuality = XMVCA.XCharacter:GetCharacterInitialQuality(characterId)
    local curLuaInex = character.Quality - initQuality + 1
    self.Parent.ParentUi.PanelModel:RefreshDynamicTable3D(curLuaInex)
end

function XPanelQualityWholeV2P6:OnDisable()
    self.Parent.ParentUi.PanelModel:SetDynamicTableActive(false)
end

function XPanelQualityWholeV2P6:OnBtnOverviewClick()
    local enbaleCb = function ()
        self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.QualityOverview)
    end
    local closeCb = function ()
        self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Quality)
    end
    XLuaUiManager.Open("UiCharacterQualityOverviewV2P6", self.Parent.ParentUi.CurCharacter.Id, enbaleCb, closeCb)  --取到 uicharacterSystem的当前角色
end

return XPanelQualityWholeV2P6
