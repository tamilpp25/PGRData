local XUiDrawSuitPreview = XLuaUiManager.Register(XLuaUi, "UiDrawSuitPreview")

function XUiDrawSuitPreview:OnAwake()
    self:InitAutoScript()
end


function XUiDrawSuitPreview:OnStart(suitId, parentUi)
    self.ParentUi = parentUi
    self.Grids = {}
    self:UpdatePanel()
end

function XUiDrawSuitPreview:UpdatePanel()
    self.SuitId = self.ParentUi.CurSuitId
    self.GridCommon.gameObject:SetActive(false)
    local skillDesList = XDataCenter.EquipManager.GetSuitSkillDesList(self.SuitId)
    for i = 1, XEquipConfig.MAX_SUIT_SKILL_COUNT do
        if skillDesList[i * 2] then
            self["TxtSkillDes" .. i].text = skillDesList[i * 2]
            self["TxtSkillDes" .. i].gameObject:SetActive(true)
        else
            self["TxtSkillDes" .. i].gameObject:SetActive(false)
        end
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelContent)
    self.TxtName.text = XDataCenter.EquipManager.GetSuitName(self.SuitId)
    self.RImgIco:SetRawImage(XDataCenter.EquipManager.GetSuitBigIconBagPath(self.SuitId))
    local ids = XDataCenter.EquipManager.GetEquipTemplateIdsBySuitId(self.SuitId)

    table.sort(ids, function(a, b)
        local aid = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(a)
        local bid = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(b)
        return aid.Site < bid.Site
    end)

    for i = 1, #ids do
        if not self.Grids[i] then
            local go = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelGrid)
            local item = XUiGridCommon.New(self, go)
            go.gameObject:SetActive(true)
            table.insert(self.Grids, item)
        end
    end

    for i = 1, #self.Grids do
        self.Grids[i]:Refresh(ids[i])
    end

    for i = #ids + 1, #self.Grids do
        self.Grids[i].GameObject:SetActive(false)
    end
end

function XUiDrawSuitPreview:RefreshData()

end

function XUiDrawSuitPreview:OnEnable()
    if self.ParentUi then
        self:UpdatePanel()
    end
end


-- auto
-- Automatic generation of code, forbid to edit
function XUiDrawSuitPreview:InitAutoScript()
    self:AutoAddListener()
end

function XUiDrawSuitPreview:AutoAddListener()
    -- self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end
-- auto
